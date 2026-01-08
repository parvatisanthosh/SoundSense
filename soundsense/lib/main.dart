import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'core/services/sleep_scheduler_service.dart';
import 'core/services/sound_intelligence_hub.dart';
// Your screens
import 'screens/sleep_mode_screen.dart';
import 'screens/splash_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/training/sound_training_screen.dart';
import 'features/training/azure_voice_training_screen.dart';
import 'features/transcription/enhanced_transcription_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/chat/chat_screen.dart';
// Friend's SOS feature
import 'features/sos/emergency_contacts_screen.dart';
import 'features/speaker_recognition/speaker_recognition_screen.dart';

void main() async {
   
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F1419),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Initialize core services
  print('🚀 Initializing Dhwani...');
  
  // 1. Initialize settings
  await SettingsService().init();
  print('✅ Settings initialized');
  
  // 2. Initialize Intelligence Hub (coordinates everything)
  final hub = SoundIntelligenceHub();
  await hub.initialize();
  print('✅ Intelligence Hub initialized');
  
  // 3. Initialize Sleep Scheduler (auto sleep mode)
  final sleepScheduler = SleepSchedulerService.instance;
  await sleepScheduler.initialize();
  print('✅ Sleep Scheduler initialized');
  
  print('🎉 Dhwani ready!');
  
  runApp(const SoundSenseApp());
}

class SoundSenseApp extends StatelessWidget {
  const SoundSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService().darkModeNotifier,
      builder: (context, isDark, child) {
        // Update system chrome based on theme
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF0F1419) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));
        
        return MaterialApp(
          title: 'Dhwani',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/': (context) => const DashboardScreen(),
            '/sleep_mode': (context) => const SleepModeScreen(),
            '/transcription': (context) => const EnhancedTranscriptionScreen(),
            '/sound-training': (context) => const SoundTrainingScreen(),
            '/voice-training': (context) => const AzureVoiceTrainingScreen(),
            '/speaker-recognition': (context) => const SpeakerRecognitionScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/emergency': (context) => const EmergencyContactsScreen(),
            '/chat': (context) => const ChatScreen(),
          },
        );
      },
    );
  }
}