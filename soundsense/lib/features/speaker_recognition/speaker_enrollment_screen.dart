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
  
  // ✅ INCREASED: More samples = better accuracy!
  final int _requiredSamples = 6; // Increased from 4 to 6
  int _samplesCollected = 0;
  bool _isRecording = false;
  bool _isEnrolling = false;
  String? _speakerName;
  int _recordingProgress = 0;
  
  // ✅ MORE VARIED PHRASES for better voice coverage
  final List<String> _trainingPhrases = [
    "Hello, my name is [NAME] and this is my voice",
    "The quick brown fox jumps over the lazy dog",
    "I am training the system to recognize my unique voice",
    "Please remember my voice for future recognition",
    "One two three four five, testing my microphone",
    "This is sample number six for voice enrollment",
  ];

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    final healthy = await _apiService.checkHealth();
    if (!healthy && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Server offline. Please check connection.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

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

    setState(() {
      _isRecording = true;
      _recordingProgress = 0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}/enrollment_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16,
        ),
        path: recordingPath,
      );
      
      // ✅ LONGER RECORDING: 10 seconds instead of 8
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _recordingProgress = i);
        }
      }
      
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingProgress = 0;
      });
      
      if (path != null) {
        await _enrollSample(path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingProgress = 0;
      });
      _showError('Recording error: $e');
    }
  }

  Future<void> _enrollSample(String audioPath) async {
    // Show processing indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Processing audio...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final file = File(audioPath);
      final audioBytes = await file.readAsBytes();
      
      // ✅ STRICTER VALIDATION
      print('🎙️ Enrollment sample ${_samplesCollected + 1}: ${audioBytes.length} bytes');
      
      if (audioBytes.length < 200000) { // Increased minimum size
        await file.delete();
        _showError('Recording too short (${audioBytes.length} bytes). Please speak continuously for 10 seconds.');
        return;
      }
      
      // ✅ CHECK AUDIO ENERGY to ensure it's not just silence
      final audioQuality = _checkAudioQuality(audioBytes);
      if (!audioQuality.isGood) {
        await file.delete();
        _showError('Audio quality issue: ${audioQuality.reason}. Please try again.');
        return;
      }
      
      final result = await _apiService.enrollSpeaker(_speakerName!, audioBytes);
      await file.delete();
      
      if (result != null && result['success'] == true) {
        setState(() {
          _samplesCollected++;
        });
        
        if (_samplesCollected >= _requiredSamples) {
          _showSuccess('✓ $_speakerName enrolled with $_requiredSamples samples!');
          
          // Show completion dialog
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _showCompletionDialog();
            }
          });
        } else {
          _showSuccess('✓ Sample ${_samplesCollected}/$_requiredSamples recorded');
        }
      } else {
        _showError('Failed to enroll sample. Server error. Please try again.');
      }
    } catch (e) {
      print('❌ Enrollment error: $e');
      _showError('Enrollment error: $e');
    }
  }

  // ✅ NEW: Check audio quality before sending
  AudioQualityCheck _checkAudioQuality(List<int> audioBytes) {
    // Skip WAV header (44 bytes)
    final pcmData = audioBytes.sublist(44);
    
    // Calculate RMS energy
    double sumSquares = 0;
    int sampleCount = 0;
    
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      int sample = pcmData[i] | (pcmData[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      
      double normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
      sampleCount++;
    }
    
    double rms = sampleCount > 0 ? sumSquares / sampleCount : 0;
    
    print('📊 Audio RMS energy: ${rms.toStringAsExponential(2)}');
    
    // Check if audio is too quiet (likely silence or very low volume)
    if (rms < 0.0001) {
      return AudioQualityCheck(false, 'Audio too quiet. Please speak louder.');
    }
    
    // Check if audio is clipping (too loud)
    if (rms > 0.5) {
      return AudioQualityCheck(false, 'Audio too loud. Move mic further away.');
    }
    
    return AudioQualityCheck(true, 'Good');
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text(
              'Enrollment Complete!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_speakerName has been successfully enrolled with $_requiredSamples voice samples.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A9FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tips for Best Recognition:',
                    style: TextStyle(
                      color: const Color(0xFF4A9FFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Use same device & environment\n'
                    '• Speak at similar volume\n'
                    '• Avoid background noise\n'
                    '• Start with 45% threshold',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close enrollment screen
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF4A9FFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Add Family Member',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isEnrolling ? _buildEnrollmentView() : _buildNameInputView(),
        ),
      ),
    );
  }

  Widget _buildNameInputView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.person_add, size: 80, color: Color(0xFF4A9FFF)),
        const SizedBox(height: 32),
        Text(
          'Add Family Member',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'High-accuracy voice enrollment',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        TextField(
          controller: _nameController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            hintText: 'e.g., Mom, Dad, Rahul',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF4A9FFF)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startEnrollment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Start Training',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // ✅ UPDATED INFO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF4A9FFF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'High-Accuracy Training',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• 6 voice samples (10 seconds each)\n'
                '• Speak clearly and naturally\n'
                '• Read the provided phrases\n'
                '• Quiet environment recommended\n'
                '• Better enrollment = better recognition!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentView() {
    final progress = _samplesCollected / _requiredSamples;
    final currentPhrase = _trainingPhrases[_samplesCollected % _trainingPhrases.length]
        .replaceAll('[NAME]', _speakerName ?? '');
    
    return Column(
      children: [
        const SizedBox(height: 20),
        
        Text(
          'Training: $_speakerName',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 32),
        
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A9FFF)),
              ),
            ),
            Column(
              children: [
                Text(
                  '$_samplesCollected/$_requiredSamples',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'samples',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 40),
        
        if (_isRecording)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Row(
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
                    Text(
                      'Recording... $_recordingProgress/10s',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _recordingProgress / 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  currentPhrase,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4A9FFF).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: const Color(0xFF4A9FFF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Read aloud (10 seconds):',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currentPhrase,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRecording ? null : _recordSample,
            icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
            label: Text(
              _isRecording ? 'Recording...' : 'Record Sample $_samplesCollected/$_requiredSamples',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.grey : const Color(0xFF4A9FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
        
        const SizedBox(height: 20),
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

class AudioQualityCheck {
  final bool isGood;
  final String reason;
  AudioQualityCheck(this.isGood, this.reason);
}