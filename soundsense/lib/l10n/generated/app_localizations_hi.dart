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
}
