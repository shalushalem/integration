import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/services/backend_service.dart';
import 'package:myapp/widgets/ahvi_chat_prompt_bar.dart';
import 'package:myapp/widgets/ahvi_lens_sheet.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart';

Future<void> showAhviStylistChatSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AhviStylistChatSheet(),
  );
}

class AhviStylistFab extends StatefulWidget {
  final VoidCallback onTap;

  const AhviStylistFab({super.key, required this.onTap});

  @override
  State<AhviStylistFab> createState() => _AhviStylistFabState();
}

class _AhviStylistFabState extends State<AhviStylistFab> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 22, 10),
          decoration: BoxDecoration(
            color: t.backgroundPrimary,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: t.cardBorder),
            boxShadow: [
              BoxShadow(
                color: t.backgroundPrimary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: t.textPrimary.withValues(alpha: 0.12),
                child: Text('✦', style: TextStyle(color: t.textPrimary)),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask AHVI',
                    style: GoogleFonts.anton(
                      fontSize: 13,
                      color: t.textPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AhviStylistChatSheet extends StatefulWidget {
  const _AhviStylistChatSheet();

  @override
  State<_AhviStylistChatSheet> createState() => _AhviStylistChatSheetState();
}

class _AhviStylistChatSheetState extends State<_AhviStylistChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<_SheetMessage> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  bool _typing = false;
  bool _showPrompts = true;
  bool _chatHasText = false;
  String _runningMemory = '';
  String _userId = 'demo_user';

  final List<String> _quickPrompts = const [
    'What should I wear today?',
    'Style tips for tonight',
    'Build a minimal routine',
    'Help me plan my day',
    'Smart tips for this week',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _chatHasText && mounted) {
        setState(() => _chatHasText = hasText);
      }
    });
    Timer(const Duration(milliseconds: 320), () {
      if (!mounted || _messages.isNotEmpty) return;
      setState(() {
        _messages.add(
          _SheetMessage(
            text:
                "Hi! I'm AHVI, your personal AI stylist ✦\n\nAsk me about outfit ideas, routines, planning, or daily recommendations.",
            isUser: false,
          ),
        );
      });
    });
  }

  Future<void> _fetchUserId() async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final user = await appwrite.getCurrentUser();
      if (!mounted || user == null || user.$id.isEmpty) return;
      setState(() => _userId = user.$id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _typing) return;
    _inputController.clear();
    setState(() {
      _showPrompts = false;
      _typing = true;
      _messages.add(_SheetMessage(text: trimmed, isUser: true));
      _chatHistory.add({'role': 'user', 'content': trimmed});
    });
    _scrollToBottom();
    try {
      final backend = Provider.of<BackendService>(context, listen: false);
      final response = await backend.sendChatQuery(
        trimmed,
        _userId,
        List<Map<String, String>>.from(_chatHistory),
        _runningMemory,
        moduleContext: 'style',
      );

      if (!mounted) return;
      if (response['updated_memory'] != null) {
        _runningMemory = response['updated_memory'].toString();
      }

      final aiText =
          response['message']?['content']?.toString().trim() ??
          response['content']?.toString().trim() ??
          response['error']?.toString().trim() ??
          "I couldn't reach AHVI backend right now.";

      _chatHistory.add({'role': 'assistant', 'content': aiText});
      setState(() {
        _typing = false;
        _messages.add(_SheetMessage(text: aiText, isUser: false));
      });
    } catch (_) {
      if (!mounted) return;
      const fallback = "I couldn't reach AHVI backend right now.";
      _chatHistory.add({'role': 'assistant', 'content': fallback});
      setState(() {
        _typing = false;
        _messages.add(_SheetMessage(text: fallback, isUser: false));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: t.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.panelBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: t.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.cardBorder, width: 1),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: t.textPrimary,
                      size: 15,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [t.accent.primary, t.accent.tertiary],
                    ),
                  ),
                  child: const Center(
                    child: Text('✦', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AHVI',
                        style: GoogleFonts.anton(
                          fontSize: 19,
                          color: t.textPrimary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'Your personal AI stylist',
                        style: TextStyle(
                          fontSize: 11,
                          color: t.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.history_rounded, color: t.mutedText),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                ..._messages.map((msg) => _Bubble(msg: msg)),
                if (_typing) _TypingBubble(color: t.accent.secondary),
              ],
            ),
          ),
          if (_showPrompts)
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(_quickPrompts[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: t.panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.cardBorder),
                    ),
                    child: Text(
                      _quickPrompts[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: t.accent.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: _quickPrompts.length,
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: t.phoneShellInner,
              border: Border(top: BorderSide(color: t.cardBorder)),
            ),
            child: AhviChatPromptBar(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              controller: _inputController,
              focusNode: _inputFocusNode,
              hintText: 'Ask your stylist...',
              hasText: _chatHasText,
              surface: t.phoneShellInner,
              border: t.cardBorder,
              accent: t.accent.primary,
              accentSecondary: t.accent.secondary,
              textHeading: t.textPrimary,
              textMuted: t.mutedText,
              shadowMedium: t.backgroundPrimary.withValues(alpha: 0.20),
              onAccent: Colors.white,
              onSubmitted: (value) => _sendMessage(value),
              onSend: () => _sendMessage(_inputController.text),
              onEmptySend: () {},
              onAddTap: () => showAhviLensSheet(
                context,
                t: context.themeTokens,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMessage {
  final String text;
  final bool isUser;

  _SheetMessage({required this.text, required this.isUser});
}

class _Bubble extends StatelessWidget {
  final _SheetMessage msg;

  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: t.backgroundSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser
                ? t.accent.primary.withValues(alpha: 0.4)
                : t.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: t.textPrimary, fontSize: 12, height: 1.45),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final Color color;

  const _TypingBubble({required this.color});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.themeTokens.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeTokens.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final p = ((_controller.value + i * 0.2) % 1.0);
                final o = 0.35 + (0.65 * (1 - (p - 0.5).abs() * 2));
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: o),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
