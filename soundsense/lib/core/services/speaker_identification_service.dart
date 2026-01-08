import 'dart:typed_data';
import 'dart:math' show sqrt;
import '../models/voice_profile_model.dart';
import 'pyannote_api_service.dart';
import 'training_database.dart';

/// Service for training and identifying speakers
class SpeakerIdentificationService {
  final PyannoteApiService _apiService = PyannoteApiService.instance;
  final TrainingDatabase _database = TrainingDatabase.instance;
  
  List<VoiceProfile> _voiceProfiles = [];
  bool _isInitialized = false;

  // Singleton
  static SpeakerIdentificationService? _instance;
  static SpeakerIdentificationService get instance {
    _instance ??= SpeakerIdentificationService._();
    return _instance!;
  }
  SpeakerIdentificationService._();

  /// Initialize service and load saved profiles
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check API health
    final isHealthy = await _apiService.checkHealth();
    if (!isHealthy) {
      print('⚠️ Warning: Pyannote API server is not responding');
      // Don't throw - allow offline mode
    }
    
    await _database.initialize();
    _voiceProfiles = await _database.getAllVoiceProfiles();
    _isInitialized = true;
    
    print('✅ Speaker ID service initialized with ${_voiceProfiles.length} profiles');
  }

  /// Get all voice profiles
  List<VoiceProfile> get voiceProfiles => List.unmodifiable(_voiceProfiles);

  /// Start training a new voice profile
  VoiceTrainingSession startTraining({
    required String name,
    required String relationship,
    String? emoji,
    int requiredSamples = 3,
  }) {
    return VoiceTrainingSession(
      name: name,
      relationship: relationship,
      emoji: emoji ?? Relationship.getEmoji(relationship),
      requiredSamples: requiredSamples,
      apiService: _apiService,
      onComplete: _saveVoiceProfile,
    );
  }

  /// Save a trained voice profile
  Future<void> _saveVoiceProfile(VoiceProfile profile) async {
    await _database.saveVoiceProfile(profile);
    _voiceProfiles.add(profile);
    print('✅ Saved voice profile: ${profile.name}');
  }

  /// Delete a voice profile
  Future<void> deleteVoiceProfile(String id) async {
    await _database.deleteVoiceProfile(id);
    _voiceProfiles.removeWhere((p) => p.id == id);
  }

  /// Identify speaker from audio using Pyannote API
  Future<SpeakerIdentificationResult> identifySpeaker(
    Uint8List audioData, {
    double threshold = 0.70,
  }) async {
    if (_voiceProfiles.isEmpty) {
      return SpeakerIdentificationResult(
        speaker: null,
        confidence: 0.0,
        isUnknown: true,
      );
    }

    // Call Pyannote API
    final result = await _apiService.recognizeSpeaker(audioData);
    
    if (result == null) {
      return SpeakerIdentificationResult(
        speaker: null,
        confidence: 0.0,
        isUnknown: true,
      );
    }

    final bool identified = result['identified'] ?? false;
    final String? speakerName = result['name'];
    final double confidence = (result['confidence'] ?? 0.0).toDouble();

    if (identified && speakerName != null) {
      // Find matching profile
      try {
        final profile = _voiceProfiles.firstWhere(
          (p) => p.name == speakerName,
        );
        
        return SpeakerIdentificationResult(
          speaker: profile,
          confidence: confidence,
          isUnknown: false,
        );
      } catch (e) {
        print('⚠️ Profile not found locally for: $speakerName');
        return SpeakerIdentificationResult(
          speaker: null,
          confidence: confidence,
          isUnknown: true,
        );
      }
    }

    return SpeakerIdentificationResult(
      speaker: null,
      confidence: confidence,
      isUnknown: true,
    );
  }

  /// Identify speaker with multiple audio chunks for better accuracy
  Future<SpeakerIdentificationResult> identifySpeakerFromChunks(
    List<Uint8List> audioChunks, {
    double threshold = 0.70,
  }) async {
    if (audioChunks.isEmpty) {
      return SpeakerIdentificationResult(
        speaker: null,
        confidence: 0.0,
        isUnknown: true,
      );
    }

    // Get identification result for each chunk
    final results = <SpeakerIdentificationResult>[];
    for (final chunk in audioChunks) {
      final result = await identifySpeaker(chunk, threshold: threshold);
      results.add(result);
    }

    // Vote for best speaker
    final votes = <String, int>{};
    final scores = <String, List<double>>{};
    
    for (final result in results) {
      if (!result.isUnknown && result.speaker != null) {
        final id = result.speaker!.id;
        votes[id] = (votes[id] ?? 0) + 1;
        scores[id] = [...(scores[id] ?? []), result.confidence];
      }
    }

    if (votes.isEmpty) {
      return SpeakerIdentificationResult(
        speaker: null,
        confidence: 0.0,
        isUnknown: true,
      );
    }

    // Find speaker with most votes
    String? winnerId;
    int maxVotes = 0;
    for (final entry in votes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winnerId = entry.key;
      }
    }

    if (winnerId != null) {
      final winner = _voiceProfiles.firstWhere((p) => p.id == winnerId);
      final avgConfidence = scores[winnerId]!.reduce((a, b) => a + b) / scores[winnerId]!.length;
      
      return SpeakerIdentificationResult(
        speaker: winner,
        confidence: avgConfidence,
        isUnknown: false,
      );
    }

    return SpeakerIdentificationResult(
      speaker: null,
      confidence: 0.0,
      isUnknown: true,
    );
  }

  /// Update a voice profile
  Future<void> updateVoiceProfile(VoiceProfile updated) async {
    await _database.saveVoiceProfile(updated);
    final index = _voiceProfiles.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _voiceProfiles[index] = updated;
    }
  }

  /// Add more training samples to existing profile
  Future<void> addTrainingSample(String profileId, Uint8List audioData) async {
    final index = _voiceProfiles.indexWhere((p) => p.id == profileId);
    if (index == -1) return;

    final profile = _voiceProfiles[index];
    
    // Enroll additional sample to API
    final result = await _apiService.enrollSpeaker(profile.name, audioData);
    
    if (result != null) {
      final updatedProfile = profile.copyWith(
        sampleCount: profile.sampleCount + 1,
      );
      
      await updateVoiceProfile(updatedProfile);
      print('✅ Added training sample for ${profile.name}');
    } else {
      print('❌ Failed to add training sample');
    }
  }
}


/// Training session for voice profiles
class VoiceTrainingSession {
  final String name;
  final String relationship;
  final String emoji;
  final int requiredSamples;
  final PyannoteApiService _apiService;
  final Function(VoiceProfile) _onComplete;

  int _samplesCollected = 0;
  final List<double> _pitchSamples = [];
  final List<double> _energySamples = [];
  bool _isComplete = false;

  VoiceTrainingSession({
    required this.name,
    required this.relationship,
    required this.emoji,
    required this.requiredSamples,
    required PyannoteApiService apiService,
    required Function(VoiceProfile) onComplete,
  })  : _apiService = apiService,
        _onComplete = onComplete;

  /// Number of samples collected
  int get samplesCollected => _samplesCollected;

  /// Number of samples remaining
  int get samplesRemaining => requiredSamples - samplesCollected;

  /// Whether training is complete
  bool get isComplete => _isComplete;

  /// Progress percentage
  int get progressPercent => ((samplesCollected / requiredSamples) * 100).round();

  /// Phrases to read during training
  static List<String> get trainingPhrases => [
    "Hello, my name is speaking now",
    "The quick brown fox jumps over the lazy dog",
    "I am recording my voice for Dhwani",
    "This app will help identify who is speaking",
    "Thank you for using this accessibility app",
    "Voice recognition makes communication easier",
    "I want to help people who cannot hear",
  ];

  /// Get current phrase to read
  String get currentPhrase {
    if (samplesCollected < trainingPhrases.length) {
      return trainingPhrases[samplesCollected];
    }
    return "Please continue speaking naturally";
  }

  /// Add a training sample
  Future<bool> addSample(Uint8List audioData) async {
    if (_isComplete) return false;

    // Check audio has sufficient energy (not silence)
    if (!_hasVoiceActivity(audioData)) {
      print('⚠️ Sample rejected: no voice detected');
      return false;
    }

    // Send to Pyannote API for enrollment
    final result = await _apiService.enrollSpeaker(name, audioData);
    
    if (result == null) {
      print('❌ Failed to enroll sample');
      return false;
    }

    _samplesCollected++;
    
    // Extract voice characteristics for local storage
    final features = _extractFeatures(audioData);
    _pitchSamples.add(features['pitch'] ?? 0);
    _energySamples.add(features['energy'] ?? 0);
    
    print('✅ Voice sample $_samplesCollected/$requiredSamples enrolled on server');

    if (samplesCollected >= requiredSamples) {
      await _finishTraining();
    }

    return true;
  }

  /// Check if audio contains voice activity
  bool _hasVoiceActivity(Uint8List audioData) {
    double energy = 0;
    for (int i = 0; i < audioData.length - 1; i += 2) {
      int sample = audioData[i] | (audioData[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      energy += (sample / 32768.0) * (sample / 32768.0);
    }
    energy = energy / (audioData.length / 2);
    return energy > 0.001; // Threshold for voice activity
  }

  /// Extract voice features
  Map<String, double> _extractFeatures(Uint8List audioData) {
    final samples = <double>[];
    for (int i = 0; i < audioData.length - 1; i += 2) {
      int sample = audioData[i] | (audioData[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      samples.add(sample / 32768.0);
    }

    // Calculate energy
    double energy = 0;
    for (final s in samples) {
      energy += s * s;
    }
    energy = energy / samples.length;

    // Estimate pitch via zero crossings
    int crossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i] >= 0) != (samples[i - 1] >= 0)) {
        crossings++;
      }
    }
    double pitch = crossings / (2 * samples.length / 16000.0);

    return {
      'pitch': pitch,
      'energy': energy,
    };
  }

  /// Finish training and save profile
  Future<void> _finishTraining() async {
    if (_isComplete) return;
    _isComplete = true;

    // Calculate average pitch and energy
    double avgPitch = 0;
    double avgEnergy = 0;
    if (_pitchSamples.isNotEmpty) {
      avgPitch = _pitchSamples.reduce((a, b) => a + b) / _pitchSamples.length;
      avgEnergy = _energySamples.reduce((a, b) => a + b) / _energySamples.length;
    }

    final profile = VoiceProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship,
      emoji: emoji,
      voiceEmbeddings: [], // Embeddings stored on server
      createdAt: DateTime.now(),
      sampleCount: _samplesCollected,
      averagePitch: avgPitch,
      averageEnergy: avgEnergy,
    );

    await _onComplete(profile);
    print('✅ Voice training complete for: $name');
  }

  /// Cancel training
  void cancel() {
    _samplesCollected = 0;
    _pitchSamples.clear();
    _energySamples.clear();
    _isComplete = true;
  }
}


/// Result of speaker identification
class SpeakerIdentificationResult {
  final VoiceProfile? speaker;
  final double confidence;
  final bool isUnknown;

  SpeakerIdentificationResult({
    required this.speaker,
    required this.confidence,
    required this.isUnknown,
  });

  @override
  String toString() {
    if (isUnknown) {
      return 'Unknown speaker (confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
    }
    return '${speaker?.name} (confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}


/// Relationship types and their emojis
class Relationship {
  static const String mother = 'Mother';
  static const String father = 'Father';
  static const String sibling = 'Sibling';
  static const String grandparent = 'Grandparent';
  static const String friend = 'Friend';
  static const String caregiver = 'Caregiver';
  static const String other = 'Other';

  static String getEmoji(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'mother':
        return '👩';
      case 'father':
        return '👨';
      case 'sibling':
        return '👶';
      case 'grandparent':
        return '👴';
      case 'friend':
        return '👋';
      case 'caregiver':
        return '🩺';
      default:
        return '👤';
    }
  }

  static List<String> get all => [
    mother,
    father,
    sibling,
    grandparent,
    friend,
    caregiver,
    other,
  ];
}