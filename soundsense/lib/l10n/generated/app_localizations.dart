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
  /// **'Online • Azure AI'**
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

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Improve sound detection'**
  String get notificationsSubtitle;

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

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get settingsSubtitle;

  /// No description provided for @settingsSectionSleep.
  ///
  /// In en, this message translates to:
  /// **'SLEEP GUARDIAN'**
  String get settingsSectionSleep;

  /// No description provided for @settingsSectionSound.
  ///
  /// In en, this message translates to:
  /// **'SOUND DETECTION'**
  String get settingsSectionSound;

  /// No description provided for @settingsSectionAlerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS & HAPTICS'**
  String get settingsSectionAlerts;

  /// No description provided for @settingsSectionEmergency.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get settingsSectionEmergency;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsAutoSleep.
  ///
  /// In en, this message translates to:
  /// **'Auto Sleep Mode'**
  String get settingsAutoSleep;

  /// No description provided for @settingsAutoSleepDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsAutoSleepDisabled;

  /// No description provided for @settingsAutoSleepScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {schedule}'**
  String settingsAutoSleepScheduled(Object schedule);

  /// No description provided for @settingsActivateSleep.
  ///
  /// In en, this message translates to:
  /// **'Activate Sleep Mode Now'**
  String get settingsActivateSleep;

  /// No description provided for @settingsDeactivateSleep.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Sleep Mode'**
  String get settingsDeactivateSleep;

  /// No description provided for @settingsSleepModeActivated.
  ///
  /// In en, this message translates to:
  /// **'Sleep mode activated manually'**
  String get settingsSleepModeActivated;

  /// No description provided for @settingsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get settingsSchedule;

  /// No description provided for @settingsSleepStart.
  ///
  /// In en, this message translates to:
  /// **'Sleep Start'**
  String get settingsSleepStart;

  /// No description provided for @settingsWakeUp.
  ///
  /// In en, this message translates to:
  /// **'Wake Up'**
  String get settingsWakeUp;

  /// No description provided for @settingsActiveDetection.
  ///
  /// In en, this message translates to:
  /// **'Active Detection'**
  String get settingsActiveDetection;

  /// No description provided for @settingsSensitivityLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get settingsSensitivityLow;

  /// No description provided for @settingsSensitivityHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get settingsSensitivityHigh;

  /// No description provided for @settingsHaptic.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get settingsHaptic;

  /// No description provided for @settingsHapticDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on detection'**
  String get settingsHapticDesc;

  /// No description provided for @settingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice Alerts (TTS)'**
  String get settingsVoice;

  /// No description provided for @settingsVoiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Speak detected sounds'**
  String get settingsVoiceDesc;

  /// No description provided for @settingsFlash.
  ///
  /// In en, this message translates to:
  /// **'Visual Flash'**
  String get settingsFlash;

  /// No description provided for @settingsFlashDesc.
  ///
  /// In en, this message translates to:
  /// **'Screen flash alerts'**
  String get settingsFlashDesc;

  /// No description provided for @settingsEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get settingsEmergencyContacts;

  /// No description provided for @settingsEmergencyContactsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage SOS contacts'**
  String get settingsEmergencyContactsDesc;

  /// No description provided for @settingsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get settingsReset;

  /// No description provided for @settingsResetDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore default settings'**
  String get settingsResetDesc;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to default?'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetAction;

  /// No description provided for @settingsCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancelAction;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsLanguageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get settingsLanguageHindi;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsModeSystem;

  /// No description provided for @settingsModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get settingsModeLight;

  /// No description provided for @settingsModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsModeDark;

  /// No description provided for @settingsSleepStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String settingsSleepStartsIn(Object time);

  /// No description provided for @settingsSleepEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {time}'**
  String settingsSleepEndsIn(Object time);

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

  /// No description provided for @dashboardManualSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual SOS'**
  String get dashboardManualSosTitle;

  /// No description provided for @dashboardManualSosContent.
  ///
  /// In en, this message translates to:
  /// **'Send emergency alert to all contacts?'**
  String get dashboardManualSosContent;

  /// No description provided for @dashboardManualSosAction.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get dashboardManualSosAction;

  /// No description provided for @dashboardSleepGuardianTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Guardian'**
  String get dashboardSleepGuardianTitle;

  /// No description provided for @dashboardSleepGuardianContent.
  ///
  /// In en, this message translates to:
  /// **'Activate Sleep Guardian mode?\n\nThis will monitor for critical sounds while you sleep.'**
  String get dashboardSleepGuardianContent;

  /// No description provided for @dashboardSleepGuardianAction.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get dashboardSleepGuardianAction;

  /// No description provided for @dashboardStopListeningFirst.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Stop listening first'**
  String get dashboardStopListeningFirst;

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

  /// No description provided for @feedbackCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get feedbackCorrect;

  /// No description provided for @feedbackWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get feedbackWrong;

  /// No description provided for @feedbackDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss (Don\'t show again)'**
  String get feedbackDismiss;

  /// No description provided for @feedbackTrain.
  ///
  /// In en, this message translates to:
  /// **'Train This Sound'**
  String get feedbackTrain;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'✓ Thanks! I\'ll remember this'**
  String get feedbackThanks;

  /// No description provided for @feedbackNoted.
  ///
  /// In en, this message translates to:
  /// **'✓ Noted! I\'ll improve'**
  String get feedbackNoted;

  /// No description provided for @sosSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'✓ SOS Sent!'**
  String get sosSentSuccess;

  /// No description provided for @dashboardStatusSounds.
  ///
  /// In en, this message translates to:
  /// **'{count} sounds'**
  String dashboardStatusSounds(Object count);

  /// No description provided for @dashboardStatusTranscripts.
  ///
  /// In en, this message translates to:
  /// **'{count} transcripts'**
  String dashboardStatusTranscripts(Object count);

  /// No description provided for @voiceProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Profiles'**
  String get voiceProfileTitle;

  /// No description provided for @voiceProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Person\'s Name'**
  String get voiceProfileNameLabel;

  /// No description provided for @voiceProfileNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mom, Dad, John'**
  String get voiceProfileNameHint;

  /// No description provided for @voiceProfileRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get voiceProfileRelationshipLabel;

  /// No description provided for @voiceProfileCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Voice Profile'**
  String get voiceProfileCreateButton;

  /// No description provided for @voiceProfileSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Profiles'**
  String get voiceProfileSavedTitle;

  /// No description provided for @voiceProfileAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add Another Person'**
  String get voiceProfileAddAnother;

  /// No description provided for @voiceProfileTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get voiceProfileTraining;

  /// No description provided for @voiceProfileProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get voiceProfileProgress;

  /// No description provided for @voiceProfileEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get voiceProfileEnrolled;

  /// No description provided for @voiceProfileReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get voiceProfileReady;

  /// No description provided for @voiceProfilePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get voiceProfilePending;

  /// No description provided for @voiceProfileInstructions.
  ///
  /// In en, this message translates to:
  /// **'Ask {name} to speak naturally for {seconds} seconds in a quiet environment.'**
  String voiceProfileInstructions(Object name, Object seconds);

  /// No description provided for @voiceProfileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Voice profile saved! This person can now be identified during live captions.'**
  String get voiceProfileSuccess;

  /// No description provided for @transcriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhwani Live'**
  String get transcriptionTitle;

  /// No description provided for @transcriptionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to listen'**
  String get transcriptionReady;

  /// No description provided for @transcriptionListening.
  ///
  /// In en, this message translates to:
  /// **'Listening now'**
  String get transcriptionListening;

  /// No description provided for @transcriptionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap microphone to start'**
  String get transcriptionPrompt;

  /// No description provided for @transcriptionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent Captions'**
  String get transcriptionRecent;

  /// No description provided for @transcriptionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get transcriptionClear;

  /// No description provided for @transcriptionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No captions yet'**
  String get transcriptionEmpty;

  /// No description provided for @transcriptionMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get transcriptionMute;

  /// No description provided for @transcriptionSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get transcriptionSize;

  /// No description provided for @transcriptionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transcriptionSave;

  /// No description provided for @relMom.
  ///
  /// In en, this message translates to:
  /// **'Mom'**
  String get relMom;

  /// No description provided for @relDad.
  ///
  /// In en, this message translates to:
  /// **'Dad'**
  String get relDad;

  /// No description provided for @relSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relSister;

  /// No description provided for @relBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relBrother;

  /// No description provided for @relSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relSpouse;

  /// No description provided for @relChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relChild;

  /// No description provided for @relFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relFriend;

  /// No description provided for @relColleague.
  ///
  /// In en, this message translates to:
  /// **'Colleague'**
  String get relColleague;

  /// No description provided for @relDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get relDoctor;

  /// No description provided for @relOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relOther;
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
