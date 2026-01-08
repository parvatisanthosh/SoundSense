import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SoundSenseBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isListening;
  final VoidCallback onMicTap;
  final Function(int) onTap;

  const SoundSenseBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.isListening,
    required this.onMicTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home, 0),
          _buildNavItem(context, Icons.smart_toy_outlined, 1), // Chat
          // Main listening button
          GestureDetector(
            onTap: onMicTap,
            onLongPress: () {
              // Long press for emergency contacts
              Navigator.pushNamed(context, '/emergency');
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isListening
                      ? [Colors.red, Colors.red.shade700]
                      : [const Color(0xFF4A9FFF), const Color(0xFF9C27B0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? Colors.red : const Color(0xFF4A9FFF))
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: Theme.of(context).colorScheme.onSurface,
                size: 32,
              ),
            ).animate(onPlay: (c) => isListening ? c.repeat() : null).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1000.ms,
                ).then().scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: 1000.ms,
                ),
          ),
          _buildNavItem(context, Icons.notifications_none, 2),
          _buildNavItem(context, Icons.settings, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    // Map index 2 to Settings (since we removed index 2 clock, settings becomes index 2 in our 3-item list + mic)
    // Actually, let's keep the logic simple:
    // 0: Home
    // 1: Notification
    // 2: Settings
    
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A9FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }
}
