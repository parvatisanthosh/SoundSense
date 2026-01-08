import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/azure_speaker_service.dart';

/// Voice Training Screen for Azure Speaker Recognition
class AzureVoiceTrainingScreen extends StatefulWidget {
  const AzureVoiceTrainingScreen({super.key});

  @override
  State<AzureVoiceTrainingScreen> createState() =>
      _AzureVoiceTrainingScreenState();
}

class _AzureVoiceTrainingScreenState extends State<AzureVoiceTrainingScreen>
    with TickerProviderStateMixin {
  final AzureSpeakerService _speakerService = AzureSpeakerService.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final _nameController = TextEditingController();

  // State
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _currentProfileId;
  String _statusMessage = '';
  double _enrollmentProgress = 0;
  bool _isEnrolled = false;

  // Recording
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  static const int _targetSeconds = 25;
  List<int> _audioBytes = [];

  late AnimationController _pulseController;

  // Relationships
  String _selectedRelationship = 'Friend';
  final List<Map<String, String>> _relationships = [
    {'name': 'Mom', 'emoji': '👩'},
    {'name': 'Dad', 'emoji': '👨'},
    {'name': 'Sister', 'emoji': '👧'},
    {'name': 'Brother', 'emoji': '👦'},
    {'name': 'Spouse', 'emoji': '💑'},
    {'name': 'Child', 'emoji': '👶'},
    {'name': 'Friend', 'emoji': '🧑‍🤝‍🧑'},
    {'name': 'Colleague', 'emoji': '💼'},
    {'name': 'Doctor', 'emoji': '👨‍⚕️'},
    {'name': 'Other', 'emoji': '👤'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1419),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Voice Profiles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_currentProfileId == null) ...[
              _buildNameInput(),
              const SizedBox(height: 20),
              _buildRelationshipSelector(),
              const SizedBox(height: 24),
              _buildCreateProfileButton(),
            ] else
              _buildRecordingSection(),
            const SizedBox(height: 32),
            _buildExistingProfiles(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A9FFF).withOpacity(0.2),
            const Color(0xFF9C27B0).withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4A9FFF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9FFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.record_voice_over_rounded,
                color: Color(0xFF4A9FFF), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Azure Voice Recognition',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF2ED573), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Microsoft AI • 95%+ Accuracy',
                      style: TextStyle(
                        color: const Color(0xFF2ED573),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Person\'s Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g., Mom, Dad, John',
            hintStyle: const TextStyle(color: Color(0xFF9DABB9)),
            prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF9DABB9)),
            filled: true,
            fillColor: const Color(0xFF1A2632),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildRelationshipSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Relationship',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _relationships.map((rel) {
            final isSelected = _selectedRelationship == rel['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedRelationship = rel['name']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4A9FFF)
                      : const Color(0xFF1A2632),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4A9FFF)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rel['emoji']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      rel['name']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF9DABB9),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCreateProfileButton() {
    final canCreate = _nameController.text.trim().isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canCreate && !_isProcessing ? _createProfile : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9FFF),
              disabledBackgroundColor: const Color(0xFF2A3F54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Create Voice Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (_statusMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusMessage.contains('Error')
                  ? const Color(0xFFFF4757).withOpacity(0.1)
                  : const Color(0xFF2ED573).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _statusMessage.contains('Error')
                    ? const Color(0xFFFF4757).withOpacity(0.3)
                    : const Color(0xFF2ED573).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusMessage.contains('Error')
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  color: _statusMessage.contains('Error')
                      ? const Color(0xFFFF4757)
                      : const Color(0xFF2ED573),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Error')
                          ? const Color(0xFFFF4757)
                          : const Color(0xFF2ED573),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(
                _relationships.firstWhere(
                    (r) => r['name'] == _selectedRelationship)['emoji']!,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Training',
                      style: TextStyle(color: Color(0xFF9DABB9), fontSize: 14),
                    ),
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEnrolled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF2ED573), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Enrolled',
                        style: TextStyle(
                          color: Color(0xFF2ED573),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '${(_enrollmentProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: _isEnrolled
                          ? const Color(0xFF2ED573)
                          : const Color(0xFF4A9FFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _enrollmentProgress,
                  backgroundColor: const Color(0xFF2A3F54),
                  valueColor: AlwaysStoppedAnimation(
                    _isEnrolled
                        ? const Color(0xFF2ED573)
                        : const Color(0xFF4A9FFF),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          if (_isRecording) ...[
            const SizedBox(height: 24),
            Text(
              '$_recordingSeconds',
              style: const TextStyle(
                color: Color(0xFFFF4757),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'seconds recorded of $_targetSeconds',
              style: const TextStyle(color: Color(0xFF9DABB9), fontSize: 14),
            ),
          ],

          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A9FFF).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFF4A9FFF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEnrolled
                        ? 'Voice profile saved! This person can now be identified during live captions.'
                        : 'Ask ${_nameController.text} to speak naturally for $_targetSeconds seconds in a quiet environment.',
                    style: const TextStyle(
                      color: Color(0xFF4A9FFF),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Record Button
          if (!_isEnrolled)
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _isRecording
                      ? 1.0 + (_pulseController.value * 0.08)
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isRecording
                              ? [const Color(0xFFFF4757), const Color(0xFFFF6B81)]
                              : [const Color(0xFF4A9FFF), const Color(0xFF6FB1FC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? const Color(0xFFFF4757)
                                    : const Color(0xFF4A9FFF))
                                .withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_isEnrolled) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentProfileId = null;
                    _isEnrolled = false;
                    _enrollmentProgress = 0;
                    _nameController.clear();
                    _statusMessage = '';
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Another Person'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          if (!_isEnrolled) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancelTraining,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFFF4757), fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildExistingProfiles() {
    final profiles = _speakerService.profiles;
    if (profiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved Profiles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...profiles.asMap().entries.map((entry) {
          final index = entry.key;
          final profile = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2632),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9FFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(profile.emoji ?? '👤',
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.personName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: profile.isEnrolled
                                  ? const Color(0xFF2ED573)
                                  : const Color(0xFFFFA502),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.isEnrolled ? 'Ready' : 'Pending',
                            style: TextStyle(
                              color: profile.isEnrolled
                                  ? const Color(0xFF2ED573)
                                  : const Color(0xFFFFA502),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteProfile(profile.profileId),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFFF4757),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: index * 100))
              .fadeIn()
              .slideX(begin: 0.1);
        }),
      ],
    );
  }

  // ============================================================
  // Actions
  // ============================================================

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating profile...';
    });

    final profileId = await _speakerService.createVoiceProfile(name);

    setState(() {
      _isProcessing = false;
      if (profileId != null) {
        _currentProfileId = profileId;
        _statusMessage = 'Profile created! Now record voice.';
      } else {
        _statusMessage = 'Error: Failed to create profile. Check API key.';
      }
    });
  }

  Future<void> _startRecording() async {
    print('🎤 _startRecording called');
    
    if (_isRecording || _currentProfileId == null) {
      print('❌ Cannot start: isRecording=$_isRecording, profileId=$_currentProfileId');
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      _showSnackbar('Microphone permission denied');
      return;
    }

    try {
      print('🎤 Starting stream recording...');

      // Use stream instead of file - collect audio data in memory
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      
      print('✅ Stream started!');

      // Collect audio data
      _audioBytes = [];
      
      stream.listen((data) {
        _audioBytes.addAll(data);
      });

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        setState(() {
          _recordingSeconds++;
          _enrollmentProgress = _recordingSeconds / _targetSeconds;
        });

        if (_recordingSeconds >= _targetSeconds) {
          timer.cancel();
          await _stopRecording();
        }
      });
    } catch (e) {
      print('❌ Recording error: $e');
      setState(() => _isRecording = false);
      _showSnackbar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    print('🎤 Stopping stream recording...');
    
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    
    setState(() => _isRecording = false);

    if (_currentProfileId == null) {
      print('❌ No profile ID');
      _showSnackbar('Recording failed');
      return;
    }

    print('📁 Collected ${_audioBytes.length} bytes of audio');

    setState(() {
      _statusMessage = 'Enrolling voice with Azure...';
      _isProcessing = true;
    });

    try {
      final audioData = Uint8List.fromList(_audioBytes);
      print('📁 Audio size: ${audioData.length} bytes');

      final result = await _speakerService.enrollVoiceProfile(
        _currentProfileId!,
        audioData,
      );

      setState(() {
        _isProcessing = false;
        if (result.isEnrolled) {
          _isEnrolled = true;
          _enrollmentProgress = 1.0;
          _statusMessage = '✅ Voice enrolled successfully!';
          _showSnackbar('Voice profile saved! 🎉');
        } else if (result.success) {
          _statusMessage = 'Need ${result.remainingSeconds.round()}s more audio';
          _showSnackbar('Record more audio');
        } else {
          _statusMessage = 'Error: ${result.message}';
        }
      });
    } catch (e) {
      print('❌ Error processing recording: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _cancelTraining() async {
    if (_currentProfileId != null) {
      await _speakerService.deleteVoiceProfile(_currentProfileId!);
    }
    setState(() {
      _currentProfileId = null;
      _isEnrolled = false;
      _enrollmentProgress = 0;
      _statusMessage = '';
    });
  }

  Future<void> _deleteProfile(String profileId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2632),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Profile?',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(color: Color(0xFF9DABB9), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9DABB9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF4757)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _speakerService.deleteVoiceProfile(profileId);
      setState(() {});
      _showSnackbar('Profile deleted');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A2632),
      ),
    );
  }
}