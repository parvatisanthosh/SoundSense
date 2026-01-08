import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/azure_chat_service.dart';

import '../../core/services/sound_intelligence_hub.dart';
import '../../shared/widgets/sound_sense_bottom_nav_bar.dart';

class ChatScreen extends StatefulWidget {
  final List<String> recentSounds;

  const ChatScreen({super.key, this.recentSounds = const []});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AzureChatService _chatService = AzureChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatService.updateRecentSounds(widget.recentSounds);

    _messages.add(ChatMessage(
      text:
          "Hi! 👋 I'm your SoundSense assistant powered by AI. I can help you understand sounds, answer questions about your environment, or just chat. How can I help you today?",
      isUser: false,
    ));
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final response = await _chatService.sendMessage(text);

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (widget.recentSounds.isNotEmpty) _buildSoundsBanner(),
            Expanded(child: _buildMessagesList()),
            _buildInputArea(),
            // Add Navbar
            SoundSenseBottomNavBar(
              currentIndex: 1, // Chat
              isListening: SoundIntelligenceHub().isListening,
              onMicTap: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              onTap: (index) {
                if (index == 0) { // Home
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                } else if (index == 2) { // Notifications
                  Navigator.pushNamed(context, '/notifications');
                } else if (index == 3) { // Settings
                  Navigator.pushNamed(context, '/settings');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child:
                const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: Theme.of(context).textTheme.headlineLarge),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online • Azure OpenAI',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearChat,
            icon: Icon(Icons.refresh_rounded, color: Theme.of(context).iconTheme.color),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hearing_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recent: ${widget.recentSounds.take(3).join(", ")}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index], index);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(AppTheme.radiusLG)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(AppTheme.radiusLG),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey),
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: message.isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey),
              ),
              child: Icon(Icons.person_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 18),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLG).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(delay: Duration(milliseconds: i * 200))
                    .then()
                    .fadeOut(delay: const Duration(milliseconds: 400)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                      color: Theme.of(context).inputDecorationTheme.enabledBorder?.borderSide.color 
                          ?? Colors.grey.withOpacity(0.3)
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear(); // ✅ FIXED: Clear messages first
      _chatService.clearHistory(); // Then clear service history
      _messages.add(ChatMessage(
        text:
            "Chat cleared! 🧹 I'm ready to help you with anything. What would you like to know?",
        isUser: false,
      ));
    });
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}