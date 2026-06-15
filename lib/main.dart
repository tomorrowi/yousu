import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/location_manager.dart';
import 'services/sensor_manager.dart';
import 'storage/trip_repository.dart';
import 'viewmodels/speed_viewmodel.dart';
import 'viewmodels/trip_history_viewmodel.dart';
import 'views/speed_view.dart';
import 'views/trip_history_view.dart';
import 'views/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  final locationManager = LocationManager();
  final sensorManager = SensorManager();
  final repository = TripRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locationManager),
        ChangeNotifierProvider(create: (_) => sensorManager),
        ChangeNotifierProvider(
          create: (_) => SpeedViewModel(
            locationManager: locationManager,
            sensorManager: sensorManager,
            repository: repository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TripHistoryViewModel(repository: repository),
        ),
      ],
      child: const YousuApp(),
    ),
  );
}

class YousuApp extends StatefulWidget {
  const YousuApp({super.key});

  @override
  State<YousuApp> createState() => _YousuAppState();
}

class _YousuAppState extends State<YousuApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '有速',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            SpeedView(),
            TripHistoryView(),
            SettingsView(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed),
              label: '测速',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: '记录',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
