import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_intelligence_hub.dart';

/// Sleep Scheduler Service
/// 
/// Automatically activates/deactivates sleep mode based on user's schedule
/// Keeps microphone ON throughout the night for continuous monitoring
/// 
/// Features:
/// - Auto sleep mode at scheduled times (default 10 PM - 6 AM)
/// - User-configurable schedule
/// - Manual override support
/// - Background monitoring
/// - Persistent settings
class SleepSchedulerService {
  // Singleton
  static final SleepSchedulerService _instance = SleepSchedulerService._internal();
  factory SleepSchedulerService() => _instance;
  SleepSchedulerService._internal();

  static SleepSchedulerService get instance => _instance;

  // Services
  final SoundIntelligenceHub _hub = SoundIntelligenceHub();

  // State
  bool _isEnabled = false;
  bool _isInSleepWindow = false;
  bool _manualOverride = false;
  Timer? _schedulerTimer;

  // Default schedule (user can change)
  int _sleepStartHour = 22;    // 10 PM
  int _sleepStartMinute = 0;
  int _sleepEndHour = 6;       // 6 AM
  int _sleepEndMinute = 0;

  // Preferences key
  static const String _prefKeyEnabled = 'sleep_scheduler_enabled';
  static const String _prefKeyStartHour = 'sleep_start_hour';
  static const String _prefKeyStartMinute = 'sleep_start_minute';
  static const String _prefKeyEndHour = 'sleep_end_hour';
  static const String _prefKeyEndMinute = 'sleep_end_minute';

  // Stream for UI updates
  final _statusController = StreamController<SleepSchedulerStatus>.broadcast();
  Stream<SleepSchedulerStatus> get statusStream => _statusController.stream;

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isInSleepWindow => _isInSleepWindow;
  bool get isSleepModeActive => _hub.currentMode == ListeningMode.sleepMode;
  
  SleepSchedule get schedule => SleepSchedule(
    startHour: _sleepStartHour,
    startMinute: _sleepStartMinute,
    endHour: _sleepEndHour,
    endMinute: _sleepEndMinute,
  );

  /// Initialize the scheduler
  Future<void> initialize() async {
    debugPrint('😴 Initializing Sleep Scheduler...');

    // Load saved preferences
    await _loadPreferences();

    // Check current time immediately
    _checkSchedule();

    // Start monitoring if enabled
    if (_isEnabled) {
      await startMonitoring();
    }

    debugPrint('✅ Sleep Scheduler initialized (enabled: $_isEnabled)');
  }

  /// Start monitoring time and auto-activating sleep mode
  Future<void> startMonitoring() async {
    if (_schedulerTimer != null) {
      debugPrint('⚠️ Scheduler already monitoring');
      return;
    }

    debugPrint('⏰ Starting sleep schedule monitoring...');
    _isEnabled = true;
    await _savePreferences();

    // Check every minute
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkSchedule();
    });

    // Check immediately
    _checkSchedule();

    _emitStatus();
    debugPrint('✅ Sleep schedule monitoring active');
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    debugPrint('🛑 Stopping sleep schedule monitoring...');
    
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    _isEnabled = false;
    await _savePreferences();

    // If sleep mode is active, deactivate it
    if (isSleepModeActive && !_manualOverride) {
      await _hub.stopListening();
      _isInSleepWindow = false;
    }

    _emitStatus();
    debugPrint('✅ Sleep schedule monitoring stopped');
  }

  /// Check if current time is in sleep window and activate/deactivate accordingly
  void _checkSchedule() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    final startMinutes = _sleepStartHour * 60 + _sleepStartMinute;
    final endMinutes = _sleepEndHour * 60 + _sleepEndMinute;

    bool shouldBeInSleepWindow;

    // Handle overnight schedule (e.g., 10 PM to 6 AM)
    if (startMinutes > endMinutes) {
      // Sleep window crosses midnight
      shouldBeInSleepWindow = currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Sleep window is within same day
      shouldBeInSleepWindow = currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }

    // State changed?
    if (shouldBeInSleepWindow != _isInSleepWindow) {
      _isInSleepWindow = shouldBeInSleepWindow;
      
      if (_isInSleepWindow) {
        _onEnterSleepWindow();
      } else {
        _onExitSleepWindow();
      }
    }
  }

  /// Entered sleep window - activate sleep mode
  void _onEnterSleepWindow() async {
    debugPrint('🌙 Entered sleep window (${_sleepStartHour}:${_sleepStartMinute.toString().padLeft(2, '0')})');

    // Don't activate if manual override is active
    if (_manualOverride) {
      debugPrint('⚠️ Manual override active, not auto-activating');
      _emitStatus();
      return;
    }

    // Activate sleep mode
    debugPrint('😴 Auto-activating sleep mode...');
    
    try {
      final success = await _hub.startListening(mode: ListeningMode.sleepMode);
      
      if (success) {
        debugPrint('✅ Sleep mode activated successfully');
        _emitStatus(message: 'Sleep Guardian activated');
      } else {
        debugPrint('❌ Failed to activate sleep mode');
        _emitStatus(message: 'Failed to activate sleep mode');
      }
    } catch (e) {
      debugPrint('❌ Error activating sleep mode: $e');
      _emitStatus(message: 'Error: $e');
    }
  }

  /// Exited sleep window - deactivate sleep mode
  void _onExitSleepWindow() async {
    debugPrint('☀️ Exited sleep window (${_sleepEndHour}:${_sleepEndMinute.toString().padLeft(2, '0')})');

    // Don't deactivate if manual override is active
    if (_manualOverride) {
      debugPrint('⚠️ Manual override active, not auto-deactivating');
      _emitStatus();
      return;
    }

    // Deactivate sleep mode (only if it was auto-activated)
    if (isSleepModeActive) {
      debugPrint('😴 Auto-deactivating sleep mode...');
      
      try {
        await _hub.stopListening();
        debugPrint('✅ Sleep mode deactivated');
        _emitStatus(message: 'Sleep Guardian deactivated');
      } catch (e) {
        debugPrint('❌ Error deactivating sleep mode: $e');
        _emitStatus(message: 'Error: $e');
      }
    }
  }

  /// Manually activate sleep mode (override schedule)
  Future<bool> activateManualSleepMode() async {
    debugPrint('👆 Manual sleep mode activation requested');
    
    _manualOverride = true;
    
    try {
      final success = await _hub.startListening(mode: ListeningMode.sleepMode);
      
      if (success) {
        debugPrint('✅ Manual sleep mode activated');
        _emitStatus(message: 'Sleep mode activated manually');
        return true;
      } else {
        _manualOverride = false;
        debugPrint('❌ Failed to activate manual sleep mode');
        return false;
      }
    } catch (e) {
      _manualOverride = false;
      debugPrint('❌ Error in manual activation: $e');
      return false;
    }
  }

  /// Manually deactivate sleep mode (override schedule)
  Future<void> deactivateManualSleepMode() async {
    debugPrint('👆 Manual sleep mode deactivation requested');
    
    _manualOverride = false;
    
    if (isSleepModeActive) {
      await _hub.stopListening();
      debugPrint('✅ Manual sleep mode deactivated');
      _emitStatus(message: 'Sleep mode deactivated manually');
    }
  }

  /// Update sleep schedule
  Future<void> updateSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    debugPrint('⏰ Updating sleep schedule: ${startHour}:${startMinute.toString().padLeft(2, '0')} - ${endHour}:${endMinute.toString().padLeft(2, '0')}');

    _sleepStartHour = startHour;
    _sleepStartMinute = startMinute;
    _sleepEndHour = endHour;
    _sleepEndMinute = endMinute;

    await _savePreferences();

    // Re-check schedule with new times
    if (_isEnabled) {
      _checkSchedule();
    }

    _emitStatus();
  }

  /// Toggle auto sleep mode on/off
  Future<void> toggleEnabled(bool enabled) async {
    if (enabled) {
      await startMonitoring();
    } else {
      await stopMonitoring();
    }
  }

  /// Get next activation/deactivation time
  DateTime getNextScheduledChange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Calculate next sleep start time
    DateTime nextStart = DateTime(
      today.year,
      today.month,
      today.day,
      _sleepStartHour,
      _sleepStartMinute,
    );
    
    // If start time has passed today, move to tomorrow
    if (now.isAfter(nextStart)) {
      nextStart = nextStart.add(const Duration(days: 1));
    }
    
    // Calculate next sleep end time
    DateTime nextEnd = DateTime(
      today.year,
      today.month,
      today.day,
      _sleepEndHour,
      _sleepEndMinute,
    );
    
    // If end time has passed today, move to tomorrow
    if (now.isAfter(nextEnd)) {
      nextEnd = nextEnd.add(const Duration(days: 1));
    }
    
    // Handle overnight schedule
    if (_sleepStartHour > _sleepEndHour) {
      // If we're before start time, end is later today
      // If we're after start time, end is tomorrow
      if (now.hour < _sleepStartHour) {
        nextEnd = DateTime(
          today.year,
          today.month,
          today.day,
          _sleepEndHour,
          _sleepEndMinute,
        );
      } else {
        nextEnd = DateTime(
          today.year,
          today.month,
          today.day + 1,
          _sleepEndHour,
          _sleepEndMinute,
        );
      }
    }
    
    // Return whichever is sooner
    return _isInSleepWindow ? nextEnd : nextStart;
  }

  /// Emit status update
  void _emitStatus({String? message}) {
    _statusController.add(SleepSchedulerStatus(
      isEnabled: _isEnabled,
      isInSleepWindow: _isInSleepWindow,
      isSleepModeActive: isSleepModeActive,
      isManualOverride: _manualOverride,
      schedule: schedule,
      nextChange: getNextScheduledChange(),
      message: message,
    ));
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isEnabled = prefs.getBool(_prefKeyEnabled) ?? false;
      _sleepStartHour = prefs.getInt(_prefKeyStartHour) ?? 22;
      _sleepStartMinute = prefs.getInt(_prefKeyStartMinute) ?? 0;
      _sleepEndHour = prefs.getInt(_prefKeyEndHour) ?? 6;
      _sleepEndMinute = prefs.getInt(_prefKeyEndMinute) ?? 0;
      
      debugPrint('📚 Loaded sleep schedule: ${_sleepStartHour}:${_sleepStartMinute.toString().padLeft(2, '0')} - ${_sleepEndHour}:${_sleepEndMinute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('❌ Failed to load preferences: $e');
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_prefKeyEnabled, _isEnabled);
      await prefs.setInt(_prefKeyStartHour, _sleepStartHour);
      await prefs.setInt(_prefKeyStartMinute, _sleepStartMinute);
      await prefs.setInt(_prefKeyEndHour, _sleepEndHour);
      await prefs.setInt(_prefKeyEndMinute, _sleepEndMinute);
      
      debugPrint('💾 Saved sleep schedule preferences');
    } catch (e) {
      debugPrint('❌ Failed to save preferences: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _schedulerTimer?.cancel();
    _statusController.close();
  }
}

/// Sleep schedule configuration
class SleepSchedule {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  SleepSchedule({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  String get startTime => '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String get endTime => '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  
  @override
  String toString() => '$startTime - $endTime';
}

/// Sleep scheduler status for UI
class SleepSchedulerStatus {
  final bool isEnabled;
  final bool isInSleepWindow;
  final bool isSleepModeActive;
  final bool isManualOverride;
  final SleepSchedule schedule;
  final DateTime nextChange;
  final String? message;

  SleepSchedulerStatus({
    required this.isEnabled,
    required this.isInSleepWindow,
    required this.isSleepModeActive,
    required this.isManualOverride,
    required this.schedule,
    required this.nextChange,
    this.message,
  });

  String get statusText {
    if (!isEnabled) return 'Auto sleep disabled';
    if (isSleepModeActive && isManualOverride) return 'Sleep mode (manual)';
    if (isSleepModeActive) return 'Sleep mode active';
    if (isInSleepWindow) return 'Sleep window active';
    return 'Scheduled: ${schedule.startTime}';
  }
}