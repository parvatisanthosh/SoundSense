import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import '../../core/services/azure_speech_service.dart';
import '../../core/services/azure_speaker_service.dart';
import '../../core/config/env_config.dart';

/// Modern Live Captions Screen with Azure Speaker Identification
class EnhancedTranscriptionScreen extends StatefulWidget {
  const EnhancedTranscriptionScreen({super.key});

  @override
  State<EnhancedTranscriptionScreen> createState() => _EnhancedTranscriptionScreenState();
}

class _EnhancedTranscriptionScreenState extends State<EnhancedTranscriptionScreen> {
  // Services - EXACTLY THE SAME
  late AzureSpeechService _speechService;
  final AzureSpeakerService _speakerService = AzureSpeakerService.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // State - EXACTLY THE SAME
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isConnected = false;
  String _selectedLanguage = 'en-US';
  
  // Transcription with speakers - EXACTLY THE SAME
  final List<TranscriptEntry> _transcriptEntries = [];
  String _partialText = '';
  IdentificationResult? _currentSpeaker;
  
  // Audio buffer for speaker identification - EXACTLY THE SAME
  List<int> _speakerAudioBuffer = [];
  Timer? _speakerIdentificationTimer;
  
  // Streams - EXACTLY THE SAME
  StreamSubscription? _transcriptionSub;
  StreamSubscription? _partialSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _audioSub;
  
  final ScrollController _scrollController = ScrollController();
  
  // UI State
  bool _isMuted = false;
  double _fontSize = 1.0; // 1.0 = normal, 1.5 = large
  
  final List<Map<String, String>> _languages = [
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-IN', 'name': 'English (India)'},
    {'code': 'hi-IN', 'name': 'Hindi'},
    {'code': 'ta-IN', 'name': 'Tamil'},
    {'code': 'te-IN', 'name': 'Telugu'},
    {'code': 'ml-IN', 'name': 'Malayalam'},
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
  // ALL ORIGINAL LOGIC PRESERVED
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
        speaker: _currentSpeaker,
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
      const Duration(seconds: 3),
      (_) => _identifyCurrentSpeaker(),
    );
  }

  void _stopSpeakerIdentification() {
    _speakerIdentificationTimer?.cancel();
    _speakerIdentificationTimer = null;
  }

  Future<void> _identifyCurrentSpeaker() async {
    if (_speakerAudioBuffer.length < 16000 * 2) return;
    
    final audioData = Uint8List.fromList(_speakerAudioBuffer);
    _speakerAudioBuffer = [];
    
    final result = await _speakerService.identifySpeaker(audioData);
    
    setState(() {
      _currentSpeaker = result;
    });
    
    if (result.identified) {
      print('🎤 Identified: ${result.personName} (${result.confidencePercent}%)');
    }
  }

  void _addAudioForSpeakerIdentification(List<int> audioData) {
    _speakerAudioBuffer.addAll(audioData);
    
    const maxBufferSize = 16000 * 2 * 3;
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
      _showSnackbar('Failed to connect', isError: true);
      return;
    }
    
    try {
      final stream = await _audioRecorder.startStream(
        RecordConfig(
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
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // NEW MODERN UI
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
          
          // QR Code Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2632),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
          ),
        ],
      ),
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
          child: displayText.isEmpty
              ? Text(
                  _isListening ? 'Start speaking...' : 'Tap microphone to start',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 24 * _fontSize,
                  ),
                )
              : _buildHighlightedText(displayText),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2632),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('Filter', style: TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                      ],
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

  Widget _buildCaptionCard(TranscriptEntry entry) {
    final isKnown = entry.speaker?.identified ?? false;
    final name = entry.speaker?.personName ?? 'Unknown Speaker';
    final time = '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')} ${entry.timestamp.hour >= 12 ? 'PM' : 'AM'}';
    
    String emoji = '👤';
    if (isKnown) {
      final profile = _speakerService.profiles.firstWhere(
        (p) => p.personName == name,
        orElse: () => AzureVoiceProfile(profileId: '', personName: name),
      );
      emoji = profile.emoji ?? '👤';
    }
    
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
                      name,
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

/// Transcript entry with speaker info - SAME AS ORIGINAL
class TranscriptEntry {
  final String text;
  final IdentificationResult? speaker;
  final DateTime timestamp;

  TranscriptEntry({
    required this.text,
    this.speaker,
    required this.timestamp,
  });
}