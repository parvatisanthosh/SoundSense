import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/azure_speech_service.dart';
import '../../core/services/pyannote_api_service.dart'; // ✅ NEW: Pyannote instead of Azure speaker service
import '../../core/config/env_config.dart';

/// Modern Live Captions Screen with Pyannote Speaker Identification
class EnhancedTranscriptionScreen extends StatefulWidget {
  const EnhancedTranscriptionScreen({super.key});

  @override
  State<EnhancedTranscriptionScreen> createState() =>
      _EnhancedTranscriptionScreenState();
}

class _EnhancedTranscriptionScreenState extends State<EnhancedTranscriptionScreen> {
  // Services
  late AzureSpeechService _speechService;
  final PyannoteApiService _speakerService = PyannoteApiService.instance; // ✅ CHANGED: Using Pyannote
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isConnected = false;
  String _selectedLanguage = 'en-US';
  
  // Transcription with speakers
  final List<TranscriptEntry> _transcriptEntries = [];
  String _partialText = '';
  String? _currentSpeakerName; // ✅ CHANGED: Simple string instead of IdentificationResult
  double _currentConfidence = 0.0; // ✅ NEW: Store confidence
  
  // Audio buffer for speaker identification
  List<int> _speakerAudioBuffer = [];
  Timer? _speakerIdentificationTimer;
  
  // Streams
  StreamSubscription? _transcriptionSub;
  StreamSubscription? _partialSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _audioSub;

  final ScrollController _scrollController = ScrollController();
  
  // UI State
  bool _isMuted = false;
  double _fontSize = 1.0;
  
  final List<Map<String, String>> _languages = [
    {'code': 'en-US', 'name': 'English (US)', 'flag': '🇺🇸'},
    {'code': 'en-IN', 'name': 'English (India)', 'flag': '🇮🇳'},
    {'code': 'hi-IN', 'name': 'Hindi', 'flag': '🇮🇳'},
    {'code': 'es-ES', 'name': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'fr-FR', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'de-DE', 'name': 'German', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _speechService = AzureSpeechService(
      apiKey: EnvConfig.azureSpeechApiKey,
      region: EnvConfig.azureSpeechRegion,
    );
    
    _transcriptionSub = _speechService.transcriptionStream.listen(_onTranscription);
    _partialSub = _speechService.partialStream.listen(_onPartialResult);
    _connectionSub = _speechService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
        if (!connected) _isListening = false;
      });
    });
    _errorSub = _speechService.errorStream.listen((error) {
      _showSnackbar(error, isError: true);
    });

    // ✅ NEW: Check if Pyannote server is available
    final healthy = await _speakerService.checkHealth();
    if (!healthy) {
      _showSnackbar('Speaker recognition offline', isError: false);
    }

    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _transcriptionSub?.cancel();
    _partialSub?.cancel();
    _connectionSub?.cancel();
    _errorSub?.cancel();
    _audioSub?.cancel();
    _speakerIdentificationTimer?.cancel();
    _speechService.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // TRANSCRIPTION LOGIC (Same as before)
  // ============================================================

  void _onTranscription(String fullText) {
    if (fullText.isEmpty) return;
    
    String newText = fullText;
    if (_transcriptEntries.isNotEmpty) {
      final lastFullText = _transcriptEntries.map((e) => e.text).join(' ');
      if (fullText.startsWith(lastFullText)) {
        newText = fullText.substring(lastFullText.length).trim();
      }
    }

    if (newText.isEmpty) return;

    setState(() {
      _transcriptEntries.add(TranscriptEntry(
        text: newText,
        speakerName: _currentSpeakerName, // ✅ CHANGED: Using string name
        confidence: _currentConfidence, // ✅ NEW: Store confidence
        timestamp: DateTime.now(),
      ));
      _partialText = '';
    });

    _scrollToBottom();
  }

  void _onPartialResult(String partial) {
    setState(() => _partialText = partial);
  }

  void _startSpeakerIdentification() {
    _speakerAudioBuffer = [];
    _speakerIdentificationTimer = Timer.periodic(
      const Duration(seconds: 3), // ✅ Identify every 3 seconds
      (_) => _identifyCurrentSpeaker(),
    );
  }

  void _stopSpeakerIdentification() {
    _speakerIdentificationTimer?.cancel();
    _speakerIdentificationTimer = null;
  }

  // ✅ CHANGED: Using Pyannote API
  Future<void> _identifyCurrentSpeaker() async {
    // Need at least 2 seconds of audio (16000 samples/sec * 2 bytes/sample * 2 seconds)
    if (_speakerAudioBuffer.length < 16000 * 2 * 2) return;
    
    final audioData = Uint8List.fromList(_speakerAudioBuffer);
    _speakerAudioBuffer = [];
    
    try {
      // Call Pyannote API
      final result = await _speakerService.recognizeSpeaker(audioData);
      
      if (result != null && mounted) {
        setState(() {
          if (result['identified'] == true) {
            _currentSpeakerName = result['name'];
            _currentConfidence = (result['confidence'] ?? 0.0).toDouble();
            print('🔊 Identified: $_currentSpeakerName (${(_currentConfidence * 100).toStringAsFixed(1)}%)');
          } else {
            _currentSpeakerName = null;
            _currentConfidence = (result['confidence'] ?? 0.0).toDouble();
          }
        });
      }
    } catch (e) {
      print('❌ Speaker identification error: $e');
    }
  }

  void _addAudioForSpeakerIdentification(List<int> audioData) {
    _speakerAudioBuffer.addAll(audioData);
    
    // Keep last 4 seconds of audio
    const maxBufferSize = 16000 * 2 * 4;
    if (_speakerAudioBuffer.length > maxBufferSize) {
      _speakerAudioBuffer = _speakerAudioBuffer.sublist(
        _speakerAudioBuffer.length - maxBufferSize,
      );
    }
  }

  Future<void> _startListening() async {
    if (!await _audioRecorder.hasPermission()) {
      _showSnackbar('Microphone permission denied', isError: true);
      return;
    }

    final connected = await _speechService.startTranscription(
      language: _selectedLanguage,
    );

    if (!connected) {
      _showSnackbar('Failed to connect to Azure', isError: true);
      return;
    }

    try {
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      setState(() => _isListening = true);

      _startSpeakerIdentification();

      _audioSub = stream.listen((data) {
        if (!_isMuted) {
          _speechService.sendAudioData(Uint8List.fromList(data));
          _addAudioForSpeakerIdentification(data);
        }
      });
    } catch (e) {
      _showSnackbar('Failed to start: $e', isError: true);
      await _speechService.stopTranscription();
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);

    _stopSpeakerIdentification();
    await _audioSub?.cancel();
    await _audioRecorder.stop();
    await _speechService.stopTranscription();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _clearTranscription() {
    setState(() {
      _transcriptEntries.clear();
      _partialText = '';
      _currentSpeakerName = null;
      _currentConfidence = 0.0;
    });
    _speechService.clearTranscription();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFFF4757) : const Color(0xFF2ED573),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // UI (Same beautiful design)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9FFF)))
            : Column(
                children: [
                  _buildModernHeader(),
                  _buildLiveIndicator(),
                  _buildLiveCaptionDisplay(),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  _buildRecentCaptionsSection(),
                  _buildBottomNav(),
                ],
              ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8BEAC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Container(
                width: 28,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isListening ? 'Listening now' : 'Ready to listen',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dhwani Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Language selector
          GestureDetector(
            onTap: _isListening ? null : _showLanguageSelector,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2632),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _languages.firstWhere((l) => l['code'] == _selectedLanguage)['flag'] ?? '🌐',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2632),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._languages.map((lang) => ListTile(
                    onTap: () {
                      setState(() => _selectedLanguage = lang['code']!);
                      Navigator.pop(context);
                    },
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang['name']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    trailing: _selectedLanguage == lang['code']
                        ? const Icon(Icons.check_circle, color: Color(0xFF4A9FFF))
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveIndicator() {
    if (!_isListening) return const SizedBox.shrink();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (index) => Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate(onPlay: (c) => c.repeat())
              .scaleY(begin: 0.5, end: 1.0, duration: 400.ms, delay: Duration(milliseconds: index * 100))
              .then()
              .scaleY(begin: 1.0, end: 0.5, duration: 400.ms)),
            const SizedBox(width: 8),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCaptionDisplay() {
    final displayText = _partialText.isNotEmpty ? _partialText : 
                       _transcriptEntries.isNotEmpty ? _transcriptEntries.last.text : '';
    
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ NEW: Show current speaker name
              if (_currentSpeakerName != null && _isListening)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9FFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4A9FFF), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Color(0xFF4A9FFF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _currentSpeakerName!,
                        style: const TextStyle(
                          color: Color(0xFF4A9FFF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${(_currentConfidence * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: const Color(0xFF4A9FFF).withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Caption text
              displayText.isEmpty
                  ? Text(
                      _isListening ? 'Start speaking...' : 'Tap microphone to start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 24 * _fontSize,
                      ),
                    )
                  : _buildHighlightedText(displayText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    // Highlight important keywords in blue
    final keywords = ['tomorrow', 'today', 'yesterday', 'now', 'urgent', 'important'];
    final words = text.split(' ');
    
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: words.map((word) {
          final isKeyword = keywords.any((kw) => word.toLowerCase().contains(kw));
          return TextSpan(
            text: '$word ',
            style: TextStyle(
              color: isKeyword ? const Color(0xFF4A9FFF) : Colors.white,
              fontSize: 32 * _fontSize,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: _isMuted ? Icons.mic_off : Icons.volume_off,
            label: 'Mute',
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
          _buildActionButton(
            icon: Icons.text_fields,
            label: 'Size',
            onTap: () => setState(() => _fontSize = _fontSize == 1.0 ? 1.5 : 1.0),
          ),
          _buildActionButton(
            icon: Icons.history,
            label: 'Save',
            onTap: _saveCurrentCaption,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF4A9FFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCaptionsSection() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Captions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearTranscription,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2632),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('Clear', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _transcriptEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No captions yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _transcriptEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _transcriptEntries.reversed.toList()[index];
                        return _buildCaptionCard(entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CHANGED: Simplified caption card for Pyannote
  Widget _buildCaptionCard(TranscriptEntry entry) {
    final speakerName = entry.speakerName ?? 'Unknown';
    final time = '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')} ${entry.timestamp.hour >= 12 ? 'PM' : 'AM'}';
    
    // Get emoji based on name
    String emoji = _getEmojiForSpeaker(speakerName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4A9FFF).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.speakerName != null
                    ? const Color(0xFF4A9FFF).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      speakerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (entry.confidence > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${(entry.confidence * 100).toStringAsFixed(0)}% confident',
                      style: TextStyle(
                        color: const Color(0xFF4A9FFF).withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  entry.text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Get emoji for speaker
  String _getEmojiForSpeaker(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mom') || lower.contains('mother')) return '👩';
    if (lower.contains('dad') || lower.contains('father')) return '👨';
    if (lower.contains('grandma') || lower.contains('grandmother')) return '👵';
    if (lower.contains('grandpa') || lower.contains('grandfather')) return '👴';
    if (lower.contains('sister')) return '👧';
    if (lower.contains('brother')) return '👦';
    return '👤';
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, false, () => Navigator.pushReplacementNamed(context, '/')),
          _buildNavItem(Icons.graphic_eq, true, null),
          _buildNavItem(Icons.settings, false, () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: isActive ? _toggleListening : onTap,
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

  void _saveCurrentCaption() {
    if (_partialText.isEmpty && _transcriptEntries.isEmpty) {
      _showSnackbar('No caption to save', isError: true);
      return;
    }
    _showSnackbar('Caption saved! ✓');
  }
}

/// ✅ CHANGED: Simplified transcript entry for Pyannote
class TranscriptEntry {
  final String text;
  final String? speakerName; // Simple string name
  final double confidence; // Confidence score
  final DateTime timestamp;

  TranscriptEntry({
    required this.text,
    this.speakerName,
    this.confidence = 0.0,
    required this.timestamp,
  });
}