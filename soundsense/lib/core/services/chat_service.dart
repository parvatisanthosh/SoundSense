import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Replace with your API key
  static const String _apiKey = 'AIzaSyA9E5q63mvxDPCVCIuaYQL3HRMudz34Knc';
  static const String _baseUrl =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';


  // Store recent sounds for context
  List<String> _recentSounds = [];

  void updateRecentSounds(List<String> sounds) {
    _recentSounds = sounds.take(5).toList();
  }

 Future<String> sendMessage(String userMessage) async {
  try {
    // Build context about recent sounds
    String soundContext = '';
    if (_recentSounds.isNotEmpty) {
      soundContext = '''
DETECTED SOUNDS NEARBY:
${_recentSounds.map((s) => "- $s").join("\n")}

Use this information to help the user understand their environment.
''';
    }

    // System prompt for SoundSense assistant
    final systemPrompt = '''
You are SoundSense Assistant, a specialized AI for deaf and hard-of-hearing users.

USER CONTEXT:
- The user is DEAF or hard-of-hearing
- They are using SoundSense app which detects sounds around them
- They CANNOT hear sounds, so describe what sounds mean and imply
- They need help understanding their sound environment

$soundContext

YOUR RESPONSIBILITIES:
1. Explain what detected sounds mean (e.g., "Car horn usually means a vehicle is warning you")
2. Provide SAFETY advice (e.g., "Siren detected - emergency vehicle nearby, move aside")
3. Describe sound patterns (e.g., "Doorbell means someone is at your door")
4. Be supportive and never assume they can hear anything
5. If asked about a sound, explain what it typically indicates

RESPONSE RULES:
- Keep responses SHORT (2-3 sentences)
- Be DIRECT and helpful
- Focus on SAFETY first
- Use simple, clear language
''';

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '$systemPrompt\n\nUser message: $userMessage'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 300,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      return 'Sorry, I could not process your request. Please try again.';
    }
  } catch (e) {
    print('Chat error: $e');
    return 'Sorry, something went wrong. Please check your internet connection.';
  }
}
}