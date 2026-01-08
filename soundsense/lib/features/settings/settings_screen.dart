import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/sleep_scheduler_service.dart';
import '../sos/emergency_contacts_screen.dart';
import '../../core/services/sound_intelligence_hub.dart' hide TimeOfDay;
import '../../shared/widgets/sound_sense_bottom_nav_bar.dart';
import 'package:soundsense/l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final SleepSchedulerService _sleepScheduler = SleepSchedulerService.instance;

  @override
  void initState() {
    super.initState();
    _initializeSleepScheduler();
  }

  Future<void> _initializeSleepScheduler() async {
    await _sleepScheduler.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NEW: Sleep Guardian Section
                    _buildSectionTitle('😴 Sleep Guardian'),
                    const SizedBox(height: 16),
                    _buildSleepGuardianCard(),
                    
                    const SizedBox(height: 32),
                    
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
                    
                    // Emergency Section
                    _buildSectionTitle('Emergency'),
                    const SizedBox(height: 16),
                    _buildEmergencyCard(),
                    
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
            
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NEW: SLEEP GUARDIAN CARD
  // ============================================================

  Widget _buildSleepGuardianCard() {
    return StreamBuilder<SleepSchedulerStatus>(
      stream: _sleepScheduler.statusStream,
      initialData: SleepSchedulerStatus(
        isEnabled: _sleepScheduler.isEnabled,
        isInSleepWindow: _sleepScheduler.isInSleepWindow,
        isSleepModeActive: _sleepScheduler.isSleepModeActive,
        isManualOverride: false,
        schedule: _sleepScheduler.schedule,
        nextChange: _sleepScheduler.getNextScheduledChange(),
      ),
      builder: (context, snapshot) {
        final status = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: status.isSleepModeActive 
                ? const Color(0xFF9C27B0).withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
              width: status.isSleepModeActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Auto Sleep Mode Toggle
              _buildAlertItem(
                icon: Icons.bedtime,
                iconColor: const Color(0xFF9C27B0),
                iconBgColor: const Color(0xFF9C27B0).withOpacity(0.2),
                title: 'Auto Sleep Mode',
                subtitle: status.isEnabled 
                  ? 'Scheduled: ${status.schedule.toString()}'
                  : 'Disabled',
                value: status.isEnabled,
                onChanged: (value) async {
                  await _sleepScheduler.toggleEnabled(value);
                  setState(() {});
                },
              ),
              
              // Show schedule settings when enabled
              if (status.isEnabled) ...[
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                
                // Schedule Time Settings
                _buildScheduleTimeSettings(status.schedule),
                
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                
                // Status Display
                _buildSleepModeStatus(status),
              ],
              
              // Manual Sleep Mode Button (always visible)
              Divider(color: Colors.white.withOpacity(0.05), height: 1),
              _buildManualSleepModeButton(status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleTimeSettings(SleepSchedule schedule) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Start Time
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sleep Start',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectTime(
                  context,
                  isStartTime: true,
                  currentHour: schedule.startHour,
                  currentMinute: schedule.startMinute,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9C27B0).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF9C27B0), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        schedule.startTime,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // End Time
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wake Up',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectTime(
                  context,
                  isStartTime: false,
                  currentHour: schedule.endHour,
                  currentMinute: schedule.endMinute,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4A9FFF).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: Color(0xFF4A9FFF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        schedule.endTime,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepModeStatus(SleepSchedulerStatus status) {
    final nextChange = status.nextChange;
    final timeUntil = nextChange.difference(DateTime.now());
    
    String timeText;
    if (timeUntil.inHours > 0) {
      timeText = '${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m';
    } else {
      timeText = '${timeUntil.inMinutes}m';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status.isSleepModeActive ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (status.isSleepModeActive ? Colors.green : Colors.orange).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.statusText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.isSleepModeActive 
                    ? 'Ends in $timeText'
                    : 'Starts in $timeText',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSleepModeButton(SleepSchedulerStatus status) {
    final isManualActive = status.isSleepModeActive && status.isManualOverride;
    
    return GestureDetector(
      onTap: () async {
        if (isManualActive) {
          await _sleepScheduler.deactivateManualSleepMode();
        } else {
          final success = await _sleepScheduler.activateManualSleepMode();
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sleep mode activated manually'),
                backgroundColor: Color(0xFF9C27B0),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isManualActive 
            ? const Color(0xFF9C27B0).withOpacity(0.1)
            : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isManualActive ? Icons.bedtime_off : Icons.bedtime,
              color: isManualActive ? Colors.orange : const Color(0xFF9C27B0),
            ),
            const SizedBox(width: 12),
            Text(
              isManualActive ? 'Deactivate Sleep Mode' : 'Activate Sleep Mode Now',
              style: TextStyle(
                color: isManualActive ? Colors.orange : const Color(0xFF9C27B0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isStartTime,
    required int currentHour,
    required int currentMinute,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9C27B0),
              surface: Color(0xFF1A2632),
              background: Color(0xFF0F1419),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final schedule = _sleepScheduler.schedule;
      
      if (isStartTime) {
        await _sleepScheduler.updateSchedule(
          startHour: picked.hour,
          startMinute: picked.minute,
          endHour: schedule.endHour,
          endMinute: schedule.endMinute,
        );
      } else {
        await _sleepScheduler.updateSchedule(
          startHour: schedule.startHour,
          startMinute: schedule.startMinute,
          endHour: picked.hour,
          endMinute: picked.minute,
        );
      }
      
      setState(() {});
    }
  }

  // ============================================================
  // EXISTING SECTIONS (Keep as is)
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8BEAC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/app_logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.settingsTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize your experience',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSoundDetectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
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
          
          _buildSensitivityBars(),
          
          const SizedBox(height: 24),
          
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOW',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'HIGH',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  onChanged: (value) async {
                    await _settings.setSensitivity(value);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                Expanded(
                  child: Text(
                    'Active Detection',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).cardTheme.color,
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
            icon: Icons.record_voice_over,
            iconColor: const Color(0xFF1EA55B),
            iconBgColor: const Color(0xFF1EA55B).withOpacity(0.2),
            title: 'Voice Alerts (TTS)',
            subtitle: 'Speak detected sounds',
            value: _settings.ttsEnabled,
            onChanged: (value) async {
              await _settings.setTTSEnabled(value);
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
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.contacts,
                      color: Color(0xFFFF4757),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage SOS contacts',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF9DABB9),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildAlertItem(
            icon: _settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            iconColor: const Color(0xFF4A9FFF),
            iconBgColor: const Color(0xFF4A9FFF).withOpacity(0.2),
            title: _settings.isDarkMode ? AppLocalizations.of(context)!.settingsDarkMode : AppLocalizations.of(context)!.settingsDarkMode,
            subtitle: _settings.isDarkMode ? 'On' : 'Off',
            value: _settings.isDarkMode,
            onChanged: (value) async {
              await _settings.setDarkMode(value);
              setState(() {});
            },
          ),
          
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          
          GestureDetector(
            onTap: () {
              _showLanguageDialog();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Color(0xFF9C27B0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.settingsLanguage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _settings.locale.languageCode == 'hi' ? 'Hindi' : 'English',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF9DABB9),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          
          GestureDetector(
            onTap: () {
              _showResetDialog();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Color(0xFFFF4757),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Reset Settings',
                      style: TextStyle(
                        color: Color(0xFFFF4757),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    required void Function(bool)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onChanged != null)
            _buildModernToggle(value, onChanged)
          else
            Icon(
              Icons.check_circle,
              color: iconColor,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildModernToggle(bool value, void Function(bool) onChanged) {
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
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SoundSenseBottomNavBar(
      currentIndex: 3, // Settings is now index 3
      isListening: _settings.isListening,
      onMicTap: () {
         Navigator.popUntil(context, ModalRoute.withName('/'));
      },
      onTap: (index) {
        if (index == 0) { // Home
           Navigator.popUntil(context, ModalRoute.withName('/'));
        } else if (index == 1) { // Chat
           Navigator.pushNamed(context, '/chat');
        } else if (index == 2) { // Notifications
           Navigator.pushNamed(context, '/notifications');
        }
      },
    );
  }
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2632),
        title: const Text(
          'Reset Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all settings to default values. Continue?',
          style: TextStyle(color: Color(0xFF9DABB9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _settings.resetToDefaults();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF4757)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2632),
        title: const Text(
          'Select Language',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'en',
                groupValue: _settings.locale.languageCode,
                activeColor: const Color(0xFF4A9FFF),
                onChanged: (value) async {
                  if (value != null) {
                    await _settings.setLocale(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
              onTap: () async {
                await _settings.setLocale('en');
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('Hindi', style: TextStyle(color: Colors.white)),
              leading: Radio<String>(
                value: 'hi',
                groupValue: _settings.locale.languageCode,
                activeColor: const Color(0xFF4A9FFF),
                onChanged: (value) async {
                  if (value != null) {
                    await _settings.setLocale(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
              onTap: () async {
                await _settings.setLocale('hi');
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to get listening state since it wasn't in the original build
// We need to import the hub.
extension on SettingsService {
  bool get isListening => SoundIntelligenceHub().isListening;
}