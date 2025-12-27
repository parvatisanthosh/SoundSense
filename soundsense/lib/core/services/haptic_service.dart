import 'package:flutter/services.dart';
import 'settings_service.dart';

class HapticService {
  static final SettingsService _settings = SettingsService();

  static Future<void> vibrate(String priority) async {
    // Check if vibration is enabled
    if (!_settings.vibrationEnabled) return;

    // Get intensity from settings
    String intensity = _settings.vibrationIntensity;

    switch (priority) {
      case 'critical':
        await _vibrateByIntensity(intensity, isCritical: true);
        break;
      case 'important':
        await _vibrateByIntensity(intensity, isCritical: false);
        break;
      default:
        await HapticFeedback.lightImpact();
    }
  }

  static Future<void> _vibrateByIntensity(String intensity, {required bool isCritical}) async {
    int repeatCount = isCritical ? 3 : 2;

    switch (intensity) {
      case 'High':
        for (int i = 0; i < repeatCount; i++) {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
        }
        break;
      case 'Medium':
        for (int i = 0; i < repeatCount; i++) {
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 150));
        }
        break;
      case 'Low':
        for (int i = 0; i < repeatCount; i++) {
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 150));
        }
        break;
    }
  }

  static Future<void> tapFeedback() async {
    if (!_settings.vibrationEnabled) return;
    await HapticFeedback.selectionClick();
  }
}