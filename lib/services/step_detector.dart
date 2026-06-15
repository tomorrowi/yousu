import 'dart:math' as math;

/// 步态检测器 — 通过加速度计峰值检测步伐，估算步行速度
///
/// **原理**：行走时加速度幅度周期性波动，每步产生一个明显的峰值。
/// 通过检测峰值 → 计算步频 → 步频 × 步长 = 步行速度。
///
/// **为什么不用加速度积分**：
/// 加速度计原始数据含重力（~9.81 m/s²），没有姿态解算无法可靠去除。
/// 两次积分后的位移误差按 t² 增长，几秒就发散到几十米。
/// 步态检测按每一步独立计数，没有累积误差，精度远高于纯积分。
///
/// **适用场景**：
/// - GPS 信号弱/缺失时（室内、隧道、高楼间）
/// - 步行速度 2~7 km/h
/// - 不适合跑步（步频过高、步长变化大）
class StepDetector {
  // ── 配置 ──

  /// 步长（米），由用户身高估算：height_cm × 0.00415
  double _strideLengthMeters = 0.705; // 默认 170cm 身高

  /// 最小步间间隔（毫秒），防止误检。对应最快约 240 步/分
  static const int _minStepIntervalMs = 250;

  /// 峰值检测阈值 — 加速度幅度需超过 (重力估算 + 此值) 才计数
  static const double _peakThresholdAboveGravity = 0.5;

  /// 衰退时间（秒）— 超过此时间无新步伐，速度衰减归零
  static const int _decayTimeoutSeconds = 2;

  /// 平滑系数（0~1），越小越平滑
  static const double _speedSmoothing = 0.4;

  // ── 状态 ──

  /// 重力估算（低通滤波）
  double _gravityEstimate = 9.81;

  /// 当前上升沿的加速度幅度最大值
  double _currentPeak = 0;

  /// 是否正处于上升沿
  bool _inRisingPhase = false;

  /// 上一次检测到步伐的时间
  DateTime? _lastStepTime;

  /// 最近几步的间隔（秒），用于计算步频
  final List<double> _recentIntervals = [];
  static const int _maxStoredIntervals = 8;

  /// 总步数（本次测速会话内）
  int _stepCount = 0;

  /// 当前步频（步/分钟）
  double _cadence = 0;

  /// 当前瞬时速度（km/h）
  double _rawSpeedKmh = 0;

  /// 平滑后速度（km/h）
  double _speedKmh = 0;

  /// 室内累计距离（km），由步数 × 步长计算
  double _indoorDistanceKm = 0;

  // ── 公开属性 ──

  double get speedKmh => _speedKmh;
  double get cadence => _cadence;
  int get stepCount => _stepCount;
  double get strideLength => _strideLengthMeters;
  double get indoorDistanceKm => _indoorDistanceKm;

  /// 是否检测到有效步行（有步频输出）
  bool get isWalking => _cadence > 20;

  /// 设置步长（米），由身高变化时调用
  void setStrideLength(double meters) {
    _strideLengthMeters = meters.clamp(0.3, 1.5);
  }

  /// 根据身高（厘米）设置步长
  void setHeight(double heightCm) {
    // 通用公式：步长 ≈ 身高(cm) × 0.415 → 转为米
    _strideLengthMeters = (heightCm * 0.00415).clamp(0.3, 1.5);
  }

  /// 处理一帧加速度数据
  ///
  /// [ax], [ay], [az] — 三轴加速度 (m/s²)，包含重力
  void process(double ax, double ay, double az) {
    final magnitude = math.sqrt(ax * ax + ay * ay + az * az);
    final now = DateTime.now();

    // ── 1. 更新重力估算（低通滤波，α=0.1） ──
    _gravityEstimate = _gravityEstimate * 0.9 + magnitude * 0.1;

    // ── 2. 峰值检测状态机 ──
    final threshold = _gravityEstimate + _peakThresholdAboveGravity;

    if (!_inRisingPhase) {
      // 等待上升沿：幅度首次超过阈值
      if (magnitude > threshold) {
        _inRisingPhase = true;
        _currentPeak = magnitude;
      }
    } else {
      // 在上升沿中：追踪最大值
      if (magnitude > _currentPeak) {
        _currentPeak = magnitude;
      } else if (magnitude < _currentPeak * 0.85) {
        // 下降超过 15%，峰值已过 → 判断是否为有效步伐
        _inRisingPhase = false;

        if (_currentPeak > threshold) {
          final msSinceLast = _lastStepTime != null
              ? now.difference(_lastStepTime!).inMilliseconds
              : _minStepIntervalMs;

          if (msSinceLast >= _minStepIntervalMs) {
            _onStepDetected(msSinceLast / 1000.0, now);
          }
        }
        _currentPeak = 0;
      }
    }

    // ── 3. 衰退检查：长时间无步伐则减速 ──
    if (_lastStepTime != null &&
        now.difference(_lastStepTime!).inSeconds > _decayTimeoutSeconds) {
      _speedKmh *= 0.85;
      if (_speedKmh < 0.15) _speedKmh = 0;
      _cadence *= 0.85;
      if (_cadence < 1) _cadence = 0;
    }
  }

  /// 检测到一个有效步伐
  void _onStepDetected(double intervalSeconds, DateTime timestamp) {
    _stepCount++;

    // 记录间隔
    _recentIntervals.add(intervalSeconds);
    if (_recentIntervals.length > _maxStoredIntervals) {
      _recentIntervals.removeAt(0);
    }

    // 计算步频（步/分钟）= 60 / 平均间隔
    if (_recentIntervals.isNotEmpty) {
      final avgInterval =
          _recentIntervals.reduce((a, b) => a + b) / _recentIntervals.length;
      _cadence = 60.0 / avgInterval;
    }

    // 计算瞬时速度（km/h）= 步频(步/分) × 步长(米) × 60 / 1000
    _rawSpeedKmh = _cadence * _strideLengthMeters * 60.0 / 1000.0;

    // 指数平滑
    _speedKmh = _speedKmh * (1 - _speedSmoothing) +
        _rawSpeedKmh * _speedSmoothing;

    // 累积室内距离
    _indoorDistanceKm += _strideLengthMeters / 1000.0; // 米 → 千米

    _lastStepTime = timestamp;
  }

  /// 重置检测器（开始新测速时调用）
  void reset() {
    _stepCount = 0;
    _cadence = 0;
    _rawSpeedKmh = 0;
    _speedKmh = 0;
    _indoorDistanceKm = 0;
    _gravityEstimate = 9.81;
    _currentPeak = 0;
    _inRisingPhase = false;
    _lastStepTime = null;
    _recentIntervals.clear();
  }
}
