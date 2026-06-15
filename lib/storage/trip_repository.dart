import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';

/// 行程数据持久化（使用 SharedPreferences + JSON）
class TripRepository {
  static const String _key = 'trips_data';

  /// 保存行程
  Future<void> saveTrip(Trip trip) async {
    final trips = await getAllTrips();
    // 替换已有或新增
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
    } else {
      trips.add(trip);
    }
    await _saveAll(trips);
  }

  /// 获取所有行程（按时间倒序）
  Future<List<Trip>> getAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final List<dynamic> jsonList = json.decode(raw);
    final trips = jsonList.map((e) => Trip.fromJson(e)).toList();
    trips.sort((a, b) => b.startTime.compareTo(a.startTime));
    return trips;
  }

  /// 获取单个行程
  Future<Trip?> getTrip(String id) async {
    final trips = await getAllTrips();
    try {
      return trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 删除行程
  Future<void> deleteTrip(String id) async {
    final trips = await getAllTrips();
    trips.removeWhere((t) => t.id == id);
    await _saveAll(trips);
  }

  /// 行程总数
  Future<int> get count async {
    final trips = await getAllTrips();
    return trips.length;
  }

  Future<void> _saveAll(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = trips.map((t) => t.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}
