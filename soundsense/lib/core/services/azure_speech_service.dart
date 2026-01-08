import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AzureSpeechService {
  final String _apiKey;
  final String _region;
  
  bool _isListening = false;
  String _currentTranscription = '';
  
  final StreamController<String> _transcriptionController = 
      StreamController<String>.broadcast();
  final StreamController<String> _partialController = 
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();
  
  List<int> _audioBuffer = [];
  Timer? _processTimer;
  int _transcriptionAttempts = 0;
  int _savedFileCount = 0;
  
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<String> get partialStream => _partialController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  bool get isListening => _isListening;
  String get currentTranscription => _currentTranscription;
  
  AzureSpeechService({
    required String apiKey,
    String region = 'eastus',
  })  : _apiKey = apiKey,
        _region = region {
    debugPrint('🔧 AzureSpeechService created');
    HttpOverrides.global = _DevHttpOverrides();
  }
  
  Future<bool> startTranscription({String language = 'en-US'}) async {
    if (_isListening) return true;
    
    debugPrint('🎤 Starting Azure Speech...');
    _isListening = true;
    _audioBuffer = [];
    _currentTranscription = '';
    _transcriptionAttempts = 0;
    _savedFileCount = 0;
    _connectionController.add(true);
    
    _processTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _processAudioBuffer(language);
    });
    
    return true;
  }
  
  Future<void> stopTranscription() async {
    debugPrint('🛑 Stopping Azure Speech...');
    _isListening = false;
    _processTimer?.cancel();
    _processTimer = null;
    
    if (_audioBuffer.isNotEmpty) {
      await _processAudioBuffer('en-US');
    }
    
    _audioBuffer = [];
    _connectionController.add(false);
  }
  
  void sendAudioData(Uint8List audioData) {
    if (!_isListening) return;
    _audioBuffer.addAll(audioData);
  }
  
  Future<void> _processAudioBuffer(String language) async {
    _transcriptionAttempts++;
    
    if (_audioBuffer.isEmpty || _audioBuffer.length < 32000) {
      return;
    }
    
    final maxBytes = 160000; // ~5 seconds
    final bytesToProcess = _audioBuffer.length > maxBytes ? maxBytes : _audioBuffer.length;
    
    debugPrint('🔍 Processing $bytesToProcess bytes...');
    
    final audioData = Uint8List.fromList(_audioBuffer.sublist(0, bytesToProcess));
    _audioBuffer.removeRange(0, bytesToProcess);
    
    // ✅ SAVE AUDIO FILE FOR DEBUGGING
    await _saveAudioFile(audioData);
    
    final avgPower = _calculateAudioPower(audioData);
    debugPrint('🔊 Audio power: ${avgPower.toStringAsFixed(2)}');
    
    final result = await _transcribeAudio(audioData, language);
    
    if (result != null && result.isNotEmpty) {
      debugPrint('✅ Transcribed: "$result"');
      _partialController.add(result);
      await Future.delayed(const Duration(milliseconds: 300));
      _currentTranscription = result;
      _transcriptionController.add(_currentTranscription);
    } else {
      debugPrint('❌ No transcription');
    }
  }
  
  /// ✅ NEW: Save audio file for debugging
  Future<void> _saveAudioFile(Uint8List audioData) async {
    try {
      _savedFileCount++;
      final dir = await getTemporaryDirectory();
      final wavFile = _createWavFile(audioData);
      final file = File('${dir.path}/debug_audio_$_savedFileCount.wav');
      await file.writeAsBytes(wavFile);
      debugPrint('💾 Saved audio to: ${file.path}');
      debugPrint('💾 File size: ${wavFile.length} bytes');
      
      // Analyze the audio
      _analyzeAudio(audioData);
    } catch (e) {
      debugPrint('❌ Failed to save audio: $e');
    }
  }
  
  /// ✅ NEW: Analyze audio data
  void _analyzeAudio(Uint8List audioData) {
    int silentSamples = 0;
    int totalSamples = 0;
    double maxAmplitude = 0;
    
    for (int i = 0; i < audioData.length - 1; i += 2) {
      int sample = audioData[i] | (audioData[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      
      final amplitude = sample.abs();
      if (amplitude > maxAmplitude) maxAmplitude = amplitude.toDouble();
      if (amplitude < 100) silentSamples++;
      totalSamples++;
    }
    
    final silencePercent = (silentSamples / totalSamples) * 100;
    debugPrint('📊 Max amplitude: ${maxAmplitude.toInt()} / 32768');
    debugPrint('📊 Silence: ${silencePercent.toStringAsFixed(1)}%');
    
    if (maxAmplitude < 1000) {
      debugPrint('⚠️ WARNING: Audio very quiet (max ${maxAmplitude.toInt()})');
    }
    if (silencePercent > 80) {
      debugPrint('⚠️ WARNING: Mostly silence (${silencePercent.toStringAsFixed(1)}%)');
    }
  }
  
  double _calculateAudioPower(Uint8List audioData) {
    double sum = 0;
    for (int i = 0; i < audioData.length - 1; i += 2) {
      int sample = audioData[i] | (audioData[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      sum += sample.abs();
    }
    return sum / (audioData.length / 2);
  }
  
  Future<String?> _transcribeAudio(Uint8List audioData, String language) async {
    final url = 'https://$_region.stt.speech.microsoft.com/'
        'speech/recognition/conversation/cognitiveservices/v1'
        '?language=$language'
        '&format=detailed';
    
    try {
      final wavData = _createWavFile(audioData);
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Ocp-Apim-Subscription-Key': _apiKey,
          'Content-Type': 'audio/wav; codec=audio/pcm; samplerate=16000',
          'Accept': 'application/json',
        },
        body: wavData,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['RecognitionStatus'];
        
        debugPrint('🌐 Status: $status');
        
        if (status == 'Success') {
          final displayText = data['DisplayText'];
          final nBest = data['NBest'];
          
          if (displayText != null && displayText.isNotEmpty) {
            return displayText;
          }
          
          if (nBest != null && nBest is List && nBest.isNotEmpty) {
            final firstResult = nBest[0];
            final display = firstResult['Display'];
            final confidence = firstResult['Confidence'];
            
            debugPrint('🔍 NBest confidence: $confidence');
            
            if (display != null && display.isNotEmpty) {
              return display;
            }
          }
          
          debugPrint('⚠️ Success but empty (Azure heard no speech)');
          return null;
        } else if (status == 'InitialSilenceTimeout') {
          debugPrint('⏸️ Silence timeout');
          return null;
        } else if (status == 'BabbleTimeout') {
          debugPrint('⏸️ Babble timeout (noise)');
          return null;
        }
      } else {
        debugPrint('❌ HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
    
    return null;
  }
  
  Uint8List _createWavFile(Uint8List pcmData) {
    final int sampleRate = 16000;
    final int numChannels = 1;
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;
    
    final header = ByteData(44);
    
    // RIFF chunk
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    
    // fmt chunk
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    
    // data chunk
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);
    
    final wavFile = Uint8List(44 + pcmData.length);
    wavFile.setAll(0, header.buffer.asUint8List());
    wavFile.setAll(44, pcmData);
    
    return wavFile;
  }
  
  void clearTranscription() {
    _currentTranscription = '';
    _transcriptionController.add('');
  }
  
  void dispose() {
    stopTranscription();
    _transcriptionController.close();
    _partialController.close();
    _connectionController.close();
    _errorController.close();
  }
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}