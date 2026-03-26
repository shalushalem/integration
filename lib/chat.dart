import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myapp/bills_page.dart' as bills_page;
import 'package:myapp/calendar.dart' as calendar_page;
import 'package:myapp/life_goals.dart' as life_goals_page;
import 'package:myapp/meal_planner.dart' as meal_planner_page;
import 'package:myapp/medi_tracker.dart' as medi_tracker_page;
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/services/backend_service.dart';
import 'package:myapp/skincare.dart' as skincare_page;
import 'package:myapp/theme/theme_tokens.dart';
import 'package:myapp/workout.dart' as workout_page;
import 'package:provider/provider.dart';

const _chipsByModule = <String, List<String>>{
  'style': [
    'What should I wear today?',
    'Build a rooftop party outfit',
    'Show trending casual looks',
  ],
  'organize': [
    'Meals',
    'Medicines',
    'Bills',
    'Workout',
    'Calendar',
    'Skincare',
    'Life Goals',
  ],
  'plan': [
    'Plan a 3-day Goa trip',
    'Pack for business travel',
    'Create a wedding checklist',
  ],
};

class _ChatMessage {
  final String text;
  final bool isMe;
  final List<dynamic> chips;
  final String? boardId;
  final String? packId;
  _ChatMessage({
    required this.text,
    required this.isMe,
    this.chips = const [],
    this.boardId,
    this.packId,
  });
}

enum _RespType { outfits, plan, card, checklist }

class _LocalResponse {
  final _RespType type;
  final String intro;
  final List<_Outfit> outfits;
  final List<_Plan> plans;
  final _CardData? card;
  const _LocalResponse({
    required this.type,
    required this.intro,
    this.outfits = const [],
    this.plans = const [],
    this.card,
  });
}

class _Outfit {
  final String name;
  final List<String> tags;
  final String image;
  const _Outfit(this.name, this.tags, this.image);
}

class _Plan {
  final String title;
  final List<String> items;
  const _Plan(this.title, this.items);
}

class _CardData {
  final String title;
  final IconData icon;
  final List<_CardRow> rows;
  final String footer;
  final String pageKey;
  const _CardData(this.title, this.icon, this.rows, this.footer, this.pageKey);
}

class _CardRow {
  final bool done;
  final String main;
  final String sub;
  final String tag;
  const _CardRow(this.done, this.main, this.sub, this.tag);
}

const _local = <String, _LocalResponse>{};

class ChatScreen extends StatefulWidget {
  final String moduleContext;
  final String? initialPrompt;
  const ChatScreen({
    super.key,
    this.moduleContext = 'style',
    this.initialPrompt,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  final List<ProxyDocument> _chatThreads = [];
  Map<String, dynamic> _chatUserProfile = <String, dynamic>{};
  List<Map<String, dynamic>> _chatWardrobe = <Map<String, dynamic>>[];
  String _runningMemory = '';
  String? _chatThreadId;
  bool _isRestoringHistory = false;
  bool _isThreadsLoading = false;
  bool _isTyping = false;
  String _userName = 'User';
  bool _chatHasText = false;
  final Map<String, List<List<bool>>> _checklistChecksByTitle = {};
  final Map<String, List<List<String>>> _checklistItemsByTitle = {};
  final Map<String, List<TextEditingController>> _checklistAddCtrlsByTitle = {};
  final Map<String, bool> _checklistSavedByTitle = {};
  final Set<int> _savedMessageIndexes = <int>{};
  String get _module => widget.moduleContext.toLowerCase().trim() == 'prepare'
      ? 'plan'
      : widget.moduleContext.toLowerCase().trim();

  _ChatMessage _defaultGreeting() => _ChatMessage(
    text: "Hi! I'm AHVI. How can I help you style or plan your day?",
    isMe: false,
  );

  @override
  void initState() {
    super.initState();
    _chatController.addListener(() {
      final hasText = _chatController.text.trim().isNotEmpty;
      if (hasText != _chatHasText) setState(() => _chatHasText = hasText);
    });
    _fetchUser();
    _messages.add(_defaultGreeting());
    final pendingPrompt = widget.initialPrompt?.trim();
    if (pendingPrompt != null && pendingPrompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendMessage(pendingPrompt);
      });
    }
  }

  Future<void> _fetchUser() async {
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    final user = await appwrite.getCurrentUser();
    if (user != null) {
      final firstName = user.name.isNotEmpty
          ? user.name.split(' ').first
          : 'Stylist';
      final profile = await _loadChatProfile(appwrite, user.$id, user.name);
      final wardrobe = await appwrite.getWardrobeItems();
      if (!mounted) return;
      setState(() {
        _userName = firstName;
        _chatUserProfile = profile;
        _chatWardrobe = wardrobe;
      });
      await _restoreChatHistory(appwrite);
    }
  }

  Future<void> _restoreChatHistory(AppwriteService appwrite) async {
    if (_isRestoringHistory) return;
    _isRestoringHistory = true;
    try {
      final threads = await _reloadThreads(appwrite, cacheFirst: true);
      if (threads.isEmpty) {
        if (!mounted) return;
        setState(() {
          _chatThreadId = null;
          _chatHistory.clear();
          _messages
            ..clear()
            ..add(_defaultGreeting());
        });
        return;
      }
      final thread = threads.first;
      _chatThreadId = thread.$id;
      await _openThread(thread.$id, appwrite: appwrite);
    } catch (_) {
      // Keep current in-memory fallback.
    } finally {
      _isRestoringHistory = false;
    }
  }

  Future<List<ProxyDocument>> _reloadThreads(
    AppwriteService appwrite, {
    bool cacheFirst = false,
  }) async {
    if (!mounted) return const <ProxyDocument>[];
    setState(() => _isThreadsLoading = true);
    var cachedThreads = const <ProxyDocument>[];
    try {
      if (cacheFirst) {
        cachedThreads = await appwrite.getCachedChatThreads(limit: 100);
        if (cachedThreads.isNotEmpty && mounted) {
          setState(() {
            _chatThreads
              ..clear()
              ..addAll(cachedThreads);
          });
        }
      }

      final threads = await appwrite.getChatThreads(limit: 100);
      if (!mounted) return threads.isNotEmpty ? threads : cachedThreads;
      setState(() {
        _chatThreads
          ..clear()
          ..addAll(threads);
      });
      return threads.isNotEmpty ? threads : cachedThreads;
    } catch (_) {
      return cachedThreads;
    } finally {
      if (mounted) setState(() => _isThreadsLoading = false);
    }
  }

  Map<String, dynamic> _decodeMeta(dynamic metaRaw) {
    if (metaRaw is Map) return Map<String, dynamic>.from(metaRaw);
    if (metaRaw is String && metaRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metaRaw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  Future<void> _openThread(
    String threadId, {
    AppwriteService? appwrite,
  }) async {
    final svc = appwrite ?? Provider.of<AppwriteService>(context, listen: false);
    final docs = await svc.getChatMessages(threadId: threadId, limit: 1000);
    docs.sort((a, b) {
      final ad = DateTime.tryParse(
            a.raw[r'$createdAt']?.toString() ?? a.data['createdAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse(
            b.raw[r'$createdAt']?.toString() ?? b.data['createdAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd);
    });

    final restoredMessages = <_ChatMessage>[];
    final restoredHistory = <Map<String, String>>[];
    for (final d in docs) {
      final role = (d.data['role'] ?? '').toString().trim().toLowerCase();
      final content = (d.data['content'] ?? '').toString();
      if (content.trim().isEmpty) continue;
      final meta = _decodeMeta(d.data['meta']);
      final chips = meta['chips'] is List
          ? List<dynamic>.from(meta['chips'] as List)
          : const <dynamic>[];
      final isMe = role == 'user';
      restoredMessages.add(
        _ChatMessage(
          text: content,
          isMe: isMe,
          chips: chips,
          boardId: meta['boardId']?.toString(),
          packId: meta['packId']?.toString(),
        ),
      );
      restoredHistory.add({
        'role': isMe ? 'user' : 'assistant',
        'content': content,
      });
    }

    if (!mounted) return;
    setState(() {
      _chatThreadId = threadId;
      _messages
        ..clear()
        ..addAll(
          restoredMessages.isEmpty
              ? [
                  _defaultGreeting(),
                ]
              : restoredMessages,
        );
      _chatHistory
        ..clear()
        ..addAll(restoredHistory);
    });
    _scrollToBottom();
  }

  Future<void> _startNewChat() async {
    if (!mounted) return;
    setState(() {
      _chatThreadId = null;
      _messages
        ..clear()
        ..add(_defaultGreeting());
      _chatHistory.clear();
    });
    _chatController.clear();
    Navigator.of(context).maybePop();
  }

  Future<void> _deleteThread(String threadId) async {
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    try {
      final docs = await appwrite.getChatMessages(threadId: threadId, limit: 1000);
      for (final d in docs) {
        await appwrite.deleteChatMessage(d.$id);
      }
      await appwrite.deleteChatThread(threadId);
      await _reloadThreads(appwrite);

      if (!mounted) return;
      if (_chatThreadId == threadId) {
        setState(() {
          _chatThreadId = null;
          _chatHistory.clear();
          _messages
            ..clear()
            ..add(_defaultGreeting());
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat thread deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete thread: $e')),
      );
    }
  }

  Future<void> _persistMessage({
    required String role,
    required String content,
    List<dynamic> chips = const [],
    String? boardId,
    String? packId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      if (_chatThreadId == null) {
        final newThread = await appwrite.createChatThread({
          'title': 'New Chat',
          'module': _module,
          'lastMessage': '',
        });
        _chatThreadId = newThread.$id;
      }

      await appwrite.createChatMessage({
        'threadId': _chatThreadId,
        'role': role,
        'content': trimmed,
        'meta': jsonEncode({
          'chips': chips,
          'boardId': boardId,
          'packId': packId,
          'module': _module,
        }),
      });

      final title = trimmed.length > 60 ? '${trimmed.substring(0, 60)}...' : trimmed;
      await appwrite.updateChatThread(_chatThreadId!, {
        'lastMessage': trimmed,
        if (role == 'user' && title.isNotEmpty) 'title': title,
      });
      await _reloadThreads(appwrite);
    } catch (e) {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      // If thread was just created but message failed, delete it to avoid empty thread.
      try {
        final threadId = _chatThreadId;
        if (threadId != null) {
          final docs = await appwrite.getChatMessages(threadId: threadId, limit: 1);
          if (docs.isEmpty) {
            await appwrite.deleteChatThread(threadId);
            _chatThreadId = null;
            await _reloadThreads(appwrite);
          }
        }
      } catch (_) {}
      // Non-blocking persistence failure; UI continues.
      debugPrint('Chat persist failed: $e');
    }
  }

  Future<Map<String, dynamic>> _loadChatProfile(
    AppwriteService appwrite,
    String userId,
    String fullName,
  ) async {
    final base = <String, dynamic>{
      'user_id': userId,
      'name': fullName,
      'first_name': fullName.trim().isEmpty ? 'User' : fullName.split(' ').first,
    };
    try {
      final doc = await appwrite.getUserProfile();
      final raw = Map<String, dynamic>.from(doc.data);
      final merged = <String, dynamic>{...raw, ...base};
      final gender = (merged['gender'] ??
              merged['sex'] ??
              merged['preferredGender'] ??
              merged['profile_gender'])
          ?.toString()
          .trim();
      if (gender != null && gender.isNotEmpty) {
        merged['gender'] = gender;
      }

      final shoppingPrefs =
          merged['shopping_preferences'] ??
          merged['shoppingPreferences'] ??
          merged['style_preferences'] ??
          merged['stylePreferences'] ??
          merged['preferred_styles'];
      if (shoppingPrefs != null) {
        merged['shopping_preferences'] = shoppingPrefs;
      }

      final pronouns =
          merged['pronouns'] ?? merged['preferred_pronouns'] ?? merged['pronoun'];
      if (pronouns != null && pronouns.toString().trim().isNotEmpty) {
        merged['pronouns'] = pronouns.toString().trim();
      }

      final dob = (merged['dob_iso'] ?? merged['dob'] ?? merged['dateOfBirth'])
          ?.toString()
          .trim();
      if (dob != null && dob.isNotEmpty) {
        merged['dob_iso'] = dob;
        final age = _ageFromDob(dob);
        if (age != null) merged['age'] = age;
      }
      return merged;
    } catch (_) {
      return base;
    }
  }

  int? _ageFromDob(String dobIso) {
    try {
      final dob = DateTime.parse(dobIso);
      final now = DateTime.now();
      var age = now.year - dob.year;
      final hadBirthday =
          now.month > dob.month ||
          (now.month == dob.month && now.day >= dob.day);
      if (!hadBirthday) age -= 1;
      return age < 0 ? null : age;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshChatContext() async {
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    final user = await appwrite.getCurrentUser();
    if (user == null) return;

    final profile = await _loadChatProfile(appwrite, user.$id, user.name);
    final wardrobe = await appwrite.getWardrobeItems();
    if (!mounted) return;
    setState(() {
      _chatUserProfile = profile;
      _chatWardrobe = wardrobe;
    });
  }

  void _handleChipTap(String chip) {
    _sendMessage(chip);
  }

  void _sendMessage([String? chipText]) async {
    final text = chipText ?? _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true));
      _chatHistory.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _persistMessage(role: 'user', content: text);
    _scrollToBottom();
    try {
      await _refreshChatContext();
      final backend = Provider.of<BackendService>(context, listen: false);
      final historyPayload = List<Map<String, String>>.from(_chatHistory);
      if (historyPayload.isNotEmpty &&
          historyPayload.last['role'] == 'user' &&
          historyPayload.last['content'] == text) {
        historyPayload.removeLast();
      }
      final response = await backend.sendChatQuery(
        text,
        'user_$_userName',
        historyPayload,
        _runningMemory,
        userProfile: _chatUserProfile,
        wardrobeItems: _chatWardrobe,
        moduleContext: _module,
      );
      if (!mounted) return;
      if (response['updated_memory'] != null) {
        _runningMemory = response['updated_memory'];
      }
      final msg = response['message'];
      final aiText = (() {
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        if (msg is Map && msg['content'] != null) {
          final content = msg['content'].toString().trim();
          if (content.isNotEmpty) return content;
        }
        if (response['error'] != null) {
          final error = response['error'].toString().trim();
          if (error.isNotEmpty) return error;
        }
        return "I'm having trouble connecting.";
      })();
      _chatHistory.add({'role': 'assistant', 'content': aiText});
      final aiChips = response['chips'] is List
          ? List<dynamic>.from(response['chips'] as List)
          : const <dynamic>[];
      _persistMessage(
        role: 'assistant',
        content: aiText,
        chips: aiChips,
        boardId: response['board_ids']?.toString(),
        packId: response['pack_ids']?.toString(),
      );
      setState(
        () => _messages.add(
          _ChatMessage(
            text: aiText,
            isMe: false,
            chips: aiChips,
            boardId: response['board_ids'],
            packId: response['pack_ids'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMessage(text: 'Connection Error: $e', isMe: false),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  String _normalizeBoardOccasion(String boardLabel) {
    final v = boardLabel.trim().toLowerCase();
    switch (v) {
      case 'party looks':
      case 'party':
        return 'Party';
      case 'office fit':
      case 'office':
        return 'Office';
      case 'vacation':
        return 'Vacation';
      default:
        return 'Occasion';
    }
  }

  Future<void> _saveMessageToBoard({
    required int index,
    required _ChatMessage message,
    required String boardLabel,
  }) async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final occasion = _normalizeBoardOccasion(boardLabel);
      final title = message.text.length > 60
          ? '${message.text.substring(0, 60).trim()}...'
          : message.text;
      final payload = <String, dynamic>{
        'title': title.isEmpty ? 'Style Board' : title,
        'description': message.text,
        'occasion': occasion,
        'imageUrl': '',
        'board_ids': message.boardId ?? '',
        'chips': message.chips.map((e) => e.toString()).toList(),
        'source': 'chat',
        'created_at': DateTime.now().toIso8601String(),
      };
      await appwrite.createSavedBoard(payload);
      if (!mounted) return;
      setState(() {
        _savedMessageIndexes.add(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $occasion board')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save board: $e')),
      );
    }
  }

  void _openOrganizePage(String pageKey) {
    Widget? page;
    switch (pageKey) {
      case 'meal':
        page = const meal_planner_page.Screen4();
        break;
      case 'medi':
        page = const medi_tracker_page.MediTrackScreen();
        break;
      case 'bill':
        page = const bills_page.BillsScreen();
        break;
      case 'workout':
        page = const workout_page.WorkoutScreen();
        break;
      case 'calendar':
        page = const calendar_page.CalendarScreen();
        break;
      case 'skincare':
        page = const skincare_page.SkincareScreen();
        break;
      case 'lifegoals':
        page = const life_goals_page.LifeGoalsScreen();
        break;
    }
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
  }

  Widget _buildHistoryDrawer(AppThemeTokens t) {
    return Drawer(
      backgroundColor: t.backgroundSecondary,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _startNewChat,
                    icon: Icon(Icons.add_rounded, size: 16, color: t.accent.primary),
                    label: Text(
                      'New',
                      style: TextStyle(
                        color: t.accent.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: t.cardBorder, height: 1),
            Expanded(
              child: _isThreadsLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _chatThreads.isEmpty
                      ? Center(
                          child: Text(
                            'No chats yet.',
                            style: TextStyle(color: t.mutedText),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _chatThreads.length,
                          itemBuilder: (_, i) {
                            final th = _chatThreads[i];
                            final id = th.$id;
                            final selected = id == _chatThreadId;
                            final title =
                                (th.data['title'] ?? 'New Chat').toString();
                            final preview =
                                (th.data['lastMessage'] ?? '').toString();
                            return ListTile(
                              selected: selected,
                              selectedTileColor:
                                  t.accent.primary.withValues(alpha: 0.12),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: preview.trim().isEmpty
                                  ? null
                                  : Text(
                                      preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: t.mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                              trailing: IconButton(
                                tooltip: 'Delete thread',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: t.mutedText,
                                ),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: t.backgroundSecondary,
                                      title: Text(
                                        'Delete chat?',
                                        style: TextStyle(color: t.textPrimary),
                                      ),
                                      content: Text(
                                        'This will permanently remove this chat history.',
                                        style: TextStyle(color: t.mutedText),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: t.mutedText,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await _deleteThread(id);
                                  }
                                },
                              ),
                              onTap: () async {
                                await _openThread(id);
                                if (!mounted) return;
                                Navigator.of(context).maybePop();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatFocusNode.dispose();
    _scrollController.dispose();
    for (final ctrls in _checklistAddCtrlsByTitle.values) {
      for (final c in ctrls) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Scaffold(
      key: _scaffoldKey,
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
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            icon: Icon(Icons.history_rounded, color: t.textPrimary),
          ),
        ],
      ),
      endDrawer: _buildHistoryDrawer(t),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _msg(_messages[i], t, i),
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
            _input(t),
          ],
        ),
      ),
    );
  }

  Widget _msg(_ChatMessage m, AppThemeTokens t, int index) => Column(
    crossAxisAlignment: m.isMe
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Align(
        alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: m.isMe ? t.accent.primary : t.panel,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(m.isMe ? 18 : 4),
              bottomRight: Radius.circular(m.isMe ? 4 : 18),
            ),
            border: m.isMe ? null : Border.all(color: t.cardBorder),
          ),
          child: Text(
            m.text,
            style: TextStyle(
              color: m.isMe ? Colors.white : t.textPrimary,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ),
      ),
      if (!m.isMe && _module == 'style')
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: GestureDetector(
            onTap: _savedMessageIndexes.contains(index)
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: t.backgroundSecondary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              'Save to a Style Board',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...[
                              'Party Looks',
                              'Occasion',
                              'Office Fit',
                              'Vacation',
                            ].map(
                              (b) => ListTile(
                                title: Text(
                                  b,
                                  style: TextStyle(color: t.textPrimary),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: t.mutedText,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _saveMessageToBoard(
                                    index: index,
                                    message: m,
                                    boardLabel: b,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _savedMessageIndexes.contains(index)
                    ? t.accent.tertiary.withValues(alpha: 0.2)
                    : t.panel,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.cardBorder),
              ),
              child: Text(
                _savedMessageIndexes.contains(index)
                    ? 'Saved to Board'
                    : 'Save to Board',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      if (!m.isMe && m.chips.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: m.chips
                .map(
                  (c) => GestureDetector(
                    onTap: () => _sendMessage(c.toString()),
                    child: _chip(c.toString(), t),
                  ),
                )
                .toList(),
          ),
        ),
    ],
  );

  Widget _localView(_LocalResponse r, AppThemeTokens t) {
    if (r.type == _RespType.outfits) {
      return SizedBox(
        height: 155,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: r.outfits.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final o = r.outfits[i];
            return Container(
              width: 86,
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
                    height: 96,
                    child: Image.network(
                      o.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: t.accent.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.name,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 3,
                          children: o.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.accent.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: t.mutedText,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
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
    if (r.type == _RespType.plan) {
      final colors = [t.accent.primary, t.accent.secondary, t.accent.tertiary];
      return Column(
        children: r.plans
            .asMap()
            .entries
            .map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: colors[e.key % 3], width: 2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.value.title,
                      style: TextStyle(
                        color: colors[e.key % 3],
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...e.value.items.map(
                      (it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          it,
                          style: TextStyle(
                            color: t.mutedText,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }
    if (r.type == _RespType.checklist) {
      return _buildChecklistCard(r, t);
    }
    final d = r.card!;
    final accent = t.accent.primary;
    final done = d.rows.where((x) => x.done).length;
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 28, bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(d.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.title,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Text(
                  '$done/${d.rows.length}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...d.rows.map(
            (x) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: t.panel.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.cardBorder.withValues(alpha: 0.9)),
              ),
              child: Row(
                children: [
                  Icon(
                    x.done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: x.done ? accent : t.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          x.main,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          x.sub,
                          style: TextStyle(color: t.mutedText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      x.tag,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _openOrganizePage(d.pageKey),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.cardBorder)),
              ),
              child: Text(
                d.footer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(_LocalResponse r, AppThemeTokens t) {
    final title = r.intro.isNotEmpty ? r.intro : 'Checklist';
    const sections = [
      (
        name: 'Documents',
        emoji: '📄',
        color: Color(0xFF04D7C8),
        items: [
          'Passport / ID',
          'Boarding pass',
          'Travel insurance',
          'Hotel confirmation',
          'Visa (if required)',
        ],
      ),
      (
        name: 'Tech & Power',
        emoji: '🔌',
        color: Color(0xFF8D7DFF),
        items: [
          'Phone + charger',
          'Power bank',
          'Headphones',
          'Laptop or tablet',
          'Universal adapter',
        ],
      ),
      (
        name: 'Comfort',
        emoji: '😴',
        color: Color(0xFF6B91FF),
        items: [
          'Neck pillow',
          'Eye mask',
          'Earplugs',
          'Light jacket',
          'Compression socks',
        ],
      ),
    ];
    const sectionImages = [
      [
        'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1522199755839-a2bacb67c546?w=400&h=260&fit=crop&auto=format',
      ],
      [
        'https://images.unsplash.com/photo-1517336714739-489689fd1ca8?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1593344484962-796055d4a3a4?w=400&h=260&fit=crop&auto=format',
      ],
      [
        'https://images.unsplash.com/photo-1520006403909-838d6b92c22e?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1506485338023-6ce5f36692df?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400&h=260&fit=crop&auto=format',
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=400&h=260&fit=crop&auto=format',
      ],
    ];

    final itemsState = _checklistItemsByTitle.putIfAbsent(
      title,
      () => sections.map((s) => List<String>.from(s.items)).toList(),
    );
    final addCtrls = _checklistAddCtrlsByTitle.putIfAbsent(
      title,
      () => List.generate(sections.length, (_) => TextEditingController()),
    );
    final checksState = _checklistChecksByTitle.putIfAbsent(
      title,
      () => itemsState
          .map(
            (items) => List<bool>.filled(items.length, false, growable: true),
          )
          .toList(),
    );
    final isSaved = _checklistSavedByTitle[title] ?? false;

    for (var i = 0; i < itemsState.length; i++) {
      final targetLen = itemsState[i].length;
      if (checksState[i].length < targetLen) {
        checksState[i].addAll(
          List<bool>.filled(
            targetLen - checksState[i].length,
            false,
            growable: true,
          ),
        );
      } else if (checksState[i].length > targetLen) {
        checksState[i] = checksState[i].sublist(0, targetLen);
      }
    }

    final totalItems = itemsState.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
    final totalChecked = checksState.fold<int>(
      0,
      (sum, items) => sum + items.where((v) => v).length,
    );
    final progress = totalItems == 0 ? 0.0 : totalChecked / totalItems;

    return Container(
      margin: const EdgeInsets.only(left: 4, right: 28, bottom: 16),
      decoration: BoxDecoration(
        color: t.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: t.phoneShell,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.intro,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalChecked of $totalItems items',
                  style: TextStyle(
                    color: t.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 7,
                  decoration: BoxDecoration(
                    color: t.cardBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 300),
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(color: t.accent.tertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(sections.length, (sIdx) {
            final s = sections[sIdx];
            return Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: t.card,
                border: Border(
                  top: BorderSide(color: t.cardBorder.withValues(alpha: 0.7)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(s.emoji),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.name,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sectionImages[sIdx].length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, imgIdx) {
                        final img = sectionImages[sIdx][imgIdx];
                        return Container(
                          width: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: t.cardBorder.withValues(alpha: 0.85),
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: t.panel.withValues(alpha: 0.75),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_outlined,
                                size: 16,
                                color: t.mutedText,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(itemsState[sIdx].length, (i) {
                    final done = checksState[sIdx][i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: t.panel.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: t.cardBorder.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => checksState[sIdx][i] = !done),
                            child: Icon(
                              done
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: done ? s.color : t.mutedText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              itemsState[sIdx][i],
                              style: TextStyle(
                                color: done ? t.mutedText : t.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                itemsState[sIdx].removeAt(i);
                                checksState[sIdx].removeAt(i);
                              });
                            },
                            child: Text(
                              '×',
                              style: TextStyle(
                                color: t.mutedText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: t.phoneShellInner.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCtrls[sIdx],
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: '+ Add item…',
                              hintStyle: TextStyle(
                                color: t.mutedText,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) {
                              final v = addCtrls[sIdx].text.trim();
                              if (v.isEmpty) return;
                              setState(() {
                                itemsState[sIdx].add(v);
                                checksState[sIdx].add(false);
                                addCtrls[sIdx].clear();
                              });
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final v = addCtrls[sIdx].text.trim();
                            if (v.isEmpty) return;
                            setState(() {
                              itemsState[sIdx].add(v);
                              checksState[sIdx].add(false);
                              addCtrls[sIdx].clear();
                            });
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '+',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10131B),
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: GestureDetector(
              onTap: isSaved
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: t.backgroundSecondary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                'Save to a Style Board',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...[
                                'Party Looks',
                                'Occasion',
                                'Office Fit',
                                'Vacation',
                              ].map(
                                (b) => ListTile(
                                  title: Text(
                                    b,
                                    style: TextStyle(color: t.textPrimary),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: t.mutedText,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(
                                      () =>
                                          _checklistSavedByTitle[title] = true,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSaved
                      ? LinearGradient(
                          colors: [t.accent.tertiary, t.accent.tertiary],
                        )
                      : LinearGradient(
                          colors: [t.accent.tertiary, t.accent.primary],
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isSaved ? 'List Saved!' : 'Save to Style Board',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(AppThemeTokens t) {
    final chips = _chipsByModule[_module] ?? const <String>[];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 7),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _handleChipTap(chips[i]),
          child: _chip(chips[i], t),
        ),
      ),
    );
  }

  Widget _chip(String label, AppThemeTokens t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: t.panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: t.cardBorder, width: 1.2),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: t.mutedText,
      ),
    ),
  );

  Widget _input(AppThemeTokens t) {
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [t.accent.primary, t.accent.secondary],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chips(t),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: t.phoneShellInner.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.cardBorder, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    style: TextStyle(color: t.textPrimary, fontSize: 14.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Ask AHVI anything...',
                      hintStyle: TextStyle(color: t.mutedText, fontSize: 14.5),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        _sendMessage(v.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: _chatHasText
                          ? grad
                          : LinearGradient(
                              colors: [
                                t.accent.primary.withValues(alpha: 0.35),
                                t.accent.secondary.withValues(alpha: 0.35),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}


