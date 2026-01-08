import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:soundsense/l10n/generated/app_localizations.dart';

class SoundSenseBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onMicTap;
  final bool isListening;

  const SoundSenseBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onMicTap,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) // Dark surface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabItem(context, 0, Icons.home_rounded, AppLocalizations.of(context)!.navHome, activeColor: const Color(0xFF4A9FFF)),
            _buildTabItem(context, 1, Icons.chat_bubble_rounded, AppLocalizations.of(context)!.navChat),
            
            // Center Mic FAB
            Transform.translate(
              offset: const Offset(0, -25),
              child: GestureDetector(
                onTap: onMicTap,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:const Color(0xFFFF5252).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ).animate(target: isListening ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms)
                .then().scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 1000.ms),
              ),
            ),
            
            _buildTabItem(context, 2, Icons.notifications_rounded, AppLocalizations.of(context)!.navAlerts),
            _buildTabItem(context, 3, Icons.settings_rounded, AppLocalizations.of(context)!.navSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, IconData icon, String label, {Color? activeColor}) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine colors based on theme
    final defaultSelectedColor = isDark ? Colors.white : const Color(0xFF1A1F36);
    final unselectedColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF9CA3AF);
    
    final color = isSelected ? (activeColor ?? defaultSelectedColor) : unselectedColor;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected && activeColor != null 
                    ? activeColor.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
