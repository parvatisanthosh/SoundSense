import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/animation_service.dart';

class SoundAnimation extends StatelessWidget {
  final String soundName;
  final double confidence;
  final String priority;
  final VoidCallback? onTap;

  const SoundAnimation({
    super.key,
    required this.soundName,
    required this.confidence,
    required this.priority,
    this.onTap,
  });

  Color _getPriorityColor() {
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
    final animationPath = AnimationService.getAnimationPath(soundName);
    final emoji = AnimationService.getEmoji(soundName);
    final description = AnimationService.getDescription(soundName, confidence, priority);
    final color = _getPriorityColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                priority.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.5),
            
            const SizedBox(height: 16),
            
            // Animation Container
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Lottie.asset(
                animationPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to emoji if animation fails
                  return Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  );
                },
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 1000.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(0.95, 0.95),
                  duration: 1000.ms,
                ),
            
            const SizedBox(height: 16),
            
            // Sound Name
            Text(
              soundName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 8),
            
            // Confidence Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Confidence: ',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    Text(
                      '${(confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: confidence,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ).animate().scaleX(begin: 0, alignment: Alignment.centerLeft, delay: 300.ms),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description for deaf users
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}