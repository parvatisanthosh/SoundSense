import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/detected_sound.dart';
import '../../core/models/sound_category.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/animation_service.dart';
import '../../core/services/custom_sound_service.dart';
import '../../core/services/tts_alert_service.dart';
// THE BRAIN - Intelligence Hub coordinates everything!
import '../../core/services/sound_intelligence_hub.dart';
// SOS Services
import '../../core/services/sos_service.dart';
import '../../core/services/sms_service.dart';
import '../../core/services/location_service.dart';
// Screens
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import '../training/sound_training_screen.dart';
import '../training/azure_voice_training_screen.dart';
import '../transcription/enhanced_transcription_screen.dart';
import '../sos/emergency_contacts_screen.dart';
import '../sos/sos_countdown_screen.dart';
import '../speaker_recognition/speaker_recognition_screen.dart';
import '../../shared/widgets/critical_alerts.dart';
import 'package:soundsense/l10n/generated/app_localizations.dart';
import '../../shared/widgets/sound_grid.dart';
import '../../shared/widgets/sound_sense_bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  
  // ============================================================
  // THE INTELLIGENCE HUB - Replaces all separate services!
  // ============================================================
  final SoundIntelligenceHub _hub = SoundIntelligenceHub();
  
  // Settings (still needed for UI)
  final SettingsService _settings = SettingsService();
  final SOSService _sosService = SOSService.instance;

  // UI State
  bool _isListening = false;
  double _currentDecibel = 0;
  List<DetectedSound> _detectedSounds = [];
  DetectedSound? _currentSound;
  bool _showCriticalAlert = false;
  
  // ✅ NEW: Speech-to-text state
  String _currentTranscription = '';
  String _partialTranscription = '';
  final List<TranscriptionEntry> _transcriptHistory = [];
  
  // SOS state
  bool _showSOSCountdown = false;
  bool _showSOSSent = false;
  int _sosContactsNotified = 0;

  // Smart suggestions from hub
  SmartSuggestion? _currentSuggestion;

  // Your floating animations
  late List<AnimationController> _floatControllers;
  late List<Animation<double>> _floatAnimations;

  @override
  void initState() {
    super.initState();
    _initializeHub();
    _initializeFloatingAnimations();
    _initializeSOS();
  }

  // ============================================================
  // INITIALIZATION - Much simpler now!
  // ============================================================

  /// Initialize the Intelligence Hub
  /// 
  /// This ONE method sets up EVERYTHING:
  /// - YAMNet model
  /// - Custom sounds
  /// - TTS
  /// - SOS
  /// - Settings
  /// - Speaker Recognition
  /// - Speech-to-Text ✅ NEW
  /// All coordinated by the hub!
  Future<void> _initializeHub() async {
    try {
      print('🚀 Dashboard: Initializing Intelligence Hub with Speech-to-Text...');
      
      // Initialize the hub (it handles everything)
      await _hub.initialize();
      
      // Listen to hub's sound events
      _hub.soundEventStream.listen(_onSmartSoundEvent);
      
      // Listen to hub's emergency events
      _hub.emergencyStream.listen(_onEmergencyEvent);
      
      // Listen to hub's smart suggestions
      _hub.suggestionStream.listen(_onSmartSuggestion);
      
      // Listen to speaker events
      _hub.speakerEventStream.listen(_onSpeakerEvent);
      
      // ✅ NEW: Listen to transcription events
      _hub.transcriptionStream.listen(_onTranscription);
      
      print('✅ Dashboard: Hub initialized with Sound + Speaker + Speech-to-Text!');
    } catch (e) {
      print('❌ Dashboard: Hub initialization error: $e');
      _showError('Failed to initialize: $e');
    }
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

  Future<void> _initializeSOS() async {
    await _sosService.initialize();
    await LocationService.instance.initialize();
  }

  // ============================================================
  // HUB EVENT HANDLERS - Hub tells us what to display!
  // ============================================================

  /// Handle smart sound event from hub
  /// 
  /// Hub has already:
  /// - Detected the sound (YAMNet or custom)
  /// - Triggered TTS announcement
  /// - Vibrated if needed
  /// - Checked for SOS
  /// 
  /// We just need to UPDATE THE UI!
  void _onSmartSoundEvent(SmartSoundEvent event) {
    print('🎯 Dashboard received sound event: ${event.displayName}');
    
    setState(() {
      // Convert to DetectedSound for UI
      final detectedSound = event.toDetectedSound();
      
      _detectedSounds.insert(0, detectedSound);
      _currentSound = detectedSound;
      
      // Keep only recent 50 sounds
      if (_detectedSounds.length > 50) {
        _detectedSounds = _detectedSounds.sublist(0, 50);
      }
      
      // Show critical alert if needed
      if (event.priority == 'critical') {
        _showCriticalAlert = true;
        
        // Auto-dismiss after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _showCriticalAlert = false);
          }
        });
      }
    });
  }

  /// Handle emergency event from hub
  /// 
  /// Hub detected critical pattern and wants to trigger SOS
  void _onEmergencyEvent(EmergencyEvent event) async {
    print('🚨 Dashboard received emergency: ${event.sounds}');
    
    setState(() {
      _showSOSCountdown = true;
    });
    
    // Get current location for SOS
    String location = 'Unknown';
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        location = '${position.latitude.toStringAsFixed(4)}°N, ${position.longitude.toStringAsFixed(4)}°E';
      }
    } catch (e) {
      print('Failed to get location: $e');
    }
    
    // Navigate to SOS countdown screen
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SOSCountdownScreen(
          detectedSounds: event.sounds,
          location: location,
          onCancel: () {
            setState(() => _showSOSCountdown = false);
            Navigator.pop(context);
          },
         onSendSOS: () async {
  // Send SOS
  final result = await SMSService.instance.sendSOSToContacts(event.sounds);
  
  // ✅ Check if widget is still mounted before Navigator
  if (!mounted) return;
  
  setState(() {
    _showSOSCountdown = false;
    _showSOSSent = true;
    _sosContactsNotified = result.contactsNotified;
  });
  
  Navigator.pop(context);
  
  // Show result
  if (mounted && result.success) {
    _showSnackbar('✓ ${result.message}');
  }
},
        ),
      ),
    );
  }

  /// Handle smart suggestion from hub
  /// 
  /// Hub suggests improvements (e.g., "Train this sound?")
  void _onSmartSuggestion(SmartSuggestion suggestion) {
  // ❌ Ignore training suggestions on dashboard
  if (suggestion.type == SuggestionType.trainCustomSound) {
    return;
  }

  setState(() {
    _currentSuggestion = suggestion;
  });

  Future.delayed(const Duration(seconds: 8), () {
    if (mounted) {
      setState(() => _currentSuggestion = null);
    }
  });
}

  /// Handle speaker event from hub
  /// 
  /// Shows who is currently speaking
  void _onSpeakerEvent(SpeakerEvent event) {
    print('👤 Dashboard received speaker event: ${event.speakerName ?? "Unknown"} (${(event.confidence * 100).toStringAsFixed(1)}%)');
    
    // Visual feedback is handled in sound events and transcriptions
  }

  /// ✅ NEW: Handle transcription event from hub
  /// 
  /// Shows what people are saying in real-time
  void _onTranscription(TranscriptionEvent event) {
    setState(() {
      if (event.isFinal) {
        // Final transcription - save to history
        _transcriptHistory.insert(0, TranscriptionEntry(
          text: event.text,
          speakerName: event.speakerName ?? 'Unknown',
          confidence: event.speakerConfidence,
          timestamp: event.timestamp,
        ));
        
        // Keep only last 50 transcriptions
        if (_transcriptHistory.length > 50) {
          _transcriptHistory.removeAt(_transcriptHistory.length - 1);
        }
        
        _currentTranscription = event.text;
        _partialTranscription = '';
        
        print('🗣️ Dashboard: Final transcription from ${event.speakerName ?? "Unknown"}: "${event.text}"');
      } else {
        // Partial transcription - show live caption
        _partialTranscription = event.text;
        print('🗣️ Dashboard: Live caption: "$event.text"');
      }
    });
  }

  // ============================================================
  // USER ACTIONS - So simple now!
  // ============================================================

  /// Start/Stop listening - ONE button does everything!
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  /// Start listening - Hub handles EVERYTHING automatically!
  Future<void> _startListening() async {
    try {
      print('🎤 Dashboard: Starting listening with Speech-to-Text...');
      
      // Hub starts everything:
      // - Audio service
      // - Sound detection (YAMNet + custom)
      // - Speaker recognition
      // - Speech-to-text ✅ NEW
      // - TTS ready
      // - SOS monitoring
      // - All coordinated!
      final success = await _hub.startListening(mode: ListeningMode.normal);
      
      if (success) {
        setState(() {
          _isListening = true;
          _detectedSounds.clear();
          _transcriptHistory.clear(); // ✅ NEW
          _currentTranscription = ''; // ✅ NEW
          _partialTranscription = ''; // ✅ NEW
        });
        print('✅ Dashboard: Listening started with transcription!');
      } else {
        _showError('Failed to start listening');
      }
    } catch (e) {
      print('❌ Dashboard: Start error: $e');
      _showError('Error: $e');
    }
  }

  /// Stop listening
  Future<void> _stopListening() async {
    print('🛑 Dashboard: Stopping...');
    
    await _hub.stopListening();
    
    setState(() {
      _isListening = false;
    });
    
    print('✅ Dashboard: Stopped');
  }

  /// User feedback - Help hub learn!
  void _onSoundTap(DetectedSound sound) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sound info
            Text(
              sound.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(sound.confidence * 100).toStringAsFixed(0)}% confident',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // Feedback buttons
            Row(
              children: [
                Expanded(
                  child: _buildFeedbackButton(
                    icon: Icons.check_circle,
                    label: AppLocalizations.of(context)!.feedbackCorrect,
                    color: Colors.green,
                    onTap: () {
                      _hub.confirmSound(sound.name, correct: true);
                      Navigator.pop(context);
                      _showSnackbar(AppLocalizations.of(context)!.feedbackThanks);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFeedbackButton(
                    icon: Icons.cancel,
                    label: AppLocalizations.of(context)!.feedbackWrong,
                    color: Colors.red,
                    onTap: () {
                      _hub.confirmSound(sound.name, correct: false);
                      Navigator.pop(context);
                      _showSnackbar(AppLocalizations.of(context)!.feedbackNoted);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeedbackButton(
              icon: Icons.close,
              label: AppLocalizations.of(context)!.feedbackDismiss,
              color: Colors.orange,
              onTap: () {
                _hub.dismissSound(sound.name);
                Navigator.pop(context);
                _showSnackbar('✓ I won\'t show "${sound.name}" anymore');
              },
            ),
            const SizedBox(height: 12),
            _buildFeedbackButton(
              icon: Icons.mic,
              label: AppLocalizations.of(context)!.feedbackTrain,
              color: const Color(0xFF4A9FFF),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sound-training');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4A9FFF),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================================
  // UI BUILD - Your beautiful design with transcriptions!
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Your critical alert
    if (_showCriticalAlert && _currentSound != null) {
      return CriticalSoundAlert(
        soundName: _currentSound!.name,
        confidence: _currentSound!.confidence,
        onDismiss: () {
          setState(() {
            _showCriticalAlert = false;
          });
        },
      );
    }

    // SOS confirmation
    if (_showSOSSent) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.sosSentSuccess,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_sosContactsNotified ${AppLocalizations.of(context)!.sosNotified}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Lottie background (your design)
            Positioned.fill(
              child: Lottie.asset(
                'assets/animations/bloob.json',
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),

            // Main content
            Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildSoundDetectionArea()),
                _buildControlCenter(),
                _buildBottomNav(),
              ],
            ),

            // Smart suggestion overlay
            if (_currentSuggestion != null)
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: _buildSmartSuggestion(_currentSuggestion!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSuggestion(SmartSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A9FFF).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9FFF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (suggestion.reason.isNotEmpty)
                  Text(
                    suggestion.reason,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (suggestion.type == SuggestionType.trainCustomSound)
            TextButton(
              onPressed: () {
                setState(() => _currentSuggestion = null);
                Navigator.pushNamed(context, '/sound-training');
              },
              child: Text(
                'Train',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, // or explicit color if needed
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // App Icon
          ClipOval(
            child: Image.asset(
              'assets/images/app_logo.jpg',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isListening ? AppLocalizations.of(context)!.dashboardListening : AppLocalizations.of(context)!.dashboardGreeting,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
  onPressed: _triggerManualSOS,
  icon: const Icon(Icons.sos, color: Colors.red),
  tooltip: 'Manual SOS',
),
IconButton(
  onPressed: _triggerManualSleep,
  icon: const Icon(Icons.bedtime, color: Colors.purple),
  tooltip: 'Sleep Mode',
),
          // Settings button
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundDetectionArea() {
    if (!_isListening) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.dashboardListeningPrompt,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ NEW: Live caption (partial transcription)
          if (_partialTranscription.isNotEmpty)
            _buildLiveCaption(),
          
          if (_partialTranscription.isNotEmpty)
            const SizedBox(height: 16),
          
          // ✅ NEW: Transcript history
          if (_transcriptHistory.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.recentSpeech,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              math.min(5, _transcriptHistory.length),
              (index) => _buildTranscriptBubble(_transcriptHistory[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Sound detection (existing)
          if (_detectedSounds.isEmpty && _transcriptHistory.isEmpty)
            _buildListeningIndicator()
          else if (_detectedSounds.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.detectedSounds,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
             math.min(5, _detectedSounds.length),
              (index) {
                final sound = _detectedSounds[index];
                final animIndex = index % _floatAnimations.length;
                
                return AnimatedBuilder(
                  animation: _floatAnimations[animIndex],
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimations[animIndex].value),
                      child: child,
                    );
                  },
                  child: _buildSoundBubble(sound, index),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// ✅ NEW: Build live caption
/// ✅ UPDATED: Build live caption with speaker identification
Widget _buildLiveCaption() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF4A9FFF).withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFF4A9FFF).withOpacity(0.5),
        width: 2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with listening indicator
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4A9FFF),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 500.ms)
              .then()
              .fadeOut(duration: 500.ms),
            const SizedBox(width: 8),
            Text(
              'LIVE CAPTION',
              style: TextStyle(
                color: const Color(0xFF4A9FFF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // ✅ NEW: Speaker identification - shown ABOVE the text
        if (_hub.currentSpeaker != null && _hub.currentSpeakerConfidence > 0.4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9FFF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  size: 18,
                  color: Color(0xFF4A9FFF),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_hub.currentSpeaker}',
                  style: const TextStyle(
                    color: Color(0xFF4A9FFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_hub.currentSpeakerConfidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF4A9FFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Unknown Speaker',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Divider
        Container(
          height: 1,
          color: const Color(0xFF4A9FFF).withOpacity(0.3),
        ),
        
        const SizedBox(height: 12),
        
        // Live caption text
        Text(
          _partialTranscription.isEmpty 
            ? 'Listening...' 
            : _partialTranscription,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontStyle: _partialTranscription.isEmpty ? FontStyle.italic : FontStyle.normal,
            height: 1.4,
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 200.ms);
}
/// ✅ UPDATED: Build transcript bubble with speaker name above
Widget _buildTranscriptBubble(TranscriptionEntry entry) {
  // Determine speaker color based on confidence
  final speakerColor = entry.confidence > 0.7 
    ? const Color(0xFF4A9FFF)
    : entry.confidence > 0.4
      ? Colors.orange
      : Colors.grey;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: speakerColor.withOpacity(0.3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Speaker badge - prominently displayed at top
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: speakerColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    color: speakerColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.speakerName,
                    style: TextStyle(
                      color: speakerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (entry.confidence > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(entry.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: speakerColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(entry.timestamp),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Transcription text
        Text(
          entry.text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0);
}

  Widget _buildListeningIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A9FFF).withOpacity(0.2),
            ),
            child: const Center(
              child: Icon(
                Icons.hearing,
                size: 50,
                color: Color(0xFF4A9FFF),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms)
            .then()
            .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 1500.ms),
          const SizedBox(height: 24),
          Text(
            'Listening for sounds and speech...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundBubble(DetectedSound sound, int index) {
    final isRecent = index < 3;
    final opacity = isRecent ? 1.0 : 0.6;
    
    return GestureDetector(
      onTap: () => _onSoundTap(sound),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(opacity) ?? Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPriorityColor(sound.priority).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getPriorityColor(sound.priority).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getSoundEmoji(sound.name),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${(sound.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(sound.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Show speaker if known
                  if (_hub.currentSpeaker != null && _hub.currentSpeakerConfidence > 0.4)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: const Color(0xFF4A9FFF).withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_hub.currentSpeaker} (${(_hub.currentSpeakerConfidence * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: const Color(0xFF4A9FFF).withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (sound.priority == 'critical')
              const Icon(Icons.warning, color: Colors.red, size: 24),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.2, end: 0),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return const Color(0xFF4A9FFF);
    }
  }

  String _getSoundEmoji(String soundName) {
    final lower = soundName.toLowerCase();
    if (lower.contains('fire') || lower.contains('alarm')) return '🔥';
    if (lower.contains('door')) return '🚪';
    if (lower.contains('baby')) return '👶';
    if (lower.contains('phone')) return '📱';
    if (lower.contains('dog')) return '🐕';
    if (lower.contains('music')) return '🎵';
    if (lower.contains('speech')) return '💬';
    if (lower.contains('car')) return '🚗';
    if (lower.contains('⭐')) return '⭐'; // Custom sounds
    return '🔊';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }






  Widget _buildControlCenter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(
                icon: Icons.graphic_eq,
                label: AppLocalizations.of(context)!.quickActionCaptions,
                onTap: () => Navigator.pushNamed(context, '/transcription'),
              ),
              _buildQuickAction(
                icon: Icons.person_search,
                label: AppLocalizations.of(context)!.quickActionSpeaker,
                onTap: () => Navigator.pushNamed(context, '/speaker-recognition'),
              ),
              _buildQuickAction(
                icon: Icons.mic_outlined,
                label: AppLocalizations.of(context)!.quickActionTrain,
                onTap: () => Navigator.pushNamed(context, '/sound-training'),
              ),
              _buildQuickAction(
                icon: Icons.record_voice_over,
                label: AppLocalizations.of(context)!.quickActionVoices,
                onTap: () => Navigator.pushNamed(context, '/voice-training'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isListening)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_detectedSounds.isNotEmpty)
                  Text(AppLocalizations.of(context)!.dashboardStatusSounds(_detectedSounds.length), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                if (_detectedSounds.isNotEmpty && _transcriptHistory.isNotEmpty)
                  Text(' • ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                if (_transcriptHistory.isNotEmpty)
                  Text(AppLocalizations.of(context)!.dashboardStatusTranscripts(_transcriptHistory.length), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF4A9FFF)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SoundSenseBottomNavBar(
      currentIndex: 0,
      isListening: _isListening,
      onMicTap: _toggleListening,
      onTap: (index) {
        if (index == 1) Navigator.pushNamed(context, '/chat');
        if (index == 2) Navigator.pushNamed(context, '/notifications');
        if (index == 3) Navigator.pushNamed(context, '/settings');
      },
    );
  }
 Future<void> _triggerManualSOS() async {
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.dashboardManualSosTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.dashboardManualSosContent,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.settingsCancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.dashboardManualSosAction),
          ),
        ],
      ),
    );
    
    if (shouldSend == true) {
      _onEmergencyEvent(EmergencyEvent(
        type: EmergencyType.manualTrigger,
        sounds: ['Manual SOS'],
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _triggerManualSleep() async {
    if (_isListening) {
      _showSnackbar(AppLocalizations.of(context)!.dashboardStopListeningFirst);
      return;
    }
    
    final shouldActivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            const Icon(Icons.bedtime, color: Colors.purple, size: 32),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.dashboardSleepGuardianTitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.dashboardSleepGuardianContent,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.settingsCancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text(AppLocalizations.of(context)!.dashboardSleepGuardianAction),
          ),
        ],
      ),
    );
    
    if (shouldActivate == true) {
      try {
        final success = await _hub.startListening(mode: ListeningMode.sleepMode);
        
        if (success) {
          setState(() => _isListening = true);
          _showSnackbar('😴 Sleep Guardian Active');
        } else {
          _showError('Failed to start Sleep Guardian');
        }
      } catch (e) {
        _showError('Error: $e');
      }
    }
  }
  @override
  void dispose() {
    _hub.dispose();
    for (var controller in _floatControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

/// ✅ NEW: Transcription entry data class
class TranscriptionEntry {
  final String text;
  final String speakerName;
  final double confidence;
  final DateTime timestamp;

  TranscriptionEntry({
    required this.text,
    required this.speakerName,
    required this.confidence,
    required this.timestamp,
  });
}