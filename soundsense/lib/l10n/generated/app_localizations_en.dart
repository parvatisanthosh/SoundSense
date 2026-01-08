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
}
