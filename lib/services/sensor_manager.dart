import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 传感器原始数据
class SensorData {
  final DateTime timestamp;

  /// 加速度 (m/s²)，三轴分量
  final double accelX;
  final double accelY;
  final double accelZ;

  /// 加速度幅度（可用于检测运动剧烈程度）
  double get accelMagnitude =>
      math.sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  /// 去除重力后的加速度幅度（用于检测加减速）
  /// 注意：这只是简单近似，真正的姿态解算需要融合陀螺仪
  double get linearAccelMagnitude => (accelMagnitude - 9.81).abs();

  /// 陀螺仪角速度 (rad/s)，三轴分量
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  /// 陀螺仪角速度幅度
  double get gyroMagnitude =>
      math.sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

  /// 磁场强度 (μT)
  final double magnetX;
  final double magnetY;
  final double magnetZ;

  const SensorData({
    required this.timestamp,
    this.accelX = 0,
    this.accelY = 0,
    this.accelZ = 0,
    this.gyroX = 0,
    this.gyroY = 0,
    this.gyroZ = 0,
    this.magnetX = 0,
    this.magnetY = 0,
    this.magnetZ = 0,
  });

  SensorData copyWith({
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    double? magnetX,
    double? magnetY,
    double? magnetZ,
  }) {
    return SensorData(
      timestamp: DateTime.now(),
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      magnetX: magnetX ?? this.magnetX,
      magnetY: magnetY ?? this.magnetY,
      magnetZ: magnetZ ?? this.magnetZ,
    );
  }
}

/// 传感器管理器 — 统一管理加速度计、陀螺仪、磁力计
class SensorManager extends ChangeNotifier {
  SensorData _data = SensorData(timestamp: DateTime.now());
  SensorData get data => _data;

  bool _isActive = false;
  bool get isActive => _isActive;

  // 采样间隔（微秒）
  static const int defaultInterval = 20000; // 50Hz
  int _interval = defaultInterval;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magnetSub;

  /// 设置采样频率
  void setFrequency(int hz) {
    _interval = (1000000 / hz).round();
    if (_isActive) {
      stop();
      start();
    }
  }

  /// 省电模式（降低频率）
  void setLowPower(bool lowPower) {
    setFrequency(lowPower ? 10 : 50);
  }

  /// 启动所有传感器
  void start() {
    if (_isActive) return;
    _isActive = true;

    _accelSub = accelerometerEventStream(
      samplingPeriod: Duration(microseconds: _interval),
    ).listen(_onAccel);

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: Duration(microseconds: _interval),
    ).listen(_onGyro);

    _magnetSub = magnetometerEventStream(
      samplingPeriod: Duration(microseconds: _interval * 5), // 磁力计低频
    ).listen(_onMagnet);
  }

  /// 停止所有传感器
  void stop() {
    _isActive = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magnetSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magnetSub = null;
  }

  void _onAccel(AccelerometerEvent event) {
    _data = _data.copyWith(
      accelX: event.x,
      accelY: event.y,
      accelZ: event.z,
    );
    notifyListeners();
  }

  void _onGyro(GyroscopeEvent event) {
    _data = _data.copyWith(
      gyroX: event.x,
      gyroY: event.y,
      gyroZ: event.z,
    );
    notifyListeners();
  }

  void _onMagnet(MagnetometerEvent event) {
    _data = _data.copyWith(
      magnetX: event.x,
      magnetY: event.y,
      magnetZ: event.z,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
