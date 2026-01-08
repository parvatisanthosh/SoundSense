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

  /// Identify current speaker
  Future<void> _identifyCurrentSpeaker() async {
    // Need at least 2 seconds of audio (16000 samples/sec * 2 bytes/sample * 2 seconds)
    if (_speakerAudioBuffer.length < 16000 * 2 * 2) {
      return;
    }

    final audioData = Uint8List.fromList(_speakerAudioBuffer);
    _speakerAudioBuffer.clear();

    try {
      final result = await _speakerService.recognizeSpeaker(audioData);

      if (result != null) {
        final identified = result['identified'] ?? false;
        final name = identified ? result['name'] : null;
        final confidence = (result['confidence'] ?? 0.0).toDouble();

        // Update current speaker
        final previousSpeaker = _currentSpeakerName;
        _currentSpeakerName = name;
        _currentSpeakerConfidence = confidence;

        // If speaker changed, emit event
        if (name != previousSpeaker) {
          debugPrint('👤 Speaker: ${name ?? "Unknown"} (${(confidence * 100).toStringAsFixed(1)}%)');
          
          _speakerEventController.add(SpeakerEvent(
            speakerName: name,
            confidence: confidence,
            timestamp: DateTime.now(),
          ));

          // Announce speaker change with TTS (if enabled)
          if (_settings.ttsEnabled && name != null && confidence > 0.5) {
            await _tts.speakAlert('$name is speaking', priority: 'normal');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Speaker identification error: $e');
    }
  }

// Copy the _processAudioData method and replace it in your sound_intelligence_hub.dart file

/// Process audio data - MAIN PIPELINE
Future<void> _processAudioData(List<double> audioData) async {
  _audioBuffer.addAll(audioData);
  
  // Debug log every 50000 samples
  if (_audioBuffer.length % 50000 < audioData.length) {
    debugPrint('🔍 Audio buffer: ${_audioBuffer.length} samples');
    debugPrint('🔍 _isTranscribing=$_isTranscribing, _speechServiceReady=$_speechServiceReady');
  }

  // Add to speaker recognition buffer
  _addAudioForSpeakerIdentification(audioData);

  // Send audio to Azure Speech Service for transcription
  if (_isTranscribing && _speechServiceReady) {
    try {
      final audioBytes = _samplesToBytes(audioData);
      debugPrint('🔍 Sending ${audioBytes.length} bytes to Azure'); // Log EVERY send
      _speechService.sendAudioData(audioBytes);
    } catch (e) {
      debugPrint('⚠️ Error sending audio to speech service: $e');
    }
  } else {
    // Log why we're NOT sending
    if (_audioBuffer.length % 50000 < audioData.length) {
      debugPrint('❌ NOT sending to Azure: transcribing=$_isTranscribing, ready=$_speechServiceReady');
    }
  }
  
  // Add to sound detection buffer
  _audioBuffer.addAll(audioData);

  // Add to speaker recognition buffer
  _addAudioForSpeakerIdentification(audioData);

  // Send audio to Azure Speech Service for transcription
  if (_isTranscribing && _speechServiceReady) {
    try {
      final audioBytes = _samplesToBytes(audioData);
      // Log every 50000 buffer size to avoid spam but still see activity
      if (_audioBuffer.length % 50000 < audioData.length) {
        debugPrint('🔍 Sending ${audioBytes.length} bytes to Azure (buffer: ${_audioBuffer.length})');
      }
      _speechService.sendAudioData(audioBytes);
    } catch (e) {
      debugPrint('⚠️ Error sending audio to speech service: $e');
    }
  } else {
    // Log why we're NOT sending
    if (_audioBuffer.length % 100000 < audioData.length) {
      debugPrint('🔍 NOT transcribing: _isTranscribing=$_isTranscribing, _speechServiceReady=$_speechServiceReady');
    }
  }

  // Need enough samples for YAMNet
  if (_audioBuffer.length < _requiredSamples) {
    return;
  }

  final samples = _audioBuffer.sublist(0, _requiredSamples);
  _audioBuffer = _audioBuffer.sublist(_requiredSamples);

  final audioBytes = _samplesToBytes(samples);

  // STEP 1: Check custom sounds
  final customMatch = await _customSounds.detectCustomSound(audioBytes);
  if (customMatch != null) {
    debugPrint('🎯 Custom sound detected: ${customMatch.displayName} (${customMatch.confidencePercent}%)');
    await _handleCustomSoundDetection(customMatch);
    return;
  }

  // STEP 2: Check YAMNet
  if (!_classifier.isReady) return;

  final yamnetResults = await _classifier.classify(samples);
  if (yamnetResults.isEmpty) return;

  // STEP 3: Process YAMNet results
  for (var result in yamnetResults) {
    await _handleYAMNetDetection(result);
  }
}

  /// Add audio for speaker identification
  void _addAudioForSpeakerIdentification(List<double> audioData) {
    // Convert double samples to int16 bytes
    for (var sample in audioData) {
      int intSample = (sample * 32768).round().clamp(-32768, 32767);
      if (intSample < 0) intSample += 65536;
      _speakerAudioBuffer.add(intSample & 0xFF);
      _speakerAudioBuffer.add((intSample >> 8) & 0xFF);
    }

    // Keep only last 4 seconds
    const maxBufferSize = 16000 * 2 * 4;
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
  Future<void> _handleYAMNetDetection(SoundResult result) async {
    final priority = SoundCategory.getPriority(result.label);

    if (!_settings.shouldShowSound(priority)) return;
    if (_shouldSkipBasedOnLearning(result.label)) {
      debugPrint('🤫 Skipping ${result.label} - user previously dismissed');
      return;
    }

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

    if (similarRecent >= 3 && !_customSounds.hasSound(event.soundName)) {
      _suggestionController.add(SmartSuggestion(
        type: SuggestionType.trainCustomSound,
        message: 'Train "${event.soundName}" for better accuracy?',
        soundName: event.soundName,
        reason: 'Detected $similarRecent times with low confidence',
      ));
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
  final isDuplicate = _soundHistory.isNotEmpty &&
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