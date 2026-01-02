import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/sleep_mode_settings.dart';
import '../services/sleep_mode_service.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Sleep Mode"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Status Indicator
              Center(
                child: GestureDetector(
                  onTap: _toggleSleepMode,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isActive 
                              ? Colors.greenAccent.withOpacity(0.2) 
                              : Colors.grey.withOpacity(0.1),
                          boxShadow: _isActive 
                              ? [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.3 * _pulseController.value),
                                    blurRadius: 20 + (10 * _pulseController.value),
                                    spreadRadius: 5 + (5 * _pulseController.value),
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Icon(
                            _isActive ? Icons.shield_moon : Icons.power_settings_new,
                            size: 80,
                            color: _isActive ? Colors.greenAccent : Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isActive ? "Sleep Mode Active" : "Tap to Activate",
                style: TextStyle(
                  color: _isActive ? Colors.greenAccent : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              
              // Settings Section
              Expanded(
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 20,
                  blur: 20,
                  alignment: Alignment.bottomCenter,
                  border: 2,
                  linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      stops: const [0.1, 1],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.5),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "Wake Methods",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildSwitchTile(
                        "Phone Flash", 
                        "Blinks camera light rapidly",
                        _settings.flashEnabled, 
                        (val) {
                          setState(() => _settings.flashEnabled = val);
                          _saveSettings();
                        }
                      ),
                      _buildSwitchTile(
                        "Vibration", 
                        "Maximum vibration pattern",
                        _settings.vibrationEnabled, 
                        (val) {
                          setState(() => _settings.vibrationEnabled = val);
                          _saveSettings();
                        }
                      ),
                      
                      const SizedBox(height: 20),
                      const Text(
                        "Critical Sounds",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildSoundChip("Fire Alarm", 'fire_alarm'),
                          _buildSoundChip("Baby Cry", 'baby_cry'),
                          _buildSoundChip("Glass Break", 'break_in'),
                          _buildSoundChip("Smoke Detector", 'smoke_detector'),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                           _service.triggerTestAlert();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                        child: const Text("Test Alert", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6))),
      value: value,
      activeColor: Colors.greenAccent,
      onChanged: onChanged,
    );
  }

  Widget _buildSoundChip(String label, String key) {
    final isSelected = _settings.criticalSounds.contains(key);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blueAccent.withOpacity(0.3),
      checkmarkColor: Colors.blueAccent,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _settings.criticalSounds.add(key);
          } else {
            _settings.criticalSounds.remove(key);
          }
          _saveSettings();
        });
      },
      backgroundColor: Colors.white.withOpacity(0.1),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
