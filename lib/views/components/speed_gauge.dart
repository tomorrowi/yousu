import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 速度仪表盘 — 大字速度数字
class SpeedGauge extends StatelessWidget {
  final double speed;
  final String unit;

  const SpeedGauge({
    super.key,
    required this.speed,
    this.unit = 'km/h',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 速度数字
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: _speedColorGradient(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds);
          },
          child: Text(
            speed.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
              letterSpacing: -4,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 单位
        Text(
          unit,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  List<Color> _speedColorGradient() {
    if (speed < 30) return [const Color(0xFF06D6A0), const Color(0xFF00D4FF)];
    if (speed < 120) return [const Color(0xFF00D4FF), const Color(0xFFFFFFFF)];
    if (speed < 250) return [const Color(0xFFFFD166), const Color(0xFFFF6B35)];
    return [const Color(0xFFFF6B35), const Color(0xFFFF3366)];
  }
}
