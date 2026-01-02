import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech Alert Service
/// Speaks sound alerts through Bluetooth hearing aids/earbuds
class TTSAlertService {
  static final TTSAlertService _instance = TTSAlertService._();
  static TTSAlertService get instance => _instance;
  TTSAlertService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = true;
  
  // Prevent speaking too frequently
  DateTime? _lastSpoken;
  static const Duration _cooldown = Duration(seconds: 2);
Future<void> initialize() async {
  if (_isInitialized) {
    print('📢 TTS already initialized');
    return;
  }

  try {
    print('📢 Initializing TTS...');
    
    // Force audio to speaker
    await _tts.setQueueMode(1); // Add to queue
    
    // Set language
    await _tts.setLanguage('en-US');
    
    // Set speech rate (slower for clarity)
    await _tts.setSpeechRate(0.5);
    
    // Set volume to MAX
    await _tts.setVolume(1.0);
    
    // Set pitch
    await _tts.setPitch(1.0);

    // Add completion handler
    _tts.setCompletionHandler(() {
      print('📢 TTS finished speaking');
    });

    // Add error handler
    _tts.setErrorHandler((msg) {
      print('❌ TTS error: $msg');
    });

    _isInitialized = true;
    print('✅ TTS Alert Service initialized');
  } catch (e) {
    print('❌ TTS initialization failed: $e');
  }
}

  /// Enable/disable TTS alerts
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print('📢 TTS Alerts ${enabled ? "enabled" : "disabled"}');
  }

  bool get isEnabled => _isEnabled;

Future<void> speakAlert(String soundName, {String? priority}) async {
  print('📢 speakAlert called with: $soundName, priority: $priority');
  print('📢 TTS enabled: $_isEnabled');
  print('📢 TTS initialized: $_isInitialized');
  
  if (!_isEnabled) {
    print('📢 TTS is disabled, skipping');
    return;
  }
  if (!_isInitialized) {
    print('📢 TTS not initialized, initializing now...');
    await initialize();
  }

  // Check cooldown to prevent spam
  if (_lastSpoken != null) {
    final elapsed = DateTime.now().difference(_lastSpoken!);
    if (elapsed < _cooldown) {
      print('📢 TTS cooldown, skipping: $soundName');
      return;
    }
  }

  // Clean up sound name
  final cleanName = _cleanSoundName(soundName);
  
  // Build message based on priority
  String message;
  if (priority == 'critical') {
    message = 'Alert! $cleanName!';
  } else if (priority == 'important') {
    message = '$cleanName detected';
  } else {
    message = cleanName;
  }

  print('📢 Speaking: $message');
  _lastSpoken = DateTime.now();
  
  try {
    var result = await _tts.speak(message);
    print('📢 TTS speak result: $result');
  } catch (e) {
    print('❌ TTS speak error: $e');
  }
}

  /// Clean up sound name for better speech
  String _cleanSoundName(String name) {
    // Remove special characters
    var clean = name.replaceAll('⭐ ', '');
    
    // Replace underscores with spaces
    clean = clean.replaceAll('_', ' ');
    
    // Capitalize first letter
    if (clean.isNotEmpty) {
      clean = clean[0].toUpperCase() + clean.substring(1);
    }
    
    return clean;
  }

  /// Speak custom message
  Future<void> speak(String message) async {
    if (!_isEnabled) return;
    if (!_isInitialized) await initialize();
    
    print('📢 Speaking custom: $message');
    await _tts.speak(message);
  }

  /// Stop current speech
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set language (e.g., 'en-US', 'hi-IN')
  Future<void> setLanguage(String language) async {
    await _tts.setLanguage(language);
    print('📢 TTS language set to: $language');
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    final languages = await _tts.getLanguages;
    return languages.cast<String>();
  }
}