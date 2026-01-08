// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dhwani';

  @override
  String get dashboardGreeting => 'Ready';

  @override
  String get dashboardListening => 'Listening';

  @override
  String get dashboardListeningPrompt => 'Tap microphone to start';

  @override
  String get dashboardPartialListeningPrompt =>
      'Listening for sounds and speech...';

  @override
  String get recentSpeech => 'Recent Speech';

  @override
  String get detectedSounds => 'Detected Sounds';

  @override
  String get quickActionCaptions => 'Captions';

  @override
  String get quickActionSpeaker => 'Speaker';

  @override
  String get quickActionTrain => 'Train';

  @override
  String get quickActionVoices => 'Voices';

  @override
  String get navHome => 'Home';

  @override
  String get navChat => 'Chat';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get chatWelcome =>
      'Hi! 👋 I\'m your SoundSense assistant powered by AI. I can help you understand sounds, answer questions about your environment, or just chat. How can I help you today?';

  @override
  String get chatAiAssistant => 'AI Assistant';

  @override
  String get chatStatusOnline => 'Online • Gemini AI';

  @override
  String get chatRecent => 'Recent:';

  @override
  String get chatInputHint => 'Ask me anything...';

  @override
  String get chatCleared =>
      'Chat cleared! 🧹 I\'m ready to help you with anything. What would you like to know?';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationTimeJustNow => 'Just now';

  @override
  String get notificationsSpeaker => 'Speaker:';

  @override
  String get trainTitle => 'Teach Dhwani';

  @override
  String get trainNewSound => 'a new sound';

  @override
  String get trainIdentity => 'SOUND IDENTITY';

  @override
  String get trainNameHint => 'e.g. Microwave Beep';

  @override
  String get trainCategory => 'Category';

  @override
  String get trainCustomSounds => 'Your Custom Sounds';

  @override
  String get trainStart => 'Start Training';

  @override
  String get trainStep => 'Step';

  @override
  String get trainRecordTitle => 'Record Sample';

  @override
  String get trainRecordSubtitle => 'Capture clear audio of the sound.';

  @override
  String get trainReady => 'Ready to record';

  @override
  String get trainRecording => 'Recording...';

  @override
  String get trainRecord => 'Record';

  @override
  String get trainUpload => 'Upload';

  @override
  String get trainListening => 'LISTENING';

  @override
  String get trainComplete => 'Training complete! 🎉';

  @override
  String get trainDelete => 'Delete Sound?';

  @override
  String get trainDeleteConfirm => 'This cannot be undone.';

  @override
  String get trainCancel => 'Cancel';

  @override
  String get trainDeleteAction => 'Delete';

  @override
  String get sosTitle => 'Emergency SOS';

  @override
  String get sosDescription =>
      'Press the button below to send an emergency alert to all your contacts with your location.';

  @override
  String get sosSendButton => 'SEND SOS NOW';

  @override
  String get sosContactsHeader => 'Emergency Contacts';

  @override
  String get sosNoContacts => 'No Contacts Added';

  @override
  String get sosAddContactPrompt =>
      'Add emergency contacts to enable SOS alerts. They will receive your location when you trigger an emergency.';

  @override
  String get sosAddButton => 'Add Contact';

  @override
  String get sosHowItWorks => 'How SOS Works';

  @override
  String get sosStepSound =>
      'Automatic trigger on critical sounds (siren, alarm)';

  @override
  String get sosStepLocation => 'Sends your GPS location';

  @override
  String get sosStepSms => 'SMS sent to all emergency contacts';

  @override
  String get sosStepCountdown => '10 second countdown to cancel';

  @override
  String get sosAddContactTitle => 'Add Emergency Contact';

  @override
  String get sosNameLabel => 'Name';

  @override
  String get sosPhoneLabel => 'Phone Number';

  @override
  String get sosRelationshipLabel => 'Relationship';

  @override
  String get sosAddContactAction => 'Add Contact';

  @override
  String get sosRemoveContactTitle => 'Remove Contact?';

  @override
  String sosRemoveContactConfirm(Object name) {
    return 'Remove $name from emergency contacts?';
  }

  @override
  String get sosRemoveAction => 'Remove';

  @override
  String get settingsSubtitle => 'Customize your experience';

  @override
  String get settingsSectionSleep => 'SLEEP GUARDIAN';

  @override
  String get settingsSectionSound => 'SOUND DETECTION';

  @override
  String get settingsSectionAlerts => 'ALERTS & HAPTICS';

  @override
  String get settingsSectionEmergency => 'EMERGENCY';

  @override
  String get settingsSectionGeneral => 'GENERAL';

  @override
  String get settingsAutoSleep => 'Auto Sleep Mode';

  @override
  String get settingsAutoSleepDisabled => 'Disabled';

  @override
  String settingsAutoSleepScheduled(Object schedule) {
    return 'Scheduled: $schedule';
  }

  @override
  String get settingsActivateSleep => 'Activate Sleep Mode Now';

  @override
  String get settingsDeactivateSleep => 'Deactivate Sleep Mode';

  @override
  String get settingsSleepModeActivated => 'Sleep mode activated manually';

  @override
  String get settingsSchedule => 'Schedule';

  @override
  String get settingsSleepStart => 'Sleep Start';

  @override
  String get settingsWakeUp => 'Wake Up';

  @override
  String get settingsActiveDetection => 'Active Detection';

  @override
  String get settingsSensitivityLow => 'LOW';

  @override
  String get settingsSensitivityHigh => 'HIGH';

  @override
  String get settingsHaptic => 'Haptic Feedback';

  @override
  String get settingsHapticDesc => 'Vibrate on detection';

  @override
  String get settingsVoice => 'Voice Alerts (TTS)';

  @override
  String get settingsVoiceDesc => 'Speak detected sounds';

  @override
  String get settingsFlash => 'Visual Flash';

  @override
  String get settingsFlashDesc => 'Screen flash alerts';

  @override
  String get settingsEmergencyContacts => 'Emergency Contacts';

  @override
  String get settingsEmergencyContactsDesc => 'Manage SOS contacts';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsReset => 'Reset Settings';

  @override
  String get settingsResetDesc => 'Restore default settings';

  @override
  String get settingsResetConfirm =>
      'Are you sure you want to reset all settings to default?';

  @override
  String get settingsResetAction => 'Reset';

  @override
  String get settingsCancelAction => 'Cancel';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsLanguageHindi => 'Hindi';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsModeSystem => 'System Default';

  @override
  String get settingsModeLight => 'Light Mode';

  @override
  String get settingsModeDark => 'Dark Mode';

  @override
  String settingsSleepStartsIn(Object time) {
    return 'Starts in $time';
  }

  @override
  String settingsSleepEndsIn(Object time) {
    return 'Ends in $time';
  }

  @override
  String get sosCountSeconds => 'seconds until SOS is sent';

  @override
  String get sosDetectedSounds => 'Detected Sounds';

  @override
  String get sosTapCancel => 'TAP TO CANCEL';

  @override
  String get sosCancelQuote => 'I\'m okay, cancel the alert';

  @override
  String get sosSentTitle => 'SOS SENT';

  @override
  String get sosNotified => 'contact(s) notified';

  @override
  String get sosSentMessage =>
      'Your emergency contacts have been sent your location. Help is on the way.';

  @override
  String get sosSafe => 'I AM SAFE';

  @override
  String get sosCallEmergency => 'Call Emergency Services (112)';

  @override
  String get dashboardManualSosTitle => 'Manual SOS';

  @override
  String get dashboardManualSosContent =>
      'Send emergency alert to all contacts?';

  @override
  String get dashboardManualSosAction => 'Send SOS';

  @override
  String get dashboardSleepGuardianTitle => 'Sleep Guardian';

  @override
  String get dashboardSleepGuardianContent =>
      'Activate Sleep Guardian mode?\n\nThis will monitor for critical sounds while you sleep.';

  @override
  String get dashboardSleepGuardianAction => 'Activate';

  @override
  String get dashboardStopListeningFirst => '⚠️ Stop listening first';

  @override
  String get spkTitle => 'Speaker Recognition';

  @override
  String get spkServerUnavailable => 'Server not available';

  @override
  String get spkMicDenied => 'Microphone permission denied';

  @override
  String get spkUnknown => 'Unknown';

  @override
  String get spkUnknownSpeaker => 'Unknown speaker';

  @override
  String get spkFailed => 'Recognition failed';

  @override
  String get spkConnectError => 'Cannot connect to server';

  @override
  String get spkRetry => 'Retry';

  @override
  String get spkIdentify => 'Identify Speaker';

  @override
  String get spkRecording => 'Recording (4s)...';

  @override
  String get spkAddMember => 'Add Family Member';

  @override
  String get spkHowTo => 'How to use:';

  @override
  String get spkInstruction1 =>
      '1. First, add family members using \"Add Family Member\"';

  @override
  String get spkInstruction2 =>
      '2. Then tap \"Identify Speaker\" to recognize who\'s talking';

  @override
  String get spkInstruction3 => '3. The app will record for 3 seconds';

  @override
  String get feedbackCorrect => 'Correct';

  @override
  String get feedbackWrong => 'Wrong';

  @override
  String get feedbackDismiss => 'Dismiss (Don\'t show again)';

  @override
  String get feedbackTrain => 'Train This Sound';

  @override
  String get feedbackThanks => '✓ Thanks! I\'ll remember this';

  @override
  String get feedbackNoted => '✓ Noted! I\'ll improve';

  @override
  String get sosSentSuccess => '✓ SOS Sent!';

  @override
  String dashboardStatusSounds(Object count) {
    return '$count sounds';
  }

  @override
  String dashboardStatusTranscripts(Object count) {
    return '$count transcripts';
  }

  @override
  String get voiceProfileTitle => 'Voice Profiles';

  @override
  String get voiceProfileNameLabel => 'Person\'s Name';

  @override
  String get voiceProfileNameHint => 'e.g., Mom, Dad, John';

  @override
  String get voiceProfileRelationshipLabel => 'Relationship';

  @override
  String get voiceProfileCreateButton => 'Create Voice Profile';

  @override
  String get voiceProfileSavedTitle => 'Saved Profiles';

  @override
  String get voiceProfileAddAnother => 'Add Another Person';

  @override
  String get voiceProfileTraining => 'Training';

  @override
  String get voiceProfileProgress => 'Progress';

  @override
  String get voiceProfileEnrolled => 'Enrolled';

  @override
  String get voiceProfileReady => 'Ready';

  @override
  String get voiceProfilePending => 'Pending';

  @override
  String voiceProfileInstructions(Object name, Object seconds) {
    return 'Ask $name to speak naturally for $seconds seconds in a quiet environment.';
  }

  @override
  String get voiceProfileSuccess =>
      'Voice profile saved! This person can now be identified during live captions.';

  @override
  String get transcriptionTitle => 'Dhwani Live';

  @override
  String get transcriptionReady => 'Ready to listen';

  @override
  String get transcriptionListening => 'Listening now';

  @override
  String get transcriptionPrompt => 'Tap microphone to start';

  @override
  String get transcriptionRecent => 'Recent Captions';

  @override
  String get transcriptionClear => 'Clear';

  @override
  String get transcriptionEmpty => 'No captions yet';

  @override
  String get transcriptionMute => 'Mute';

  @override
  String get transcriptionSize => 'Size';

  @override
  String get transcriptionSave => 'Save';

  @override
  String get relMom => 'Mom';

  @override
  String get relDad => 'Dad';

  @override
  String get relSister => 'Sister';

  @override
  String get relBrother => 'Brother';

  @override
  String get relSpouse => 'Spouse';

  @override
  String get relChild => 'Child';

  @override
  String get relFriend => 'Friend';

  @override
  String get relColleague => 'Colleague';

  @override
  String get relDoctor => 'Doctor';

  @override
  String get relOther => 'Other';
}
