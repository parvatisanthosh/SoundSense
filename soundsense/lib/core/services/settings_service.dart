import 'package:shared_preferences/shared_preferences.dart';
import 'tts_alert_service.dart';

class SettingsService {
  static const String _criticalAlertsKey = 'critical_alerts';
  static const String _importantAlertsKey = 'important_alerts';
  static const String _normalAlertsKey = 'normal_alerts';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _vibrationIntensityKey = 'vibration_intensity';
  static const String _sensitivityKey = 'sensitivity';

  // Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Current settings values (cached)
  bool criticalAlerts = true;
  bool importantAlerts = true;
  bool normalAlerts = false;
  bool vibrationEnabled = true;
  String vibrationIntensity = 'Medium';
  double sensitivity = 0.5;

  bool _ttsEnabled = true;

bool get ttsEnabled => _ttsEnabled;

Future<void> setTTSEnabled(bool value) async {
  _ttsEnabled = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tts_enabled', value);
  TTSAlertService.instance.setEnabled(value);
}

  // Initialize
  Future<void> init() async {
    
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    
  }

  // Load all settings
  // Load all settings
Future<void> _loadSettings() async {
  criticalAlerts = _prefs?.getBool(_criticalAlertsKey) ?? true;
  importantAlerts = _prefs?.getBool(_importantAlertsKey) ?? true;
  normalAlerts = _prefs?.getBool(_normalAlertsKey) ?? false;
  vibrationEnabled = _prefs?.getBool(_vibrationEnabledKey) ?? true;
  vibrationIntensity = _prefs?.getString(_vibrationIntensityKey) ?? 'Medium';
  sensitivity = _prefs?.getDouble(_sensitivityKey) ?? 0.5;
  
  // Load TTS setting
  _ttsEnabled = _prefs?.getBool('tts_enabled') ?? true;
  TTSAlertService.instance.setEnabled(_ttsEnabled);
}

  // Save individual settings
  Future<void> setCriticalAlerts(bool value) async {
    criticalAlerts = value;
    await _prefs?.setBool(_criticalAlertsKey, value);
  }

  Future<void> setImportantAlerts(bool value) async {
    importantAlerts = value;
    await _prefs?.setBool(_importantAlertsKey, value);
  }

  Future<void> setNormalAlerts(bool value) async {
    normalAlerts = value;
    await _prefs?.setBool(_normalAlertsKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    await _prefs?.setBool(_vibrationEnabledKey, value);
  }

  Future<void> setVibrationIntensity(String value) async {
    vibrationIntensity = value;
    await _prefs?.setString(_vibrationIntensityKey, value);
  }

  Future<void> setSensitivity(double value) async {
    sensitivity = value;
    await _prefs?.setDouble(_sensitivityKey, value);
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await setCriticalAlerts(true);
    await setImportantAlerts(true);
    await setNormalAlerts(false);
    await setVibrationEnabled(true);
    await setVibrationIntensity('Medium');
    await setSensitivity(0.5);
  }

  // Check if sound should show based on priority
  bool shouldShowSound(String priority) {
    switch (priority) {
      case 'critical':
        return criticalAlerts;
      case 'important':
        return importantAlerts;
      case 'normal':
        return normalAlerts;
      default:
        return true;
    }
  }

  // Get minimum decibel threshold based on sensitivity
  double getDecibelThreshold() {
    // Low sensitivity = high threshold (70dB)
    // High sensitivity = low threshold (30dB)
    return 70 - (sensitivity * 40);
  }
}