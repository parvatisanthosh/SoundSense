// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'ध्वनि';

  @override
  String get dashboardGreeting => 'तैयार';

  @override
  String get dashboardListening => 'सुनाई दे रहा है';

  @override
  String get dashboardListeningPrompt => 'शुरू करने के लिए माइक्रोफोन टैप करें';

  @override
  String get dashboardPartialListeningPrompt => 'आवाज़ें और भाषण सुन रहा है...';

  @override
  String get recentSpeech => 'हाल की बातचीत';

  @override
  String get detectedSounds => 'पहचानी गई आवाज़ें';

  @override
  String get quickActionCaptions => 'कैप्शन';

  @override
  String get quickActionSpeaker => 'वक्ता';

  @override
  String get quickActionTrain => 'सिखाएं';

  @override
  String get quickActionVoices => 'आवाज़ें';

  @override
  String get navHome => 'होम';

  @override
  String get navChat => 'चैट';

  @override
  String get navAlerts => 'अलर्ट';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsDarkMode => 'डार्क मोड';
}
