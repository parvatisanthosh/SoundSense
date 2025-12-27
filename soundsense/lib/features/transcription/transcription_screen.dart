import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/audio_service.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final AudioService _audioService = AudioService();
  bool _isListening = false;
  double _currentDecibel = 0;
  List<String> _conversationHistory = [];
  String _statusMessage = 'Tap mic to start listening';

  @override
  void initState() {
    super.initState();
    _setupAudio();
  }

  void _setupAudio() {
    _audioService.onNoiseLevel = (double decibel) {
      setState(() {
        _currentDecibel = decibel;
        
        // Detect speech based on decibel levels
        if (_isListening && decibel > 55) {
          _statusMessage = 'Speech detected...';
        } else if (_isListening) {
          _statusMessage = 'Listening for speech...';
        }
      });
    };
  }

  void _toggleListening() async {
    if (_isListening) {
      _audioService.stopListening();
      setState(() {
        _isListening = false;
        _statusMessage = 'Tap mic to start listening';
      });
    } else {
      try {
        await _audioService.startListening();
        setState(() {
          _isListening = true;
          _statusMessage = 'Listening for speech...';
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

  void _clearHistory() {
    setState(() {
      _conversationHistory.clear();
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Color _getDecibelColor() {
    if (_currentDecibel > 70) return const Color(0xFFFF4757);
    if (_currentDecibel > 55) return const Color(0xFFFFA502);
    return const Color(0xFF2ED573);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Live Captions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          if (_conversationHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isListening 
                ? const Color(0xFF2ED573).withOpacity(0.2)
                : const Color(0xFF16213E),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isListening 
                            ? const Color(0xFF2ED573) 
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isListening ? const Color(0xFF2ED573) : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (_isListening) ...[
                  const SizedBox(height: 12),
                  // Decibel meter
                  Text(
                    '${_currentDecibel.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      color: _getDecibelColor(),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_currentDecibel / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getDecibelColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2ED573).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2ED573),
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Speech Transcription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature will convert nearby conversations to text. '
                  'Full transcription requires Azure Speech Services which will be available in 3 days when your credits activate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔜 Coming in 3 days with Azure',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Placeholder for future transcriptions
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subtitles,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transcriptions will appear here',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mic Button
          Container(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? const Color(0xFFFF4757)
                      : const Color(0xFF2ED573),
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
