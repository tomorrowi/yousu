import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/location_manager.dart';
import '../services/sensor_manager.dart';
import '../services/speed_filter.dart';
import '../services/scene_detector.dart';
import '../storage/trip_repository.dart';

/// 测速状态
enum SpeedState {
  idle,       // 未开始
  running,    // 测速中
  paused,     // 暂停
  noGps,      // GPS 信号丢失
}

/// 测速主页 ViewModel
class SpeedViewModel extends ChangeNotifier {
  final LocationManager _locationManager;
  final SensorManager _sensorManager;
  final SpeedFilter _speedFilter = SpeedFilter();
  final SceneDetector _sceneDetector = SceneDetector();
  final TripRepository _repository;

  SpeedViewModel({
    required LocationManager locationManager,
    required SensorManager sensorManager,
    required TripRepository repository,
  })  : _locationManager = locationManager,
        _sensorManager = sensorManager,
        _repository = repository {
    _locationManager.addListener(_onLocationUpdate);
    _sensorManager.addListener(_onSensorUpdate);
  }

  // MARK: - 状态

  SpeedState _state = SpeedState.idle;
  SpeedState get state => _state;

  double _displaySpeed = 0;
  double get displaySpeed => _displaySpeed;

  double get displaySpeedConverted {
    // 暂时用 km/h，后续可接入单位设置
    return _displaySpeed;
  }

  double _heading = 0;
  double get heading => _heading;

  double _maxSpeed = 0;
  double get maxSpeed => _maxSpeed;

  double _avgSpeed = 0;
  double get avgSpeed => _avgSpeed;

  double _altitude = 0;
  double get altitude => _altitude;

  double _distance = 0;
  double get distance => _distance;

  TripScene _scene = TripScene.unknown;
  TripScene get scene => _scene;

  double _sceneConfidence = 0;
  double get sceneConfidence => _sceneConfidence;

  // 速度历史（供图表使用）
  final List<SpeedDataPoint> speedHistory = [];
  static const int maxHistoryPoints = 300;

  // 限流：最多每 200ms 记录一个数据点
  DateTime? _lastRecordTime;

  // 上一次 GPS 坐标（用于距离累积）
  double? _prevLatitude;
  double? _prevLongitude;

  // 当前行程
  Trip? _currentTrip;

  // GPS 最后更新时间
  DateTime? _lastGpsTime;

  Timer? _tripTimer;
  Timer? _predictionTimer;
  DateTime? _tripStartTime;

  // MARK: - 操作

  /// 开始测速
  Future<void> startSpeedTest() async {
    _speedFilter.reset();
    _sceneDetector.reset();
    _maxSpeed = 0;
    _avgSpeed = 0;
    _displaySpeed = 0;
    _heading = 0;
    _altitude = 0;
    _distance = 0;
    _prevLatitude = null;
    _prevLongitude = null;
    _state = SpeedState.running;
    speedHistory.clear();
    _lastRecordTime = null;

    // 创建行程
    _currentTrip = Trip.create();
    _tripStartTime = DateTime.now();
    _lastGpsTime = null;

    // 启动传感器
    _sensorManager.start();
    await _locationManager.startUpdating();

    // GPS 丢失检测定时器
    _startGpsWatchdog();

    notifyListeners();
  }

  /// 停止测速
  Future<void> stopSpeedTest() async {
    _state = SpeedState.idle;
    _sensorManager.stop();
    await _locationManager.stopUpdating();
    _tripTimer?.cancel();
    _predictionTimer?.cancel();

    // 保存行程
    if (_currentTrip != null) {
      _currentTrip!
        ..endTime = DateTime.now()
        ..maxSpeed = _maxSpeed
        ..avgSpeed = _avgSpeed
        ..distance = _distance
        ..scene = _scene
        ..isCompleted = true;

      await _repository.saveTrip(_currentTrip!);
    }

    _currentTrip = null;
    notifyListeners();
  }

  /// 手动切换场景
  void setScene(TripScene scene) {
    _scene = scene;
    notifyListeners();
  }

  // MARK: - 数据更新

  void _onLocationUpdate() {
    final loc = _locationManager.locationData;
    if (loc == null) return;

    _lastGpsTime = DateTime.now();
    if (_state == SpeedState.noGps) {
      _state = SpeedState.running;
    }

    _heading = loc.course;
    _altitude = loc.altitude;

    // 用经纬度差分累积距离（比 speed*dt 更准确）
    if (_prevLatitude != null && _prevLongitude != null) {
      final deltaM = _haversineDistance(
        _prevLatitude!, _prevLongitude!,
        loc.latitude, loc.longitude,
      );
      if (deltaM < 500) {
        // 过滤掉 GPS 跳变（>500m 不累计）
        _distance += deltaM / 1000.0; // m → km
      }
    }
    _prevLatitude = loc.latitude;
    _prevLongitude = loc.longitude;

    notifyListeners();
  }

  void _onSensorUpdate() {
    if (_state != SpeedState.running && _state != SpeedState.noGps) return;

    final loc = _locationManager.locationData;

    // 没有 GPS 数据时不做速度估算
    if (loc == null || _lastGpsTime == null) return;

    final sensor = _sensorManager.data;

    // 用 GPS 速度做绝对基准，平滑滤波
    final filteredSpeed = _speedFilter.update(loc.speedKmh);

    _displaySpeed = filteredSpeed;

    // 更新最大值
    if (filteredSpeed > _maxSpeed) {
      _maxSpeed = filteredSpeed;
    }

    // 更新均值
    if (speedHistory.isNotEmpty) {
      final total = speedHistory.fold<double>(
        0,
        (sum, p) => sum + p.speed,
      );
      _avgSpeed = (total + filteredSpeed) / (speedHistory.length + 1);
    } else {
      _avgSpeed = filteredSpeed;
    }

    // 场景识别
    _scene = _sceneDetector.update(
      speedKmh: filteredSpeed,
      accelerationMagnitude: sensor.accelMagnitude,
      pressure: null, // sensors_plus 暂不支持气压计
    );
    _sceneConfidence = _sceneDetector.confidence;

    // 记录数据点（限流：最多 5Hz）
    final now = DateTime.now();
    if (_lastRecordTime == null ||
        now.difference(_lastRecordTime!).inMilliseconds >= 200) {
      _lastRecordTime = now;
      speedHistory.add(SpeedDataPoint(
        speed: filteredSpeed,
        heading: _heading,
        altitude: loc.altitude,
      ));
      if (speedHistory.length > maxHistoryPoints) {
        speedHistory.removeAt(0);
      }
    }

    notifyListeners();
  }

  /// GPS 看门狗：超过 10 秒无 GPS 更新则标记 GPS 丢失
  void _startGpsWatchdog() {
    _tripTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_lastGpsTime != null &&
          DateTime.now().difference(_lastGpsTime!).inSeconds > 10) {
        if (_state == SpeedState.running) {
          _state = SpeedState.noGps;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _locationManager.removeListener(_onLocationUpdate);
    _sensorManager.removeListener(_onSensorUpdate);
    _tripTimer?.cancel();
    _predictionTimer?.cancel();
    super.dispose();
  }

  /// Haversine 公式计算两点间距离（米）
  double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371000.0; // 地球半径（米）
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final rLat1 = lat1 * math.pi / 180.0;
    final rLat2 = lat2 * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) * math.cos(rLat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
