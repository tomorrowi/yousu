/// 一维速度平滑滤波器
///
/// **设计原则**：不直接用加速度计积分（含重力无法可靠去除），
/// 而是用 GPS 速度做绝对基准，逐帧做指数平滑消除抖动。
///
/// 加速计仅用于检测运动状态（静止/加速/减速），不参与速度计算。
class SpeedFilter {
  double _estimatedSpeed = 0;

  /// 平滑系数（0~1），越小越平滑但响应越慢
  static const double _smoothingFactor = 0.3;

  /// 静止判定阈值 (km/h)，低于此值归零
  static const double minReliableSpeed = 0.8;

  /// GPS 速度变化阈值 (km/h)，超过此值视为突变直接跟随
  static const double _jumpThreshold = 15.0;

  /// 输入 GPS 速度，输出平滑后的速度
  ///
  /// [gpsSpeedKmh] GPS 测得的速度 (km/h)
  ///
  /// 返回平滑后的速度 (km/h)
  double update(double gpsSpeedKmh) {
    // 静止：快速归零，防止 GPS 漂移抖动
    if (gpsSpeedKmh < minReliableSpeed) {
      _estimatedSpeed *= 0.3;
      // 归零阈值：足够小就清零
      if (_estimatedSpeed < 0.3) _estimatedSpeed = 0;
      return _estimatedSpeed;
    }

    // 速度突变（如从静止突然移动）：快速跟随
    if ((gpsSpeedKmh - _estimatedSpeed).abs() > _jumpThreshold) {
      _estimatedSpeed = gpsSpeedKmh;
      return _estimatedSpeed;
    }

    // 正常情况：指数平滑
    _estimatedSpeed = _estimatedSpeed +
        _smoothingFactor * (gpsSpeedKmh - _estimatedSpeed);

    return _estimatedSpeed;
  }

  /// 重置滤波器
  void reset() {
    _estimatedSpeed = 0;
  }

  /// 当前估计速度
  double get estimatedSpeed => _estimatedSpeed.clamp(0, double.infinity);
}
