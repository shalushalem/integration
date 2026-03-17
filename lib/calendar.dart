import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ── Color Palette ──
const Color kBg = Color(0xFF08111F);
const Color kBg2 = Color(0xFF0F1A2D);
const Color kPhoneShell = Color(0xFF192131);
const Color kPhoneShell2 = Color(0xFF111723);
const Color kText = Color(0xFFF5F7FF);
const Color kMuted = Color(0xB8E6EBFF);
const Color kTextDim = Color(0x66E6EBFF);
const Color kTextLight = Color(0x80E6EBFF);
const Color kAccent = Color(0xFF6B91FF);
const Color kAccent2 = Color(0xFF8D7DFF);
const Color kAccent3 = Color(0xFF04D7C8);
const Color kAccent4 = Color(0xFFFF8EC7);
const Color kAccent5 = Color(0xFFFFD86E);
const Color kCardBorder = Color(0x1FFFFFFF);
const Color kPanel = Color(0x14FFFFFF);
const Color kPanel2 = Color(0x1FFFFFFF);

// ── Sample Data ──
const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

// [PATCH B11/B27] Plan data model replaces static kSamplePlans
class PlanItem {
  final String emoji;
  final String title;
  final String desc;
  final String outfit;
  final String color;
  bool reminderOn;

  PlanItem({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.outfit,
    required this.color,
    this.reminderOn = true,
  });
}

const List<Map<String, String>> kEventTypes = [
  {'label': 'Gym', 'emoji': '💪', 'type': 'teal'},
  {'label': 'Office', 'emoji': '💼', 'type': 'purple'},
  {'label': 'Party', 'emoji': '🎊', 'type': 'pink'},
  {'label': 'Shopping', 'emoji': '🛍️', 'type': 'amber'},
  {'label': 'Study', 'emoji': '📖', 'type': 'blue'},
  {'label': 'Travel', 'emoji': '✈️', 'type': 'teal'},
  {'label': 'Event', 'emoji': '🌟', 'type': 'blue'},
  {'label': 'Date Night', 'emoji': '❤️', 'type': 'pink'},
];

const List<Map<String, String>> kSuggestionChips = [
  {'label': 'What should I wear today?'},
  {'label': 'Outfit for a date night 🌙'},
  {'label': 'Casual weekend look'},
  {'label': 'Work-appropriate outfit'},
  {'label': 'What to pack for a trip?'},
  {'label': 'Summer party outfit 🎉'},
];

// [PATCH B34] Outfit data for modal carousel (mirrors HTML OUTFITS map)
const Map<String, List<Map<String, String>>> kOutfits = {
  'Gym': [
    {'vibe': 'Cardio Day', 'desc': 'Leggings, Sports tank, Running shoes', 'tip': 'Go breathable — skip cotton.', 'summary': 'Leggings, sports tank & running shoes'},
    {'vibe': 'Weight Training', 'desc': 'Gym shorts, Loose tee, Cross-trainers', 'tip': 'Flat soles = better grip.', 'summary': 'Gym shorts, loose tee & cross-trainers'},
    {'vibe': 'Yoga / Pilates', 'desc': 'High-waist yoga pants, Fitted top, Grip socks', 'tip': 'Fitted top only.', 'summary': 'Yoga pants, fitted top & grip socks'},
  ],
  'Office': [
    {'vibe': 'Formal Meeting', 'desc': 'Dress shirt, Dark trousers, Leather shoes', 'tip': 'Iron your collar.', 'summary': 'Dress shirt, dark trousers & leather shoes'},
    {'vibe': 'Regular Workday', 'desc': 'Chinos, Polo or blouse, Loafers', 'tip': 'Stick to 2–3 neutral colors.', 'summary': 'Chinos, polo & loafers'},
    {'vibe': 'Creative Office', 'desc': 'Dark jeans, Knit top, Clean sneakers', 'tip': 'Swap to loafers for clients.', 'summary': 'Dark jeans, knit top & sneakers'},
  ],
  'Party': [
    {'vibe': 'Evening Out', 'desc': 'Slip dress, Strappy heels, Small bag', 'tip': 'Bold dress OR bold shoes.', 'summary': 'Slip dress, heels & small bag'},
    {'vibe': 'Cocktail Party', 'desc': 'Wide-leg trousers, Silky top, Block heels', 'tip': 'Half-tuck for polish.', 'summary': 'Wide-leg trousers, silky top & block heels'},
    {'vibe': 'House Party', 'desc': 'Jeans, Printed top, Ankle boots', 'tip': 'Stylish jeans always hit.', 'summary': 'Jeans, printed top & ankle boots'},
  ],
};

class Screen4 extends StatefulWidget {
  const Screen4({super.key});

  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> with TickerProviderStateMixin {
  // Calendar state
  final DateTime _today = DateTime.now();
  late int _viewYear;
  late int _viewMonth;
  late DateTime _selectedDay;

  // [PATCH B11/B27] Replace static kSamplePlans with mutable per-day plans map
  final Map<String, List<PlanItem>> _plansData = {
    DateTime.now().toIso8601String().substring(0, 10): [
      PlanItem(emoji: '💪', title: 'Gym', desc: 'Cardio Day · 7:00 AM', outfit: 'Leggings, sports tank & running shoes', color: 'teal'),
      PlanItem(emoji: '💼', title: 'Office', desc: 'Formal Meeting · 10:30 AM', outfit: 'Dress shirt, dark trousers & leather shoes', color: 'purple'),
      PlanItem(emoji: '🎊', title: 'Party', desc: 'Evening Out · 8:00 PM', outfit: 'Slip dress, heels & small bag', color: 'pink'),
    ],
  };

  String get _selectedDayKey => _selectedDay.toIso8601String().substring(0, 10);
  List<PlanItem> get _todayPlans => _plansData[_selectedDayKey] ?? [];

  // Modal state
  bool _modalOpen = false;
  String _selectedEvent = '';
  String _selectedEventEmoji = '📅';
  String _selectedAmPm = 'AM';
  final TextEditingController _hourCtrl = TextEditingController();
  final TextEditingController _minCtrl = TextEditingController();
  // [PATCH B23] FocusNodes for auto-advance hour→minute
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minFocus = FocusNode();
  // [PATCH B21] Outfit carousel pick index
  int _pickedOutfitIdx = -1;

  // Chat state
  bool _showChat = false;
  String _activeOccasion = 'Gym';
  String _activeEmoji = '💪';
  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  // [PATCH B30] Typing indicator
  bool _isTyping = false;
  // [PATCH B32] Chips visibility
  bool _chipsVisible = true;
  // [PATCH B34] Awaiting time for reminder
  bool _awaitingTime = false;

  // [PATCH B29] Per-message animation controllers
  final List<AnimationController> _bubbleControllers = [];

  // [PATCH B02] Pulse dot animation controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // [PATCH B15] Modal sheet animation controller
  late AnimationController _modalAnimController;
  late Animation<Offset> _modalSlideAnim;
  late Animation<double> _modalFadeAnim;

  // [PATCH B07] Plan card stagger animation controllers
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardFadeAnims = [];
  final List<Animation<Offset>> _cardSlideAnims = [];

  // [PATCH B37] Toast overlay
  OverlayEntry? _toastOverlay;

  // [PATCH B36] Typing dot controller
  late AnimationController _typingController;

  // ScrollController for chat auto-scroll
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewYear = _today.year;
    _viewMonth = _today.month - 1;
    _selectedDay = _today;

    // [PATCH B02] Pulse controller — 2500ms repeat
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // [PATCH B15] Modal slide-up animation — 420ms spring
    _modalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _modalSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _modalAnimController,
      curve: Curves.easeOutCubic,
    ));
    _modalFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _modalAnimController, curve: Curves.easeOut),
    );

    // [PATCH B30] Typing dot animation — 1200ms repeat
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // [PATCH B23] Hour auto-advance listener
    _hourCtrl.addListener(() {
      final v = int.tryParse(_hourCtrl.text);
      if (_hourCtrl.text.length >= 2) {
        if (v != null && v > 12) _hourCtrl.text = '12';
        FocusScope.of(context).requestFocus(_minFocus);
      }
    });

    // [PATCH B24] Minute zero-pad on blur
    _minFocus.addListener(() {
      if (!_minFocus.hasFocus && _minCtrl.text.length == 1) {
        _minCtrl.text = '0${_minCtrl.text}';
      }
    });

    // [PATCH B07] Initialize stagger controllers for initial plans
    _initCardAnimations();
  }

  /// [PATCH B07] Creates staggered entrance controllers for current day's plans
  void _initCardAnimations() {
    for (final c in _cardControllers) {
      c.dispose();
    }
    _cardControllers.clear();
    _cardFadeAnims.clear();
    _cardSlideAnims.clear();

    final plans = _todayPlans;
    for (int i = 0; i < plans.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _cardControllers.add(ctrl);
      _cardFadeAnims.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
        ),
      );
      _cardSlideAnims.add(
        Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
      );
      // Stagger each card by 70ms
      Future.delayed(Duration(milliseconds: i * 70), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _chatCtrl.dispose();
    _hourFocus.dispose();
    _minFocus.dispose();
    _pulseController.dispose();
    _modalAnimController.dispose();
    _typingController.dispose();
    for (final c in _bubbleControllers) {
      c.dispose();
    }
    for (final c in _cardControllers) {
      c.dispose();
    }
    _chatScrollController.dispose();
    super.dispose();
  }

  String get _monthTitle => '${kMonths[_viewMonth]} $_viewYear';

  List<DateTime> get _daysInMonth {
    final daysCount = DateTime(_viewYear, _viewMonth + 2, 0).day;
    return List.generate(
        daysCount, (i) => DateTime(_viewYear, _viewMonth + 1, i + 1));
  }

  bool _isToday(DateTime d) =>
      d.year == _today.year && d.month == _today.month && d.day == _today.day;

  bool _isSelected(DateTime d) =>
      d.year == _selectedDay.year &&
          d.month == _selectedDay.month &&
          d.day == _selectedDay.day;

  String _weekdayShort(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'teal': return kAccent3;
      case 'purple': return kAccent2;
      case 'pink': return kAccent4;
      case 'amber': return kAccent5;
      case 'blue': return kAccent;
      default: return kAccent;
    }
  }

  LinearGradient _eventBg(String type) {
    switch (type) {
      case 'teal':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x3804D7C8), Color(0x1E04D7C8)],
        );
      case 'purple':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x388D7DFF), Color(0x1E8D7DFF)],
        );
      case 'pink':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x2EFF8EC7), Color(0x1AFF8EC7)],
        );
      case 'amber':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x38FFD86E), Color(0x1EFFD86E)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x286B91FF), Color(0x1A6B91FF)],
        );
    }
  }

  LinearGradient _planCardBg(String color) {
    switch (color) {
      case 'teal':
        return const LinearGradient(
          begin: Alignment(-0.7, -0.7), end: Alignment(0.7, 0.7),
          colors: [Color(0x3304D7C8), Color(0x1E04D7C8)],
        );
      case 'purple':
        return const LinearGradient(
          begin: Alignment(-0.7, -0.7), end: Alignment(0.7, 0.7),
          colors: [Color(0x338D7DFF), Color(0x1E8D7DFF)],
        );
      case 'pink':
        return const LinearGradient(
          begin: Alignment(-0.7, -0.7), end: Alignment(0.7, 0.7),
          colors: [Color(0x2EFF8EC7), Color(0x1AFF8EC7)],
        );
      default:
        return const LinearGradient(
          begin: Alignment(-0.7, -0.7), end: Alignment(0.7, 0.7),
          colors: [Color(0x286B91FF), Color(0x1A6B91FF)],
        );
    }
  }

  Color _planBorderTop(String color) {
    switch (color) {
      case 'teal': return const Color(0x4D04D7C8);
      case 'purple': return const Color(0x4D8D7DFF);
      case 'pink': return const Color(0x47FF8EC7);
      default: return const Color(0x336B91FF);
    }
  }

  // ── [PATCH B37] Toast system ──────────────────────────────────────────────
  void _showToast(String message) {
    _toastOverlay?.remove();
    _toastOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        onDismissed: () {
          entry.remove();
          if (_toastOverlay == entry) _toastOverlay = null;
        },
      ),
    );

    _toastOverlay = entry;
    overlay.insert(entry);
  }

  // ── [PATCH B11] Delete plan ───────────────────────────────────────────────
  void _deletePlan(int index) {
    setState(() {
      _plansData[_selectedDayKey]?.removeAt(index);
    });
    _initCardAnimations();
    _showToast('Plan removed');
  }

  // ── [PATCH B13] Toggle reminder ───────────────────────────────────────────
  void _toggleReminder(int index) {
    final plans = _plansData[_selectedDayKey];
    if (plans == null || index >= plans.length) return;
    setState(() {
      plans[index].reminderOn = !plans[index].reminderOn;
    });
    _showToast(plans[index].reminderOn ? '🔔 Reminder turned on!' : '🔕 Reminder turned off');
  }

  // ── [PATCH B27] Save plan from modal ─────────────────────────────────────
  void _savePlan() {
    final hRaw = int.tryParse(_hourCtrl.text);
    final mRaw = int.tryParse(_minCtrl.text);
    if (_selectedEvent.isEmpty) {
      _showToast('⚠ Please choose an occasion first.');
      return;
    }
    if (hRaw == null || hRaw < 1 || hRaw > 12) {
      _showToast('⚠ Enter a valid hour (1–12).');
      return;
    }
    if (mRaw == null || mRaw < 0 || mRaw > 59) {
      _showToast('⚠ Enter a valid minute (0–59).');
      return;
    }

    final hh = hRaw.toString().padLeft(2, '0');
    final mm = mRaw.toString().padLeft(2, '0');
    final timeDisplay = '$hh:$mm $_selectedAmPm';

    final selectedOutfit = (_pickedOutfitIdx >= 0 &&
        kOutfits.containsKey(_selectedEvent) &&
        _pickedOutfitIdx < kOutfits[_selectedEvent]!.length)
        ? kOutfits[_selectedEvent]![_pickedOutfitIdx]['summary'] ?? ''
        : '(no outfit selected)';

    final newPlan = PlanItem(
      emoji: _selectedEventEmoji,
      title: _selectedEvent,
      desc: '$timeDisplay',
      outfit: selectedOutfit,
      color: ['teal', 'purple', 'pink'][DateTime.now().millisecondsSinceEpoch % 3],
    );

    setState(() {
      _plansData[_selectedDayKey] = [...(_plansData[_selectedDayKey] ?? []), newPlan];
      _modalOpen = false;
    });
    _initCardAnimations();
    _showToast('📅 Plan saved!');
  }

  // ── [PATCH B15] Open modal with animation ────────────────────────────────
  void _openModal() {
    setState(() {
      _modalOpen = true;
      _selectedEvent = '';
      _selectedEventEmoji = '📅';
      _pickedOutfitIdx = -1;
      _selectedAmPm = 'AM';
      _hourCtrl.clear();
      _minCtrl.clear();
    });
    _modalAnimController.forward(from: 0);
  }

  // ── [PATCH B34] Real AI API call ─────────────────────────────────────────
  Future<String> _getAIReply(String userText) async {
    const systemPrompt =
        'You are a friendly personal style assistant. When asked about outfits, '
        'give a complete look: top, bottom, shoes, and one accessory. '
        'Be specific with colours and fit. Keep replies to 2–3 sentences, warm and conversational.';
    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userText},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        return (content.firstWhere(
              (c) => (c as Map)['type'] == 'text',
          orElse: () => {'text': "I'm not sure — try rephrasing!"},
        ) as Map)['text'] as String;
      }
      return "Couldn't connect right now — please try again!";
    } catch (e) {
      return "Couldn't connect right now — please try again!";
    }
  }

  // ── [PATCH B29] Add bubble with entrance animation ────────────────────────
  AnimationController _createBubbleController() {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bubbleControllers.add(ctrl);
    ctrl.forward();
    return ctrl;
  }

  // ── [PATCH B34] Send message with real API + B30 typing indicator ─────────
  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;

    // [PATCH B32] Hide chips after first send
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatCtrl.clear();
      _chipsVisible = false;
      _isTyping = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // [PATCH B34] Real API call
    final reply = await _getAIReply(
        '$text — I am planning for $_activeOccasion $_activeEmoji');

    setState(() {
      _isTyping = false;
      _messages.add({'role': 'ai', 'text': reply});
    });

    // Scroll to bottom again after AI reply
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
                colors: [kBg, kBg2, kPhoneShell],
              ),
            ),
          ),

          // Main content or chat page
          _showChat ? _buildChatPage() : _buildMainContent(),

          // [PATCH B15] Modal overlay with slide-up animation
          if (_modalOpen) _buildModal(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // MAIN CONTENT
  // ══════════════════════════════════════════
  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 18),
                  _buildCalendarBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // [PATCH B01] Back button with scale animation on tap
        _ScaleButton(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPanel2,
              shape: BoxShape.circle,
              border: Border.all(color: kCardBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x4D000000), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.chevron_left, color: kText, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule / Calendar',
              style: TextStyle(
                fontFamily: 'SF Pro Display', fontSize: 18,
                fontWeight: FontWeight.w700, color: kText, height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                // [PATCH B02] Animated pulse dot replacing static container
                _PulseDot(controller: _pulseController, animation: _pulseAnim),
                const SizedBox(width: 6),
                // [PATCH B41] Dynamic plan count text
                Text(
                  _buildSubtitleText(),
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // [PATCH B41] Compute subtitle dynamically
  String _buildSubtitleText() {
    int total = 0;
    _plansData.forEach((_, list) => total += list.length);
    final todayKey = _today.toIso8601String().substring(0, 10);
    final todayCount = _plansData[todayKey]?.length ?? 0;
    return '$total outfit plan${total != 1 ? 's' : ''} · $todayCount today';
  }

  Widget _buildCalendarBox() {
    return Container(
      decoration: BoxDecoration(
        color: kPhoneShell,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildMonthNav(),
          _buildWeekStrip(),
          _buildPlansDivider(),
          _buildPlansSection(),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // [PATCH B04] Nav arrows with scale animation
          _ScaleButton(
            onTap: () {
              setState(() {
                _viewMonth--;
                if (_viewMonth < 0) { _viewMonth = 11; _viewYear--; }
              });
            },
            scaleTo: 1.1,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chevron_left, color: kText, size: 18),
            ),
          ),
          Text(
            _monthTitle,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.2,
            ),
          ),
          // [PATCH B04] Nav arrow right
          _ScaleButton(
            onTap: () {
              setState(() {
                _viewMonth++;
                if (_viewMonth > 11) { _viewMonth = 0; _viewYear++; }
              });
            },
            scaleTo: 1.1,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chevron_right, color: kText, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final days = _daysInMonth;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final day = days[i];
          final isActive = _isSelected(day);
          final isToday = _isToday(day);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = day);
              _initCardAnimations();
            },
            // [PATCH B05/B06] Day pill with animated lift on selection
            child: _AnimatedDayPill(
              day: day,
              isActive: isActive,
              isToday: isToday,
              weekdayShort: _weekdayShort(day),
              // [PATCH B42] Show event dot if day has plans
              hasEvents: (_plansData[day.toIso8601String().substring(0, 10)] ?? []).isNotEmpty,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlansDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Color(0x1FFFFFFF), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildPlansSection() {
    final isToday = _isToday(_selectedDay);
    final label = isToday
        ? "Today's Plans"
        : '${_weekdayShort(_selectedDay)}, ${kMonths[_selectedDay.month - 1].substring(0, 3)} ${_selectedDay.day}';
    final plans = _todayPlans;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 0.12 * 11, color: kMuted,
            ),
          ),
          const SizedBox(height: 12),
          // [PATCH B07/B11] Plans grid with staggered animations + live data
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nothing planned ??\nTap "Add a Plan" below',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kMuted, height: 1.6),
                ),
              ),
            )
          else
            _buildPlansGrid(plans),
          const SizedBox(height: 12),
          _buildAddPlanButton(),
        ],
      ),
    );
  }

  // [PATCH B07] Staggered grid
  Widget _buildPlansGrid(List<PlanItem> plans) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: plans.length,
      itemBuilder: (context, i) {
        // [PATCH B07] Wrap each card in staggered FadeTransition + SlideTransition
        if (i < _cardControllers.length) {
          return FadeTransition(
            opacity: _cardFadeAnims[i],
            child: SlideTransition(
              position: _cardSlideAnims[i],
              child: _buildPlanCard(plans[i], i),
            ),
          );
        }
        return _buildPlanCard(plans[i], i);
      },
    );
  }

  Widget _buildPlanCard(PlanItem plan, int index) {
    final color = plan.color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeOccasion = plan.title;
          _activeEmoji = plan.emoji;
          _showChat = true;
          _messages.clear();
          _chipsVisible = true; // [PATCH B32] Reset chips on new chat
        });
      },
      // [PATCH B08] Plan card lift on hover/tap via _ScaleButton wrapper
      child: _ScaleButton(
        onTap: () {
          setState(() {
            _activeOccasion = plan.title;
            _activeEmoji = plan.emoji;
            _showChat = true;
            _messages.clear();
            _chipsVisible = true;
          });
        },
        scaleTo: 1.02,
        translateY: -4.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: _planCardBg(color),
            borderRadius: BorderRadius.circular(18),
            border: Border(
              top: BorderSide(color: _planBorderTop(color), width: 1),
              left: BorderSide(color: _planBorderTop(color).withOpacity(0.5), width: 1),
              right: BorderSide(color: kCardBorder.withOpacity(0.3), width: 1),
              bottom: BorderSide(color: kCardBorder.withOpacity(0.2), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(plan.title, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kText,
                  )),
                  const SizedBox(height: 4),
                  Text(plan.desc, style: const TextStyle(
                    fontSize: 11.5, color: kMuted, height: 1.5,
                  )),
                ],
              ),
              // [PATCH B10/B11] Delete button with rotate animation + functional delete
              Positioned(
                top: 0, right: 0,
                child: _RotatingDeleteButton(
                  onTap: () => _deletePlan(index),
                ),
              ),
              // [PATCH B12/B13] Bell button with scale animation + toggle logic
              Positioned(
                bottom: 0, right: 0,
                child: _BellButton(
                  isOn: plan.reminderOn,
                  onTap: () => _toggleReminder(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlanButton() {
    // [PATCH B14] Add plan button with lift animation
    return _ScaleButton(
      onTap: _openModal,
      translateY: -2.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: const BorderSide(color: Color(0x1AFFFFFF)),
            left: const BorderSide(color: Color(0x14FFFFFF)),
            right: const BorderSide(color: Color(0x0AFFFFFF)),
            bottom: BorderSide(color: kAccent2.withOpacity(0.35), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, size: 14, color: kMuted),
            SizedBox(width: 8),
            Text('Add a Plan', style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: kMuted,
            )),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // CHAT PAGE
  // ══════════════════════════════════════════
  Widget _buildChatPage() {
    return SafeArea(
      child: Column(
        children: [
          _buildChatHeader(),
          Expanded(child: _buildChatMessages()),
          _buildChatInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kCardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // [PATCH B28] Chat back button with scale + translate animation
          _ScaleButton(
            onTap: () => setState(() => _showChat = false),
            scaleTo: 1.08,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kCardBorder),
              ),
              child: const Icon(Icons.chevron_left, color: kText, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_activeOccasion — Style Chat',
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kText,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: kAccent3, shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Ask anything about your outfit.',
                      style: TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    final allItems = <Widget>[];

    if (_messages.isEmpty) {
      allItems.add(_buildAIBubble(
        'Hi! I\'m your style assistant for $_activeOccasion $_activeEmoji '
            'Ask me what to wear and I\'ll put together a complete outfit for you! 👗',
      ));
    } else {
      for (final msg in _messages) {
        if (msg['role'] == 'user') {
          allItems.add(_buildUserBubble(msg['text']!));
        } else {
          allItems.add(_buildAIBubble(msg['text']!));
        }
      }
    }

    // [PATCH B30] Show typing indicator when waiting for AI
    if (_isTyping) {
      allItems.add(_buildTypingIndicator());
    }

    return ListView(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(18),
      children: allItems,
    );
  }

  // [PATCH B29] AI bubble with entrance animation
  Widget _buildAIBubble(String text) {
    final ctrl = _createBubbleController();
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2), end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  color: kPanel, shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: kCardBorder)),
                ),
                child: const Center(child: Text('👗', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: kPanel,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5),
                        ),
                        border: Border.all(color: kCardBorder),
                        boxShadow: const [
                          BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Text(text, style: const TextStyle(
                        fontSize: 13.5, color: kText, height: 1.55,
                      )),
                    ),
                    const SizedBox(height: 3),
                    const Text('Now', style: TextStyle(fontSize: 10, color: kTextDim)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [PATCH B29] User bubble with entrance animation
  Widget _buildUserBubble(String text) {
    final ctrl = _createBubbleController();
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2), end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0x476B91FF), Color(0x338D7DFF)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(5),
                        ),
                        border: Border.all(color: const Color(0x596B91FF)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x266B91FF), blurRadius: 14, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Text(text, style: const TextStyle(
                        fontSize: 13.5, color: kText, height: 1.55,
                      )),
                    ),
                    const SizedBox(height: 3),
                    const Text('Now', style: TextStyle(fontSize: 10, color: kTextDim)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [PATCH B30] Typing indicator with animated bouncing dots
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              color: kPanel, shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: kCardBorder)),
            ),
            child: Center(child: Text(_activeEmoji, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: kPanel,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5),
              ),
              border: Border.all(color: kCardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, _) {
                    // Staggered: dot i peaks at phase offset (i * 0.15)
                    final phase = (_typingController.value + i * 0.15) % 1.0;
                    final t = (phase < 0.5) ? phase * 2 : (1 - phase) * 2;
                    final offset = Curves.easeInOut.transform(t) * -5.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t > 0.5 ? kAccent : kTextDim,
                          ),
                        ),
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

  Widget _buildChatInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        children: [
          // [PATCH B31/B32] Suggestion chips with visibility + animation + auto-send
          if (_chipsVisible)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kSuggestionChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return _ScaleButton(
                    onTap: () {
                      // [PATCH B32] Fill AND auto-send, hide chips
                      _chatCtrl.text = kSuggestionChips[i]['label']!;
                      _sendMessage();
                    },
                    scaleTo: 1.03,
                    translateY: -2.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: kPanel,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: const Color(0x4D6B91FF), width: 1.5),
                        boxShadow: const [BoxShadow(color: Color(0x1A6B91FF), blurRadius: 8)],
                      ),
                      child: Text(
                        kSuggestionChips[i]['label']!,
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: kAccent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: kPanel2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kCardBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 17, color: kTextDim),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(fontSize: 14, color: kText),
                    decoration: const InputDecoration(
                      hintText: 'Ask about your outfit…',
                      hintStyle: TextStyle(color: kTextDim),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button — no voice recognition yet, placeholder
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: kPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x408D7DFF)),
                  ),
                  child: const Icon(Icons.mic_none, size: 16, color: kAccent2),
                ),
                const SizedBox(width: 8),
                // [PATCH B33] Send button with scale animation
                _ScaleButton(
                  onTap: _sendMessage,
                  scaleTo: 1.08,
                  pressScale: 0.94,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x666B91FF),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // MODAL — Add Plan
  // ══════════════════════════════════════════
  Widget _buildModal() {
    return GestureDetector(
      // [PATCH B16] Backdrop dismiss
      onTap: () => setState(() => _modalOpen = false),
      child: FadeTransition(
        // [PATCH B15] Fade in overlay
        opacity: _modalFadeAnim,
        child: Container(
          color: const Color(0xA608111F),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: SlideTransition(
                // [PATCH B15] Sheet slide-up
                position: _modalSlideAnim,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [kBg2, kPhoneShell],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32), topRight: Radius.circular(32),
                      bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22),
                    ),
                    border: const Border(
                      top: BorderSide(color: Color(0x24FFFFFF), width: 1.5),
                      left: BorderSide(color: Color(0x1AFFFFFF)),
                      right: BorderSide(color: Color(0x0FFFFFFF)),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x8C000000), blurRadius: 36, offset: Offset(0, -8)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 42, height: 4,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: const Color(0x2EFFFFFF),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('New Plan', style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600, color: kText,
                            )),
                            GestureDetector(
                              onTap: () => setState(() => _modalOpen = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                decoration: BoxDecoration(
                                  color: kPanel,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: kCardBorder),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.close, size: 13, color: kMuted),
                                    SizedBox(width: 5),
                                    Text('Close', style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600, color: kMuted,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('CHOOSE OCCASION', style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w700,
                          letterSpacing: 0.16 * 10.5, color: kMuted,
                        )),
                        const SizedBox(height: 10),
                        // [PATCH B17/B18] Event grid with press animation + navigation to chat
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, mainAxisSpacing: 8,
                            crossAxisSpacing: 8, childAspectRatio: 0.9,
                          ),
                          itemCount: kEventTypes.length,
                          itemBuilder: (context, i) {
                            final ev = kEventTypes[i];
                            final isActive = _selectedEvent == ev['label'];
                            return _ScaleButton(
                              onTap: () {
                                // [PATCH B18] Select event AND navigate to chat
                                setState(() {
                                  _selectedEvent = ev['label']!;
                                  _selectedEventEmoji = ev['emoji']!;
                                  _modalOpen = false;
                                  _activeOccasion = ev['label']!;
                                  _activeEmoji = ev['emoji']!;
                                  _showChat = true;
                                  _messages.clear();
                                  _chipsVisible = true;
                                });
                              },
                              scaleTo: 1.06,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: _eventBg(ev['type']!),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? _eventColor(ev['type']!).withOpacity(0.55)
                                        : kCardBorder,
                                    width: isActive ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(ev['emoji']!, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(height: 5),
                                    Text(ev['label']!, style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: _eventColor(ev['type']!),
                                    )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // [PATCH B20/B21] Outfit suggestions carousel
                        Text(
                          _selectedEvent.isNotEmpty
                              ? 'IDEAS FOR $_selectedEvent'
                              : 'OUTFIT SUGGESTIONS',
                          style: const TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w700,
                            letterSpacing: 0.16 * 10.5, color: kMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildOutfitCarousel(),
                        const SizedBox(height: 16),
                        const Text('SET TIME', style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w700,
                          letterSpacing: 0.16 * 10.5, color: kMuted,
                        )),
                        const SizedBox(height: 10),
                        _buildTimeRow(),
                        const SizedBox(height: 16),
                        // [PATCH B26] Save button with press animation
                        _ScaleButton(
                          onTap: _savePlan,
                          scaleTo: 1.015,
                          pressScale: 0.98,
                          translateY: -2.0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x596B91FF),
                                  blurRadius: 22, offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.calendar_today, size: 16, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Save to Calendar', style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // [PATCH B20/B21] Outfit carousel for modal
  Widget _buildOutfitCarousel() {
    final outfits = kOutfits[_selectedEvent];
    if (outfits == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAccent2.withOpacity(0.28), width: 1.5),
        ),
        child: const Center(
          child: Text(
            'Select an occasion above to see outfit ideas ?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextDim),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: outfits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final outfit = outfits[i];
          final isPicked = _pickedOutfitIdx == i;
          // [PATCH B20/B21] Outfit card with scale + picked badge animation
          return _ScaleButton(
            onTap: () => setState(() => _pickedOutfitIdx = i),
            scaleTo: 1.02,
            translateY: -3.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 165,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.7, -0.7),
                  end: const Alignment(0.7, 0.7),
                  colors: isPicked
                      ? [const Color(0x478D7DFF), const Color(0x2E6B91FF)]
                      : [const Color(0x286B91FF), const Color(0x1A8D7DFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPicked
                      ? kAccent2.withOpacity(0.55)
                      : kCardBorder,
                  width: isPicked ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPicked
                        ? kAccent2.withOpacity(0.35)
                        : Colors.black.withOpacity(0.25),
                    blurRadius: isPicked ? 22 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outfit['vibe'] ?? '',
                        style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          letterSpacing: 1.2, color: kAccent,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        outfit['desc'] ?? '',
                        style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: kText, height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '💡 ${outfit['tip'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: kMuted, height: 1.5),
                      ),
                    ],
                  ),
                  // [PATCH B21] Picked badge with scale animation
                  Positioned(
                    top: 0, right: 0,
                    child: AnimatedScale(
                      scale: isPicked ? 1.0 : 0.65,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: isPicked ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text('✓ Picked', style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white,
                          )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRow() {
    // [PATCH B22] Focus-aware time row with animated border glow
    return _FocusGlowContainer(
      focusNodes: [_hourFocus, _minFocus],
      child: Row(
        children: [
          const Icon(Icons.access_time_outlined, size: 18, color: kTextDim),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _hourCtrl,
              focusNode: _hourFocus,
              keyboardType: TextInputType.number,
              // [PATCH B23] Max-length of 2 for auto-advance
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: kText,
              ),
              decoration: const InputDecoration(
                hintText: 'HH',
                hintStyle: TextStyle(color: Color(0x38E6EBFF)),
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const Text(':', style: TextStyle(fontSize: 22, color: kTextDim)),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _minCtrl,
              focusNode: _minFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: kText,
              ),
              decoration: const InputDecoration(
                hintText: 'MM',
                hintStyle: TextStyle(color: Color(0x38E6EBFF)),
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Container(
            width: 1, height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [kCardBorder, Color(0x0FFFFFFF)],
              ),
            ),
          ),
          Row(
            children: [
              _buildAmPmBtn('AM'),
              const SizedBox(width: 4),
              _buildAmPmBtn('PM'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmBtn(String label) {
    final isActive = _selectedAmPm == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedAmPm = label),
      child: AnimatedContainer(
        // [PATCH B25] Animated AM/PM toggle
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [kAccent, kAccent2])
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [BoxShadow(color: kAccent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800,
            letterSpacing: 0.06 * 12,
            color: isActive ? Colors.white : kMuted,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════

/// [PATCH B01/B04/B08/B14/B26/B28/B33] Universal scale+translate press button
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleTo;
  final double pressScale;
  final double translateY;

  const _ScaleButton({
    required this.child,
    required this.onTap,
    this.scaleTo = 1.0,
    this.pressScale = 0.96,
    this.translateY = 0.0,
  });

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _yAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _yAnim = Tween<double>(begin: 0.0, end: widget.translateY).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _pressed = true);
    _ctrl.forward();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _yAnim.value),
            child: Transform.scale(
              scale: _pressed ? _scaleAnim.value : 1.0,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// [PATCH B05/B06] Animated day pill with lift on selection
class _AnimatedDayPill extends StatefulWidget {
  final DateTime day;
  final bool isActive;
  final bool isToday;
  final bool hasEvents;
  final String weekdayShort;

  const _AnimatedDayPill({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.hasEvents,
    required this.weekdayShort,
  });

  @override
  State<_AnimatedDayPill> createState() => _AnimatedDayPillState();
}

class _AnimatedDayPillState extends State<_AnimatedDayPill> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(
        0,
        widget.isActive ? -3.0 : 0.0,
        0,
      ),
      transformAlignment: Alignment.center,
      child: AnimatedScale(
        scale: widget.isActive ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50, height: 76,
              decoration: BoxDecoration(
                gradient: widget.isActive
                    ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0x4D6B91FF), Color(0x388D7DFF), Color(0x266B91FF)],
                )
                    : null,
                color: widget.isActive ? null : kPanel,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  top: BorderSide(
                    color: widget.isActive ? const Color(0x33FFFFFF) : const Color(0x1FFFFFFF),
                  ),
                  left: BorderSide(
                    color: widget.isActive ? const Color(0x596B91FF) : const Color(0x14FFFFFF),
                  ),
                  right: const BorderSide(color: Color(0x0DFFFFFF)),
                  bottom: const BorderSide(color: Color(0x0AFFFFFF)),
                ),
                boxShadow: widget.isActive
                    ? const [BoxShadow(color: Color(0x596B91FF), blurRadius: 24, offset: Offset(0, 8))]
                    : const [BoxShadow(color: Color(0x596B91FF), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.weekdayShort,
                    style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                      letterSpacing: 0.08 * 9.5,
                      color: widget.isActive ? kAccent : kTextDim,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.day.day}',
                    style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700, color: kText, height: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isToday)
              Positioned(
                top: 7, right: 7,
                child: Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    color: kAccent3, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0xBF04D7C8), blurRadius: 7)],
                  ),
                ),
              ),
            // [PATCH B42] Event dot only if has plans
            if (widget.hasEvents)
              Positioned(
                bottom: 17, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [kAccent, kAccent2]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [PATCH B10/B11] Delete button with rotate-on-press animation
class _RotatingDeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RotatingDeleteButton({required this.onTap});

  @override
  State<_RotatingDeleteButton> createState() => _RotatingDeleteButtonState();
}

class _RotatingDeleteButtonState extends State<_RotatingDeleteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.25) // 90 degrees = 0.25 turns
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: RotationTransition(
            turns: _rotateAnim,
            child: child,
          ),
        ),
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: kPanel, shape: BoxShape.circle,
            border: Border.all(color: kCardBorder),
          ),
          child: const Icon(Icons.close, size: 9, color: kAccent4),
        ),
      ),
    );
  }
}

/// [PATCH B12/B13] Bell button with scale animation and toggle state
class _BellButton extends StatefulWidget {
  final bool isOn;
  final VoidCallback onTap;
  const _BellButton({required this.isOn, required this.onTap});

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 26, height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isOn
                ? const LinearGradient(
              colors: [Color(0x386B91FF), Color(0x236B91FF)],
            )
                : null,
            color: widget.isOn ? null : kPanel,
            border: widget.isOn
                ? Border.all(color: const Color(0x666B91FF), width: 1.5)
                : null,
          ),
          child: Icon(
            widget.isOn ? Icons.notifications : Icons.notifications_off_outlined,
            size: 13,
            color: widget.isOn ? kAccent : kTextDim,
          ),
        ),
      ),
    );
  }
}

/// [PATCH B02] Animated pulse dot
class _PulseDot extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> animation;

  const _PulseDot({required this.controller, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Pulse: box-shadow spread grows from 0→8 then back to 0
        final spread = Curves.easeOut.transform(
          (animation.value < 0.7)
              ? animation.value / 0.7
              : (1.0 - animation.value) / 0.3,
        ) * 8.0;
        return Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [kAccent, kAccent2]),
            boxShadow: [
              BoxShadow(
                color: kAccent.withOpacity(0.6),
                blurRadius: spread,
                spreadRadius: spread * 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [PATCH B22] Focus-aware container with animated glow border
class _FocusGlowContainer extends StatefulWidget {
  final Widget child;
  final List<FocusNode> focusNodes;

  const _FocusGlowContainer({required this.child, required this.focusNodes});

  @override
  State<_FocusGlowContainer> createState() => _FocusGlowContainerState();
}

class _FocusGlowContainerState extends State<_FocusGlowContainer> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    for (final fn in widget.focusNodes) {
      fn.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    final focused = widget.focusNodes.any((fn) => fn.hasFocus);
    if (focused != _isFocused) {
      setState(() => _isFocused = focused);
    }
  }

  @override
  void dispose() {
    for (final fn in widget.focusNodes) {
      fn.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? kAccent2.withOpacity(0.5) : kCardBorder,
        ),
        boxShadow: _isFocused
            ? [BoxShadow(color: kAccent2.withOpacity(0.18), blurRadius: 10, spreadRadius: 2)]
            : [],
      ),
      child: widget.child,
    );
  }
}

/// [PATCH B37] Toast overlay widget
class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const _ToastWidget({required this.message, required this.onDismissed});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) {
          _ctrl.reverse().then((_) {
            if (mounted) widget.onDismissed();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0, right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xEC0F1A2D),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kCardBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 20),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w500, color: kText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Inline, reusable calendar panel for Boards screen.

// Inline, reusable calendar panel for Boards screen.
typedef PlanCountsCallback = void Function(int totalPlans, int todayPlans);

class ExpandableCalendarPanel extends StatefulWidget {
  final PlanCountsCallback? onCountsChanged;
  const ExpandableCalendarPanel({super.key, this.onCountsChanged});

  @override
  State<ExpandableCalendarPanel> createState() => _ExpandableCalendarPanelState();
}

class _ExpandableCalendarPanelState extends State<ExpandableCalendarPanel>
    with TickerProviderStateMixin {
  final DateTime _today = DateTime.now();
  late DateTime _selectedDay;
  late DateTime _weekAnchor;

  final Map<String, List<PlanItem>> _plansData = {
    DateTime.now().toIso8601String().substring(0, 10): [
      PlanItem(emoji: '💪', title: 'Gym', desc: 'Cardio Day · 7:00 AM', outfit: '', color: 'blue'),
      PlanItem(emoji: '💼', title: 'Office', desc: 'Formal Meeting · 10:30 AM', outfit: '', color: 'purple'),
    ],
  };

  String _selectedEvent = '';
  String _selectedEventEmoji = '📅';
  String _selectedAmPm = 'AM';
  final TextEditingController _hourCtrl = TextEditingController();
  final TextEditingController _minCtrl = TextEditingController();
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minFocus = FocusNode();

  OverlayEntry? _toastOverlay;

  String get _selectedDayKey => _selectedDay.toIso8601String().substring(0, 10);
  List<PlanItem> get _todayPlans => _plansData[_selectedDayKey] ?? [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_today.year, _today.month, _today.day);
    _weekAnchor = _startOfWeek(_selectedDay);

    _hourCtrl.addListener(() {
      final v = int.tryParse(_hourCtrl.text);
      if (_hourCtrl.text.length >= 2) {
        if (v != null && v > 12) _hourCtrl.text = '12';
        FocusScope.of(context).requestFocus(_minFocus);
      }
    });

    _minFocus.addListener(() {
      if (!_minFocus.hasFocus && _minCtrl.text.length == 1) {
        _minCtrl.text = '0${_minCtrl.text}';
      }
    });

    _notifyCounts();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _hourFocus.dispose();
    _minFocus.dispose();
    super.dispose();
  }

  void _notifyCounts() {
    if (widget.onCountsChanged == null) return;
    int total = 0;
    _plansData.forEach((_, list) => total += list.length);
    final todayKey = _today.toIso8601String().substring(0, 10);
    final todayCount = _plansData[todayKey]?.length ?? 0;
    widget.onCountsChanged!(total, todayCount);
  }
  DateTime _startOfWeek(DateTime d) {
    final weekday = d.weekday; // 1=Mon
    return d.subtract(Duration(days: weekday - 1));
  }

  List<DateTime> _weekDays(DateTime start) {
    return List<DateTime>.generate(
      7,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }

  void _shiftWeek(int delta) {
    setState(() {
      _weekAnchor = _weekAnchor.add(Duration(days: 7 * delta));
      _selectedDay = _selectedDay.add(Duration(days: 7 * delta));
    });
  }

  void _selectDay(DateTime d) {
    setState(() => _selectedDay = d);
  }

  bool _isToday(DateTime d) =>
      d.year == _today.year && d.month == _today.month && d.day == _today.day;

  bool _isSelected(DateTime d) =>
      d.year == _selectedDay.year && d.month == _selectedDay.month && d.day == _selectedDay.day;

  String _weekdayShort(DateTime d) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return names[d.weekday - 1];
  }

  void _openModal() {
    setState(() {
      _selectedEvent = '';
      _selectedEventEmoji = '📅';
      _selectedAmPm = 'AM';
      _hourCtrl.clear();
      _minCtrl.clear();
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xA608111F),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => _buildModalSheet(modalSetState),
      ),
    );
  }

  void _savePlan() {
    final hRaw = int.tryParse(_hourCtrl.text);
    final mRaw = int.tryParse(_minCtrl.text);
    if (_selectedEvent.isEmpty) {
      _showToast('Please choose an occasion first.');
      return;
    }
    if (hRaw == null || hRaw < 1 || hRaw > 12) {
      _showToast('Enter a valid hour (1-12).');
      return;
    }
    if (mRaw == null || mRaw < 0 || mRaw > 59) {
      _showToast('Enter a valid minute (0-59).');
      return;
    }

    final hh = hRaw.toString().padLeft(2, '0');
    final mm = mRaw.toString().padLeft(2, '0');
    final timeDisplay = '$hh:$mm $_selectedAmPm';

    final plan = PlanItem(
      emoji: _selectedEventEmoji,
      title: _selectedEvent,
      desc: timeDisplay,
      outfit: '',
      color: ['blue', 'purple', 'pink'][DateTime.now().millisecondsSinceEpoch % 3],
    );

    setState(() {
      _plansData[_selectedDayKey] = [...(_plansData[_selectedDayKey] ?? []), plan];
    });
    _notifyCounts();
    _showToast('Plan saved!');
    if (mounted) Navigator.of(context).pop();
  }

  void _showToast(String message) {
    _toastOverlay?.remove();
    _toastOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        onDismissed: () {
          entry.remove();
          if (_toastOverlay == entry) _toastOverlay = null;
        },
      ),
    );

    _toastOverlay = entry;
    overlay.insert(entry);
  }
  LinearGradient _eventBg(String type, bool active) {
    switch (type) {
      case 'teal':
        return LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: active
              ? const [Color(0x6004D7C8), Color(0x3004D7C8)]
              : const [Color(0x3804D7C8), Color(0x1E04D7C8)],
        );
      case 'purple':
        return LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: active
              ? const [Color(0x608D7DFF), Color(0x308D7DFF)]
              : const [Color(0x388D7DFF), Color(0x1E8D7DFF)],
        );
      case 'pink':
        return LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: active
              ? const [Color(0x60FF8EC7), Color(0x30FF8EC7)]
              : const [Color(0x2EFF8EC7), Color(0x1AFF8EC7)],
        );
      case 'amber':
        return LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: active
              ? const [Color(0x60FFD86E), Color(0x30FFD86E)]
              : const [Color(0x38FFD86E), Color(0x1EFFD86E)],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: active
              ? const [Color(0x606B91FF), Color(0x306B91FF)]
              : const [Color(0x286B91FF), Color(0x1A6B91FF)],
        );
    }
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'teal': return kAccent3;
      case 'purple': return kAccent2;
      case 'pink': return kAccent4;
      case 'amber': return kAccent5;
      default: return kAccent;
    }
  }

  LinearGradient _planCardBg(String color) {
    switch (color) {
      case 'pink':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x28FF8EC7), Color(0x14FF8EC7)],
        );
      case 'purple':
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x2A8D7DFF), Color(0x148D7DFF)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x2A6B91FF), Color(0x146B91FF)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = _weekDays(_weekAnchor);

    return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPanel, kPanel2],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kCardBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ScaleButton(
                      onTap: () => _shiftWeek(-1),
                      scaleTo: 1.1,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: kPanel,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.chevron_left, color: kText, size: 18),
                      ),
                    ),
                    Text(
                      _monthTitleFor(week),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    _ScaleButton(
                      onTap: () => _shiftWeek(1),
                      scaleTo: 1.1,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: kPanel,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.chevron_right, color: kText, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: week.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, i) {
                    final day = week[i];
                    final isActive = _isSelected(day);
                    final isToday = _isToday(day);
                    return GestureDetector(
                      onTap: () => _selectDay(day),
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0x4D6B91FF), Color(0x388D7DFF), Color(0x266B91FF)],
                                )
                              : null,
                          color: isActive ? null : kPanel,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            top: BorderSide(color: isActive ? const Color(0x33FFFFFF) : kCardBorder),
                            left: BorderSide(color: isActive ? const Color(0x596B91FF) : const Color(0x14FFFFFF)),
                            right: const BorderSide(color: Color(0x0DFFFFFF)),
                            bottom: const BorderSide(color: Color(0x0AFFFFFF)),
                          ),
                          boxShadow: isActive
                              ? const [BoxShadow(color: Color(0x596B91FF), blurRadius: 24, offset: Offset(0, 8))]
                              : const [BoxShadow(color: Color(0x596B91FF), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _weekdayShort(day),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.08 * 9.5,
                                    color: isActive ? kAccent : kTextDim,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                            if (isToday)
                              const Positioned(
                                top: 7,
                                right: 7,
                                child: _TodayDot(),
                              ),
                            if (isActive)
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [kAccent, kAccent2]),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, kCardBorder, Colors.transparent],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x0F6B91FF), Color(0x0A8D7DFF)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TODAY'S PLANS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_todayPlans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            'Nothing planned ??\nTap "Add a Plan" below',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: kMuted, height: 1.6),
                          ),
                        ),
                      )
                    else
                      _buildPlansGrid(_todayPlans),
                    const SizedBox(height: 12),
                    _buildAddPlanButton(),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  String _monthTitleFor(List<DateTime> week) {
    final m = week.first.month;
    return '${kMonths[m - 1]} ${week.first.year}';
  }

  Widget _buildPlansGrid(List<PlanItem> plans) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 1.1,
      ),
      itemCount: plans.length,
      itemBuilder: (context, i) {
        final plan = plans[i];
        return Container(
          decoration: BoxDecoration(
            gradient: _planCardBg(plan.color),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kCardBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(plan.title, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: kText,
              )),
              const SizedBox(height: 4),
              Text(plan.desc, style: const TextStyle(
                fontSize: 11.5, color: kMuted, height: 1.5,
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddPlanButton() {
    return _ScaleButton(
      onTap: _openModal,
      translateY: -2.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kAccent, kAccent2]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x596B91FF), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        child: const Center(
          child: Text(
            '+ Add a Plan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildModalSheet(StateSetter modalSetState) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [kBg2, kPhoneShell],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32),
            bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22),
          ),
          border: const Border(
            top: BorderSide(color: Color(0x24FFFFFF), width: 1.5),
            left: BorderSide(color: Color(0x1AFFFFFF)),
            right: BorderSide(color: Color(0x0FFFFFFF)),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x8C000000), blurRadius: 36, offset: Offset(0, -8)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0x2EFFFFFF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Plan', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: kText,
                  )),
                  GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: kPanel,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: kCardBorder),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.close, size: 13, color: kMuted),
                          SizedBox(width: 5),
                          Text('Close', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: kMuted,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('CHOOSE OCCASION', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.16 * 10.5, color: kMuted,
              )),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 8,
                  crossAxisSpacing: 8, childAspectRatio: 0.9,
                ),
                itemCount: kEventTypes.length,
                itemBuilder: (context, i) {
                  final ev = kEventTypes[i];
                  final isActive = _selectedEvent == ev['label'];
                  return _ScaleButton(
                    onTap: () {
                      modalSetState(() {
                        _selectedEvent = ev['label']!;
                        _selectedEventEmoji = ev['emoji']!;
                      });
                    },
                    scaleTo: 1.06,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: _eventBg(ev['type']!, isActive),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? _eventColor(ev['type']!).withOpacity(0.55)
                              : kCardBorder,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(ev['emoji']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 5),
                          Text(ev['label']!, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: _eventColor(ev['type']!),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text('OUTFIT SUGGESTIONS', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.16 * 10.5, color: kMuted,
              )),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPanel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAccent2.withOpacity(0.28), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'Select an occasion above to see outfit ideas ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: kTextDim),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('SET TIME', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.16 * 10.5, color: kMuted,
              )),
              const SizedBox(height: 10),
              _buildTimeRow(modalSetState),
              const SizedBox(height: 16),
              _ScaleButton(
                onTap: () {
                  _savePlan();
                  Navigator.of(context).pop();
                },
                scaleTo: 1.015,
                pressScale: 0.98,
                translateY: -2.0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x596B91FF), blurRadius: 22, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_today, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Save to Calendar', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(StateSetter modalSetState) {
    return _FocusGlowContainer(
      focusNodes: [_hourFocus, _minFocus],
      child: Row(
        children: [
          const Icon(Icons.access_time_outlined, size: 18, color: kTextDim),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _hourCtrl,
              focusNode: _hourFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: kText,
              ),
              decoration: const InputDecoration(
                hintText: 'HH',
                hintStyle: TextStyle(color: Color(0x38E6EBFF)),
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const Text(':', style: TextStyle(fontSize: 22, color: kTextDim)),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _minCtrl,
              focusNode: _minFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: kText,
              ),
              decoration: const InputDecoration(
                hintText: 'MM',
                hintStyle: TextStyle(color: Color(0x38E6EBFF)),
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Container(
            width: 1, height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [kCardBorder, Color(0x0FFFFFFF)],
              ),
            ),
          ),
          Row(
            children: [
              _buildAmPmBtn('AM', modalSetState),
              const SizedBox(width: 4),
              _buildAmPmBtn('PM', modalSetState),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmBtn(String label, StateSetter modalSetState) {
    final isActive = _selectedAmPm == label;
    return GestureDetector(
      onTap: () {
        modalSetState(() {
          _selectedAmPm = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [kAccent, kAccent2]) : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [BoxShadow(color: kAccent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800,
            letterSpacing: 0.06 * 12,
            color: isActive ? Colors.white : kMuted,
          ),
        ),
      ),
    );
  }
}

class _TodayDot extends StatelessWidget {
  const _TodayDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: kAccent3,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0xBF04D7C8), blurRadius: 7)],
      ),
    );
  }
}
