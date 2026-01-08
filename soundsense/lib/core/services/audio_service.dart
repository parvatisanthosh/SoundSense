import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Fixed Audio Service with 16kHz sample rate for Azure/Pyannote compatibility
class AudioService {
  bool _isListening = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<List<int>>? _audioSubscription;
  
  // Callbacks
  Function(double decibel)? onNoiseLevel;
  Function(List<double> audioData)? onAudioData;
  
  bool get isListening => _isListening;

  // Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Check if permission granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start listening with 16kHz sample rate
  Future<void> startListening() async {
    if (_isListening) {
      print('⚠️ Already listening');
      return;
    }

    bool hasAccess = await requestPermission();
    if (!hasAccess) {
      throw Exception('Microphone permission denied');
    }

    try {
      print('🎤 Starting audio recording at 16kHz...');
      
      // Start audio stream with 16kHz (critical for Azure/Pyannote!)
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,  // ✅ 16kHz - REQUIRED for Azure and Pyannote!
          numChannels: 1,     // Mono
          bitRate: 128000,
        ),
      );

      print('✅ Audio recording started at 16kHz');

      // Listen to audio stream
      _audioSubscription = stream.listen(
        (List<int> rawBytes) {
          // Convert bytes to doubles (-1.0 to 1.0 range)
          final audioData = _convertBytesToDoubles(rawBytes);
          
          // Calculate noise level (decibels) for visualization
          if (onNoiseLevel != null) {
            final decibel = _calculateDecibel(audioData);
            onNoiseLevel!(decibel);
          }
          
          // Send audio data for processing
          if (onAudioData != null) {
            onAudioData!(audioData);
          }
        },
        onError: (error) {
          print('❌ Audio streamer error: $error');
        },
      );

      _isListening = true;
    } catch (e) {
      print('❌ Failed to start audio: $e');
      _isListening = false;
      rethrow;
    }
  }

  /// Stop listening
  void stopListening() {
    print('🛑 Stopping audio recording...');
    
    _audioSubscription?.cancel();
    _audioSubscription = null;
    
    _audioRecorder.stop();
    
    _isListening = false;
    print('✅ Audio recording stopped');
  }

  /// Convert raw bytes to double samples (-1.0 to 1.0)
  List<double> _convertBytesToDoubles(List<int> bytes) {
    final samples = <double>[];
    
    // PCM16 = 2 bytes per sample (little-endian)
    for (int i = 0; i < bytes.length - 1; i += 2) {
      // Combine two bytes into 16-bit signed integer
      int sample = bytes[i] | (bytes[i + 1] << 8);
      
      // Convert to signed
      if (sample > 32767) {
        sample -= 65536;
      }
      
      // Normalize to -1.0 to 1.0
      samples.add(sample / 32768.0);
    }
    
    return samples;
  }

  /// Calculate decibel level from audio samples
  double _calculateDecibel(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    // Calculate RMS (Root Mean Square)
    double sumSquares = 0.0;
    for (var sample in samples) {
      sumSquares += sample * sample;
    }
    double rms = sumSquares / samples.length;
    
    // Convert to decibels (reference: 0 dB = max amplitude)
    if (rms < 0.0001) return 0.0; // Silence
    
    double decibel = 20 * (rms / 0.5).abs().clamp(0.0, 1.0) * 100;
    return decibel.clamp(0.0, 100.0);
  }

  /// Dispose
  void dispose() {
    stopListening();
    _audioRecorder.dispose();
  }
}