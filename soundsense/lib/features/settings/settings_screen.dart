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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound Alerts Section
          _buildSectionHeader('Sound Alerts'),
          _buildSwitchTile(
            'Critical Sounds',
            'Sirens, car horns, alarms',
            Icons.warning_amber,
            const Color(0xFFFF4757),
            _settings.criticalAlerts,
            (value) async {
              await _settings.setCriticalAlerts(value);
              setState(() {});
            },
          ),
          _buildSwitchTile(
            'Important Sounds',
            'Doorbell, dog bark, baby cry',
            Icons.notification_important,
            const Color(0xFFFFA502),
            _settings.importantAlerts,
            (value) async {
              await _settings.setImportantAlerts(value);
              setState(() {});
            },
          ),
          _buildSwitchTile(
            'Normal Sounds',
            'Music, speech, background noise',
            Icons.volume_up,
            const Color(0xFF2ED573),
            _settings.normalAlerts,
            (value) async {
              await _settings.setNormalAlerts(value);
              setState(() {});
            },
          ),

          const SizedBox(height: 24),

          // Vibration Section
          _buildSectionHeader('Vibration'),
          _buildSwitchTile(
            'Enable Vibration',
            'Vibrate when sounds are detected',
            Icons.vibration,
            const Color(0xFF00D9FF),
            _settings.vibrationEnabled,
            (value) async {
              await _settings.setVibrationEnabled(value);
              setState(() {});
            },
          ),
          if (_settings.vibrationEnabled) ...[
            const SizedBox(height: 8),
            _buildDropdownTile(
              'Vibration Intensity',
              Icons.speed,
              _settings.vibrationIntensity,
              ['Low', 'Medium', 'High'],
              (value) async {
                await _settings.setVibrationIntensity(value!);
                setState(() {});
              },
            ),
          ],

          const SizedBox(height: 24),

          // Sensitivity Section
          _buildSectionHeader('Detection Sensitivity'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sensitivity',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      _getSensitivityLabel(),
                      style: const TextStyle(
                        color: Color(0xFF2ED573),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _settings.sensitivity,
                  onChanged: (value) async {
                    await _settings.setSensitivity(value);
                    setState(() {});
                  },
                  activeColor: const Color(0xFF2ED573),
                  inactiveColor: Colors.grey[700],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text('High', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Threshold: ${_settings.getDecibelThreshold().toStringAsFixed(0)} dB',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildInfoTile('App Version', '1.0.0', Icons.info_outline),
          const SizedBox(height: 8),
          _buildInfoTile('AI Model', 'YAMNet (521 sounds)', Icons.psychology),
          const SizedBox(height: 8),
          _buildInfoTile('Developer', 'Team SoundSense', Icons.code),

          const SizedBox(height: 32),

          // Reset Button
          Center(
            child: ElevatedButton.icon(
              onPressed: _resetSettings,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reset to Defaults', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2ED573),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2ED573),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00D9FF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: options.map((String option) {
                return DropdownMenuItem<String>(value: option, child: Text(option));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 22),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  String _getSensitivityLabel() {
    if (_settings.sensitivity < 0.33) return 'Low';
    if (_settings.sensitivity < 0.66) return 'Medium';
    return 'High';
  }

  void _resetSettings() async {
    await _settings.resetToDefaults();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: Color(0xFF2ED573),
      ),
    );
  }
}