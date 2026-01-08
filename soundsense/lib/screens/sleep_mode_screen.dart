import 'package:flutter/material.dart';
import '../models/sleep_mode_settings.dart';
import '../services/sleep_mode_service.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen> with SingleTickerProviderStateMixin {
  // ALL ORIGINAL STATE - EXACTLY THE SAME
  bool _isActive = false;
  SleepModeSettings _settings = SleepModeSettings();
  final SleepModeService _service = SleepModeService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _service.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _loadSettings() async {
    final settings = await SleepModeSettings.load();
    setState(() {
      _settings = settings;
    });
  }

  void _toggleSleepMode() async {
    setState(() {
      _isActive = !_isActive;
    });

    if (_isActive) {
      await _service.startMonitoring();
    } else {
      await _service.stopMonitoring();
    }
  }

  void _saveSettings() {
    _settings.save();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================
  // NEW MODERN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildActivationButton(),
                    const SizedBox(height: 60),
                    _buildSettingsCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Sleep Guardian',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationButton() {
    return GestureDetector(
      onTap: _toggleSleepMode,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isActive 
                  ? const Color(0xFF1A2632).withOpacity(0.5)
                  : Theme.of(context).cardTheme.color,
              border: Border.all(
                color: _isActive 
                    ? Color.lerp(
                        const Color(0xFF4A9FFF).withOpacity(0.3),
                        const Color(0xFF4A9FFF).withOpacity(0.6),
                        _pulseController.value,
                      )!
                    : const Color(0xFF2A3F54),
                width: 2,
              ),
              boxShadow: _isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4A9FFF).withOpacity(0.2 * _pulseController.value),
                        blurRadius: 30 + (20 * _pulseController.value),
                        spreadRadius: 5 + (5 * _pulseController.value),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                Icons.power_settings_new,
                size: 80,
                color: _isActive ? const Color(0xFF4A9FFF) : const Color(0xFF9DABB9),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wake Methods',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Phone Flash Toggle
          _buildModernToggle(
            title: 'Phone Flash',
            subtitle: 'Blinks camera light rapidly',
            value: _settings.flashEnabled,
            onChanged: (val) {
              setState(() => _settings.flashEnabled = val);
              _saveSettings();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Vibration Toggle
          _buildModernToggle(
            title: 'Vibration',
            subtitle: 'Maximum vibration pattern',
            value: _settings.vibrationEnabled,
            onChanged: (val) {
              setState(() => _settings.vibrationEnabled = val);
              _saveSettings();
            },
          ),
          
          const SizedBox(height: 32),
          
          // Critical Sounds Section
          Text(
            'Critical Sounds',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSoundChip('Fire Alarm', 'fire_alarm'),
              _buildSoundChip('Baby Cry', 'baby_cry'),
              _buildSoundChip('Glass Break', 'break_in'),
              _buildSoundChip('Smoke Detector', 'smoke_detector'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Test Alert Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _service.triggerTestAlert();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test alert triggered'),
                    backgroundColor: Color(0xFF4A9FFF),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF2A3F54)),
                ),
              ),
              child: const Text(
                'Test Alert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF4A9FFF) : const Color(0xFF2A3F54),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                ),
                child: value
                    ? const Icon(Icons.check, color: Color(0xFF4A9FFF), size: 16)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoundChip(String label, String key) {
    final isSelected = _settings.criticalSounds.contains(key);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _settings.criticalSounds.remove(key);
          } else {
            _settings.criticalSounds.add(key);
          }
          _saveSettings();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4A9FFF).withOpacity(0.2)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF4A9FFF)
                : const Color(0xFF2A3F54),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check,
                color: Color(0xFF4A9FFF),
                size: 18,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4A9FFF) : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, true, () => Navigator.pop(context)),
          _buildNavItem(Icons.credit_card, false, null),
          _buildNavItem(Icons.music_note, false, null),
          _buildNavItem(Icons.settings, false, null),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A9FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}