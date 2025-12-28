import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/detected_sound.dart';
import '../../core/services/animation_service.dart';

class SoundGrid extends StatelessWidget {
  final List<DetectedSound> sounds;
  final Function(DetectedSound) onSoundTap;

  const SoundGrid({
    super.key,
    required this.sounds,
    required this.onSoundTap,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return const Color(0xFFFF4757);
      case 'important':
        return const Color(0xFFFFA502);
      default:
        return const Color(0xFF2ED573);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Take top 5 sounds
    final topSounds = sounds.take(5).toList();
    
    if (topSounds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: topSounds.asMap().entries.map((entry) {
          final index = entry.key;
          final sound = entry.value;
          return _buildSoundTile(sound, index);
        }).toList(),
      ),
    );
  }

  Widget _buildSoundTile(DetectedSound sound, int index) {
    final color = _getPriorityColor(sound.priority);
    final emoji = AnimationService.getEmoji(sound.name);
    final animationPath = AnimationService.getAnimationPath(sound.name);
    
    // Size based on confidence (bigger = more confident)
    final size = 80.0 + (sound.confidence * 30);

    return GestureDetector(
      onTap: () => onSoundTap(sound),
      child: Container(
        width: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation or Emoji
            SizedBox(
              width: size - 30,
              height: size - 30,
              child: Lottie.asset(
                animationPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: size / 2.5),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Sound name
            Text(
              sound.name.length > 10 
                  ? '${sound.name.substring(0, 8)}...' 
                  : sound.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Confidence
            Text(
              '${(sound.confidence * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
        .fadeIn()
        .scale(begin: const Offset(0.5, 0.5))
        .then()
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 1000),
        );
  }
}