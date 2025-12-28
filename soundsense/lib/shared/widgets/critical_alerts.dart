import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/animation_service.dart';

class CriticalAlert extends StatefulWidget {
  final String soundName;
  final double confidence;
  final VoidCallback onDismiss;

  const CriticalAlert({
    super.key,
    required this.soundName,
    required this.confidence,
    required this.onDismiss,
  });

  @override
  State<CriticalAlert> createState() => _CriticalAlertState();
}

class _CriticalAlertState extends State<CriticalAlert>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    
    // Continuous vibration
    _startVibration();
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Flash animation
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startVibration() async {
    for (int i = 0; i < 10; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = AnimationService.getEmoji(widget.soundName);
    final description = AnimationService.getDescription(
      widget.soundName, 
      widget.confidence, 
      'critical'
    );
    final animationPath = AnimationService.getAnimationPath(widget.soundName);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _flashController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    const Color(0xFF8B0000),
                    const Color(0xFFFF4757),
                    _flashController.value,
                  )!,
                  const Color(0xFF1A1A2E),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.2),
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF4757),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFFF4757),
                    size: 64,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ALERT text
              const Text(
                '⚠️ ALERT ⚠️',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .tint(color: const Color(0xFFFF4757), duration: 500.ms),
              
              const SizedBox(height: 32),
              
              // Animation
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Lottie.asset(
                  animationPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    );
                  },
                ),
              ).animate()
                  .scale(duration: 300.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 24),
              
              // Sound Name
              Text(
                widget.soundName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: 0.5),
              
              const SizedBox(height: 16),
              
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 48),
              
              // Dismiss Button
              GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    'TAP TO DISMISS',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 800.ms),
              
              const SizedBox(height: 24),
              
              // Confidence
              Text(
                'Confidence: ${(widget.confidence * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
