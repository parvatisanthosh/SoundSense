import 'package:flutter/material.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'core/services/settings_service.dart';
import 'screens/sleep_mode_screen.dart';
import 'screens/splash_screen.dart';
import 'features/training/sound_training_screen.dart';
import 'features/training/azure_voice_training_screen.dart';
import 'features/transcription/enhanced_transcription_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
   
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const DashboardScreen(),
        '/sleep_mode': (context) => const SleepModeScreen(),
        '/transcription': (context) => const EnhancedTranscriptionScreen(),
        '/sound-training': (context) => const SoundTrainingScreen(),
        '/voice-training': (context) => const AzureVoiceTrainingScreen(),
      },
    );
  }
}