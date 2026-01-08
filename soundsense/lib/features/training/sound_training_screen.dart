import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import '../../core/models/custom_sound_model.dart';
import '../../core/services/custom_sound_service.dart';
import 'package:path_provider/path_provider.dart';

class SoundTrainingScreen extends StatefulWidget {
  const SoundTrainingScreen({super.key});

  @override
  State<SoundTrainingScreen> createState() => _SoundTrainingScreenState();
}

class _SoundTrainingScreenState extends State<SoundTrainingScreen> {
  final CustomSoundService _soundService = CustomSoundService.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // State - EXACTLY THE SAME
  bool _isInitialized = false;
  bool _isRecording = false;
  TrainingSession? _currentSession;
  
  // Form - EXACTLY THE SAME
  final _nameController = TextEditingController();
  String _selectedCategory = SoundCategory.home;
  
  // Recording - EXACTLY THE SAME
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  static const int _maxRecordingSeconds = 5;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _soundService.initialize();
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  int get _currentStep {
    if (_currentSession == null) return 1;
    return _currentSession!.samplesCollected + 1;
  }

  int get _totalSteps {
    return _currentSession?.requiredSamples ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isInitialized
            ? (_currentSession == null ? _buildSetupView() : _buildTrainingView())
            : const Center(child: CircularProgressIndicator(color: Color(0xFF4A9FFF))),
      ),
    );
  }

  // ============================================================
  // Setup View - NEW UI, SAME LOGIC
  // ============================================================

  Widget _buildSetupView() {
    return Column(
      children: [
        _buildModernHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teach Dhwani',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.bold, height: 1.2),
                ),
                Text(
                  'a new sound',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 32),
                _buildSoundIdentityCard(),
                const SizedBox(height: 24),
                _buildCategorySelection(),
                const SizedBox(height: 32),
                _buildExistingSounds(),
                const SizedBox(height: 32),
                _buildStartButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 24),
            ),
          ),
          Text('New Sound', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, shape: BoxShape.circle),
            child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SOUND IDENTITY', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFF4A9FFF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'e.g. Microwave Beep',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SoundCategory.all.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4A9FFF) : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(SoundCategory.getIcon(category)),
                    const SizedBox(width: 6),
                    Text(category, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExistingSounds() {
    final sounds = _soundService.customSounds;
    if (sounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Custom Sounds', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${sounds.length} sounds', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 12),
        ...sounds.map((sound) => _buildSoundTile(sound)),
      ],
    );
  }

  Widget _buildSoundTile(CustomSound sound) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(sound.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sound.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
                Text('${sound.category} • ${sound.sampleCount} samples', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(sound.isActive ? Icons.check_circle : Icons.cancel, color: sound.isActive ? Colors.greenAccent : Colors.grey),
            onPressed: () => _toggleSound(sound),
          ),
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteSound(sound)),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final canStart = _nameController.text.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canStart ? _startTraining : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9FFF),
          disabledBackgroundColor: const Color(0xFF2A3F54),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Start Training', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ============================================================
  // Training View - NEW UI, SAME LOGIC
  // ============================================================

  Widget _buildTrainingView() {
    return Column(
      children: [
        _buildModernHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teach Dhwani', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.bold, height: 1.2)),
                Text('a new sound', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 40, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 32),
                _buildSoundIdentityCard(),
                const SizedBox(height: 32),
                _buildStepIndicator(),
                const SizedBox(height: 24),
                _buildRecordSampleSection(),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: _cancelTraining,
                    child: const Text('Cancel Training', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF4A9FFF), borderRadius: BorderRadius.circular(20)),
          child: Text('Step $_currentStep of $_totalSteps', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildRecordSampleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Sample', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Capture clear audio of the sound.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
              ],
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, shape: BoxShape.circle),
              child: const Icon(Icons.mic, color: Color(0xFF4A9FFF), size: 28),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 200,
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
          child: Center(child: _isRecording ? _buildWaveformAnimation() : Text('Ready to record', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 16))),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isRecording ? null : _recordSample,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isRecording ? const Color(0xFF2A3F54) : const Color(0xFF4A9FFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isRecording ? Icons.stop_circle : Icons.fiber_manual_record, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(_isRecording ? 'Recording...' : 'Record', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A3F54))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: Theme.of(context).colorScheme.onSurface, size: 24),
                    SizedBox(width: 12),
                    Text('Upload', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformAnimation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(9, (index) {
            final heights = [40.0, 60.0, 80.0, 100.0, 60.0, 100.0, 80.0, 60.0, 40.0];
            return _buildAnimatedBar(heights[index], index * 50);
          }),
        ),
        const SizedBox(height: 16),
        Text('LISTENING', style: TextStyle(color: const Color(0xFF4A9FFF).withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2))
            .animate(onPlay: (c) => c.repeat()).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms),
      ],
    );
  }

  Widget _buildAnimatedBar(double maxHeight, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 20.0, end: maxHeight),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: value,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: const Color(0xFF4A9FFF), borderRadius: BorderRadius.circular(3)),
        );
      },
      onEnd: () => setState(() {}),
    );
  }



  // ============================================================
  // Actions - EXACTLY THE SAME AS YOUR ORIGINAL
  // ============================================================

  void _startTraining() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _currentSession = _soundService.startTraining(
        name: name,
        category: _selectedCategory,
      );
    });
  }

  Future<void> _recordSample() async {
    if (_isRecording || _currentSession == null) return;

    if (!await _audioRecorder.hasPermission()) {
      _showSnackbar('Microphone permission denied', isError: true);
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/sound_$timestamp.wav';
      
      print('🎤 Recording to: $filePath');

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingSeconds++);
        
        if (_recordingSeconds >= _maxRecordingSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('❌ Recording error: $e');
      setState(() => _isRecording = false);
      _showSnackbar('Failed to start recording: $e', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (path == null) {
      _showSnackbar('Recording failed', isError: true);
      return;
    }

    try {
      final file = File(path);
      var audioData = await file.readAsBytes();
      
      print('📁 Raw file size: ${audioData.length} bytes');
      
      if (audioData.length > 44) {
        if (audioData[0] == 0x52 && audioData[1] == 0x49 && 
            audioData[2] == 0x46 && audioData[3] == 0x46) {
          audioData = audioData.sublist(44);
          print('📁 Stripped WAV header, PCM size: ${audioData.length} bytes');
        }
      }
      
      if (audioData.length > 31200) {
        final start = (audioData.length - 31200) ~/ 2;
        audioData = audioData.sublist(start, start + 31200);
        print('📁 Trimmed to ${audioData.length} bytes');
      }
      
      final success = await _currentSession!.addSample(audioData);
      
      if (success) {
        _showSnackbar('Sample ${_currentSession!.samplesCollected} recorded! ✓');
        
        if (_currentSession!.isComplete) {
          _showSnackbar('Training complete! 🎉');
          setState(() {
            _currentSession = null;
            _nameController.clear();
          });
        }
      } else {
        _showSnackbar('Sample rejected - try again', isError: true);
      }
    } catch (e) {
      print('❌ Error reading audio: $e');
      _showSnackbar('Error: $e', isError: true);
    }
  }

  void _cancelTraining() {
    _currentSession?.cancel();
    setState(() => _currentSession = null);
  }

  Future<void> _toggleSound(CustomSound sound) async {
    final updated = sound.copyWith(isActive: !sound.isActive);
    await _soundService.updateCustomSound(updated);
    setState(() {});
  }

  Future<void> _deleteSound(CustomSound sound) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Delete Sound?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'Delete "${sound.name}"? This cannot be undone.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _soundService.deleteCustomSound(sound.id);
      setState(() {});
      _showSnackbar('Sound deleted');
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}