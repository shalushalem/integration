import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// â”€â”€ Theme Integration â”€â”€
import 'package:myapp/theme/theme_tokens.dart';
// â”€â”€ Backend Services â”€â”€
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/services/backend_service.dart';

part 'calendar_parts.dart';

// â”€â”€ Sample Data â”€â”€
const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

// â”€â”€ Dynamic Occasion Images â”€â”€
String getOccasionImage(String occasion) {
  final occ = occasion.toLowerCase();
  if (occ.contains('gym') || occ.contains('workout')) return 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=400&q=80';
  if (occ.contains('office') || occ.contains('study')) return 'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=400&q=80';
  if (occ.contains('party')) return 'https://images.unsplash.com/photo-1566336528768-eeec445a49b5?w=400&q=80';
  if (occ.contains('shop')) return 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&q=80';
  if (occ.contains('date')) return 'https://images.unsplash.com/photo-1495385794356-15371f348c31?w=400&q=80';
  if (occ.contains('travel')) return 'https://images.unsplash.com/photo-1506012787146-f92b2d7d6d96?w=400&q=80';
  return 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&q=80'; // default chic placeholder
}

// Plan data model
class Plan {
  final String? id; 
  final String occasion;
  final String emoji;
  final String outfitDescription;
  final DateTime dateTime;
  bool reminder;

  Plan({
    this.id,
    required this.occasion,
    required this.emoji,
    required this.outfitDescription,
    required this.dateTime,
    this.reminder = true,
  });
}

const List<Map<String, String>> kEventTypes = [
  {'label': 'Gym', 'emoji': 'ðŸ’ª', 'type': 'teal'},
  {'label': 'Office', 'emoji': 'ðŸ’¼', 'type': 'purple'},
  {'label': 'Party', 'emoji': 'ðŸŽŠ', 'type': 'pink'},
  {'label': 'Shopping', 'emoji': 'ðŸ›ï¸', 'type': 'amber'},
  {'label': 'Study', 'emoji': 'ðŸ“–', 'type': 'blue'},
  {'label': 'Travel', 'emoji': 'âœˆï¸', 'type': 'teal'},
  {'label': 'Event', 'emoji': 'ðŸŒŸ', 'type': 'blue'},
  {'label': 'Date Night', 'emoji': 'â¤ï¸', 'type': 'pink'},
];

const List<Map<String, String>> kSuggestionChips = [
  {'label': 'What should I wear today?'},
  {'label': 'Outfit for a date night ðŸŒ™'},
  {'label': 'Casual weekend look'},
  {'label': 'Work-appropriate outfit'},
  {'label': 'What to pack for a trip?'},
  {'label': 'Summer party outfit ðŸŽ‰'},
];

const Map<String, List<Map<String, String>>> kOutfits = {
  'Gym': [
    {'vibe': 'Cardio Day', 'desc': 'Leggings, Sports tank, Running shoes', 'tip': 'Go breathable â€” skip cotton.', 'summary': 'Leggings, sports tank & running shoes'},
    {'vibe': 'Weight Training', 'desc': 'Gym shorts, Loose tee, Cross-trainers', 'tip': 'Flat soles = better grip.', 'summary': 'Gym shorts, loose tee & cross-trainers'},
    {'vibe': 'Yoga / Pilates', 'desc': 'High-waist yoga pants, Fitted top, Grip socks', 'tip': 'Fitted top only.', 'summary': 'Yoga pants, fitted top & grip socks'},
  ],
  'Office': [
    {'vibe': 'Formal Meeting', 'desc': 'Dress shirt, Dark trousers, Leather shoes', 'tip': 'Iron your collar.', 'summary': 'Dress shirt, dark trousers & leather shoes'},
    {'vibe': 'Regular Workday', 'desc': 'Chinos, Polo or blouse, Loafers', 'tip': 'Stick to 2â€“3 neutral colors.', 'summary': 'Chinos, polo & loafers'},
    {'vibe': 'Creative Office', 'desc': 'Dark jeans, Knit top, Clean sneakers', 'tip': 'Swap to loafers for clients.', 'summary': 'Dark jeans, knit top & sneakers'},
  ],
  'Party': [
    {'vibe': 'Evening Out', 'desc': 'Slip dress, Strappy heels, Small bag', 'tip': 'Bold dress OR bold shoes.', 'summary': 'Slip dress, heels & small bag'},
    {'vibe': 'Cocktail Party', 'desc': 'Wide-leg trousers, Silky top, Block heels', 'tip': 'Half-tuck for polish.', 'summary': 'Wide-leg trousers, silky top & block heels'},
    {'vibe': 'House Party', 'desc': 'Jeans, Printed top, Ankle boots', 'tip': 'Stylish jeans always hit.', 'summary': 'Jeans, printed top & ankle boots'},
  ],
};

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  final DateTime _today = DateTime.now();
  late int _viewYear;
  late int _viewMonth;
  late DateTime _selectedDay;

  final Map<DateTime, List<Plan>> _plansData = {};

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get _selectedDayKey => _normalizeDate(_selectedDay);
  List<Plan> _plansForDay(DateTime d) => _plansData[_normalizeDate(d)] ?? [];
  List<Plan> get _todayPlans => _plansForDay(_selectedDay);

  // Modal state
  String _selectedEvent = '';
  String _selectedEventEmoji = 'ðŸ“…';
  String _selectedAmPm = 'AM';
  final TextEditingController _hourCtrl = TextEditingController();
  final TextEditingController _minCtrl = TextEditingController();
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minFocus = FocusNode();

  // Chat & Plan Creation state
  bool _showChat = false;
  bool _isCreatingPlan = false;
  bool _isSaving = false; 
  DateTime? _pendingPlanDate;
  String _pendingOutfit = '';
  String _activeOccasion = 'Gym';
  String _activeEmoji = 'ðŸ’ª';
  List<Map<String, String>> _currentChatChips = kSuggestionChips;
  
  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  bool _chipsVisible = true;

  // Animation controllers
  final List<AnimationController> _bubbleControllers = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardFadeAnims = [];
  final List<Animation<Offset>> _cardSlideAnims = [];
  OverlayEntry? _toastOverlay;
  late AnimationController _typingController;
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewYear = _today.year;
    _viewMonth = _today.month - 1;
    _selectedDay = _normalizeDate(_today);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

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

    _loadPlansFromAppwrite();
  }

  Future<void> _loadPlansFromAppwrite() async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final docs = await appwrite.getUserPlans();
      
      final newPlans = <DateTime, List<Plan>>{};
      
      for (var doc in docs) {
        final data = doc.data;
        // Parse UTC from Appwrite to Local time
        final dt = DateTime.parse(data['dateTime']).toLocal(); 
        final dateKey = _normalizeDate(dt);
        
        final plan = Plan(
          id: doc.$id,
          occasion: data['occasion'] ?? 'Event',
          emoji: data['emoji'] ?? 'ðŸ“…',
          outfitDescription: data['outfitDescription'] ?? 'Custom Outfit',
          dateTime: dt,
          reminder: data['reminder'] ?? true,
        );
        
        newPlans.putIfAbsent(dateKey, () => []).add(plan);
      }

      if (mounted) {
        setState(() {
          _plansData.clear();
          _plansData.addAll(newPlans);
        });
        _initCardAnimations();
      }
    } catch (e) {
      debugPrint("Error loading plans: $e");
    }
  }

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

  bool _hasPlans(DateTime d) => _plansForDay(d).isNotEmpty;

  String _weekdayShort(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  Color _eventColor(String type, AppThemeTokens t) {
    switch (type) {
      case 'teal': return t.accent.tertiary;
      case 'purple': return t.accent.secondary;
      case 'pink': return Color.lerp(t.accent.primary, t.accent.tertiary, 0.5) ?? t.accent.tertiary;
      case 'amber': return Color.lerp(t.accent.secondary, t.accent.tertiary, 0.5) ?? t.accent.secondary;
      case 'blue': return t.accent.primary;
      default: return t.accent.primary;
    }
  }

  String _planTypeKey(Plan plan) {
    final occ = plan.occasion.toLowerCase();
    if (occ.contains('gym')) return 'teal';
    if (occ.contains('office') || occ.contains('work')) return 'purple';
    if (occ.contains('party') || occ.contains('date')) return 'pink';
    if (occ.contains('shop')) return 'amber';
    if (occ.contains('study')) return 'blue';
    if (occ.contains('travel')) return 'teal';
    return 'blue';
  }

  String _formatPlanTime(Plan plan) {
    final t = TimeOfDay.fromDateTime(plan.dateTime);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$mm $ampm';
  }

  LinearGradient _eventBg(String type, bool active, AppThemeTokens t) {
    final c = _eventColor(type, t);
    return LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: active
          ? [c.withValues(alpha: 0.35), c.withValues(alpha: 0.18)]
          : [c.withValues(alpha: 0.22), c.withValues(alpha: 0.11)],
    );
  }

  LinearGradient _planCardBg(String colorType, AppThemeTokens t) {
    final c = _eventColor(colorType, t);
    return LinearGradient(
      begin: const Alignment(-0.7, -0.7), end: const Alignment(0.7, 0.7),
      colors: [c.withValues(alpha: 0.20), c.withValues(alpha: 0.10)],
    );
  }

  Color _planBorderTop(String colorType, AppThemeTokens t) {
    final c = _eventColor(colorType, t);
    return c.withValues(alpha: 0.30);
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

  Future<void> _deletePlan(int index) async {
    final list = _plansData[_selectedDayKey];
    if (list == null || index >= list.length) return;
    
    final planToDelete = list[index];
    
    setState(() {
      list.removeAt(index);
      if (list.isEmpty) _plansData.remove(_selectedDayKey);
    });
    _initCardAnimations();

    if (planToDelete.id != null) {
      try {
        final appwrite = Provider.of<AppwriteService>(context, listen: false);
        await appwrite.deletePlan(planToDelete.id!);
        _showToast('Plan removed');
      } catch (e) {
        _showToast('âš  Failed to remove from cloud');
      }
    }
  }

  void _toggleReminder(int index) {
    final plans = _plansData[_selectedDayKey];
    if (plans == null || index >= plans.length) return;
    
    final plan = plans[index];
    setState(() {
      plan.reminder = !plan.reminder;
    });

    if (plan.id != null) {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      appwrite.updatePlanReminder(plan.id!, plan.reminder);
    }
    
    _showToast(plan.reminder ? 'ðŸ”” Reminder turned on!' : 'ðŸ”• Reminder turned off');
  }

  Future<void> _savePlanFromChat() async {
    if (_pendingPlanDate == null || _isSaving) return; 

    setState(() => _isSaving = true);
    final appwrite = Provider.of<AppwriteService>(context, listen: false);

    try {
      final desc = _pendingOutfit.isEmpty ? 'Custom Outfit' : _pendingOutfit;

      final doc = await appwrite.createPlan({
        'occasion': _activeOccasion,
        'emoji': _activeEmoji,
        'outfitDescription': desc, 
        'dateTime': _pendingPlanDate!.toUtc().toIso8601String(), 
        'reminder': true,
      });

      final newPlan = Plan(
        id: doc.$id,
        emoji: _activeEmoji,
        occasion: _activeOccasion,
        outfitDescription: desc,
        dateTime: _pendingPlanDate!,
        reminder: true,
      );

      setState(() {
        _plansData[_selectedDayKey] = [...(_plansData[_selectedDayKey] ?? []), newPlan];
        _plansData[_selectedDayKey]!.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _showChat = false;
        _isCreatingPlan = false;
      });
      
      _initCardAnimations();
      _showToast('ðŸ“… Plan saved!');
    } catch (e) {
      _showToast('âš  Failed to save plan. Check connection.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openModal() {
    final now = DateTime.now();
    int h = now.hour % 12;
    if (h == 0) h = 12;

    setState(() {
      _selectedEvent = '';
      _selectedEventEmoji = 'ðŸ“…';
      _selectedAmPm = now.hour >= 12 ? 'PM' : 'AM';
      _hourCtrl.text = h.toString();
      _minCtrl.text = '00';
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      useRootNavigator: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, modalSetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Material(
            color: Colors.transparent,
            child: _buildModalSheet(sheetContext, modalSetState, context.themeTokens),
          ),
        ),
      ),
    );
  }

  Future<String> _getAIReply(String userText) async {
    const systemPrompt =
        'You are a friendly personal style assistant. When asked about outfits, '
        'give a complete look: top, bottom, shoes, and one accessory. '
        'Be specific with colours and fit. Keep replies to 2â€“3 sentences, warm and conversational.';
    try {
      final backend = BackendService();
      final data = await backend.sendAnthropicMessages(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1000,
        system: systemPrompt,
        messages: [
          {'role': 'user', 'content': userText},
        ],
      );
      if (data != null) {
        final content = data['content'] as List<dynamic>;
        return (content.firstWhere(
              (c) => (c as Map)['type'] == 'text',
          orElse: () => {'text': "I'm not sure â€” try rephrasing!"},
        ) as Map)['text'] as String;
      }
      return "Couldn't connect right now â€” please try again!";
    } catch (e) {
      return "Couldn't connect right now â€” please try again!";
    }
  }

  AnimationController _createBubbleController() {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bubbleControllers.add(ctrl);
    ctrl.forward();
    return ctrl;
  }

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      if (_pendingOutfit.isEmpty) {
        _pendingOutfit = text; 
      }
      _chatCtrl.clear();
      _chipsVisible = false;
      _isTyping = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final reply = await _getAIReply(
        '$text â€” I am planning for $_activeOccasion $_activeEmoji');

    setState(() {
      _isTyping = false;
      _messages.add({'role': 'ai', 'text': reply});
    });

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
    final t = context.themeTokens;

    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
                colors: [t.backgroundPrimary, t.backgroundSecondary, t.phoneShell],
              ),
            ),
          ),
          _showChat ? _buildChatPage(t) : _buildMainContent(t),
        ],
      ),
    );
  }

  Widget _buildMainContent(AppThemeTokens t) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(t),
                  const SizedBox(height: 18),
                  _buildCalendarBox(t),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(AppThemeTokens t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ScaleButton(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.panelBorder,
              shape: BoxShape.circle,
              border: Border.all(color: t.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.chevron_left, color: t.textPrimary, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule / Calendar',
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 18,
                fontWeight: FontWeight.w700, color: t.textPrimary, height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                _PulseDot(controller: _pulseController, animation: _pulseAnim, t: t),
                const SizedBox(width: 6),
                Text(
                  _buildSubtitleText(),
                  style: TextStyle(fontSize: 12, color: t.mutedText),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _buildSubtitleText() {
    int total = 0;
    _plansData.forEach((_, list) => total += list.length);
    final todayKey = _normalizeDate(_today);
    final todayCount = _plansData[todayKey]?.length ?? 0;
    return '$total outfit plan${total != 1 ? 's' : ''} Â· $todayCount today';
  }

  Widget _buildCalendarBox(AppThemeTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.phoneShell,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildMonthNav(t),
          _buildWeekStrip(t),
          _buildPlansDivider(t),
          _buildPlansSection(t),
        ],
      ),
    );
  }

  Widget _buildMonthNav(AppThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScaleButton(
            onTap: () {
              setState(() {
                _viewMonth--;
                if (_viewMonth < 0) { _viewMonth = 11; _viewYear--; }
              });
            },
            scaleTo: 1.1,
            hoverScale: 1.1,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.chevron_left, color: t.textPrimary, size: 18),
            ),
          ),
          Text(
            _monthTitle,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: -0.2,
            ),
          ),
          _ScaleButton(
            onTap: () {
              setState(() {
                _viewMonth++;
                if (_viewMonth > 11) { _viewMonth = 0; _viewYear++; }
              });
            },
            scaleTo: 1.1,
            hoverScale: 1.1,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.chevron_right, color: t.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(AppThemeTokens t) {
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
              setState(() => _selectedDay = _normalizeDate(day));
              _initCardAnimations();
            },
            child: _AnimatedDayPill(
              day: day,
              isActive: isActive,
              isToday: isToday,
              weekdayShort: _weekdayShort(day),
              hasEvents: _hasPlans(day),
              t: t,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlansDivider(AppThemeTokens t) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, t.panelBorder, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildPlansSection(AppThemeTokens t) {
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
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 0.12 * 11, color: t.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nothing planned ðŸ¤”\nTap "Add a Plan" below',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: t.mutedText, height: 1.6),
                ),
              ),
            )
          else
            _buildPlansGrid(plans, t),
          const SizedBox(height: 12),
          _buildAddPlanButton(t),
        ],
      ),
    );
  }

  Widget _buildPlansGrid(List<Plan> plans, AppThemeTokens t) {
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
        if (i < _cardControllers.length) {
          return FadeTransition(
            opacity: _cardFadeAnims[i],
            child: SlideTransition(
              position: _cardSlideAnims[i],
              child: _buildPlanCard(plans[i], i, t),
            ),
          );
        }
        return _buildPlanCard(plans[i], i, t);
      },
    );
  }

  Widget _buildPlanCard(Plan plan, int index, AppThemeTokens t) {
    final colorType = _planTypeKey(plan);
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeOccasion = plan.occasion;
          _activeEmoji = plan.emoji;
          _isCreatingPlan = false; // Just viewing
          _showChat = true;
          _messages.clear();
          _currentChatChips = kSuggestionChips;
          _chipsVisible = true;
        });
      },
      child: _ScaleButton(
        onTap: () {
          setState(() {
            _activeOccasion = plan.occasion;
            _activeEmoji = plan.emoji;
            _isCreatingPlan = false;
            _showChat = true;
            _messages.clear();
            _currentChatChips = kSuggestionChips;
            _chipsVisible = true;
          });
        },
        scaleTo: 1.02,
        translateY: -4.0,
        hoverScale: 1.02,
        hoverTranslateY: -4.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              gradient: _planCardBg(colorType, t),
              border: Border(
                top: BorderSide(color: _planBorderTop(colorType, t), width: 1),
                left: BorderSide(color: _planBorderTop(colorType, t).withValues(alpha: 0.45), width: 1),
                right: BorderSide(color: t.cardBorder.withValues(alpha: 0.22), width: 1),
                bottom: BorderSide(color: t.cardBorder.withValues(alpha: 0.22), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Display Image! Fades in beautifully on the right side
                Positioned(
                  right: 0, top: 0, bottom: 0,
                  width: 80,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.0, 0.6],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.network(
                      getOccasionImage(plan.occasion),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                // Text Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(plan.occasion, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: t.textPrimary,
                      )),
                      const SizedBox(height: 2),
                      Text(_formatPlanTime(plan), style: TextStyle(
                        fontSize: 11, color: t.mutedText, height: 1.4,
                      )),
                      const SizedBox(height: 4),
                      // Prevents overflow crashes from long outfit descriptions
                      Flexible(
                        child: Text(plan.outfitDescription, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(
                          fontSize: 10.5, color: t.textPrimary.withValues(alpha: 0.8), height: 1.3,
                        )),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: _RotatingDeleteButton(
                    t: t,
                    onTap: () => _deletePlan(index),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: _BellButton(
                    t: t,
                    isOn: plan.reminder,
                    onTap: () => _toggleReminder(index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlanButton(AppThemeTokens t) {
    return _ScaleButton(
      onTap: _openModal,
      translateY: -2.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: t.panelBorder),
            left: BorderSide(color: t.panelBorder.withValues(alpha: 0.5)),
            right: BorderSide(color: t.panelBorder.withValues(alpha: 0.3)),
            bottom: BorderSide(color: t.accent.secondary.withValues(alpha: 0.35), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 14, color: t.mutedText),
            const SizedBox(width: 8),
            Text('Add a Plan', style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: t.mutedText,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPage(AppThemeTokens t) {
    return SafeArea(
      child: Column(
        children: [
          _buildChatHeader(t),
          Expanded(child: _buildChatMessages(t)),
          _buildChatInputBar(t),
        ],
      ),
    );
  }

  Widget _buildChatHeader(AppThemeTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ScaleButton(
            onTap: () => setState(() => _showChat = false),
            scaleTo: 1.08,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: t.panel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.cardBorder),
              ),
              child: Icon(Icons.chevron_left, color: t.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_activeOccasion â€” Style Chat',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: t.accent.tertiary, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Ask anything about your outfit.',
                        style: TextStyle(fontSize: 12, color: t.mutedText)),
                  ],
                ),
              ],
            ),
          ),
          if (_isCreatingPlan)
            _ScaleButton(
               onTap: _isSaving ? () {} : _savePlanFromChat, 
               scaleTo: _isSaving ? 1.0 : 1.05,
               child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                     gradient: LinearGradient(colors: [t.accent.primary, t.accent.secondary]),
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                       BoxShadow(color: t.accent.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                     ],
                  ),
                  child: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
               ),
            )
        ],
      ),
    );
  }

  Widget _buildChatMessages(AppThemeTokens t) {
    final allItems = <Widget>[];

    if (_messages.isEmpty) {
      allItems.add(_buildAIBubble(
        'Hi! Let\'s pick an outfit for your $_activeOccasion $_activeEmoji. What vibe are you feeling today?',
        t,
      ));
    } else {
      for (final msg in _messages) {
        if (msg['role'] == 'user') {
          allItems.add(_buildUserBubble(msg['text']!, t));
        } else {
          allItems.add(_buildAIBubble(msg['text']!, t));
        }
      }
    }

    if (_isTyping) {
      allItems.add(_buildTypingIndicator(t));
    }

    return ListView(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(18),
      children: allItems,
    );
  }

  Widget _buildAIBubble(String text, AppThemeTokens t) {
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
                decoration: BoxDecoration(
                  color: t.panel, shape: BoxShape.circle,
                  border: Border.all(color: t.cardBorder),
                ),
                child: const Center(child: Text('ðŸ‘—', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: t.panel,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5),
                        ),
                        border: Border.all(color: t.cardBorder),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Text(text, style: TextStyle(
                        fontSize: 13.5, color: t.textPrimary, height: 1.55,
                      )),
                    ),
                    const SizedBox(height: 3),
                    Text('Now', style: TextStyle(fontSize: 10, color: t.mutedText.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text, AppThemeTokens t) {
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
                        gradient: LinearGradient(
                          colors: [t.accent.primary.withValues(alpha: 0.28), t.accent.secondary.withValues(alpha: 0.20)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(5),
                        ),
                        border: Border.all(color: t.accent.primary.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(color: t.accent.primary.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Text(text, style: TextStyle(
                        fontSize: 13.5, color: t.textPrimary, height: 1.55,
                      )),
                    ),
                    const SizedBox(height: 3),
                    Text('Now', style: TextStyle(fontSize: 10, color: t.mutedText.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(AppThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: t.panel, shape: BoxShape.circle,
              border: Border.all(color: t.cardBorder),
            ),
            child: Center(child: Text(_activeEmoji, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: t.panel,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5),
              ),
              border: Border.all(color: t.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, _) {
                    final phase = (_typingController.value + i * 0.15) % 1.0;
                    final animT = (phase < 0.5) ? phase * 2 : (1 - phase) * 2;
                    final offset = Curves.easeInOut.transform(animT) * -5.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: animT > 0.5 ? t.accent.primary : t.mutedText.withValues(alpha: 0.6),
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

  Widget _buildChatInputBar(AppThemeTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        children: [
          if (_chipsVisible)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _currentChatChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return _ScaleButton(
                    onTap: () {
                      _chatCtrl.text = _currentChatChips[i]['label']!;
                      _pendingOutfit = _currentChatChips[i]['label']!;
                      _sendMessage();
                    },
                    scaleTo: 1.03,
                    translateY: -2.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: t.panel,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: t.accent.primary.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [BoxShadow(color: t.accent.primary.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: Text(
                        _currentChatChips[i]['label']!,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: t.accent.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: t.panelBorder,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 17, color: t.mutedText.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: TextStyle(fontSize: 14, color: t.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask about your outfitâ€¦',
                      hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: t.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.accent.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.mic_none, size: 16, color: t.accent.secondary),
                ),
                const SizedBox(width: 8),
                _ScaleButton(
                  onTap: _sendMessage,
                  scaleTo: 1.08,
                  pressScale: 0.94,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.accent.primary, t.accent.secondary]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: t.accent.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
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

  Widget _buildModalSheet(BuildContext sheetContext, StateSetter modalSetState, AppThemeTokens t) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [t.backgroundSecondary, t.phoneShell],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32),
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 36, offset: const Offset(0, -8)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Plan', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary,
                  )),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(), 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: t.panel,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: t.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.close, size: 13, color: t.mutedText),
                          const SizedBox(width: 5),
                          Text('Close', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: t.mutedText,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('1. SET TIME', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.16 * 10.5, color: t.mutedText,
              )),
              const SizedBox(height: 10),
              _buildTimeRow(t, modalSetState),
              const SizedBox(height: 24),
              Text('2. CHOOSE OCCASION', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.16 * 10.5, color: t.mutedText,
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
                      final hRaw = int.tryParse(_hourCtrl.text);
                      final mRaw = int.tryParse(_minCtrl.text);
                      if (hRaw == null || mRaw == null) {
                        _showToast('Please set a valid time first.');
                        return;
                      }
                      final hour = (_selectedAmPm == 'PM') ? (hRaw % 12) + 12 : (hRaw % 12);
                      
                      setState(() {
                        _selectedEvent = ev['label']!;
                        _selectedEventEmoji = ev['emoji']!;
                        _pendingPlanDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour, mRaw);
                        _activeOccasion = ev['label']!;
                        _activeEmoji = ev['emoji']!;
                        _isCreatingPlan = true;
                        _pendingOutfit = '';
                        _showChat = true;
                        _messages.clear();
                        _messages.add({
                          'role': 'ai', 
                          'text': 'Great! Planning for $_activeOccasion at $hRaw:${mRaw.toString().padLeft(2, '0')} $_selectedAmPm. What kind of outfit vibe are you looking for?'
                        });
                        
                        if (kOutfits.containsKey(_activeOccasion)) {
                          _currentChatChips = kOutfits[_activeOccasion]!.map((o) => {'label': o['summary']!}).toList();
                        } else {
                          _currentChatChips = kSuggestionChips;
                        }
                        _chipsVisible = true;
                      });
                      
                      Navigator.of(sheetContext).pop(); 
                    },
                    scaleTo: 1.06,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: _eventBg(ev['type']!, isActive, t),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? _eventColor(ev['type']!, t).withValues(alpha: 0.55)
                              : t.cardBorder,
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
                            color: _eventColor(ev['type']!, t),
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(AppThemeTokens t, StateSetter s) {
    return _FocusGlowContainer(
      focusNodes: [_hourFocus, _minFocus],
      t: t,
      child: Row(
        children: [
          Icon(Icons.access_time_outlined, size: 18, color: t.mutedText.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _hourCtrl,
              focusNode: _hourFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: t.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'HH',
                hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.2)),
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Text(':', style: TextStyle(fontSize: 22, color: t.mutedText.withValues(alpha: 0.6))),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _minCtrl,
              focusNode: _minFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: t.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'MM',
                hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.2)),
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          Container(
            width: 1, height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [t.cardBorder, Colors.white.withValues(alpha: 0.05)],
              ),
            ),
          ),
          Row(
            children: [
              _buildAmPmBtn('AM', t, s),
              const SizedBox(width: 4),
              _buildAmPmBtn('PM', t, s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmBtn(String label, AppThemeTokens t, StateSetter s) {
    final isActive = _selectedAmPm == label;
    return GestureDetector(
      onTap: () => s(() => _selectedAmPm = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: [t.accent.primary, t.accent.secondary])
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [BoxShadow(color: t.accent.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800,
            letterSpacing: 0.06 * 12,
            color: isActive ? Colors.white : t.mutedText,
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPER WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

