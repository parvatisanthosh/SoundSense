import 'dart:math' as math;
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
        if (_detectedSounds.length > 20) {
          _detectedSounds = _detectedSounds.sublist(0, 20);
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

          if (_detectedSounds.length > 20) {
            _detectedSounds = _detectedSounds.sublist(0, 20);
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

  IconData _getIconForSound(String soundName) {
    final lower = soundName.toLowerCase();
    if (lower.contains('dog') || lower.contains('bark')) return Icons.pets;
    if (lower.contains('door') || lower.contains('bell')) return Icons.notifications;
    if (lower.contains('alarm') || lower.contains('fire')) return Icons.alarm;
    if (lower.contains('baby') || lower.contains('cry')) return Icons.child_care;
    if (lower.contains('car') || lower.contains('horn')) return Icons.directions_car;
    if (lower.contains('silence') || lower.contains('mute')) return Icons.volume_off;
    if (lower.contains('pencil') || lower.contains('write')) return Icons.edit;
    if (lower.contains('ping')) return Icons.notifications_active;
    return Icons.graphic_eq;
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
      body: SafeArea(
        child: Column(
          children: [
            _buildSimpleHeader(),
            _buildListeningStatus(),
            Expanded(child: _buildFloatingBubblesView(recentSounds)),
            _buildQuickActions(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2632),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const Text(
            'DHWANI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1A2632),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningStatus() {
    if (!_isListening) return const SizedBox.shrink();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2632),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00BCD4),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 600.ms)
              .then()
              .fadeOut(duration: 600.ms),
            const SizedBox(width: 10),
            const Text(
              'LISTENING MODE ACTIVE',
              style: TextStyle(
                color: Color(0xFF00BCD4),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBubblesView(List<DetectedSound> sounds) {
    return Stack(
      children: [
        // Background Lottie
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Lottie.asset(
              'assets/animations/bloob.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
        ),

        // Concentric ripple circles
        Positioned.fill(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRippleCircle(300, 0.05),
                _buildRippleCircle(450, 0.03),
                _buildRippleCircle(600, 0.02),
              ],
            ),
          ),
        ),

        // Content
        if (sounds.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hearing,
                  size: 64,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  _isListening
                      ? 'Listening for sounds...'
                      : 'Tap microphone to start',
                  style: const TextStyle(
                    color: Color(0xFF9DABB9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          Stack(
            children: [
              // Critical Alert Card (if critical sound exists)
              if (_currentSound != null && _currentSound!.priority == 'critical')
                Positioned(
                  top: 20,
                  left: MediaQuery.of(context).size.width * 0.15,
                  right: MediaQuery.of(context).size.width * 0.15,
                  child: _buildCriticalAlertCard(),
                ),

              // Central Circle with waveform
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1A2632).withOpacity(0.8),
                        const Color(0xFF0F1419).withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A9FFF).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq,
                    color: Colors.white,
                    size: 64,
                  ),
                ).animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms)
                  .then()
                  .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1), duration: 2000.ms),
              ),

              // Floating sound pills around center
              ...sounds.asMap().entries.map((entry) {
                final index = entry.key;
                final sound = entry.value;
                return _buildFloatingPill(sound, index, sounds.length);
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildRippleCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4A9FFF).withOpacity(opacity),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildCriticalAlertCard() {
    if (_currentSound == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF4757).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4757),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSound!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'CRITICAL ALERT',
                  style: TextStyle(
                    color: Color(0xFFFF4757),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingPill(DetectedSound sound, int index, int total) {
    // Position pills in a circle around the center
    final angle = (2 * math.pi * index) / total;
    final radius = 140.0;
    final centerX = MediaQuery.of(context).size.width / 2;
    final centerY = 250.0;
    
    final x = centerX + (radius * math.cos(angle)) - 90;
    final y = centerY + (radius * math.sin(angle)) - 30;
    
    return Positioned(
      left: x,
      top: y,
      child: AnimatedBuilder(
        animation: _floatAnimations[index % 5],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimations[index % 5].value),
            child: GestureDetector(
              onTap: () => _onSoundTap(sound),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2632),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _getColorForPriority(sound.priority).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getColorForPriority(sound.priority).withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getColorForPriority(sound.priority).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForSound(sound.name),
                        color: _getColorForPriority(sound.priority),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sound.name.replaceAll('⭐ ', ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTime(sound.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control Center heading
          Row(
            children: [
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'CONTROL CENTER',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Top row: Train Sounds, Voice Profiles, Sleep Mode
          Row(
            children: [
              Expanded(
                child: _buildControlCard(
                  icon: Icons.music_note,
                  label: 'Train\nSounds',
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoundTrainingScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlCard(
                  icon: Icons.person_add,
                  label: 'Voice\nProfiles',
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AzureVoiceTrainingScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlCard(
                  icon: Icons.shield_moon,
                  label: 'Sleep\nMode',
                  color: const Color(0xFF3F51B5),
                  onTap: () {
                    Navigator.pushNamed(context, '/sleep_mode');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bottom row: Test TTS, Live Caption
          Row(
            children: [
              Expanded(
                child: _buildWideControlCard(
                  icon: Icons.volume_up,
                  label: 'Test TTS',
                  color: const Color(0xFF4CAF50),
                  onTap: _testTTS,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWideControlCard(
                  icon: Icons.closed_caption,
                  label: 'Live Caption',
                  color: const Color(0xFF00BCD4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnhancedTranscriptionScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2632),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideControlCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2632),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2632),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, true, null),
              _buildNavItem(Icons.credit_card, false, null),
              const SizedBox(width: 80),
              _buildNavItem(Icons.tune, false, null),
              _buildNavItem(Icons.settings, false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }),
            ],
          ),
          
          Positioned(
            top: -25,
            left: MediaQuery.of(context).size.width / 2 - 70,
            child: GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 140,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4757).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isListening ? Icons.mic : Icons.location_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A9FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF9DABB9),
          size: 28,
        ),
      ),
    );
  }
}