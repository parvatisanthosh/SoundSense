import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'alert_handler.dart';
import '../models/sleep_mode_settings.dart';

/// Simplified Sleep Mode Service - Uses Main YAMNet (No Separate Model!)
/// 
/// This version doesn't load a separate model. Instead, it relies on the
/// main hub's YAMNet which is already working perfectly.
class SleepModeService {
  bool _isMonitoring = false;
  final AlertHandler _alertHandler = AlertHandler();
  
  // Notification setup
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

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

    // Request permissions for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    // 1. Acquire Wakelock
    await WakelockPlus.enable();
    
    // 2. Show Foreground Notification
    await _showForegroundNotification();
    
    print("😴 Sleep Mode: Active (using main YAMNet)");
    print("   No separate model needed - hub handles detection!");
  }
  
  /// Called by hub when a critical sound is detected during sleep mode
/// Called by hub when a critical sound is detected during sleep mode
Future<void> triggerCriticalSoundAlert(String soundName) async {
  if (!_isMonitoring) return;
  
  print("😴 Sleep Mode: Critical sound detected - $soundName");
  
  // Load settings
  SleepModeSettings settings = await SleepModeSettings.load();
  
  // Check if this sound should trigger an alert
  bool shouldTrigger = _isCriticalSound(soundName, settings);
  
  if (shouldTrigger) {
    print("😴 Sleep Mode: TRIGGERING ALERT for $soundName");
    
    await _alertHandler.triggerAlert(
      flash: settings.flashEnabled,
      vibration: settings.vibrationEnabled,
      smartLights: settings.smartLightsEnabled,
      smartwatch: settings.smartwatchEnabled,
    );
    
    // Auto-stop alert after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _alertHandler.stopAlert();
    });
  } else {
    print("😴 Sleep Mode: '$soundName' not in critical list, skipping alert");
  }
}

bool _isCriticalSound(String detectedLabel, SleepModeSettings settings) {
  final label = detectedLabel.toLowerCase();
  
  // If no critical sounds selected, don't trigger anything
  if (settings.criticalSounds.isEmpty) {
    print("😴 No critical sounds configured");
    return false;
  }
  
  // Check user's selected critical sounds
  for (final key in settings.criticalSounds) {
    if (key == 'baby_cry' && (label.contains('baby') || label.contains('cry') || label.contains('infant') || label.contains('crying'))) {
      print("😴 Matched: baby_cry");
      return true;
    }
    if (key == 'fire_alarm' && (label.contains('alarm') || label.contains('fire') || label.contains('siren') || label.contains('bell'))) {
      print("😴 Matched: fire_alarm");
      return true;
    }
    if (key == 'break_in' && (label.contains('glass') || label.contains('break') || label.contains('shatter') || label.contains('crash'))) {
      print("😴 Matched: break_in");
      return true;
    }
    if (key == 'smoke_detector' && (label.contains('smoke') || label.contains('detector') || label.contains('beep') || label.contains('alarm'))) {
      print("😴 Matched: smoke_detector");
      return true;
    }
  }
  
  print("😴 No match found for: $label");
  return false;
}
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await WakelockPlus.disable();
    await flutterLocalNotificationsPlugin.cancel(888);
    await _alertHandler.stopAlert();
    print("😴 Sleep Mode: Stopped monitoring");
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
        'Sleep Guardian Active', 
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
    Future.delayed(const Duration(seconds: 5), () {
      _alertHandler.stopAlert();
    });
  }
  
  bool get isMonitoring => _isMonitoring;
}