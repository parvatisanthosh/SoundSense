import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AzureChatService {
  // 🔧 Azure OpenAI Configuration
 static String get _endpoint => dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? '';
  static String get _apiKey => dotenv.env['AZURE_OPENAI_KEY'] ?? '';
  static String get _deploymentName => dotenv.env['AZURE_OPENAI_DEPLOYMENT'] ?? 'gpt-4o-mini';
  static const String _apiVersion = '2024-02-15-preview';

  final List<Map<String, String>> _conversationHistory = [];
  List<String> _recentSounds = [];

  /// Update recent sounds context
  void updateRecentSounds(List<String> sounds) {
    _recentSounds = sounds;
    debugPrint('🔊 Updated recent sounds: ${sounds.length} items');
  }

  /// Send a message and get AI response
  Future<String> sendMessage(String userMessage) async {
    debugPrint('💬 Sending message: $userMessage');
    
    try {
      // Add user message to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // Build system prompt with context
      final systemPrompt = _buildSystemPrompt();

      // Prepare messages array for API
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ..._conversationHistory,
      ];

      // Build API URL
      final url = Uri.parse(
        '$_endpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
      );

      debugPrint('🌐 Calling Azure OpenAI API...');

      // Make API request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': _apiKey,
        },
      body: jsonEncode({
  'messages': messages,
  'max_completion_tokens': 800,
}),

      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;

        debugPrint('✅ Got response: ${assistantMessage.substring(0, assistantMessage.length > 50 ? 50 : assistantMessage.length)}...');

        // Add assistant response to history
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });

        // Keep only last 10 exchanges (20 messages) to avoid token limits
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }

        return assistantMessage;
        
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed - check API key');
        return 'Sorry, there\'s an authentication issue. Please check the API configuration.';
        
      } else if (response.statusCode == 404) {
        debugPrint('❌ Deployment not found - check deployment name');
        return 'Sorry, the AI model deployment wasn\'t found. Please check the configuration.';
        
      } else if (response.statusCode == 429) {
        debugPrint('❌ Rate limit exceeded');
        return 'Sorry, I\'m getting too many requests right now. Please try again in a moment.';
        
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        debugPrint('❌ HTTP ${response.statusCode}: $errorMessage');
        return 'Sorry, I encountered an error: $errorMessage';
      }
      
    } on http.ClientException catch (e) {
      debugPrint('❌ Network error: $e');
      return 'Sorry, I couldn\'t connect to the server. Please check your internet connection.';
      
    } on FormatException catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      return 'Sorry, I received an unexpected response from the server.';
      
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return 'Sorry, something went wrong. Please try again.';
    }
  }

  /// Build system prompt with context
  String _buildSystemPrompt() {
    String prompt = '''You are a helpful AI assistant for Dhwani, an app designed to help deaf and hard-of-hearing users understand their sound environment.

Your role is to:
- Help users understand sounds they've detected
- Answer questions about their environment and safety
- Provide clear, concise explanations about sounds
- Be empathetic, supportive, and patient
- Use simple language and avoid technical jargon
- Prioritize safety-related information

Guidelines:
- Keep responses conversational and friendly
- If discussing emergency sounds (fire alarms, sirens), emphasize safety
- Be encouraging and positive
- Avoid overly long responses unless necessary''';

    // Add recent sounds context if available
    if (_recentSounds.isNotEmpty) {
      prompt += '\n\nRecent sounds detected by the user: ${_recentSounds.take(5).join(", ")}';
      prompt += '\nYou can reference these sounds when relevant to provide context-aware help.';
    }

    return prompt;
  }

  /// Clear conversation history
  void clearHistory() {
    debugPrint('🧹 Clearing conversation history');
    _conversationHistory.clear();
  }

  /// Get conversation length
  int get conversationLength => _conversationHistory.length;
}