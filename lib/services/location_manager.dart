import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS 定位数据
class LocationData {
  final double speed;       // m/s
  double get speedKmh => speed * 3.6;
  final double course;      // 航向角度 (0-360)
  final double latitude;
  final double longitude;
  final double altitude;    // 海拔 (m)
  final double horizontalAccuracy;
  final DateTime timestamp;

  const LocationData({
    required this.speed,
    required this.course,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.horizontalAccuracy,
    required this.timestamp,
  });

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      speed: position.speed >= 0 ? position.speed : 0,
      course: position.heading >= 0 ? position.heading : 0,
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      horizontalAccuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }
}

/// 定位管理器
class LocationManager extends ChangeNotifier {
  LocationData? _locationData;
  LocationData? get locationData => _locationData;

  bool _isActive = false;
  bool get isActive => _isActive;

  LocationPermission _permission = LocationPermission.denied;
  LocationPermission get permission => _permission;

  bool _serviceEnabled = false;
  bool get serviceEnabled => _serviceEnabled;

  StreamSubscription<Position>? _positionStream;

  /// 请求权限
  Future<bool> requestPermission() async {
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      notifyListeners();
      return false;
    }

    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }

    notifyListeners();
    return _permission == LocationPermission.whileInUse ||
        _permission == LocationPermission.always;
  }

  /// 开始定位
  Future<void> startUpdating() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    _isActive = true;
    notifyListeners();

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _locationData = LocationData.fromPosition(position);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location error: $error');
      },
    );
  }

  /// 停止定位
  Future<void> stopUpdating() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isActive = false;
    _locationData = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
