import 'dart:math' as math;

/// 卡尔曼滤波器（简化一维版本）
///
/// 融合 GPS 速度（1Hz，绝对但噪声大）和加速度积分（高频但漂移），
/// 输出平滑、高刷新率的速度估计。
class SpeedFilter {
  double _estimatedSpeed = 0;
  double _errorCovariance = 1.0;

  /// 过程噪声 — 反映加速度积分的不确定性
  static const double processNoise = 0.05;

  /// GPS 测量噪声 — 反映 GPS 速度的抖动程度
  static const double measurementNoise = 2.0;

  /// 最小可信速度阈值 (km/h)，低于此值视为静止
  static const double minReliableSpeed = 0.5;

  /// 输入一次 GPS 速度 + 加速度数据，输出平滑速度
  ///
  /// [gpsSpeedKmh] GPS 测得的速度 (km/h)，可能为负值
  /// [accelMs2] 加速度计测得的线加速度 (m/s²)，沿运动方向
  /// [dt] 距上次更新的时间间隔 (秒)
  ///
  /// 返回平滑后的速度 (km/h)
  double update({
    required double gpsSpeedKmh,
    required double accelMs2,
    required double dt,
  }) {
    // 加速度转为 km/h/s，再乘 dt 得到速度变化量
    final accelKmhPerS = accelMs2 * 3.6;
    final predictedSpeed = _estimatedSpeed + accelKmhPerS * dt;

    // 卡尔曼增益
    final kalmanGain =
        _errorCovariance / (_errorCovariance + measurementNoise);

    // 融合 GPS 观测
    _estimatedSpeed =
        predictedSpeed + kalmanGain * (gpsSpeedKmh - predictedSpeed);

    // 更新误差协方差
    _errorCovariance = (1 - kalmanGain) * _errorCovariance + processNoise;

    return _estimatedSpeed;
  }

  /// 仅用加速度推算（GPS 丢失时使用）
  ///
  /// 此时没有观测修正，误差会累积，但短时间可用
  double predict(double accelMs2, double dt) {
    final accelKmhPerS = accelMs2 * 3.6;
    _estimatedSpeed += accelKmhPerS * dt;

    // 增大误差协方差，下一轮 GPS 恢复时会更快收敛
    _errorCovariance += processNoise * 5;

    return _estimatedSpeed;
  }

  /// 强行设定速度（用于初始化或 GPS 恢复后快速拉回）
  void setSpeed(double speedKmh) {
    _estimatedSpeed = speedKmh;
    _errorCovariance = 0.5;
  }

  /// 重置滤波器
  void reset() {
    _estimatedSpeed = 0;
    _errorCovariance = 1.0;
  }

  /// 当前估计速度
  double get estimatedSpeed => _estimatedSpeed.clamp(0, double.infinity);
}
