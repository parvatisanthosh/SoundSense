import 'package:flutter/material.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize settings
  await SettingsService().init();
  
  runApp(const SoundSenseApp());
}

class SoundSenseApp extends StatelessWidget {
  const SoundSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00D9FF),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const DashboardScreen(),
    );
  }
}