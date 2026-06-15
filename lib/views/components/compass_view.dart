import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 方向罗盘
class CompassView extends StatelessWidget {
  final double heading;  // 角度 (0-360)，0 = 北
  final double speed;

  const CompassView({
    super.key,
    required this.heading,
    this.speed = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),

        // 刻度
        ...List.generate(36, (i) {
          final angle = i * 10.0;
          final isMajor = i % 9 == 0;
          return Transform.rotate(
            angle: angle * math.pi / 180,
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: Container(
                  width: isMajor ? 2 : 1,
                  height: isMajor ? 8 : 4,
                  color: isMajor
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        }),

        // 方向标识
        ..._buildDirectionLabels(),

        // 指针（固定朝上，表盘旋转）
        const Icon(Icons.navigation, color: Colors.red, size: 20),

        // 中心点
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDirectionLabels() {
    final labels = [
      ('N', 0.0, const Color(0xFFFF6B35)),
      ('E', 90.0, Colors.white70),
      ('S', 180.0, Colors.white70),
      ('W', 270.0, Colors.white70),
    ];

    return labels.map((l) {
      return Transform.rotate(
        angle: l.$2 * math.pi / 180,
        child: Align(
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, 30),
            child: Transform.rotate(
              angle: -l.$2 * math.pi / 180 - heading * math.pi / 180,
              child: Text(
                l.$1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: l.$3,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
