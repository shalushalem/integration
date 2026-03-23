import 'package:flutter/material.dart';
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/services/backend_service.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final List<dynamic> chips;
  final String? boardId;
  final String? packId;

  ChatMessage({
    required this.text,
    required this.isMe,
    this.chips = const [],
    this.boardId,
    this.packId,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  List<Map<String, dynamic>> _localWardrobeCache = [];

  String _runningMemory = '';
  bool _isTyping = false;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _fetchLocalWardrobe();
    _messages.add(
      ChatMessage(
        text: "Hi! I'm AHVI. How can I help you style or plan your day?",
        isMe: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    final user = await appwrite.getCurrentUser();

    if (user != null && mounted) {
      setState(() {
        _userName = user.name.isNotEmpty ? user.name.split(' ').first : 'Stylist';
      });
    }
  }

  Future<void> _fetchLocalWardrobe() async {
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    final items = await appwrite.getWardrobeItems();
    if (mounted) setState(() => _localWardrobeCache = items);
  }

  Future<void> _sendMessage([String? chipText]) async {
    final text = chipText ?? _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
      _chatHistory.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final backend = Provider.of<BackendService>(context, listen: false);
      final response = await backend.sendChatQuery(
        text,
        'user_$_userName',
        List<Map<String, String>>.from(_chatHistory),
        _runningMemory,
      );

      if (!mounted) return;

      if (response['error'] != null) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: "Couldn't connect right now. Please try again.",
              isMe: false,
            ),
          );
        });
        _scrollToBottom();
        return;
      }

      if (response['updated_memory'] != null) {
        _runningMemory = response['updated_memory'].toString();
      }

      final aiText = response['message']?['content']?.toString() ??
          "I'm having trouble connecting.";
      _chatHistory.add({'role': 'assistant', 'content': aiText});

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: aiText,
            isMe: false,
            chips: response['chips'] ?? [],
            boardId: response['board_ids'],
            packId: response['pack_ids'],
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: 'Network issue detected. Please try again.',
            isMe: false,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 150,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildInlineStyleBoard(String boardIds, AppThemeTokens t) {
    if (boardIds.isEmpty) return const SizedBox();

    final ids = boardIds.split(',').map((e) => e.trim()).toList();
    final boardItems =
        _localWardrobeCache.where((item) => ids.contains(item['id'])).toList();

    if (boardItems.isEmpty) return const SizedBox();

    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: boardItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = boardItems[index];
          return Container(
            width: 90,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 90,
                  child: Image.network(
                    item['image_url'] ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: t.accent.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.image, color: t.mutedText),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Item',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['category'] ?? '',
                        style: TextStyle(color: t.mutedText, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;

    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: t.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: t.textPrimary),
        title: Text(
          'AHVI',
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, t);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'AHVI is typing...',
                    style: TextStyle(color: t.mutedText, fontSize: 12),
                  ),
                ),
              ),
            _buildInputArea(t),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, AppThemeTokens t) {
    return Column(
      crossAxisAlignment:
          msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: msg.isMe ? t.accent.primary : t.panel,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                bottomRight: Radius.circular(msg.isMe ? 4 : 18),
              ),
              border: msg.isMe ? null : Border.all(color: t.cardBorder),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : t.textPrimary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (!msg.isMe && msg.chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.chips.map((chip) {
                return GestureDetector(
                  onTap: () => _sendMessage(chip.toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: t.accent.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: t.accent.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      chip.toString(),
                      style: TextStyle(
                        color: t.accent.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (!msg.isMe && msg.boardId != null && msg.boardId!.isNotEmpty)
          _buildInlineStyleBoard(msg.boardId!, t),
        if (!msg.isMe && msg.packId != null && msg.packId!.isNotEmpty)
          _buildInlineStyleBoard(msg.packId!, t),
      ],
    );
  }

  Widget _buildInputArea(AppThemeTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: t.backgroundPrimary,
        border: Border(top: BorderSide(color: t.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: t.panel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: t.cardBorder),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: t.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask AHVI anything...',
                  hintStyle: TextStyle(color: t.mutedText),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: t.accent.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
