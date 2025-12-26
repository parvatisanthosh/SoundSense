import 'package:flutter/services.dart';

class HapticService {
  static Future<void> vibrate(String priority) async {
    switch (priority) {
      case 'critical':
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
      case 'important':
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.mediumImpact();
        break;
      default:
        await HapticFeedback.lightImpact();
    }
  }

  static Future<void> tapFeedback() async {
    await HapticFeedback.selectionClick();
  }
}