import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../storage/trip_repository.dart';

/// 行程历史 ViewModel
class TripHistoryViewModel extends ChangeNotifier {
  final TripRepository _repository;

  TripHistoryViewModel({required TripRepository repository})
      : _repository = repository;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 统计
  int get totalTrips => _trips.length;
  double get totalDistance => _trips.fold(0, (sum, t) => sum + t.distance);
  double get globalMaxSpeed {
    if (_trips.isEmpty) return 0;
    return _trips.map((t) => t.maxSpeed).reduce((a, b) => a > b ? a : b);
  }

  /// 加载所有行程
  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();

    _trips = await _repository.getAllTrips();

    _isLoading = false;
    notifyListeners();
  }

  /// 按场景筛选
  List<Trip> filterByScene(TripScene scene) {
    return _trips.where((t) => t.scene == scene).toList();
  }

  /// 获取单个行程
  Future<Trip?> getTrip(String id) async {
    return _repository.getTrip(id);
  }

  /// 删除行程
  Future<void> deleteTrip(String id) async {
    await _repository.deleteTrip(id);
    await loadTrips();
  }
}
