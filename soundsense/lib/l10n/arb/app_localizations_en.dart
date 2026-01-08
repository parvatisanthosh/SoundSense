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
}
