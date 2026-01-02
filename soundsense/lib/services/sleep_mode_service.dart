import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'alert_handler.dart';
import 'sound_classifier_sleep.dart';
import '../models/sleep_mode_settings.dart';
import '../core/services/audio_service.dart';
import 'dart:typed_data';

class SleepModeService {
  bool _isMonitoring = false;
  final AlertHandler _alertHandler = AlertHandler();
  final SoundClassifierSleep _classifier = SoundClassifierSleep();
  final AudioService _audioService = AudioService();
  
  // Audio buffering
  List<double> _audioBuffer = [];
  // Buffer size for ~1 second at 16kHz (YAMNet standard)
  static const int _requiredSamples = 15600;

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
    
    // Clear buffer
    _audioBuffer.clear();

    // 3. Show Foreground Notification
    await _showForegroundNotification();

    // 4. Start Audio Stream
    try {
      _audioService.onAudioData = (List<double> newSamples) {
        _processAudioData(newSamples, settings);
      };
      await _audioService.startListening();
      print("Sleep Mode: Started listening");
    } catch (e) {
      print("Sleep Mode Error: Could not start audio service - $e");
      stopMonitoring();
    }
  }

  void _processAudioData(List<double> newSamples, SleepModeSettings settings) async {
    if (!_isMonitoring) return;
    
    _audioBuffer.addAll(newSamples);

    if (_audioBuffer.length >= _requiredSamples) {
      // Extract exactly required samples
      final processBuffer = _audioBuffer.sublist(0, _requiredSamples);
      
      // Keep remainder and overlap slightly (optional, but good for continuous sounds)
      // For now, just keep remainder
      _audioBuffer = _audioBuffer.sublist(_requiredSamples);

      // Classify
      final result = await _classifier.classify(processBuffer);
      
      if (result != null) {
        print("Sleep Mode Detected: $result");
        // Check if detected sound is in user's enabled critical sounds
        // Map YAMNet labels to internal keys if necessary, or ensure they match
        // Assuming labels.txt contains display names, we might need normalization
        
        // Simple containment check for now - improve matching logic as needed
        if (_isCriticalSound(result, settings)) {
            print("Sleep Mode: TRIGGERING ALERT for $result");
            _alertHandler.triggerAlert(
              flash: settings.flashEnabled,
              vibration: settings.vibrationEnabled,
              smartLights: settings.smartLightsEnabled,
              smartwatch: settings.smartwatchEnabled,
            );
        }
      }
    }
  }

  bool _isCriticalSound(String detectedLabel, SleepModeSettings settings) {
    // Basic mapping/checking logic
    // Detected label comes from model (e.g., 'Baby cry, infant cry')
    // Settings store keys like 'baby_cry'
    
    final label = detectedLabel.toLowerCase();
    
    for (final key in settings.criticalSounds) {
      if (key == 'baby_cry' && (label.contains('baby') || label.contains('cry') || label.contains('infant'))) return true;
      if (key == 'fire_alarm' && (label.contains('alarm') || label.contains('fire'))) return true;
      if (key == 'break_in' && (label.contains('glass') || label.contains('break'))) return true;
      if (key == 'smoke_detector' && (label.contains('smoke') || label.contains('detector') || label.contains('beep'))) return true;
    }
    return false;
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _audioService.stopListening();
    await WakelockPlus.disable();
    await flutterLocalNotificationsPlugin.cancel(888); // Cancel foreground notification
    await _alertHandler.stopAlert();
    print("Sleep Mode: Stopped monitoring");
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

  void triggerTestAlert() async {
    SleepModeSettings settings = await SleepModeSettings.load();
    _alertHandler.triggerAlert(
      flash: settings.flashEnabled,
      vibration: settings.vibrationEnabled,
      smartLights: settings.smartLightsEnabled,
      smartwatch: settings.smartwatchEnabled,
    );
    
    // Auto stop alert after 5 seconds for test
    Future.delayed(Duration(seconds: 5), () {
        _alertHandler.stopAlert();
    });
  }
}
