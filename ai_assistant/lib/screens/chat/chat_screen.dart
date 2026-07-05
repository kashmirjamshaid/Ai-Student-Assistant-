import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/bookmark.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    final storage = Provider.of<StorageService>(context, listen: false);
    setState(() {
      _messages = storage.getChatHistory();
      
      // Load which message timestamps are bookmarked
      final bookmarks = storage.getBookmarks();
      _bookmarkedIds = bookmarks
          .where((b) => b.type == 'chat')
          .map((b) => b.id)
          .toSet();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    FocusScope.of(context).unfocus();

    await _sendMessageToGemini(text);
  }

  Future<void> _sendMessageToGemini(String userQuery, {bool addToChat = true}) async {
    final storage = Provider.of<StorageService>(context, listen: false);

    if (addToChat) {
      final userMessage = ChatMessage(
        sender: 'user',
        text: userQuery,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(userMessage);
        _isLoading = true;
      });
      _scrollToBottom();
      
      // Save current chat history to storage
      await storage.saveChatHistory(_messages);
    } else {
      setState(() {
        _isLoading = true;
      });
      _scrollToBottom();
    }

    // Call Gemini
    final aiResponse = await _geminiService.generateResponse(userQuery, _messages);

    final aiMessage = ChatMessage(
      sender: 'ai',
      text: aiResponse,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      _scrollToBottom();
      
      // Save updated chat history
      await storage.saveChatHistory(_messages);
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Chat?"),
        content: const Text("This will delete all messages in this conversation. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final storage = Provider.of<StorageService>(context, listen: false);
      await storage.clearChatHistory();
      setState(() {
        _messages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat history cleared")),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Response copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _bookmarkResponse(ChatMessage aiMessage) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final id = aiMessage.timestamp.toIso8601String();

    if (_bookmarkedIds.contains(id)) {
      // Unbookmark
      await storage.deleteBookmark(id);
      setState(() {
        _bookmarkedIds.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bookmark removed")),
      );
    } else {
      // Find the question corresponding to this answer (the user message right before it)
      int aiIndex = _messages.indexOf(aiMessage);
      String title = "AI Study Notes";
      if (aiIndex > 0) {
        title = _messages[aiIndex - 1].text;
        // Limit title length for display
        if (title.length > 50) {
          title = "${title.substring(0, 47)}...";
        }
      }

      final bookmark = Bookmark(
        id: id,
        type: 'chat',
        title: title,
        content: aiMessage.text,
        timestamp: aiMessage.timestamp,
      );

      await storage.saveBookmark(bookmark);
      setState(() {
        _bookmarkedIds.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved to Bookmarks")),
      );
    }
  }

  void _regenerateResponse(ChatMessage aiMessage) {
    int index = _messages.indexOf(aiMessage);
    if (index > 0) {
      final lastUserMessage = _messages[index - 1];
      setState(() {
        // Remove the AI message from list
        _messages.removeAt(index);
      });
      // Trigger new generation
      _sendMessageToGemini(lastUserMessage.text, addToChat: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Study Assistant",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Powered by Gemini",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: "Clear Chat",
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Message list or Empty state
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return const TypingIndicator();
                      }
                      
                      final msg = _messages[index];
                      final isBookmarked = _bookmarkedIds.contains(msg.timestamp.toIso8601String());

                      return ChatBubble(
                        message: msg,
                        isBookmarked: isBookmarked,
                        onCopy: () => _copyToClipboard(msg.text),
                        onBookmark: () => _bookmarkResponse(msg),
                        onRegenerate: msg.isAi ? () => _regenerateResponse(msg) : null,
                      );
                    },
                  ),
          ),

          // Divider
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: theme.scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(28.0),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Ask any topic...",
                              hintStyle: TextStyle(fontSize: 14.0),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 56.0,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              "How can I help you study?",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              "Explain topics in plain language, make bullet summaries, key points, memory tricks and more.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28.0),
            // Prompt suggestion chips
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip("Explain Photosynthesis"),
                _buildSuggestionChip("Newton's Laws of Motion"),
                _buildSuggestionChip("How does a database transaction work?"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.0,
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
      onPressed: () {
        _inputController.text = label;
      },
    );
  }
}

// Typing Indicator Dot Blinking Animation Widget
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8.0, top: 4.0),
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16.0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(4.0),
                bottomRight: Radius.circular(20.0),
              ),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.05),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final val = (sin((_controller.value * 2 * pi) - (delay * 2 * pi)) + 1) / 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.3 + 0.7 * val),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
