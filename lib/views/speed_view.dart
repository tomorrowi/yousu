import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/speed_viewmodel.dart';
import '../../models/trip.dart';
import 'components/speed_gauge.dart';
import 'components/compass_view.dart';

/// 测速主页
class SpeedView extends StatelessWidget {
  const SpeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeedViewModel>(
      builder: (context, vm, _) {
        return Container(
          color: const Color(0xFF0A0A0A),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 场景标签
                  _SceneBadge(
                    scene: vm.scene,
                    confidence: vm.sceneConfidence,
                    state: vm.state,
                    onTap: () => _showScenePicker(context, vm),
                  ),

                  const Spacer(),

                  // 速度仪表盘
                  SpeedGauge(speed: vm.displaySpeed),

                  const SizedBox(height: 12),

                  // 统计信息
                  _StatsRow(
                    maxSpeed: vm.maxSpeed,
                    avgSpeed: vm.avgSpeed,
                    distance: vm.distance,
                  ),

                  const SizedBox(height: 16),

                  // 罗盘
                  CompassView(heading: vm.heading, speed: vm.displaySpeed),

                  if (vm.altitude > 0) ...[
                    const SizedBox(height: 12),
                    _AltitudeBadge(altitude: vm.altitude),
                  ],

                  const Spacer(),

                  // 操作按钮
                  _ActionButton(
                    state: vm.state,
                    onStart: vm.startSpeedTest,
                    onStop: vm.stopSpeedTest,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showScenePicker(BuildContext context, SpeedViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择场景',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: TripScene.values.where((s) => s != TripScene.unknown).map((scene) {
                  final isSelected = vm.scene == scene;
                  return GestureDetector(
                    onTap: () {
                      vm.setScene(scene);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00D4FF).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF00D4FF))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sceneIcon(scene),
                            size: 20,
                            color: isSelected
                                ? const Color(0xFF00D4FF)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(scene.label,
                              style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF00D4FF)
                                      : Colors.white70)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  IconData _sceneIcon(TripScene scene) {
    switch (scene) {
      case TripScene.airplane:
        return Icons.flight;
      case TripScene.highSpeedRail:
        return Icons.train;
      case TripScene.car:
        return Icons.directions_car;
      case TripScene.walking:
        return Icons.directions_walk;
      default:
        return Icons.help_outline;
    }
  }
}

// MARK: - Sub-widgets

class _SceneBadge extends StatelessWidget {
  final TripScene scene;
  final double confidence;
  final SpeedState state;
  final VoidCallback onTap;

  const _SceneBadge({
    required this.scene,
    required this.confidence,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _sceneColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _sceneColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_sceneIcon, size: 16, color: _sceneColor),
            const SizedBox(width: 6),
            Text(
              state == SpeedState.running ? '${scene.label} · 测速中' : scene.label,
              style: TextStyle(
                color: _sceneColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state == SpeedState.noGps) ...[
              const SizedBox(width: 6),
              Icon(Icons.signal_wifi_off, size: 14, color: Colors.red.shade400),
            ],
          ],
        ),
      ),
    );
  }

  Color get _sceneColor {
    switch (scene) {
      case TripScene.airplane:
        return const Color(0xFFFF6B35);
      case TripScene.highSpeedRail:
        return const Color(0xFF9D4EDD);
      case TripScene.car:
        return const Color(0xFF00D4FF);
      case TripScene.walking:
        return const Color(0xFF06D6A0);
      default:
        return const Color(0xFF8892B0);
    }
  }

  IconData get _sceneIcon {
    switch (scene) {
      case TripScene.airplane:
        return Icons.flight;
      case TripScene.highSpeedRail:
        return Icons.train;
      case TripScene.car:
        return Icons.directions_car;
      case TripScene.walking:
        return Icons.directions_walk;
      default:
        return Icons.help_outline;
    }
  }
}

class _StatsRow extends StatelessWidget {
  final double maxSpeed;
  final double avgSpeed;
  final double distance;

  const _StatsRow({
    required this.maxSpeed,
    required this.avgSpeed,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statChip(
          label: '最高',
          value: '${maxSpeed.toStringAsFixed(0)} km/h',
          color: const Color(0xFFFF6B35),
        ),
        const SizedBox(width: 24),
        _statChip(
          label: '均速',
          value: '${avgSpeed.toStringAsFixed(0)} km/h',
          color: const Color(0xFF00D4FF),
        ),
        if (distance > 0) ...[
          const SizedBox(width: 24),
          _statChip(
            label: '里程',
            value: '${distance.toStringAsFixed(1)} km',
            color: const Color(0xFF06D6A0),
          ),
        ],
      ],
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
      ],
    );
  }
}

class _AltitudeBadge extends StatelessWidget {
  final double altitude;
  const _AltitudeBadge({required this.altitude});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '海拔 ${altitude.toStringAsFixed(0)}m',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final SpeedState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _ActionButton({
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state == SpeedState.running || state == SpeedState.noGps;

    return GestureDetector(
      onTap: isRunning ? onStop : onStart,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRunning
              ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
              : const Color(0xFF00D4FF).withValues(alpha: 0.2),
          border: Border.all(
            color: isRunning
                ? const Color(0xFFFF6B35)
                : const Color(0xFF00D4FF),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            isRunning ? Icons.stop : Icons.play_arrow,
            size: 36,
            color: isRunning
                ? const Color(0xFFFF6B35)
                : const Color(0xFF00D4FF),
          ),
        ),
      ),
    );
  }
}
