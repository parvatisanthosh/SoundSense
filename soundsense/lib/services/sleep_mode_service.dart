import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'alert_handler.dart';
import 'sound_classifier_sleep.dart';
import '../models/sleep_mode_settings.dart';

// Currently simpler implementation without background execution isolate for MVP
class SleepModeService {
  bool _isMonitoring = false;
  final AlertHandler _alertHandler = AlertHandler();
  final SoundClassifierSleep _classifier = SoundClassifierSleep();
  
  // Notification setup
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static final SleepModeService _instance = SleepModeService._internal();
  factory SleepModeService() => _instance;
  SleepModeService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    // 1. Acquire Wakelock
    await WakelockPlus.enable();

    // 2. Load settings and model
    SleepModeSettings settings = await SleepModeSettings.load();
    await _classifier.loadModel();

    // 3. Show Foreground Notification
    await _showForegroundNotification();

    // 4. Start Audio Stream (Placeholder loop for now)
    // Real implementation would use an audio stream package (like 'audio_streamer' or 'mic_stream')
    // and pass buffer to classifier.
    _monitoringLoop(settings);
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await WakelockPlus.disable();
    await flutterLocalNotificationsPlugin.cancel(888); // Cancel foreground notification
    await _alertHandler.stopAlert();
  }

  Future<void> _showForegroundNotification() async {
     const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'sleep_mode_channel', 
            'Sleep Mode Background Service',
            channelDescription: 'Monitoring for critical sounds while you sleep',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
        );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await flutterLocalNotificationsPlugin.show(
        888, 
        'Sleep Mode Active', 
        'Listening for critical sounds...', 
        platformChannelSpecifics
    );
  }

  void _monitoringLoop(SleepModeSettings settings) async {
    while (_isMonitoring) {
        // Mocking audio data capture
        // In real app: Stream<List<int>> stream = AudioStreamer().audioStream;
        // await for (var audio in stream) { ... }
        
        await Future.delayed(Duration(seconds: 2)); // Simulate sampling interval
        
        // Mock classification result
        // String? result = await _classifier.classify(mockAudioData);
        // if (result != null && settings.criticalSounds.contains(result)) {
        //   _triggerAlert(settings);
        // }
    }
  }

  void triggerTestAlert() async {
    SleepModeSettings settings = await SleepModeSettings.load();
    _alertHandler.triggerAlert(
      flash: settings.flashEnabled,
      vibration: settings.vibrationEnabled,
      smartLights: settings.smartLightsEnabled,
      smartwatch: settings.smartwatchEnabled,
    );
  }
}
