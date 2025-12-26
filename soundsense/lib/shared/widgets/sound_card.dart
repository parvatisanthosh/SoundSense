import 'package:flutter/material.dart';

class SoundCard extends StatelessWidget {
  final String soundName;
  final String priority;
  final double confidence;
  final VoidCallback onTap;

  const SoundCard({
    super.key,
    required this.soundName,
    required this.priority,
    required this.confidence,
    required this.onTap,
  });

  Color _getPriorityColor() {
    switch (priority) {
      case 'critical':
        return const Color(0xFFFF4757);  // Red
      case 'important':
        return const Color(0xFFFFA502);  // Orange
      default:
        return const Color(0xFF2ED573);  // Green
    }
  }

  IconData _getSoundIcon() {
    switch (soundName.toLowerCase()) {
      case 'car horn':
        return Icons.directions_car;
      case 'siren':
        return Icons.emergency;
      case 'dog bark':
        return Icons.pets;
      case 'doorbell':
        return Icons.doorbell;
      case 'baby cry':
        return Icons.child_care;
      case 'phone ring':
        return Icons.phone_android;
      case 'music':
        return Icons.music_note;
      case 'speech':
        return Icons.record_voice_over;
      default:
        return Icons.hearing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPriorityColor(),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Sound Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getPriorityColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getSoundIcon(),
                color: _getPriorityColor(),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Sound Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    soundName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(confidence * 100).toInt()}% confident',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPriorityColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                priority.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}