import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get azureSpeechApiKey => dotenv.env['AZURE_SPEECH_KEY'] ?? '';
  static String get azureSpeechRegion => dotenv.env['AZURE_SPEECH_REGION'] ?? '';
}