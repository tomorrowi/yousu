import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TripScene {
  airplane,
  highSpeedRail,
  car,
  walking,
  unknown;

  String get label {
    switch (this) {
      case TripScene.airplane:
        return '飞机';
      case TripScene.highSpeedRail:
        return '高铁';
      case TripScene.car:
        return '汽车';
      case TripScene.walking:
        return '步行';
      case TripScene.unknown:
        return '未知';
    }
  }
}

/// 行程数据模型
class Trip {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  TripScene scene;
  double maxSpeed;
  double avgSpeed;
  double distance;
  List<SpeedDataPoint> speedDataPoints;
  double? startLatitude;
  double? startLongitude;
  double? endLatitude;
  double? endLongitude;
  double? maxAltitude;
  bool isCompleted;

  Trip({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.scene,
    this.maxSpeed = 0,
    this.avgSpeed = 0,
    this.distance = 0,
    List<SpeedDataPoint>? speedDataPoints,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.maxAltitude,
    this.isCompleted = false,
  }) : speedDataPoints = speedDataPoints ?? [];

  factory Trip.create() {
    return Trip(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      scene: TripScene.unknown,
    );
  }

  // MARK: - JSON 序列化

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      scene: TripScene.values[json['scene'] ?? 4],
      maxSpeed: (json['maxSpeed'] ?? 0).toDouble(),
      avgSpeed: (json['avgSpeed'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      speedDataPoints: (json['speedDataPoints'] as List<dynamic>?)
              ?.map((e) => SpeedDataPoint.fromJson(e))
              .toList() ??
          [],
      startLatitude: json['startLatitude']?.toDouble(),
      startLongitude: json['startLongitude']?.toDouble(),
      endLatitude: json['endLatitude']?.toDouble(),
      endLongitude: json['endLongitude']?.toDouble(),
      maxAltitude: json['maxAltitude']?.toDouble(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'scene': scene.index,
        'maxSpeed': maxSpeed,
        'avgSpeed': avgSpeed,
        'distance': distance,
        'speedDataPoints': speedDataPoints.map((e) => e.toJson()).toList(),
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
        'maxAltitude': maxAltitude,
        'isCompleted': isCompleted,
      };

  // MARK: - 计算属性

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDate {
    final d = startTime;
    return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours小时$minutes分';
    }
    return '$minutes分钟';
  }

  String get formattedMaxSpeed => '${maxSpeed.toStringAsFixed(0)} km/h';

  String get formattedAvgSpeed => '${avgSpeed.toStringAsFixed(0)} km/h';

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
}

/// 速度数据点
class SpeedDataPoint {
  final DateTime timestamp;
  final double speed;
  final double heading;
  final double? altitude;

  SpeedDataPoint({
    required this.speed,
    this.heading = 0,
    this.altitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SpeedDataPoint.fromJson(Map<String, dynamic> json) {
    return SpeedDataPoint(
      speed: (json['speed'] ?? 0).toDouble(),
      heading: (json['heading'] ?? 0).toDouble(),
      altitude: json['altitude']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'speed': speed,
        'heading': heading,
        'altitude': altitude,
      };
}
