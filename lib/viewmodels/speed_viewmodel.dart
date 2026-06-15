import 'dart:async';
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
    _state = SpeedState.running;
    speedHistory.clear();

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

    // 确保在 startUpdating 后被正确解析
    if (loc.timestamp.millisecondsSinceEpoch > 0) {
      _altitude = loc.altitude;
    }

    // 累积距离
    if (speedHistory.isNotEmpty) {
      final last = speedHistory.last;
      final dt = loc.timestamp.difference(last.timestamp).inMilliseconds / 1000.0;
      if (dt > 0 && dt < 10) {
        _distance += (loc.speed * dt) / 1000.0; // m/s * s = m → km
      }
    }

    notifyListeners();
  }

  void _onSensorUpdate() {
    if (_state != SpeedState.running && _state != SpeedState.noGps) return;

    final sensor = _sensorManager.data;
    final loc = _locationManager.locationData;

    final now = DateTime.now();
    final dt = speedHistory.isNotEmpty
        ? now.difference(speedHistory.last.timestamp).inMilliseconds / 1000.0
        : 0.0;

    // 用加速度推断运动方向上的加速度
    final accelForward = sensor.accelY; // Y 轴近似为前进方向

    double filteredSpeed;
    if (loc != null && _lastGpsTime != null) {
      // GPS 覆盖范围内，完整融合
      filteredSpeed = _speedFilter.update(
        gpsSpeedKmh: loc.speedKmh,
        accelMs2: accelForward,
        dt: dt.clamp(0, 1.0),
      );
    } else {
      // GPS 丢失，仅用加速度推算
      filteredSpeed = _speedFilter.predict(
        accelForward,
        dt.clamp(0, 1.0),
      );
    }

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

    // 记录数据点
    speedHistory.add(SpeedDataPoint(
      speed: filteredSpeed,
      heading: _heading,
      altitude: loc?.altitude,
    ));
    if (speedHistory.length > maxHistoryPoints) {
      speedHistory.removeAt(0);
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
}
