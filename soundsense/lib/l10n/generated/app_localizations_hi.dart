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

  @override
  String get chatWelcome =>
      'नमस्ते! 👋 मैं AI द्वारा संचालित आपका साउंडसेंस सहायक हूँ। मैं आपको ध्वनियों को समझने, आपके पर्यावरण के बारे में सवालों का जवाब देने, या बस चैट करने में मदद कर सकता हूँ। मैं आज आपकी क्या मदद कर सकता हूँ?';

  @override
  String get chatAiAssistant => 'AI सहायक';

  @override
  String get chatStatusOnline => 'ऑनलाइन • जेमिनी AI';

  @override
  String get chatRecent => 'हाल ही में:';

  @override
  String get chatInputHint => 'मुझसे कुछ भी पूछें...';

  @override
  String get chatCleared =>
      'चैट साफ़ की गई! 🧹 मैं आपकी किसी भी चीज़ में मदद करने के लिए तैयार हूँ। आप क्या जानना चाहेंगे?';

  @override
  String get notificationsTitle => 'सूचनाएं';

  @override
  String get notificationsEmpty => 'अभी कोई सूचना नहीं है';

  @override
  String get notificationTimeJustNow => 'अभी-अभी';

  @override
  String get notificationsSpeaker => 'वक्ता:';

  @override
  String get trainTitle => 'ध्वनि को सिखाएं';

  @override
  String get trainNewSound => 'एक नई आवाज़';

  @override
  String get trainIdentity => 'ध्वनि की पहचान';

  @override
  String get trainNameHint => 'उदा. माइक्रोवेव बीप';

  @override
  String get trainCategory => 'श्रेणी';

  @override
  String get trainCustomSounds => 'आपकी कस्टम आवाज़ें';

  @override
  String get trainStart => 'प्रशिक्षण शुरू करें';

  @override
  String get trainStep => 'चरण';

  @override
  String get trainRecordTitle => 'नमुना रिकॉर्ड करें';

  @override
  String get trainRecordSubtitle => 'ध्वनि का स्पष्ट ऑडियो कैप्चर करें।';

  @override
  String get trainReady => 'रिकॉर्ड करने के लिए तैयार';

  @override
  String get trainRecording => 'रिकॉर्डिंग...';

  @override
  String get trainRecord => 'रिकॉर्ड';

  @override
  String get trainUpload => 'अपलोड';

  @override
  String get trainListening => 'सुन रहा है';

  @override
  String get trainComplete => 'प्रशिक्षण पूरा हुआ! 🎉';

  @override
  String get trainDelete => 'क्या ध्वनि हटाएं?';

  @override
  String get trainDeleteConfirm => 'इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get trainCancel => 'रद्द करें';

  @override
  String get trainDeleteAction => 'हटाएं';

  @override
  String get sosTitle => 'आपातकालीन SOS';

  @override
  String get sosDescription =>
      'अपने स्थान के साथ अपने सभी संपर्कों को आपातकालीन अलर्ट भेजने के लिए नीचे दिए गए बटन को दबाएं।';

  @override
  String get sosSendButton => 'SOS अभी भेजें';

  @override
  String get sosContactsHeader => 'आपातकालीन संपर्क';

  @override
  String get sosNoContacts => 'कोई संपर्क नहीं जोड़ा गया';

  @override
  String get sosAddContactPrompt =>
      'SOS अलर्ट सक्षम करने के लिए आपातकालीन संपर्क जोड़ें। जब आप कोई आपातकालीन स्थिति ट्रिगर करेंगे तो उन्हें आपका स्थान प्राप्त होगा।';

  @override
  String get sosAddButton => 'संपर्क जोड़ें';

  @override
  String get sosHowItWorks => 'SOS कैसे काम करता है';

  @override
  String get sosStepSound =>
      'महत्वपूर्ण ध्वनियों (साायरन, अलार्म) पर स्वचालित ट्रिगर';

  @override
  String get sosStepLocation => 'आपका GPS स्थान भेजता है';

  @override
  String get sosStepSms => 'सभी आपातकालीन संपर्कों को SMS भेजा गया';

  @override
  String get sosStepCountdown => 'रद्द करने के लिए 10 सेकंड का लाउंटडाउन';

  @override
  String get sosAddContactTitle => 'आपातकालीन संपर्क जोड़ें';

  @override
  String get sosNameLabel => 'नाम';

  @override
  String get sosPhoneLabel => 'फ़ोन नंबर';

  @override
  String get sosRelationshipLabel => 'संबंध';

  @override
  String get sosAddContactAction => 'संपर्क जोड़ें';

  @override
  String get sosRemoveContactTitle => 'संपर्क हटाएं?';

  @override
  String sosRemoveContactConfirm(Object name) {
    return 'क्या आपातकालीन संपर्कों से $name को हटाएं?';
  }

  @override
  String get sosRemoveAction => 'हटाएं';

  @override
  String get settingsSubtitle => 'अपने अनुभव को कस्टमाइज़ करें';

  @override
  String get settingsSectionSleep => 'स्लीप गार्डियन';

  @override
  String get settingsSectionSound => 'ध्वनि पहचान';

  @override
  String get settingsSectionAlerts => 'अलर्ट और हैप्टिक्स';

  @override
  String get settingsSectionEmergency => 'आपातकालीन';

  @override
  String get settingsSectionGeneral => 'सामान्य';

  @override
  String get settingsAutoSleep => 'ऑटो स्लीप मोड';

  @override
  String get settingsAutoSleepDisabled => 'अक्षम';

  @override
  String settingsAutoSleepScheduled(Object schedule) {
    return 'निर्धारित: $schedule';
  }

  @override
  String get settingsActivateSleep => 'अब स्लीप मोड सक्रिय करें';

  @override
  String get settingsDeactivateSleep => 'स्लीप मोड को निष्क्रिय करें';

  @override
  String get settingsSleepModeActivated =>
      'स्लीप मोड मैन्युअल रूप से सक्रिय किया गया';

  @override
  String get settingsSchedule => 'अनुसूची';

  @override
  String get settingsSleepStart => 'सोने का समय';

  @override
  String get settingsWakeUp => 'जागने का समय';

  @override
  String get settingsActiveDetection => 'सक्रिय पहचान';

  @override
  String get settingsSensitivityLow => 'कम';

  @override
  String get settingsSensitivityHigh => 'उच्च';

  @override
  String get settingsHaptic => 'हैप्टिक फीडबैक';

  @override
  String get settingsHapticDesc => 'पहचान पर कंपन';

  @override
  String get settingsVoice => 'वॉयस अलर्ट (TTS)';

  @override
  String get settingsVoiceDesc => 'पहचानी गई आवाज़ें बोलें';

  @override
  String get settingsFlash => 'विजुअल फ्लैश';

  @override
  String get settingsFlashDesc => 'स्क्रीन फ्लैश अलर्ट';

  @override
  String get settingsEmergencyContacts => 'आपातकालीन संपर्क';

  @override
  String get settingsEmergencyContactsDesc => 'SOS संपर्कों को प्रबंधित करें';

  @override
  String get settingsOn => 'लागू';

  @override
  String get settingsOff => 'बंद';

  @override
  String get settingsReset => 'सेटिंग्स रीसेट करें';

  @override
  String get settingsResetDesc => 'डिफ़ॉल्ट सेटिंग्स पुनर्स्थापित करें';

  @override
  String get settingsResetConfirm =>
      'क्या आप सभी सेटिंग्स को डिफ़ॉल्ट पर रीसेट करना चाहते हैं?';

  @override
  String get settingsResetAction => 'रीसेट';

  @override
  String get settingsCancelAction => 'रद्द करें';

  @override
  String get settingsSelectLanguage => 'भाषा चुनें';

  @override
  String get settingsLanguageHindi => 'हिंदी';

  @override
  String get settingsLanguageEnglish => 'अंग्रेज़ी';

  @override
  String get settingsModeSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get settingsModeLight => 'लाइट मोड';

  @override
  String get settingsModeDark => 'डार्क मोड';

  @override
  String settingsSleepStartsIn(Object time) {
    return '$time में शुरू होगा';
  }

  @override
  String settingsSleepEndsIn(Object time) {
    return '$time में समाप्त होगा';
  }

  @override
  String get sosCountSeconds => 'SOS भेजे जाने तक सेकंड';

  @override
  String get sosDetectedSounds => 'पहचानी गई आवाज़ें';

  @override
  String get sosTapCancel => 'रद्द करने के लिए टैप करें';

  @override
  String get sosCancelQuote => 'मैं ठीक हूँ, अलर्ट रद्द करें';

  @override
  String get sosSentTitle => 'SOS भेज दिया गया';

  @override
  String get sosNotified => 'संपर्क(कों) को सूचित किया गया';

  @override
  String get sosSentMessage =>
      'आपके आपातकालीन संपर्कों को आपका स्थान भेज दिया गया है। मदद रास्ते में है।';

  @override
  String get sosSafe => 'मैं सुरक्षित हूँ';

  @override
  String get sosCallEmergency => 'आपातकालीन सेवाओं को कॉल करें (112)';

  @override
  String get dashboardManualSosTitle => 'मैनुअल SOS';

  @override
  String get dashboardManualSosContent =>
      'सभी संपर्कों को आपातकालीन अलर्ट भेजें?';

  @override
  String get dashboardManualSosAction => 'SOS भेजें';

  @override
  String get dashboardSleepGuardianTitle => 'स्लीप गार्डियन';

  @override
  String get dashboardSleepGuardianContent =>
      'स्लीप गार्डियन मोड सक्रिय करें?\n\nयह आपके सोते समय महत्वपूर्ण आवाज़ों की निगरानी करेगा।';

  @override
  String get dashboardSleepGuardianAction => 'सक्रिय करें';

  @override
  String get dashboardStopListeningFirst => '⚠️ पहले सुनना बंद करें';

  @override
  String get spkTitle => 'वक्ता की पहचान';

  @override
  String get spkServerUnavailable => 'सर्वर उपलब्ध नहीं है';

  @override
  String get spkMicDenied => 'माइक्रोफ़ोन अनुमति अस्वीकृत';

  @override
  String get spkUnknown => 'अज्ञात';

  @override
  String get spkUnknownSpeaker => 'अज्ञात वक्ता';

  @override
  String get spkFailed => 'पहचान विफल रही';

  @override
  String get spkConnectError => 'सर्वर से कनेक्ट नहीं हो सकता';

  @override
  String get spkRetry => 'पुनः प्रयास करें';

  @override
  String get spkIdentify => 'वक्ता को पहचानें';

  @override
  String get spkRecording => 'रिकॉर्डिंग (4s)...';

  @override
  String get spkAddMember => 'परिवार के सदस्य को जोड़ें';

  @override
  String get spkHowTo => 'उपयोग कैसे करें:';

  @override
  String get spkInstruction1 =>
      '1. सबसे पहले, \"परिवार के सदस्य को जोड़ें\" का उपयोग करके परिवार के सदस्यों को जोड़ें';

  @override
  String get spkInstruction2 =>
      '2. फिर यह पहचानने के लिए \"वक्ता को पहचानें\" टैप करें कि कौन बात कर रहा है';

  @override
  String get spkInstruction3 => '3. ऐप 3 सेकंड के लिए रिकॉर्ड करेगा';

  @override
  String get feedbackCorrect => 'सही';

  @override
  String get feedbackWrong => 'गलत';

  @override
  String get feedbackDismiss => 'खारिज करें (फिर न दिखाएं)';

  @override
  String get feedbackTrain => 'इस ध्वनि को सिखाएं';

  @override
  String get feedbackThanks => '✓ धन्यवाद! मैं इसे याद रखूंगा';

  @override
  String get feedbackNoted => '✓ नोट किया गया! मैं सुधार करूंगा';

  @override
  String get sosSentSuccess => '✓ SOS भेजा गया!';

  @override
  String dashboardStatusSounds(Object count) {
    return '$count आवाज़ें';
  }

  @override
  String dashboardStatusTranscripts(Object count) {
    return '$count लिप्यंतरण';
  }

  @override
  String get voiceProfileTitle => 'आवाज़ प्रोफाइल';

  @override
  String get voiceProfileNameLabel => 'व्यक्ति का नाम';

  @override
  String get voiceProfileNameHint => 'उदा. माँ, पिताजी, राहुल';

  @override
  String get voiceProfileRelationshipLabel => 'रिश्ता';

  @override
  String get voiceProfileCreateButton => 'वॉयस प्रोफाइल बनाएं';

  @override
  String get voiceProfileSavedTitle => 'सहेजे गए प्रोफाइल';

  @override
  String get voiceProfileAddAnother => 'एक और व्यक्ति जोड़ें';

  @override
  String get voiceProfileTraining => 'प्रशिक्षण';

  @override
  String get voiceProfileProgress => 'प्रगति';

  @override
  String get voiceProfileEnrolled => 'नामांकित';

  @override
  String get voiceProfileReady => 'तैयार';

  @override
  String get voiceProfilePending => 'लंबित';

  @override
  String voiceProfileInstructions(Object name, Object seconds) {
    return '$name से शांत वातावरण में $seconds सेकंड के लिए स्वाभाविक रूप से बोलने को कहें।';
  }

  @override
  String get voiceProfileSuccess =>
      'वॉयस प्रोफाइल सहेजा गया! अब इस व्यक्ति को लाइव कैप्शन के दौरान पहचाना जा सकता है।';

  @override
  String get transcriptionTitle => 'ध्वनि लाइव';

  @override
  String get transcriptionReady => 'सुनने के लिए तैयार';

  @override
  String get transcriptionListening => 'अब सुन रहा है';

  @override
  String get transcriptionPrompt => 'शुरू करने के लिए माइक्रोफोन टैप करें';

  @override
  String get transcriptionRecent => 'हाल के कैप्शन';

  @override
  String get transcriptionClear => 'साफ़ करें';

  @override
  String get transcriptionEmpty => 'अभी तक कोई कैप्शन नहीं';

  @override
  String get transcriptionMute => 'म्यूट';

  @override
  String get transcriptionSize => 'आकार';

  @override
  String get transcriptionSave => 'सहेजें';

  @override
  String get relMom => 'माँ';

  @override
  String get relDad => 'पिताजी';

  @override
  String get relSister => 'बहन';

  @override
  String get relBrother => 'भाई';

  @override
  String get relSpouse => 'जीवनसाथी';

  @override
  String get relChild => 'बच्चा';

  @override
  String get relFriend => 'मित्र';

  @override
  String get relColleague => 'सहकर्मी';

  @override
  String get relDoctor => 'डॉक्टर';

  @override
  String get relOther => 'अन्य';
}
