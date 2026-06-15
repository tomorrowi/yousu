import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip.dart';
import '../../viewmodels/trip_history_viewmodel.dart';
import 'trip_detail_view.dart';

/// 行程历史列表
class TripHistoryView extends StatefulWidget {
  const TripHistoryView({super.key});

  @override
  State<TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<TripHistoryView> {
  TripScene? _selectedScene;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripHistoryViewModel>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripHistoryViewModel>(
      builder: (context, vm, _) {
        return Container(
          color: const Color(0xFF0A0A0A),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // 统计概览
                _StatsHeader(vm: vm),

                const SizedBox(height: 12),

                // 场景筛选
                _SceneFilter(
                  selected: _selectedScene,
                  onChanged: (s) => setState(() => _selectedScene = s),
                ),

                const SizedBox(height: 12),

                // 列表
                Expanded(
                  child: vm.trips.isEmpty
                      ? const _EmptyState()
                      : _TripList(
                          trips: _filterTrips(vm.trips),
                          onDelete: (id) => vm.deleteTrip(id),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Trip> _filterTrips(List<Trip> trips) {
    if (_selectedScene == null) return trips;
    return trips.where((t) => t.scene == _selectedScene).toList();
  }
}

class _StatsHeader extends StatelessWidget {
  final TripHistoryViewModel vm;

  const _StatsHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(
            label: '总行程',
            value: '${vm.totalTrips}',
            icon: Icons.explore,
          ),
          const SizedBox(width: 12),
          _statCard(
            label: '总里程',
            value: '${vm.totalDistance.toStringAsFixed(0)} km',
            icon: Icons.route,
          ),
          const SizedBox(width: 12),
          _statCard(
            label: '最高',
            value: '${vm.globalMaxSpeed.toStringAsFixed(0)} km/h',
            icon: Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF00D4FF)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8892B0), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SceneFilter extends StatelessWidget {
  final TripScene? selected;
  final ValueChanged<TripScene?> onChanged;

  const _SceneFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scenes = <TripScene?>[null, ...TripScene.values.where((s) => s != TripScene.unknown)];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          final isSelected = scene == selected;
          return GestureDetector(
            onTap: () => onChanged(scene),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00D4FF).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? Border.all(color: const Color(0xFF00D4FF))
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                scene?.label ?? '全部',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF8892B0),
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<Trip> trips;
  final ValueChanged<String> onDelete;

  const _TripList({required this.trips, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripCard(
          trip: trip,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripDetailView(tripId: trip.id),
              ),
            );
          },
          onDelete: () => onDelete(trip.id),
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sceneColor = _sceneColorMap[trip.scene] ?? const Color(0xFF8892B0);
    final icon = _sceneIconMap[trip.scene] ?? Icons.help_outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: sceneColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: sceneColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.formattedDate,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                      '${trip.formattedDuration} · ${trip.formattedDistance}',
                      style: const TextStyle(
                          color: Color(0xFF8892B0), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(trip.formattedMaxSpeed,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(trip.scene.label,
                    style: TextStyle(color: sceneColor, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _sceneColorMap = {
    TripScene.airplane: Color(0xFFFF6B35),
    TripScene.highSpeedRail: Color(0xFF9D4EDD),
    TripScene.car: Color(0xFF00D4FF),
    TripScene.walking: Color(0xFF06D6A0),
  };

  static const _sceneIconMap = {
    TripScene.airplane: Icons.flight,
    TripScene.highSpeedRail: Icons.train,
    TripScene.car: Icons.directions_car,
    TripScene.walking: Icons.directions_walk,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 48, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text('还没有行程记录',
              style: TextStyle(color: Color(0xFF8892B0))),
          const SizedBox(height: 4),
          const Text('开始测速并记录，这里会出现你的行程',
              style: TextStyle(color: Color(0xFF8892B0), fontSize: 12)),
        ],
      ),
    );
  }
}
