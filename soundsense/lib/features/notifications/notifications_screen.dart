import 'package:flutter/material.dart';
import '../../core/services/sound_intelligence_hub.dart';
import '../../shared/widgets/sound_sense_bottom_nav_bar.dart';
import 'package:soundsense/l10n/generated/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recentSounds = SoundIntelligenceHub().recentSounds;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: recentSounds.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: recentSounds.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationItem(context, recentSounds[index]);
                      },
                    ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.notificationsTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, SmartSoundEvent event) {
    // Determine color based on priority
    Color priorityColor;
    if (event.priority == 'critical') {
      priorityColor = Colors.red;
    } else if (event.priority == 'important') {
      priorityColor = Colors.orange;
    } else {
      priorityColor = const Color(0xFF4A9FFF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.priority == 'critical' ? Icons.warning_amber_rounded : Icons.notifications_none_rounded,
              color: priorityColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatTime(context, event.timestamp),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (event.transcription != null)
                  Text(
                    '"${event.transcription}"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (event.speakerName != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                     child: Text(
                      '${AppLocalizations.of(context)!.notificationsSpeaker} ${event.speakerName} ${(event.speakerConfidence * 100).toInt()}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                                       ),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.notificationTimeJustNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago'; // TODO: Localize duration
    if (diff.inHours < 24) return '${diff.inHours}h ago'; // TODO: Localize duration
    return '${timestamp.day}/${timestamp.month}';
  }

    Widget _buildBottomNav(BuildContext context) {
    return SoundSenseBottomNavBar(
      currentIndex: 2, // Notifications is now index 2
      isListening: SoundIntelligenceHub().isListening,
      onMicTap: () {
         Navigator.popUntil(context, ModalRoute.withName('/'));
      },
      onTap: (index) {
        if (index == 0) { // Home
           Navigator.popUntil(context, ModalRoute.withName('/'));
        } else if (index == 1) { // Chat
           Navigator.pushNamed(context, '/chat');
        } else if (index == 3) { // Settings
           Navigator.pushNamed(context, '/settings');
        }
      },
    );
  }
}
