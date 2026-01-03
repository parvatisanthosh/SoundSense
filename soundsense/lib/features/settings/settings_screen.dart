import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sound Detection Section
                    _buildSectionTitle('Sound Detection'),
                    const SizedBox(height: 16),
                    _buildSoundDetectionCard(),
                    
                    const SizedBox(height: 32),
                    
                    // Alerts & Haptics Section
                    _buildSectionTitle('Alerts & Haptics'),
                    const SizedBox(height: 16),
                    _buildAlertsHapticsCard(),
                    
                    const SizedBox(height: 32),
                    
                    // General Section
                    _buildSectionTitle('General'),
                    const SizedBox(height: 16),
                    _buildGeneralCard(),
                    
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dhwani Pro',
                  style: TextStyle(
                    color: Color(0xFF9DABB9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2632),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSoundDetectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensitivity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensitivity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Adjust environmental pickup',
                    style: TextStyle(
                      color: Color(0xFF9DABB9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A5C8D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  color: Color(0xFF4A9FFF),
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Visual Sensitivity Bars
          _buildSensitivityBars(),
          
          const SizedBox(height: 24),
          
          // Sensitivity Slider
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOW',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'HIGH',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  activeTrackColor: const Color(0xFF4A9FFF),
                  inactiveTrackColor: const Color(0xFF2A3F54),
                  thumbColor: const Color(0xFFCDDC39),
                  overlayColor: const Color(0xFFCDDC39).withOpacity(0.2),
                ),
                child: Slider(
                  value: _settings.sensitivity,
                  onChanged: (value) async {
                    await _settings.setSensitivity(value);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Active Detection Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1419),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EA55B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1EA55B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Active Detection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildModernToggle(
                  _settings.criticalAlerts,
                  (value) async {
                    await _settings.setCriticalAlerts(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(10, (index) {
        final normalizedSensitivity = (_settings.sensitivity * 10).round();
        final isActive = index < normalizedSensitivity;
        final height = 20.0 + (index * 4.0);
        
        return Container(
          width: 8,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4A9FFF) : const Color(0xFF2A3F54),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildAlertsHapticsCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildAlertItem(
            icon: Icons.vibration,
            iconColor: const Color(0xFFFF8C42),
            iconBgColor: const Color(0xFFFF8C42).withOpacity(0.2),
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on detection',
            value: _settings.vibrationEnabled,
            onChanged: (value) async {
              await _settings.setVibrationEnabled(value);
              setState(() {});
            },
          ),
          
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          
          _buildAlertItem(
            icon: Icons.flash_on,
            iconColor: const Color(0xFF9C27B0),
            iconBgColor: const Color(0xFF9C27B0).withOpacity(0.2),
            title: 'Visual Flash',
            subtitle: 'Screen flash alerts',
            value: _settings.importantAlerts,
            onChanged: (value) async {
              await _settings.setImportantAlerts(value);
              setState(() {});
            },
          ),
          
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          
          _buildAlertItem(
            icon: Icons.notifications,
            iconColor: const Color(0xFF4A9FFF),
            iconBgColor: const Color(0xFF4A9FFF).withOpacity(0.2),
            title: 'Push Notifications',
            subtitle: 'For high priority sounds',
            value: _settings.normalAlerts,
            onChanged: (value) async {
              await _settings.setNormalAlerts(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9DABB9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildModernToggle(value, onChanged),
        ],
      ),
    );
  }

  Widget _buildGeneralCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildGeneralItem(
            icon: Icons.volume_up,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFF4CAF50).withOpacity(0.2),
            title: 'Text-to-Speech',
            subtitle: 'Audio announcements',
            value: _settings.ttsEnabled,
            onChanged: (value) async {
              await _settings.setTTSEnabled(value);
              setState(() {});
            },
          ),
          
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          
          _buildGeneralItem(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF2196F3),
            iconBgColor: const Color(0xFF2196F3).withOpacity(0.2),
            title: 'App Version',
            subtitle: '2.4.0',
            isToggle: false,
          ),
          
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          
          _buildGeneralItem(
            icon: Icons.refresh,
            iconColor: const Color(0xFFFF5252),
            iconBgColor: const Color(0xFFFF5252).withOpacity(0.2),
            title: 'Reset Settings',
            subtitle: 'Restore defaults',
            isToggle: false,
            onTap: _resetSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    bool value = false,
    Function(bool)? onChanged,
    bool isToggle = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9DABB9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isToggle && onChanged != null)
              _buildModernToggle(value, onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildModernToggle(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFCDDC39) : const Color(0xFF2A3F54),
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
              color: value ? const Color(0xFF0F1419) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2632),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_rounded, false),
          _buildNavItem(Icons.history, false),
          _buildNavItem(Icons.settings, true),
          _buildNavItem(Icons.folder_outlined, false),
          _buildNavItem(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
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
    );
  }

  void _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2632),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Settings?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will restore all settings to default values.',
          style: TextStyle(color: Color(0xFF9DABB9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9DABB9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _settings.resetToDefaults();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            backgroundColor: Color(0xFF1EA55B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}