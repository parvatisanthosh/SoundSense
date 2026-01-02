import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';

class AlertHandler {
  bool _isAlerting = false;
  static const platform = MethodChannel('com.example.soundsense/vibration');
  
  // Singleton pattern
  static final AlertHandler _instance = AlertHandler._internal();
  factory AlertHandler() => _instance;
  AlertHandler._internal();

  Future<void> triggerAlert({
    required bool flash,
    required bool vibration,
    required bool smartLights,
    required bool smartwatch,
  }) async {
    if (_isAlerting) return;
    _isAlerting = true;

    // Trigger alerts in parallel
    List<Future> alertFutures = [];

    if (flash) {
      alertFutures.add(_triggerFlashLoop());
    }

    if (vibration) {
      alertFutures.add(_triggerVibrationLoop());
    }

    try {
      await Future.any(alertFutures); 
    } catch (e) {
      print("Error triggering alert: $e");
    }
  }

  Future<void> stopAlert() async {
    _isAlerting = false;
    try {
      await TorchLight.disableTorch();
    } catch (e) {
      print("Error stopping torch: $e");
    }
    
    try {
      await platform.invokeMethod('cancel');
    } catch (e) {
      print("Error stopping vibration: $e");
    }
  }

  Future<void> _triggerFlashLoop() async {
    while (_isAlerting) {
      try {
        await TorchLight.enableTorch();
        await Future.delayed(Duration(milliseconds: 500));
        await TorchLight.disableTorch();
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print("Flash error: $e");
        break; 
      }
    }
  }

  Future<void> _triggerVibrationLoop() async {
     while (_isAlerting) {
       try {
         // Heavy impact feedback (500ms)
         await platform.invokeMethod('vibrate', {'duration': 1000});
         await Future.delayed(Duration(milliseconds: 1000)); 
       } catch (e) {
         print("Vibration error: $e");
         break;
       }
     }
  }
}
