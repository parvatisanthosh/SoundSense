import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/services/pyannote_api_service.dart';

class SpeakerEnrollmentScreen extends StatefulWidget {
  const SpeakerEnrollmentScreen({super.key});

  @override
  State<SpeakerEnrollmentScreen> createState() => _SpeakerEnrollmentScreenState();
}

class _SpeakerEnrollmentScreenState extends State<SpeakerEnrollmentScreen> {
  final _apiService = PyannoteApiService.instance;
  final _audioRecorder = AudioRecorder();
  final _nameController = TextEditingController();
  
  final int _requiredSamples = 3;
  int _samplesCollected = 0;
  bool _isRecording = false;
  bool _isEnrolling = false;
  String? _speakerName;
  
  List<String> _trainingPhrases = [
    "Hello, this is me speaking",
    "The quick brown fox jumps over the lazy dog",
    "I am recording my voice for speaker recognition",
  ];

  Future<void> _startEnrollment() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() {
      _speakerName = name;
      _samplesCollected = 0;
      _isEnrolling = true;
    });
  }

  Future<void> _recordSample() async {
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    setState(() => _isRecording = true);

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}/enrollment_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16,
        ),
        path: recordingPath,
      );
      
      // Record for 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        await _enrollSample(path);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showError('Recording error: $e');
    }
  }

  Future<void> _enrollSample(String audioPath) async {
    try {
      // Read audio file
      final file = File(audioPath);
      final audioBytes = await file.readAsBytes();
      
      // Enroll with API
      final result = await _apiService.enrollSpeaker(_speakerName!, audioBytes);
      
      // Clean up temp file
      await file.delete();
      
      if (result != null && result['success'] == true) {
        setState(() {
          _samplesCollected++;
        });
        
        if (_samplesCollected >= _requiredSamples) {
          _showSuccess('✓ $_speakerName enrolled successfully!');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        _showError('Failed to enroll sample');
      }
    } catch (e) {
      _showError('Enrollment error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2632),
        title: const Text('Add Family Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isEnrolling ? _buildEnrollmentView() : _buildNameInputView(),
      ),
    );
  }

  Widget _buildNameInputView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.person_add,
          size: 80,
          color: Color(0xFF4A9FFF),
        ),
        const SizedBox(height: 32),
        const Text(
          'Add Family Member',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter the name of the person you want to add',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        // Name input
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintText: 'e.g., Mom, Dad, Rahul',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1A2632),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF4A9FFF)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 32),
        
        // Start button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startEnrollment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Training',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentView() {
    final progress = _samplesCollected / _requiredSamples;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress indicator
        Text(
          'Training: $_speakerName',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        
        // Progress circle
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A9FFF)),
              ),
            ),
            Column(
              children: [
                Text(
                  '$_samplesCollected/$_requiredSamples',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'samples',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 48),
        
        // Recording status
        if (_isRecording)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recording...',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2632),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Please read:',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _trainingPhrases[_samplesCollected % _trainingPhrases.length],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 48),
        
        // Record button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRecording ? null : _recordSample,
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(_isRecording ? 'Recording (4s)...' : 'Record Sample'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : const Color(0xFF4A9FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _nameController.dispose();
    super.dispose();
  }
}