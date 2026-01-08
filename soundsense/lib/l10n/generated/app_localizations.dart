import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhwani'**
  String get appTitle;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get dashboardGreeting;

  /// No description provided for @dashboardListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get dashboardListening;

  /// No description provided for @dashboardListeningPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap microphone to start'**
  String get dashboardListeningPrompt;

  /// No description provided for @dashboardPartialListeningPrompt.
  ///
  /// In en, this message translates to:
  /// **'Listening for sounds and speech...'**
  String get dashboardPartialListeningPrompt;

  /// No description provided for @recentSpeech.
  ///
  /// In en, this message translates to:
  /// **'Recent Speech'**
  String get recentSpeech;

  /// No description provided for @detectedSounds.
  ///
  /// In en, this message translates to:
  /// **'Detected Sounds'**
  String get detectedSounds;

  /// No description provided for @quickActionCaptions.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get quickActionCaptions;

  /// No description provided for @quickActionSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get quickActionSpeaker;

  /// No description provided for @quickActionTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get quickActionTrain;

  /// No description provided for @quickActionVoices.
  ///
  /// In en, this message translates to:
  /// **'Voices'**
  String get quickActionVoices;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @chatWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi! 👋 I\'m your SoundSense assistant powered by AI. I can help you understand sounds, answer questions about your environment, or just chat. How can I help you today?'**
  String get chatWelcome;

  /// No description provided for @chatAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get chatAiAssistant;

  /// No description provided for @chatStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online • Gemini AI'**
  String get chatStatusOnline;

  /// No description provided for @chatRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent:'**
  String get chatRecent;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get chatInputHint;

  /// No description provided for @chatCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat cleared! 🧹 I\'m ready to help you with anything. What would you like to know?'**
  String get chatCleared;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationTimeJustNow;

  /// No description provided for @notificationsSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker:'**
  String get notificationsSpeaker;

  /// No description provided for @trainTitle.
  ///
  /// In en, this message translates to:
  /// **'Teach Dhwani'**
  String get trainTitle;

  /// No description provided for @trainNewSound.
  ///
  /// In en, this message translates to:
  /// **'a new sound'**
  String get trainNewSound;

  /// No description provided for @trainIdentity.
  ///
  /// In en, this message translates to:
  /// **'SOUND IDENTITY'**
  String get trainIdentity;

  /// No description provided for @trainNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Microwave Beep'**
  String get trainNameHint;

  /// No description provided for @trainCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get trainCategory;

  /// No description provided for @trainCustomSounds.
  ///
  /// In en, this message translates to:
  /// **'Your Custom Sounds'**
  String get trainCustomSounds;

  /// No description provided for @trainStart.
  ///
  /// In en, this message translates to:
  /// **'Start Training'**
  String get trainStart;

  /// No description provided for @trainStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get trainStep;

  /// No description provided for @trainRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Sample'**
  String get trainRecordTitle;

  /// No description provided for @trainRecordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture clear audio of the sound.'**
  String get trainRecordSubtitle;

  /// No description provided for @trainReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to record'**
  String get trainReady;

  /// No description provided for @trainRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get trainRecording;

  /// No description provided for @trainRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get trainRecord;

  /// No description provided for @trainUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get trainUpload;

  /// No description provided for @trainListening.
  ///
  /// In en, this message translates to:
  /// **'LISTENING'**
  String get trainListening;

  /// No description provided for @trainComplete.
  ///
  /// In en, this message translates to:
  /// **'Training complete! 🎉'**
  String get trainComplete;

  /// No description provided for @trainDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Sound?'**
  String get trainDelete;

  /// No description provided for @trainDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get trainDeleteConfirm;

  /// No description provided for @trainCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trainCancel;

  /// No description provided for @trainDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get trainDeleteAction;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get sosTitle;

  /// No description provided for @sosDescription.
  ///
  /// In en, this message translates to:
  /// **'Press the button below to send an emergency alert to all your contacts with your location.'**
  String get sosDescription;

  /// No description provided for @sosSendButton.
  ///
  /// In en, this message translates to:
  /// **'SEND SOS NOW'**
  String get sosSendButton;

  /// No description provided for @sosContactsHeader.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get sosContactsHeader;

  /// No description provided for @sosNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No Contacts Added'**
  String get sosNoContacts;

  /// No description provided for @sosAddContactPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contacts to enable SOS alerts. They will receive your location when you trigger an emergency.'**
  String get sosAddContactPrompt;

  /// No description provided for @sosAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get sosAddButton;

  /// No description provided for @sosHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How SOS Works'**
  String get sosHowItWorks;

  /// No description provided for @sosStepSound.
  ///
  /// In en, this message translates to:
  /// **'Automatic trigger on critical sounds (siren, alarm)'**
  String get sosStepSound;

  /// No description provided for @sosStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Sends your GPS location'**
  String get sosStepLocation;

  /// No description provided for @sosStepSms.
  ///
  /// In en, this message translates to:
  /// **'SMS sent to all emergency contacts'**
  String get sosStepSms;

  /// No description provided for @sosStepCountdown.
  ///
  /// In en, this message translates to:
  /// **'10 second countdown to cancel'**
  String get sosStepCountdown;

  /// No description provided for @sosAddContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get sosAddContactTitle;

  /// No description provided for @sosNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sosNameLabel;

  /// No description provided for @sosPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get sosPhoneLabel;

  /// No description provided for @sosRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get sosRelationshipLabel;

  /// No description provided for @sosAddContactAction.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get sosAddContactAction;

  /// No description provided for @sosRemoveContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Contact?'**
  String get sosRemoveContactTitle;

  /// No description provided for @sosRemoveContactConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from emergency contacts?'**
  String sosRemoveContactConfirm(Object name);

  /// No description provided for @sosRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sosRemoveAction;

  /// No description provided for @sosCountSeconds.
  ///
  /// In en, this message translates to:
  /// **'seconds until SOS is sent'**
  String get sosCountSeconds;

  /// No description provided for @sosDetectedSounds.
  ///
  /// In en, this message translates to:
  /// **'Detected Sounds'**
  String get sosDetectedSounds;

  /// No description provided for @sosTapCancel.
  ///
  /// In en, this message translates to:
  /// **'TAP TO CANCEL'**
  String get sosTapCancel;

  /// No description provided for @sosCancelQuote.
  ///
  /// In en, this message translates to:
  /// **'I\'m okay, cancel the alert'**
  String get sosCancelQuote;

  /// No description provided for @sosSentTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS SENT'**
  String get sosSentTitle;

  /// No description provided for @sosNotified.
  ///
  /// In en, this message translates to:
  /// **'contact(s) notified'**
  String get sosNotified;

  /// No description provided for @sosSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Your emergency contacts have been sent your location. Help is on the way.'**
  String get sosSentMessage;

  /// No description provided for @sosSafe.
  ///
  /// In en, this message translates to:
  /// **'I AM SAFE'**
  String get sosSafe;

  /// No description provided for @sosCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency Services (112)'**
  String get sosCallEmergency;

  /// No description provided for @spkTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaker Recognition'**
  String get spkTitle;

  /// No description provided for @spkServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server not available'**
  String get spkServerUnavailable;

  /// No description provided for @spkMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get spkMicDenied;

  /// No description provided for @spkUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get spkUnknown;

  /// No description provided for @spkUnknownSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Unknown speaker'**
  String get spkUnknownSpeaker;

  /// No description provided for @spkFailed.
  ///
  /// In en, this message translates to:
  /// **'Recognition failed'**
  String get spkFailed;

  /// No description provided for @spkConnectError.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get spkConnectError;

  /// No description provided for @spkRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get spkRetry;

  /// No description provided for @spkIdentify.
  ///
  /// In en, this message translates to:
  /// **'Identify Speaker'**
  String get spkIdentify;

  /// No description provided for @spkRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording (4s)...'**
  String get spkRecording;

  /// No description provided for @spkAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get spkAddMember;

  /// No description provided for @spkHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to use:'**
  String get spkHowTo;

  /// No description provided for @spkInstruction1.
  ///
  /// In en, this message translates to:
  /// **'1. First, add family members using \"Add Family Member\"'**
  String get spkInstruction1;

  /// No description provided for @spkInstruction2.
  ///
  /// In en, this message translates to:
  /// **'2. Then tap \"Identify Speaker\" to recognize who\'s talking'**
  String get spkInstruction2;

  /// No description provided for @spkInstruction3.
  ///
  /// In en, this message translates to:
  /// **'3. The app will record for 3 seconds'**
  String get spkInstruction3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
