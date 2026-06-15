import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/trip.dart';
import '../../viewmodels/trip_history_viewmodel.dart';

/// 行程详情
class TripDetailView extends StatefulWidget {
  final String tripId;
  const TripDetailView({super.key, required this.tripId});

  @override
  State<TripDetailView> createState() => _TripDetailViewState();
}

class _TripDetailViewState extends State<TripDetailView> {
  Trip? _trip;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final vm = context.read<TripHistoryViewModel>();
    final trip = await vm.getTrip(widget.tripId);
    if (mounted) {
      setState(() => _trip = trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trip == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(title: const Text('行程详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final trip = _trip!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: Text(trip.formattedDate)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 概览卡片
            _OverviewCard(trip: trip),
            const SizedBox(height: 20),

            // 速度曲线
            const Text('速度曲线',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _SpeedCurveChart(points: trip.speedDataPoints),
            const SizedBox(height: 20),

            // 详细数据
            const Text('详细数据',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _DetailGrid(trip: trip),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Trip trip;
  const _OverviewCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final sceneColor = _sceneColors[trip.scene] ?? const Color(0xFF8892B0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: sceneColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _sceneIcons[trip.scene] ?? Icons.help_outline,
              color: sceneColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.scene.label,
                    style: TextStyle(
                        color: sceneColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    '${trip.formattedDate} · ${trip.formattedDuration}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(trip.formattedMaxSpeed,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text(trip.formattedDistance,
                  style: const TextStyle(color: Color(0xFF8892B0))),
            ],
          ),
        ],
      ),
    );
  }

  static const _sceneColors = {
    TripScene.airplane: Color(0xFFFF6B35),
    TripScene.highSpeedRail: Color(0xFF9D4EDD),
    TripScene.car: Color(0xFF00D4FF),
    TripScene.walking: Color(0xFF06D6A0),
  };

  static const _sceneIcons = {
    TripScene.airplane: Icons.flight,
    TripScene.highSpeedRail: Icons.train,
    TripScene.car: Icons.directions_car,
    TripScene.walking: Icons.directions_walk,
  };
}

class _SpeedCurveChart extends StatelessWidget {
  final List<SpeedDataPoint> points;
  const _SpeedCurveChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('暂无速度数据',
            style: TextStyle(color: Color(0xFF8892B0))),
      );
    }

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.speed);
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF00D4FF),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
              ),
            ),
          ],
          minY: 0,
        ),
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final Trip trip;
  const _DetailGrid({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _detailTile('最高速度', trip.formattedMaxSpeed)),
        const SizedBox(width: 8),
        Expanded(child: _detailTile('平均速度', trip.formattedAvgSpeed)),
      ],
    );
  }

  Widget _detailTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Color(0xFF8892B0), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
