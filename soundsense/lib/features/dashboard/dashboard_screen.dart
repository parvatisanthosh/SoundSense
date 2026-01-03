import 'package:flutter/material.dart';
import '../../shared/widgets/sound_card.dart';
import '../../core/models/detected_sound.dart';
import '../../core/models/sound_category.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/sound_classifier.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/services/settings_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/critical_alerts.dart';
import '../../core/services/animation_service.dart';
import '../../shared/widgets/sound_grid.dart';
import '../training/sound_training_screen.dart';
import '../transcription/enhanced_transcription_screen.dart';
import '../../core/services/custom_sound_service.dart';
import 'dart:typed_data';
import '../training/azure_voice_training_screen.dart';
import '../../core/services/tts_alert_service.dart';
import 'package:lottie/lottie.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final SoundClassifier _classifier = SoundClassifier();
  final SettingsService _settings = SettingsService();
  
  bool _isListening = false;
  bool _isModelLoaded = false;
  double _currentDecibel = 0;
  List<DetectedSound> _detectedSounds = [];
  List<double> _audioBuffer = [];
  DetectedSound? _currentSound;
  bool _showCriticalAlert = false;

  // Animation controllers for floating effect
  late List<AnimationController> _floatControllers;
  late List<Animation<double>> _floatAnimations;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
    _setupAudioCallbacks();
    _checkCustomSounds();
    TTSAlertService.instance.initialize();
    _initializeFloatingAnimations();
  }

  void _initializeFloatingAnimations() {
    _floatControllers = List.generate(5, (index) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 200)),
        vsync: this,
      );
      controller.repeat(reverse: true);
      return controller;
    });

    _floatAnimations = _floatControllers.map((controller) {
      return Tween<double>(begin: -6.0, end: 6.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  Future<void> _checkCustomSounds() async {
    final customSoundService = CustomSoundService.instance;
    await customSoundService.initialize();
    print('🔊 Custom sounds saved: ${customSoundService.customSounds.length}');
  }

  Future<void> _initializeClassifier() async {
    await _classifier.initialize();
    setState(() {
      _isModelLoaded = _classifier.isReady;
    });
    if (_isModelLoaded) {
      print('AI Model loaded successfully!');
    } else {
      print('Failed to load AI model');
    }
  }

  void _setupAudioCallbacks() {
    _audioService.onNoiseLevel = (double decibel) {
      setState(() {
        _currentDecibel = decibel;
      });
    };

    _audioService.onAudioData = (List<double> audioData) {
      _audioBuffer.addAll(audioData);
      
      if (_audioBuffer.length >= 15600) {
        _classifyAudio();
      }
    };
  }

  Future<void> _classifyAudio() async {
    if (!_isModelLoaded || _audioBuffer.length < 15600) return;

    final samples = _audioBuffer.sublist(0, 15600);
    _audioBuffer = _audioBuffer.sublist(15600);
    final audioBytes = _samplesToBytes(samples);

    final customMatch = await CustomSoundService.instance.detectCustomSound(audioBytes);
    if (customMatch != null) {
      print('🎯 Custom sound detected: ${customMatch.displayName} (${customMatch.confidencePercent}%)');
      TTSAlertService.instance.speakAlert(customMatch.displayName, priority: 'important');
      
      final customDetected = DetectedSound(
        name: '⭐ ${customMatch.displayName}',
        category: customMatch.sound.category,
        confidence: customMatch.confidence,
        timestamp: DateTime.now(),
        priority: 'important',
      );
      
      setState(() {
        _detectedSounds.insert(0, customDetected);
        _currentSound = customDetected;
        if (_detectedSounds.length > 5) {
          _detectedSounds = _detectedSounds.sublist(0, 5);
        }
      });
      
      HapticService.vibrate('important');
      return;
    }

    final results = await _classifier.classify(samples);
    if (results.isNotEmpty) {
      for (var result in results) {
        final priority = SoundCategory.getPriority(result.label);

        if (!_settings.shouldShowSound(priority)) continue;

        if (_settings.vibrationEnabled &&
            (priority == 'critical' || priority == 'important')) {
          HapticService.vibrate(priority);
        }

        final exists = _detectedSounds.any((s) => s.name == result.label);
        if (exists) continue;

        final newSound = DetectedSound(
          name: result.label,
          category: _getCategoryForSound(result.label),
          confidence: result.confidence,
          timestamp: DateTime.now(),
          priority: priority,
        );

        TTSAlertService.instance.speakAlert(result.label, priority: priority);

        setState(() {
          _detectedSounds.insert(0, newSound);
          _currentSound = newSound;

          if (AnimationService.isCriticalAlert(result.label)) {
            _showCriticalAlert = true;
          }

          if (_detectedSounds.length > 5) {
            _detectedSounds = _detectedSounds.sublist(0, 5);
          }
        });
      }
    }
  }

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

  String _getCategoryForSound(String soundName) {
    final lower = soundName.toLowerCase();
    if (lower.contains('car') || lower.contains('horn') || lower.contains('siren')) {
      return 'Traffic';
    } else if (lower.contains('dog') || lower.contains('cat') || lower.contains('bird')) {
      return 'Animal';
    } else if (lower.contains('music') || lower.contains('singing')) {
      return 'Music';
    } else if (lower.contains('speech') || lower.contains('talk')) {
      return 'Speech';
    } else if (lower.contains('door') || lower.contains('knock')) {
      return 'Home';
    }
    return 'Other';
  }

  @override
  void dispose() {
    _audioService.dispose();
    _classifier.dispose();
    for (var controller in _floatControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      _audioService.stopListening();
      setState(() {
        _isListening = false;
        _currentDecibel = 0;
      });
    } else {
      try {
        await _audioService.startListening();
        setState(() {
          _isListening = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testTTS() async {
    print('🔊 Testing TTS...');
    await TTSAlertService.instance.initialize();
    await TTSAlertService.instance.speak('Hello! Doorbell detected. TTS is working.');
    print('🔊 TTS speak called');
  }

  void _onSoundTap(DetectedSound sound) {
    HapticService.vibrate(sound.priority);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2632),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sound.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Category', sound.category),
            _buildInfoRow('Confidence', '${(sound.confidence * 100).toInt()}%'),
            _buildInfoRow('Priority', sound.priority.toUpperCase()),
            _buildInfoRow('Time', _formatTime(sound.timestamp)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9DABB9), fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Color _getColorForPriority(String priority) {
    switch (priority) {
      case 'critical':
        return const Color(0xFFFF4757);
      case 'important':
        return const Color(0xFFFFA502);
      case 'normal':
        return const Color(0xFF137FEC);
      default:
        return const Color(0xFF2ED573);
    }
  }

  // NEW: Floating Lottie Animation Circle
  Widget _buildFloatingSoundCircle(DetectedSound sound, int index) {
    return AnimatedBuilder(
      animation: _floatAnimations[index % 5],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimations[index % 5].value),
          child: GestureDetector(
            onTap: () => _onSoundTap(sound),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2632),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getColorForPriority(sound.priority).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation instead of Icon
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Lottie.asset(
                      AnimationService.getAnimationPath(sound.name),
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sound.name.length > 10 
                        ? '${sound.name.substring(0, 10)}...' 
                        : sound.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(sound.timestamp),
                    style: const TextStyle(
                      color: Color(0xFF9DABB9),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCriticalAlert && _currentSound != null) {
      return CriticalAlert(
        soundName: _currentSound!.name,
        confidence: _currentSound!.confidence,
        onDismiss: () {
          setState(() {
            _showCriticalAlert = false;
          });
        },
      );
    }

    final recentSounds = _detectedSounds.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Dhwani',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A2632),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Content Area with Floating Lottie Animations
          Expanded(
            child: Stack(
              children: [
                // Background Lottie (bloob.json as ambient background)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Lottie.asset(
                      'assets/animations/bloob.json',
                      fit: BoxFit.cover,
                      repeat: true,
                    ),
                  ),
                ),

                // Content
                recentSounds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hearing,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isListening
                                  ? 'Listening for sounds...'
                                  : 'Start listening to detect sounds',
                              style: const TextStyle(
                                color: Color(0xFF9DABB9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Container(
                          height: MediaQuery.of(context).size.height - 280,
                          padding: const EdgeInsets.all(24),
                          child: Stack(
                            children: [
                              // Floating Lottie circles in organic positions
                              if (recentSounds.isNotEmpty)
                                Positioned(
                                  top: 20,
                                  left: MediaQuery.of(context).size.width * 0.3,
                                  child: _buildFloatingSoundCircle(recentSounds[0], 0),
                                ),
                              if (recentSounds.length > 1)
                                Positioned(
                                  top: 100,
                                  right: 40,
                                  child: _buildFloatingSoundCircle(recentSounds[1], 1),
                                ),
                              if (recentSounds.length > 2)
                                Positioned(
                                  top: 200,
                                  left: 20,
                                  child: _buildFloatingSoundCircle(recentSounds[2], 2),
                                ),
                              if (recentSounds.length > 3)
                                Positioned(
                                  top: 320,
                                  left: MediaQuery.of(context).size.width * 0.35,
                                  child: _buildFloatingSoundCircle(recentSounds[3], 3),
                                ),
                              if (recentSounds.length > 4)
                                Positioned(
                                  top: 180,
                                  right: MediaQuery.of(context).size.width * 0.25,
                                  child: _buildFloatingSoundCircle(recentSounds[4], 4),
                                ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),

          // Feature Cards Row at Bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A2632),
              border: Border(
                top: BorderSide(color: Color(0xFF2A3642), width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureCard(
                    icon: Icons.music_note,
                    label: 'Train\nSounds',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SoundTrainingScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildFeatureCard(
                    icon: Icons.person_add,
                    label: 'Voice\nProfiles',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AzureVoiceTrainingScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildFeatureCard(
                    icon: Icons.shield_moon,
                    label: 'Sleep\nMode',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pushNamed(context, '/sleep_mode');
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildFeatureCard(
                    icon: Icons.volume_up,
                    label: 'Test\nTTS',
                    color: Colors.green,
                    onTap: _testTTS,
                  ),
                  const SizedBox(width: 10),
                  _buildFeatureCard(
                    icon: Icons.closed_caption,
                    label: 'Live\nCaptions',
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedTranscriptionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2632),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', true),
                _buildNavItem(Icons.closed_caption, 'Captions', false),
                _buildNavItem(Icons.tune, 'Custom', false),
                _buildNavItem(Icons.settings, 'Settings', false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: _isListening ? const Color(0xFFFF4757) : const Color(0xFF137FEC),
        child: Icon(
          _isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF137FEC) : const Color(0xFF9DABB9),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF137FEC) : const Color(0xFF9DABB9),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}