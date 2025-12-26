import 'package:flutter/material.dart';
import '../../shared/widgets/sound_card.dart';
import '../../core/models/detected_sound.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Demo sounds for testing UI
  final List<DetectedSound> _detectedSounds = [
    DetectedSound(
      name: 'Car Horn',
      category: 'Traffic',
      confidence: 0.92,
      timestamp: DateTime.now(),
      priority: 'critical',
    ),
    DetectedSound(
      name: 'Dog Bark',
      category: 'Animal',
      confidence: 0.85,
      timestamp: DateTime.now(),
      priority: 'important',
    ),
    DetectedSound(
      name: 'Music',
      category: 'Entertainment',
      confidence: 0.78,
      timestamp: DateTime.now(),
      priority: 'normal',
    ),
  ];

  void _onSoundTap(DetectedSound sound) {
    // Show details when user taps a sound
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
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
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'SoundSense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF16213E),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Listening Status
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ED573),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Listening...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          // Sound Cards List
          Expanded(
            child: _detectedSounds.isEmpty
                ? const Center(
                    child: Text(
                      'No sounds detected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _detectedSounds.length,
                    itemBuilder: (context, index) {
                      final sound = _detectedSounds[index];
                      return SoundCard(
                        soundName: sound.name,
                        priority: sound.priority,
                        confidence: sound.confidence,
                        onTap: () => _onSoundTap(sound),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
