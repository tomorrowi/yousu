import 'dart:collection';
import '../models/trip.dart';

/// 场景识别器
///
/// 基于速度、加速度、气压等特征判断当前出行方式：
/// - 飞机：高速 (>200 km/h) 或气压快速变化
/// - 高铁：中高速 (80-200 km/h)
/// - 汽车：中速 (5-80 km/h)
/// - 步行：低速 (<5 km/h)
class SceneDetector {
  TripScene _currentScene = TripScene.unknown;
  TripScene get currentScene => _currentScene;

  double _confidence = 0;
  double get confidence => _confidence;

  // 速度历史（用于平滑判断）
  final _speedHistory = Queue<double>();
  static const int historySize = 10;

  // 气压历史
  final _pressureHistory = Queue<_PressureSample>();
  static const int pressureHistorySize = 30;

  /// 输入新数据，输出场景判断
  TripScene update({
    required double speedKmh,
    required double accelerationMagnitude,
    double? pressure,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // 维护速度历史
    _speedHistory.addLast(speedKmh);
    if (_speedHistory.length > historySize) {
      _speedHistory.removeFirst();
    }

    // 维护气压历史
    if (pressure != null) {
      _pressureHistory.addLast(_PressureSample(now, pressure));
      if (_pressureHistory.length > pressureHistorySize) {
        _pressureHistory.removeFirst();
      }
    }

    final avgSpeed =
        _speedHistory.isEmpty
            ? speedKmh
            : _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;

    final detectedScene = _detect(avgSpeed, accelerationMagnitude, pressure);

    if (detectedScene != _currentScene) {
      _currentScene = detectedScene;
      _confidence = _calculateConfidence(avgSpeed, detectedScene);
    }

    return _currentScene;
  }

  TripScene _detect(double avgSpeed, double accelMag, double? pressure) {
    // 飞行检测（优先级最高）
    if (_isFlightDetected(pressure, accelMag)) {
      return TripScene.airplane;
    }

    // 速度判断
    if (avgSpeed < 5) return TripScene.walking;
    if (avgSpeed < 80) return TripScene.car;
    if (avgSpeed < 200) return TripScene.highSpeedRail;
    return TripScene.airplane;
  }

  bool _isFlightDetected(double? pressure, double accelMag) {
    if (pressure == null || _pressureHistory.length < 10) return false;

    final recent = _pressureHistory.toList().sublist(_pressureHistory.length - 10);
    final first = recent.first;
    final last = recent.last;

    final timeDelta = last.time.difference(first.time).inMilliseconds / 1000.0;
    if (timeDelta <= 0) return false;

    final pressureDelta = (last.value - first.value).abs();
    final pressureRate = pressureDelta / timeDelta; // kPa/s

    // 快速气压变化 (> 0.02 kPa/s ≈ > 1.7 m/s 高度变化)
    return pressureRate > 0.02;
  }

  double _calculateConfidence(double avgSpeed, TripScene scene) {
    switch (scene) {
      case TripScene.walking:
        return (avgSpeed < 3) ? 0.9 : 0.5;
      case TripScene.car:
        final margin = (avgSpeed - 5).abs() / 75;
        return 0.3 + margin.clamp(0, 0.5);
      case TripScene.highSpeedRail:
        final margin = (avgSpeed - 80).abs() / 120;
        return 0.3 + margin.clamp(0, 0.5);
      case TripScene.airplane:
        return 0.8;
      case TripScene.unknown:
        return 0;
    }
  }

  void reset() {
    _speedHistory.clear();
    _pressureHistory.clear();
    _currentScene = TripScene.unknown;
    _confidence = 0;
  }
}

class _PressureSample {
  final DateTime time;
  final double value;
  const _PressureSample(this.time, this.value);
}
