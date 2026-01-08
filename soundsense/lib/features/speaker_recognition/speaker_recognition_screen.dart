import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../core/services/pyannote_api_service.dart';
import 'speaker_enrollment_screen.dart';

class SpeakerRecognitionScreen extends StatefulWidget {
  const SpeakerRecognitionScreen({super.key});

  @override
  State<SpeakerRecognitionScreen> createState() => _SpeakerRecognitionScreenState();
}

class _SpeakerRecognitionScreenState extends State<SpeakerRecognitionScreen> {
  final _apiService = PyannoteApiService.instance;
  final _audioRecorder = AudioRecorder();
  
  bool _isServerHealthy = false;
  bool _isCheckingHealth = true;
  bool _isRecording = false;
  String _currentSpeaker = 'No one speaking';
  double _confidence = 0.0;
  
  @override
  void initState() {
    super.initState();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    setState(() => _isCheckingHealth = true);
    final healthy = await _apiService.checkHealth();
    setState(() {
      _isServerHealthy = healthy;
      _isCheckingHealth = false;
    });
  }

  Future<void> _startRecognition() async {
    if (!_isServerHealthy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server not available')),
      );
      return;
    }

    // Request permission
    if (await _audioRecorder.hasPermission()) {
      setState(() => _isRecording = true);
      
      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}/recognition_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16,
        ),
        path: recordingPath, // ✅ FIXED: Added path parameter
      );
      
      // Record for 4 seconds (same as enrollment)
      await Future.delayed(const Duration(seconds: 4));
      
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        await _recognizeSpeaker(path);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
    }
  }

  Future<void> _recognizeSpeaker(String audioPath) async {
    try {
      // Read audio file
      final file = File(audioPath);
      final audioBytes = await file.readAsBytes();
      
      // Call API
      final result = await _apiService.recognizeSpeaker(audioBytes);
      
      // Clean up temp file
      await file.delete();
      
      // 🔍 DEBUG: Print full result
      print('🔍 Recognition result: $result');
      
      if (result != null) {
        setState(() {
          if (result['identified'] == true) {
            _currentSpeaker = result['name'] ?? 'Unknown';
            _confidence = (result['confidence'] ?? 0.0).toDouble();
            print('✅ Identified: $_currentSpeaker (${(_confidence * 100).toStringAsFixed(1)}%)');
          } else {
            _currentSpeaker = 'Unknown speaker';
            _confidence = (result['confidence'] ?? 0.0).toDouble();
            print('❌ Not identified. Best score: ${(_confidence * 100).toStringAsFixed(1)}% (threshold: 70%)');
          }
        });
        
        // Show a snackbar with the result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['identified'] == true 
                ? '✓ ${result['name']} (${(_confidence * 100).toStringAsFixed(1)}%)'
                : '✗ Unknown (${(_confidence * 100).toStringAsFixed(1)}% < 70%)',
            ),
            backgroundColor: result['identified'] == true ? Colors.green : Colors.orange,
          ),
        );
      } else {
        setState(() {
          _currentSpeaker = 'Recognition failed';
          _confidence = 0.0;
        });
      }
    } catch (e) {
      print('Recognition error: $e');
      setState(() {
        _currentSpeaker = 'Error: $e';
        _confidence = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Speaker Recognition', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _checkServerHealth,
          ),
        ],
      ),
      body: _isCheckingHealth
          ? const Center(child: CircularProgressIndicator())
          : !_isServerHealthy
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Cannot connect to server',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkServerHealth,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9FFF),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording 
                ? Colors.red.withOpacity(0.2) 
                : const Color(0xFF4A9FFF).withOpacity(0.2),
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 64,
              color: _isRecording ? Colors.red : const Color(0xFF4A9FFF),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Current speaker
          Text(
            _currentSpeaker,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Confidence
          if (_confidence > 0)
            Text(
              'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          
          const SizedBox(height: 48),
          
          // Record button
          ElevatedButton.icon(
            onPressed: _isRecording ? null : _startRecognition,
            icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
            label: Text(
              _isRecording ? 'Recording (4s)...' : 'Identify Speaker',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9FFF),
              foregroundColor: Colors.white,  // ✅ Added this
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Add speaker button
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpeakerEnrollmentScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add, color: Color(0xFF4A9FFF)),
            label: const Text(
              'Add Family Member',
              style: TextStyle(color: Color(0xFF4A9FFF)),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How to use:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. First, add family members using "Add Family Member"\n'
                  '2. Then tap "Identify Speaker" to recognize who\'s talking\n'
                  '3. The app will record for 3 seconds',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}