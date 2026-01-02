import 'package:flutter/material.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'core/services/settings_service.dart';
<<<<<<< HEAD
import 'screens/sleep_mode_screen.dart';
=======
import 'features/training/sound_training_screen.dart';
import 'features/training/azure_voice_training_screen.dart';
import 'features/transcription/enhanced_transcription_screen.dart';
>>>>>>> fef6c9111f5b0219a3bf458ee8b08b194a5499b7

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  runApp(const SoundSenseApp());
}

class SoundSenseApp extends StatelessWidget {
  const SoundSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhwani',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00D9FF),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
<<<<<<< HEAD
      routes: {
        '/': (context) => const DashboardScreen(),
        '/sleep_mode': (context) => const SleepModeScreen(),
=======
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/transcription': (context) => const EnhancedTranscriptionScreen(),
        '/sound-training': (context) => const SoundTrainingScreen(),
        '/voice-training': (context) => const AzureVoiceTrainingScreen(),
>>>>>>> fef6c9111f5b0219a3bf458ee8b08b194a5499b7
      },
    );
  }
}