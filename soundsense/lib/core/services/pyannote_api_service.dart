import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class PyannoteApiService {
  static const String baseUrl =
      'https://parvathygss-dhwani-speaker-recognition.hf.space';

  // Singleton
  static PyannoteApiService? _instance;
  static PyannoteApiService get instance {
    _instance ??= PyannoteApiService._();
    return _instance!;
  }

  PyannoteApiService._();

  /// Check if server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Enroll a speaker with audio data
  Future<Map<String, dynamic>?> enrollSpeaker(
    String name,
    Uint8List audioData,
  ) async {
    try {
      // Require minimum ~1s audio (16kHz PCM)
      if (audioData.length < 32000) {
        print('⚠️ Enrollment audio too short');
        return null;
      }

      print('🎙️ Enroll audio bytes: ${audioData.length}');

      final tempFile = await _saveAudioToTempFile(audioData);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/enroll?name=${Uri.encodeComponent(name)}'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', tempFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Delay deletion to avoid multipart race condition
      Future.delayed(const Duration(seconds: 1), () {
        if (tempFile.existsSync()) tempFile.delete();
      });

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        print('❌ Enrollment failed: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Enrollment error: $e');
      return null;
    }
  }

  /// Recognize speaker from audio data
  Future<Map<String, dynamic>?> recognizeSpeaker(
    Uint8List audioData,
  ) async {
    try {
      // Require minimum ~1s audio (16kHz PCM)
      if (audioData.length < 32000) {
        print('⚠️ Recognition audio too short');
        return null;
      }

      print('🎙️ Recognition audio bytes: ${audioData.length}');

      final tempFile = await _saveAudioToTempFile(audioData);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recognize'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', tempFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Delay deletion to avoid multipart race condition
      Future.delayed(const Duration(seconds: 1), () {
        if (tempFile.existsSync()) tempFile.delete();
      });

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        print('❌ Recognition failed: ${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Recognition error: $e');
      return null;
    }
  }

  /// Save audio bytes to temporary WAV file
  Future<File> _saveAudioToTempFile(Uint8List audioData) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    // Assumes input is PCM16 mono @ 16kHz
    final wavData = _createWavFile(audioData);
    await tempFile.writeAsBytes(wavData, flush: true);

    return tempFile;
  }

  /// Create proper WAV file with header
  Uint8List _createWavFile(Uint8List audioData) {
    const int sampleRate = 16000;
    const int numChannels = 1;
    const int bitsPerSample = 16;

    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = audioData.length;
    final int fileSize = 36 + dataSize;

    final header = BytesBuilder();

    // RIFF header
    header.add('RIFF'.codeUnits);
    header.add(_int32ToBytes(fileSize));
    header.add('WAVE'.codeUnits);

    // fmt chunk
    header.add('fmt '.codeUnits);
    header.add(_int32ToBytes(16)); // PCM
    header.add(_int16ToBytes(1));
    header.add(_int16ToBytes(numChannels));
    header.add(_int32ToBytes(sampleRate));
    header.add(_int32ToBytes(byteRate));
    header.add(_int16ToBytes(blockAlign));
    header.add(_int16ToBytes(bitsPerSample));

    // data chunk
    header.add('data'.codeUnits);
    header.add(_int32ToBytes(dataSize));
    header.add(audioData);

    return header.toBytes();
  }

  Uint8List _int16ToBytes(int value) {
    return Uint8List.fromList([
      value & 0xFF,
      (value >> 8) & 0xFF,
    ]);
  }

  Uint8List _int32ToBytes(int value) {
    return Uint8List.fromList([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }
}
