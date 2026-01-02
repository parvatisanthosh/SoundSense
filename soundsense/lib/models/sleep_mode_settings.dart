import 'package:shared_preferences/shared_preferences.dart';

class SleepModeSettings {
  bool flashEnabled;
  bool vibrationEnabled;
  bool smartLightsEnabled;
  bool smartwatchEnabled;
  Set<String> criticalSounds;

  SleepModeSettings({
    this.flashEnabled = true,
    this.vibrationEnabled = true,
    this.smartLightsEnabled = false,
    this.smartwatchEnabled = false,
    this.criticalSounds = const {'fire_alarm', 'break_in', 'baby_cry', 'smoke_detector'},
  });

  // Keys for SharedPreferences
  static const String _flashKey = 'sleep_mode_flash';
  static const String _vibrationKey = 'sleep_mode_vibration';
  static const String _smartLightsKey = 'sleep_mode_smart_lights';
  static const String _smartwatchKey = 'sleep_mode_smartwatch';
  static const String _criticalSoundsKey = 'sleep_mode_critical_sounds';

  // Load settings from SharedPreferences
  static Future<SleepModeSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SleepModeSettings(
      flashEnabled: prefs.getBool(_flashKey) ?? true,
      vibrationEnabled: prefs.getBool(_vibrationKey) ?? true,
      smartLightsEnabled: prefs.getBool(_smartLightsKey) ?? false,
      smartwatchEnabled: prefs.getBool(_smartwatchKey) ?? false,
      criticalSounds: (prefs.getStringList(_criticalSoundsKey) ?? 
          ['fire_alarm', 'break_in', 'baby_cry', 'smoke_detector']).toSet(),
    );
  }

  // Save settings to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flashKey, flashEnabled);
    await prefs.setBool(_vibrationKey, vibrationEnabled);
    await prefs.setBool(_smartLightsKey, smartLightsEnabled);
    await prefs.setBool(_smartwatchKey, smartwatchEnabled);
    await prefs.setStringList(_criticalSoundsKey, criticalSounds.toList());
  }
}
