import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/detected_sound.dart';
import '../models/sound_category.dart';
import 'audio_service.dart';
import 'sound_classifier.dart';
import 'custom_sound_service.dart';
import 'tts_alert_service.dart';
import 'haptic_service.dart';
import 'sos_service.dart';
import 'settings_service.dart';
import '../../services/sleep_mode_service.dart';
import '../../core/services/pyannote_api_service.dart';
import '../../core/services/azure_speech_service.dart';

/// Central Intelligence Hub - Coordinates all app features
/// 
/// NOW INCLUDES: Speaker Recognition + Speech-to-Text Integration!
/// Shows WHO is speaking, WHAT they're saying, and WHAT sounds are detected
class SoundIntelligenceHub {
  // Singleton pattern
  
  static final SoundIntelligenceHub _instance = SoundIntelligenceHub._internal();
  factory SoundIntelligenceHub() => _instance;
  SoundIntelligenceHub._internal();

  //new
  DateTime? _lastSOSTime;
  DateTime? _lastSleepAlertTime;
  static const _sosCooldown = Duration(minutes: 5); // No SOS for 5 mins after one is sent
  static const _sleepAlertCooldown = Duration(seconds: 30);

  // Services
  final AudioService _audioService = AudioService();
  final SoundClassifier _classifier = SoundClassifier();
  final CustomSoundService _customSounds = CustomSoundService.instance;
  final TTSAlertService _tts = TTSAlertService.instance;
  final SOSService _sos = SOSService.instance;
  final SettingsService _settings = SettingsService();
  final PyannoteApiService _speakerService = PyannoteApiService.instance;
  
  // Azure Speech Service - will be initialized with API key
  late final AzureSpeechService _speechService;
  
  SleepModeService? _sleepMode;

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  ListeningMode _currentMode = ListeningMode.normal;

  // Audio buffer for processing
  List<double> _audioBuffer = [];
  static const int _requiredSamples = 15600; // ~1 second at 16kHz for YAMNet

  // Speaker recognition buffer (needs 2-3 seconds)
  List<int> _speakerAudioBuffer = [];
  Timer? _speakerIdentificationTimer;
  String? _currentSpeakerName;
  double _currentSpeakerConfidence = 0.0;

  // Speech-to-text state
  String _currentTranscription = '';
  String _partialTranscription = '';
  bool _isTranscribing = false;
  bool _speechServiceReady = false; // ✅ FIXED: Track this ourselves

  // Sound history
  final List<SmartSoundEvent> _soundHistory = [];
  static const int _maxHistorySize = 100;
  final Map<String, int> _trainingPromptRejections = {}; // Track "No" responses
static const int _maxTrainingPromptRejections = 3;

  // User preferences
  final Map<String, UserSoundPreference> _learnedPreferences = {};

  // Streams
  final _soundEventController = StreamController<SmartSoundEvent>.broadcast();
  final _suggestionController = StreamController<SmartSuggestion>.broadcast();
  final _emergencyController = StreamController<EmergencyEvent>.broadcast();
  final _speakerEventController = StreamController<SpeakerEvent>.broadcast();
  final _transcriptionController = StreamController<TranscriptionEvent>.broadcast();

  // Public streams
  Stream<SmartSoundEvent> get soundEventStream => _soundEventController.stream;
  Stream<SmartSuggestion> get suggestionStream => _suggestionController.stream;
  Stream<EmergencyEvent> get emergencyStream => _emergencyController.stream;
  Stream<SpeakerEvent> get speakerEventStream => _speakerEventController.stream;
  Stream<TranscriptionEvent> get transcriptionStream => _transcriptionController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  ListeningMode get currentMode => _currentMode;
  List<SmartSoundEvent> get recentSounds => _soundHistory.take(20).toList();
  String? get currentSpeaker => _currentSpeakerName;
  double get currentSpeakerConfidence => _currentSpeakerConfidence;
  String get currentTranscription => _currentTranscription;
  String get partialTranscription => _partialTranscription;

  /// Initialize the hub
  /// 
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🧠 Hub already initialized');
      return;
    }

    debugPrint('🧠 Initializing Sound Intelligence Hub with Speech-to-Text...');

    try {
      // 1. Initialize AI classifier
      debugPrint('🧠 Loading YAMNet model...');
      await _classifier.initialize();
      debugPrint('✅ YAMNet loaded: ${_classifier.isReady}');

      // 2. Initialize custom sounds
      debugPrint('🧠 Loading custom sounds...');
      await _customSounds.initialize();
      debugPrint('✅ Custom sounds loaded: ${_customSounds.customSounds.length}');

      // 3. Initialize TTS
      debugPrint('🧠 Initializing TTS...');
      await _tts.initialize();
      debugPrint('✅ TTS ready');

      // 4. Initialize settings
      debugPrint('🧠 Loading settings...');
      await _settings.init();
      debugPrint('✅ Settings loaded');

      // 5. Initialize SOS
      debugPrint('🧠 Initializing SOS...');
      await _sos.initialize();
      debugPrint('✅ SOS ready');

      // 6. Check speaker recognition service
      debugPrint('🧠 Checking speaker recognition...');
      final speakerHealthy = await _speakerService.checkHealth();
      if (speakerHealthy) {
        debugPrint('✅ Speaker recognition available');
      } else {
        debugPrint('⚠️ Speaker recognition offline (will work when server is up)');
      }

      // 7. Initialize Azure Speech Service
      debugPrint('🧠 Initializing Azure Speech Service...');
      try {
        // Get API key from EnvConfig (flutter_dotenv)
        final azureKey = dotenv.env['AZURE_SPEECH_KEY'] ?? '';
        final azureRegion = dotenv.env['AZURE_SPEECH_REGION'] ?? 'eastus';
        
        debugPrint('🔍 Azure Key length: ${azureKey.length}');
        debugPrint('🔍 Azure Region: $azureRegion');
        
        if (azureKey.isEmpty) {
          debugPrint('❌ Azure Speech Service: No API key found in .env file');
          debugPrint('💡 Add AZURE_SPEECH_KEY to your .env file');
          _speechServiceReady = false;
        } else {
          debugPrint('🔍 Creating AzureSpeechService instance...');
          _speechService = AzureSpeechService(
            apiKey: azureKey,
            region: azureRegion,
          );
          _speechServiceReady = true;
          debugPrint('✅ Azure Speech Service created successfully');
          _setupSpeechCallbacks();
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Azure Speech Service initialization failed: $e');
        debugPrint('Stack trace: $stackTrace');
        _speechServiceReady = false;
      }
      
      debugPrint('🔍 Final _speechServiceReady status: $_speechServiceReady');

      // 8. Load learned preferences
      await _loadLearnedPreferences();

      // 9. Set up audio callbacks
      _setupAudioCallbacks();

      _isInitialized = true;
      debugPrint('✅ Hub fully initialized with Sound + Speaker + Speech-to-Text!');
    } catch (e) {
      debugPrint('❌ Hub initialization error: $e');
      rethrow;
    }
  }

  /// Setup speech-to-text callbacks
  void _setupSpeechCallbacks() {
    debugPrint('🔍 Setting up speech callbacks...');
    
    // Listen for partial transcriptions (live captions)
    _speechService.partialStream.listen((text) {
      debugPrint('🔍 Partial stream received: "$text"');
      _partialTranscription = text;
      
      // Emit partial transcription event
      _transcriptionController.add(TranscriptionEvent(
        text: text,
        speakerName: _currentSpeakerName,
        speakerConfidence: _currentSpeakerConfidence,
        timestamp: DateTime.now(),
        isFinal: false,
      ));
      
      debugPrint('🗣️ Transcription (partial): "$text"');
    });
    

    // Listen for final transcriptions
    _speechService.transcriptionStream.listen((text) {
      debugPrint('🔍 Transcription stream received: "$text"');
      if (text.trim().isEmpty) {
        debugPrint('🔍 Skipping empty transcription');
        return;
      }
      
      _currentTranscription = text;
      _partialTranscription = '';
      
      // Emit final transcription event
      _transcriptionController.add(TranscriptionEvent(
        text: text,
        speakerName: _currentSpeakerName,
        speakerConfidence: _currentSpeakerConfidence,
        timestamp: DateTime.now(),
        isFinal: true,
      ));
      
      debugPrint('🗣️ Transcription: "$text"');
    });
    
    debugPrint('🔍 Speech callbacks setup complete');
  }

  

  /// Start listening
  Future<bool> startListening({ListeningMode mode = ListeningMode.normal}) async {
    if (!_isInitialized) {
      debugPrint('❌ Hub not initialized, initializing now...');
      await initialize();
    }
if (_isListening) {
    debugPrint('⚠️ Already listening, stopping first...');
    await stopListening();  // ✅ Stop before starting again
  }

    debugPrint('🎤 Starting listening - Mode: $mode (Sound + Speaker + Speech)');
    _currentMode = mode;

    try {
      // Start audio service
      await _audioService.startListening();
      _isListening = true;

      // Start speaker identification
      _startSpeakerIdentification();

      // Start speech-to-text
      if (_speechServiceReady) {
        try {
          await _speechService.startTranscription();
          _isTranscribing = true;
          debugPrint('✅ Azure Speech transcription started');
        } catch (e) {
          debugPrint('⚠️ Failed to start transcription: $e');
          _isTranscribing = false;
        }
      }

      // If sleep mode, integrate
      if (mode == ListeningMode.sleepMode) {
        await _activateSleepMode();
      }

      debugPrint('✅ Listening started with all features!');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
      _isListening = false;
      return false;
    }
  }
  bool _shouldOfferTraining(String soundName) {
  final pref = _learnedPreferences[soundName];

  // Never dismissed before → ask
  if (pref == null) return true;

  // User said NO 3 times → stop forever
  return pref.dismissCount < 3;
}
bool shouldShowTrainingPrompt(String soundName) {
  // Don't prompt for custom sounds (already trained)
  if (_customSounds.hasSound(soundName)) {
    return false;
  }
  
  // Don't prompt if user said "No" 3+ times
  final rejections = _trainingPromptRejections[soundName] ?? 0;
  if (rejections >= _maxTrainingPromptRejections) {
    return false;
  }
  
  return true;
}

// Add this method to handle "No" response
void rejectTrainingPrompt(String soundName) {
  _trainingPromptRejections[soundName] = (_trainingPromptRejections[soundName] ?? 0) + 1;
  
  final count = _trainingPromptRejections[soundName]!;
  debugPrint('❌ User rejected training for "$soundName" ($count/$_maxTrainingPromptRejections)');
  
  if (count >= _maxTrainingPromptRejections) {
    debugPrint('🔕 Will not prompt training for "$soundName" anymore');
  }
  
  _saveTrainingPreferences();
}

// Add this method to reset if user trains the sound
void acceptTrainingPrompt(String soundName) {
  _trainingPromptRejections.remove(soundName);
  debugPrint('✅ User accepted training for "$soundName"');
  _saveTrainingPreferences();
}

// Save preferences (add this near _saveLearnedPreferences)
Future<void> _saveTrainingPreferences() async {
  // TODO: Implement persistent storage if needed
  // For now, rejections are reset when app restarts
}

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    debugPrint('🛑 Stopping listening...');

    _audioService.stopListening();
    _audioBuffer.clear();
    
    // Stop speaker identification
    _stopSpeakerIdentification();
    _speakerAudioBuffer.clear();
    _currentSpeakerName = null;
    _currentSpeakerConfidence = 0.0;
    
    // Stop speech-to-text
    if (_isTranscribing) {
      try {
        await _speechService.stopTranscription();
        _isTranscribing = false;
        _currentTranscription = '';
        _partialTranscription = '';
        debugPrint('✅ Azure Speech transcription stopped');
      } catch (e) {
        debugPrint('⚠️ Error stopping transcription: $e');
      }
    }
    
    _isListening = false;

    if (_currentMode == ListeningMode.sleepMode) {
      await _deactivateSleepMode();
    }

    _currentMode = ListeningMode.normal;
    debugPrint('✅ Listening stopped');
  }

  /// Set up audio callbacks
  void _setupAudioCallbacks() {
    _audioService.onNoiseLevel = (double decibel) {
      // Pass through for visualization
    };

    _audioService.onAudioData = (List<double> audioData) {
      _processAudioData(audioData);
    };
  }

  /// Start speaker identification
  void _startSpeakerIdentification() {
    _speakerAudioBuffer = [];
    _speakerIdentificationTimer = Timer.periodic(
      const Duration(seconds: 3), // Check every 3 seconds
      (_) => _identifyCurrentSpeaker(),
    );
    debugPrint('👤 Speaker identification started');
  }

  /// Stop speaker identification
  void _stopSpeakerIdentification() {
    _speakerIdentificationTimer?.cancel();
    _speakerIdentificationTimer = null;
    debugPrint('👤 Speaker identification stopped');
  }

/// ✅ ENHANCED: Speaker identification with better debugging
Future<void> _identifyCurrentSpeaker() async {
  // Need at least 3 seconds of audio for good recognition
  const minBufferSize = 16000 * 2 * 3; // 96,000 bytes
  
  debugPrint('🔍 Speaker buffer check: ${_speakerAudioBuffer.length} / $minBufferSize bytes');
  
  if (_speakerAudioBuffer.length < minBufferSize) {
    debugPrint('⏳ Not enough audio for speaker ID yet...');
    return;
  }

  // Take exactly 3 seconds
  final audioData = Uint8List.fromList(_speakerAudioBuffer.take(minBufferSize).toList());
  _speakerAudioBuffer.removeRange(0, minBufferSize);

  debugPrint('🎙️ Attempting speaker recognition with ${audioData.length} bytes...');

  try {
    final result = await _speakerService.recognizeSpeaker(audioData);

    debugPrint('📊 Speaker recognition result: $result');

    if (result != null) {
      final rawConfidence = (result['confidence'] ?? 0.0).toDouble();
      final name = result['name'];
      final identified = result['identified'] == true;
      
      debugPrint('👤 Name: $name, Confidence: ${(rawConfidence * 100).toStringAsFixed(1)}%, Identified: $identified');
      
      final previousSpeaker = _currentSpeakerName;
      
      if (identified && name != null) {
        _currentSpeakerName = name;
        _currentSpeakerConfidence = rawConfidence;
        
        debugPrint('✅ Speaker identified: $name (${(rawConfidence * 100).toStringAsFixed(1)}%)');
        
        // Only emit if speaker changed
        if (name != previousSpeaker) {
          _speakerEventController.add(SpeakerEvent(
            speakerName: name,
            confidence: rawConfidence,
            timestamp: DateTime.now(),
          ));

          // Optional TTS announcement
          if (_settings.ttsEnabled && rawConfidence > 0.75) {
            await _tts.speakAlert('$name is speaking', priority: 'normal');
          }
        }
      } else {
        debugPrint('❌ Not identified (confidence ${(rawConfidence * 100).toStringAsFixed(1)}% < 70%)');
        
        // Only clear if confidence was low
        if (_currentSpeakerConfidence < 0.5) {
          _currentSpeakerName = null;
          _currentSpeakerConfidence = rawConfidence;
        }
      }
    } else {
      debugPrint('⚠️ Speaker recognition returned null');
    }
  } catch (e) {
    debugPrint('❌ Speaker recognition error: $e');
    // Don't clear speaker on error
  }
}


// Copy the _processAudioData method and replace it in your sound_intelligence_hub.dart file

/// Process audio data - MAIN PIPELINE
/// ✅ FIXED: Process audio data - MAIN PIPELINE
Future<void> _processAudioData(List<double> audioData) async {
  // STEP 1: Add to sound detection buffer (for YAMNet)
  _audioBuffer.addAll(audioData);
  
  // STEP 2: Add to speaker recognition buffer (for Pyannote)
  _addAudioForSpeakerIdentification(audioData);

  // STEP 3: Send audio to Azure Speech Service for transcription
  if (_isTranscribing && _speechServiceReady) {
    try {
      final audioBytes = _samplesToBytes(audioData);
      
      // Log periodically to avoid spam
      if (_audioBuffer.length % 50000 < audioData.length) {
        debugPrint('🔍 Sending ${audioBytes.length} bytes to Azure (buffer: ${_audioBuffer.length})');
        debugPrint('🔍 Speaker buffer: ${_speakerAudioBuffer.length} bytes');
      }
      
      _speechService.sendAudioData(audioBytes);
    } catch (e) {
      debugPrint('⚠️ Error sending audio to speech service: $e');
    }
  }

  // STEP 4: Check if we have enough samples for YAMNet (sound detection)
  if (_audioBuffer.length < _requiredSamples) {
    return;
  }

  final samples = _audioBuffer.sublist(0, _requiredSamples);
  _audioBuffer = _audioBuffer.sublist(_requiredSamples);

  final audioBytes = _samplesToBytes(samples);

  // STEP 5: Check custom sounds
  final customMatch = await _customSounds.detectCustomSound(audioBytes);
  if (customMatch != null) {
    debugPrint('🎯 Custom sound detected: ${customMatch.displayName} (${customMatch.confidencePercent}%)');
    await _handleCustomSoundDetection(customMatch);
    return;
  }

  // STEP 6: Check YAMNet
  if (!_classifier.isReady) return;

  final yamnetResults = await _classifier.classify(samples);
  if (yamnetResults.isEmpty) return;

  // STEP 7: Process YAMNet results
  for (var result in yamnetResults) {
    await _handleYAMNetDetection(result);
  }
}

  /// Add audio for speaker identification
void _addAudioForSpeakerIdentification(List<double> audioData) {
  // Convert samples to bytes efficiently
  for (var sample in audioData) {
    int intSample = (sample * 32768).round().clamp(-32768, 32767);
    if (intSample < 0) intSample += 65536;
    _speakerAudioBuffer.add(intSample & 0xFF);
    _speakerAudioBuffer.add((intSample >> 8) & 0xFF);
  }

  // Keep only last 5 seconds
  const maxBufferSize = 16000 * 2 * 5;
  if (_speakerAudioBuffer.length > maxBufferSize) {
    _speakerAudioBuffer = _speakerAudioBuffer.sublist(
      _speakerAudioBuffer.length - maxBufferSize,
    );
  }
}

  /// Handle custom sound detection
  Future<void> _handleCustomSoundDetection(CustomSoundMatch match) async {
    final event = SmartSoundEvent(
      soundName: match.displayName,
      displayName: '⭐ ${match.displayName}',
      confidence: match.confidence,
      priority: 'important',
      source: SoundSource.customTrained,
      timestamp: DateTime.now(),
      context: _getCurrentContext(),
      speakerName: _currentSpeakerName,
      speakerConfidence: _currentSpeakerConfidence,
      transcription: _currentTranscription.isNotEmpty ? _currentTranscription : null,
    );

    await _executeSmartActions(event);
  }

  /// Handle YAMNet detection
// Find _handleYAMNetDetection (around line 350) and replace with:
Future<void> _handleYAMNetDetection(SoundResult result) async {
  final priority = SoundCategory.getPriority(result.label);

  if (!_settings.shouldShowSound(priority)) return;
  if (_shouldSkipBasedOnLearning(result.label)) {
    debugPrint('🤫 Skipping ${result.label} - user previously dismissed');
    return;
  }

  // ✅ NEW: Check if we should show training prompt
  final shouldPrompt = shouldShowTrainingPrompt(result.label);

  final event = SmartSoundEvent(
    soundName: result.label,
    displayName: result.label,
    confidence: result.confidence,
    priority: priority,
    source: SoundSource.yamnet,
    timestamp: DateTime.now(),
    context: _getCurrentContext(),
    speakerName: _currentSpeakerName,
    speakerConfidence: _currentSpeakerConfidence,
    transcription: _currentTranscription.isNotEmpty ? _currentTranscription : null,
    shouldPromptTraining: shouldPrompt, // ✅ NEW
  );

  await _executeSmartActions(event);
}

  /// Execute smart actions
  Future<void> _executeSmartActions(SmartSoundEvent event) async {
    debugPrint('🧠 Executing actions for: ${event.displayName} (${event.priority})');
    
    // Log speaker if known
    if (event.speakerName != null) {
      debugPrint('👤 Speaker: ${event.speakerName} (${(event.speakerConfidence * 100).toStringAsFixed(1)}%)');
    }

    // Log transcription if available
    if (event.transcription != null) {
      debugPrint('🗣️ Said: "${event.transcription}"');
    }

    _addToHistory(event);

    // ACTION 1: TTS
    if (_settings.ttsEnabled && event.context.shouldAnnounce) {
      // Include speaker in announcement
      String announcement = event.displayName;
      if (event.speakerName != null && event.speakerConfidence > 0.5) {
        announcement = '${event.speakerName} detected ${event.displayName}';
      }
      
      await _tts.speakAlert(announcement, priority: event.priority);
    }

    // ACTION 2: Haptics
    if (_settings.vibrationEnabled && 
        (event.priority == 'critical' || event.priority == 'important')) {
      HapticService.vibrate(event.priority);
    }

    // ACTION 3: Emergency check
    if (event.priority == 'critical') {
      await _checkEmergencyTrigger(event);
    }

    // ACTION 4: Send to UI
    _soundEventController.add(event);

    // ACTION 5: Learning
    _checkForSmartSuggestions(event);
  }

  /// Check emergency trigger
Future<void> _checkEmergencyTrigger(SmartSoundEvent event) async {
  // ✅ Sleep mode: Only trigger for ACTUAL emergency sounds
  if (_currentMode == ListeningMode.sleepMode && event.priority == 'critical') {
    // Check cooldown for sleep alerts
    if (_lastSleepAlertTime != null && 
        DateTime.now().difference(_lastSleepAlertTime!) < _sleepAlertCooldown) {
      debugPrint('😴 Sleep alert on cooldown, skipping...');
      return;
    }
    
    // ✅ Filter out false positives - only real emergency sounds
    final soundName = event.soundName.toLowerCase();
    final isRealEmergency = soundName.contains('alarm') ||
                           soundName.contains('fire') ||
                           soundName.contains('smoke') ||
                           soundName.contains('baby') ||
                           soundName.contains('cry') ||
                           soundName.contains('glass') ||
                           soundName.contains('break') ||
                           soundName.contains('siren') ||
                           soundName.contains('emergency');
    
    if (isRealEmergency) {
      debugPrint('😴 Sleep mode: REAL critical sound detected - ${event.soundName}');
      _lastSleepAlertTime = DateTime.now(); // Set cooldown
      
      if (_sleepMode != null) {
        await _sleepMode!.triggerCriticalSoundAlert(event.soundName);
      }
    } else {
      debugPrint('😴 Sleep mode: Ignoring non-emergency sound - ${event.soundName}');
    }
  }
  
  // ✅ SOS Check with cooldown
  // Check cooldown for SOS
  if (_lastSOSTime != null && 
      DateTime.now().difference(_lastSOSTime!) < _sosCooldown) {
    debugPrint('🚨 SOS on cooldown (${_sosCooldown.inMinutes} min), skipping...');
    return;
  }
  
  debugPrint('🔍 SOS Check: Event "${event.soundName}" with priority ${event.priority}');
  
  final recentCritical = _soundHistory
      .where((s) => 
          s.priority == 'critical' && 
          DateTime.now().difference(s.timestamp).inSeconds < 30)
      .toList();
  
  debugPrint('🔍 SOS Check: Found ${recentCritical.length} recent critical sounds');
  
  if (recentCritical.length < 2) {  // Changed back to 2 for safety
    debugPrint('⚠️ SOS: Need 2 critical sounds, only have ${recentCritical.length}');
    return;
  }
  
  debugPrint('🚨 Multiple critical sounds detected!');

  final soundNames = recentCritical.map((s) => s.soundName).toList();
  if (_sos.shouldTriggerSOS(soundNames)) {
    debugPrint('🚨 SOS TRIGGER CONDITIONS MET!');
    _lastSOSTime = DateTime.now(); // Set SOS cooldown
    
    _emergencyController.add(EmergencyEvent(
      type: EmergencyType.autoDetected,
      sounds: soundNames,
      timestamp: DateTime.now(),
    ));
  }
}

  /// Check for smart suggestions
  void _checkForSmartSuggestions(SmartSoundEvent event) {
    final similarRecent = _soundHistory
        .where((s) => 
            s.soundName == event.soundName &&
            s.source == SoundSource.yamnet &&
            s.confidence < 0.7)
        .length;

if (similarRecent >= 3 &&
    !_customSounds.hasSound(event.soundName) &&
    _shouldOfferTraining(event.soundName)) {

  final trainingEvent = SmartSoundEvent(
    soundName: event.soundName,
    displayName: 'Would you like to train this sound?',
    confidence: event.confidence,
    priority: 'low',
    source: SoundSource.trainingSuggestion,
    timestamp: DateTime.now(),
    context: event.context,
  );

  _addToHistory(trainingEvent);

  debugPrint('🧠 Training suggestion shown for ${event.soundName}');
}


  }

  /// Get current context
  DetectionContext _getCurrentContext() {
    final now = DateTime.now();
    final hour = now.hour;

    return DetectionContext(
      timeOfDay: _getTimeOfDay(hour),
      isNightTime: hour < 6 || hour >= 22,
      mode: _currentMode,
      shouldAnnounce: _shouldAnnounceBasedOnContext(hour),
      environmentalNoise: 'unknown',
    );
  }

  TimeOfDay _getTimeOfDay(int hour) {
    if (hour >= 6 && hour < 12) return TimeOfDay.morning;
    if (hour >= 12 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 22) return TimeOfDay.evening;
    return TimeOfDay.night;
  }

  bool _shouldAnnounceBasedOnContext(int hour) {
    if (hour < 6 || hour >= 23) return false;
    return true;
  }

  /// Check if should skip based on learning
  bool _shouldSkipBasedOnLearning(String soundName) {
    final pref = _learnedPreferences[soundName];
    if (pref == null) return false;
    return pref.dismissCount >= 5;
  }

  /// User feedback
  void confirmSound(String soundName, {required bool correct}) {
    final pref = _learnedPreferences.putIfAbsent(
      soundName,
      () => UserSoundPreference(soundName: soundName),
    );

    if (correct) {
      pref.confirmCount++;
      debugPrint('✅ User confirmed: $soundName (${pref.confirmCount} times)');
    } else {
      pref.incorrectCount++;
      debugPrint('❌ User marked incorrect: $soundName (${pref.incorrectCount} times)');
    }

    _saveLearnedPreferences();
  }

  void dismissSound(String soundName) {
    final pref = _learnedPreferences.putIfAbsent(
      soundName,
      () => UserSoundPreference(soundName: soundName),
    );

    pref.dismissCount++;
    debugPrint('🤫 User dismissed: $soundName (${pref.dismissCount} times)');

    if (pref.dismissCount >= 5) {
      debugPrint('🔕 Will hide $soundName in future');
    }

    _saveLearnedPreferences();
  }

 void _addToHistory(SmartSoundEvent event) {
  // Check if we just added the same sound within last 3 seconds
  final alreadySuggested = _soundHistory.any((s) =>
    s.soundName == event.soundName &&
    s.displayName.startsWith('Improve detection') &&
    DateTime.now().difference(s.timestamp).inMinutes < 10);

if (alreadySuggested) {
  debugPrint('🧠 Training suggestion already shown recently, skipping');
  return;
}

  final isTrainingSuggestion =
    event.source == SoundSource.trainingSuggestion;

final isDuplicate = !isTrainingSuggestion &&
    _soundHistory.isNotEmpty &&
    _soundHistory.first.soundName == event.soundName &&
    DateTime.now().difference(_soundHistory.first.timestamp).inSeconds < 3;

  
  if (isDuplicate) {
    debugPrint('🔄 Skipping duplicate sound: ${event.soundName}');
    return;
  }
  
  _soundHistory.insert(0, event);
  
  if (_soundHistory.length > _maxHistorySize) {
    _soundHistory.removeRange(_maxHistorySize, _soundHistory.length);
  }
}

  /// Sleep mode
  Future<void> _activateSleepMode() async {
    try {
      debugPrint('😴 Activating sleep mode');
      
      _sleepMode = SleepModeService();
      await _sleepMode!.init();
      await _sleepMode!.startMonitoring();
      
     
      
      debugPrint('✅ Sleep mode activated');
    } catch (e) {
      debugPrint('❌ Sleep mode activation failed: $e');
      _sleepMode = null;
      await _audioService.startListening();
    }
  }

  Future<void> _deactivateSleepMode() async {
    debugPrint('😴 Deactivating sleep mode');
    await _sleepMode?.stopMonitoring();
    _sleepMode = null;
    
   
    debugPrint('✅ Sleep mode deactivated');
  }

  /// Helper methods
  Uint8List _samplesToBytes(List<double> samples) {
    final bytes = Uint8List(samples.length * 2);
    for (int i = 0; i < samples.length; i++) {
      int sample = (samples[i] * 32768).round().clamp(-32768, 32767);
      if (sample < 0) sample += 65536;
      bytes[i * 2] = sample & 0xFF;
      bytes[i * 2 + 1] = (sample >> 8) & 0xFF;
    }
    return bytes;
  }

  Future<void> _loadLearnedPreferences() async {
    debugPrint('📚 Learned preferences: ${_learnedPreferences.length} sounds');
  }

  Future<void> _saveLearnedPreferences() async {
    // TODO: Implement persistent storage
  }

  /// Dispose
  void dispose() {
    _soundEventController.close();
    _suggestionController.close();
    _emergencyController.close();
    _speakerEventController.close();
    _transcriptionController.close();
    _speakerIdentificationTimer?.cancel();
    if (_speechServiceReady) {
      _speechService.dispose();
    }
    _audioService.dispose();
    _classifier.dispose();
  }
}

/// Listening modes
enum ListeningMode {
  normal,
  sleepMode,
}

/// Smart sound event with speaker info and transcription
class SmartSoundEvent {
  final String soundName;
  final String displayName;
  final double confidence;
  final String priority;
  final SoundSource source;
  final DateTime timestamp;
  final DetectionContext context;
  final String? speakerName;
  final double speakerConfidence;
  final bool shouldPromptTraining;
  final String? transcription;
  

  SmartSoundEvent({
    required this.soundName,
    required this.displayName,
    required this.confidence,
    required this.priority,
    required this.source,
    required this.timestamp,
    required this.context,
    this.speakerName,
    this.speakerConfidence = 0.0,
    this.transcription,
    this.shouldPromptTraining = false, 
  });

  DetectedSound toDetectedSound() {
    return DetectedSound(
      name: displayName,
      category: _getCategoryFromPriority(priority),
      confidence: confidence,
      timestamp: timestamp,
      priority: priority,
    );
  }

  String _getCategoryFromPriority(String priority) {
    switch (priority) {
      case 'critical': return 'Alert';
      case 'important': return 'Notification';
      default: return 'Sound';
    }
  }
}

/// Speaker event
class SpeakerEvent {
  final String? speakerName;
  final double confidence;
  final DateTime timestamp;

  SpeakerEvent({
    required this.speakerName,
    required this.confidence,
    required this.timestamp,
  });
}

/// Transcription event
class TranscriptionEvent {
  final String text;
  final String? speakerName;
  final double speakerConfidence;
  final DateTime timestamp;
  final bool isFinal; // true = final, false = partial (live caption)

  TranscriptionEvent({
    required this.text,
    required this.speakerName,
    required this.speakerConfidence,
    required this.timestamp,
    required this.isFinal,
  });
}

/// Sound source
enum SoundSource {
  yamnet,
  customTrained,
  sleepGuardian,
  trainingSuggestion,
}

/// Detection context
class DetectionContext {
  final TimeOfDay timeOfDay;
  final bool isNightTime;
  final ListeningMode mode;
  final bool shouldAnnounce;
  final String environmentalNoise;

  DetectionContext({
    required this.timeOfDay,
    required this.isNightTime,
    required this.mode,
    required this.shouldAnnounce,
    required this.environmentalNoise,
  });
}

enum TimeOfDay { morning, afternoon, evening, night }

/// User sound preference
class UserSoundPreference {
  final String soundName;
  int confirmCount = 0;
  int incorrectCount = 0;
  int dismissCount = 0;

  UserSoundPreference({required this.soundName});

  bool get shouldHide => dismissCount >= 5;

  double get userConfidence {
    final total = confirmCount + incorrectCount;
    if (total == 0) return 0.5;
    return confirmCount / total;
  }
}

/// Smart suggestion
class SmartSuggestion {
  final SuggestionType type;
  final String message;
  final String? soundName;
  final String reason;

  SmartSuggestion({
    required this.type,
    required this.message,
    this.soundName,
    required this.reason,
  });
}

enum SuggestionType {
  trainCustomSound,
  addEmergencyContact,
  enableTTS,
  adjustSensitivity,
}

/// Emergency event
class EmergencyEvent {
  final EmergencyType type;
  final List<String> sounds;
  final DateTime timestamp;

  EmergencyEvent({
    required this.type,
    required this.sounds,
    required this.timestamp,
  });
}

enum EmergencyType {
  autoDetected,
  manualTrigger,
}