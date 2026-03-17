import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/theme/theme_tokens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Screen4(),
    );
  }
}

class Screen4 extends StatefulWidget {
  const Screen4({super.key});
  static const List<String> _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<_FilterChipData> _filters = <_FilterChipData>[
    _FilterChipData('All', Icons.grid_view_rounded),
    _FilterChipData('Health', Icons.monitor_heart_outlined),
    _FilterChipData('Relationships', Icons.people_outline_rounded),
    _FilterChipData('Career', Icons.work_outline_rounded),
    _FilterChipData('Learning', Icons.book_outlined),
    _FilterChipData('Finance', Icons.account_balance_outlined),
    _FilterChipData('Creativity', Icons.palette_outlined),
    _FilterChipData('Mindfulness', Icons.auto_awesome_outlined),
  ];

  static const List<_DropdownOptionData> _dropdownOptions = <_DropdownOptionData>[
    _DropdownOptionData('Health & Wellness', 'Health', Icons.fitness_center_rounded),
    _DropdownOptionData('Relationships', 'Relationships', Icons.people_outline_rounded),
    _DropdownOptionData('Career', 'Career', Icons.work_outline_rounded),
    _DropdownOptionData('Learning', 'Learning', Icons.book_outlined),
    _DropdownOptionData('Finance', 'Finance', Icons.attach_money_rounded),
    _DropdownOptionData('Creativity', 'Creativity', Icons.palette_outlined),
    _DropdownOptionData('Mindfulness', 'Mindfulness', Icons.self_improvement_outlined),
    _DropdownOptionData('Purpose', 'Purpose', Icons.public_outlined),
  ];


  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> {
  AppThemeTokens get _t => context.themeTokens;
  Color get _bg => _t.backgroundPrimary;
  Color get _bg2 => _t.backgroundSecondary;
  Color get _text => _t.textPrimary;
  Color get _tileText => _t.tileText;
  Color get _accent => _t.accent.primary;
  Color get _accent2 => _t.accent.secondary;
  Color get _accent3 => _t.accent.tertiary;
  Color get _accent4 => _t.accent.primary;
  Color get _accent5 => _t.accent.secondary;
  Color get _muted => _t.mutedText;
  Color get _cardBorder => _t.cardBorder;
  Color get _panelSolid2 => _t.panel;
  Color get _borderStrong => _t.cardBorder.withValues(alpha: 0.75);
  Color get _accentSoft => _t.accent.primary.withValues(alpha: 0.12);
  Color get _accentSoft2 => _t.accent.secondary.withValues(alpha: 0.14);
  Color get _accentSoft3 => _t.accent.tertiary.withValues(alpha: 0.14);
  Color get _accentSoft4 => _t.accent.primary.withValues(alpha: 0.14);
  Color get _accentSoft5 => _t.accent.secondary.withValues(alpha: 0.18);
  Color get _accentBorder => _t.accent.primary.withValues(alpha: 0.44);
  Color get _accentBorder2 => _t.accent.secondary.withValues(alpha: 0.48);
  Color get _accentBorder3 => _t.accent.tertiary.withValues(alpha: 0.48);
  Color get _accentBorder4 => _t.accent.primary.withValues(alpha: 0.48);
  Color get _accentBorder5 => _t.accent.secondary.withValues(alpha: 0.54);
  Color get _accentGlow => _t.accent.primary.withValues(alpha: 0.30);
  Color get _accentGlow2 => _t.accent.secondary.withValues(alpha: 0.34);
  Color get _accentGlow3 => _t.accent.tertiary.withValues(alpha: 0.34);
  Color get _scrim => _t.backgroundPrimary.withValues(alpha: 0.68);
  Color get _scrimStrong => _t.backgroundPrimary.withValues(alpha: 0.82);
  LinearGradient get _uiGradient => LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: <Color>[_accent, _accent3]);

  List<_SuggestionData> get _suggestions => <_SuggestionData>[
    _SuggestionData(
      title: 'Gratitude Journal',
      description: "Write 3 things you're grateful for each evening.",
      tag: 'Mindfulness',
      icon: Icons.menu_book_rounded,
      stripe: _accentBorder2,
      tagBg: _accentSoft2,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Learn Cooking',
      description: 'Master 10 simple healthy recipes at home.',
      tag: 'Health',
      icon: Icons.restaurant_menu_rounded,
      stripe: _accentBorder3,
      tagBg: _accentSoft3,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Reconnect Monthly',
      description: 'Call or meet an old friend every month.',
      tag: 'Relationships',
      icon: Icons.phone_in_talk_outlined,
      stripe: _accentBorder4,
      tagBg: _accentSoft4,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Digital Detox',
      description: 'Spend Sunday mornings fully offline.',
      tag: 'Mindfulness',
      icon: Icons.wifi_off_rounded,
      stripe: _accentBorder,
      tagBg: _accentSoft,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Online Course',
      description: 'Finish a structured course within 3 months.',
      tag: 'Learning',
      icon: Icons.bookmarks_outlined,
      stripe: _accentBorder2,
      tagBg: _accentSoft2,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Run a 5K',
      description: 'Build up to running 5km without stopping.',
      tag: 'Health',
      icon: Icons.fitness_center_rounded,
      stripe: _accentBorder4,
      tagBg: _accentSoft5,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Emergency Fund',
      description: 'Save 3 months of expenses as a safety net.',
      tag: 'Finance',
      icon: Icons.account_balance_outlined,
      stripe: _accentBorder5,
      tagBg: _accentSoft5,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
    _SuggestionData(
      title: 'Volunteer Monthly',
      description: 'Give 2+ hours a month to a cause you care about.',
      tag: 'Purpose',
      icon: Icons.volunteer_activism_outlined,
      stripe: _accentBorder3,
      tagBg: _accentSoft3,
      cardBg: _bg,
      cardBorder: _cardBorder,
    ),
  ];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _formReminderTimeController = TextEditingController(text: '08:00');
  final TextEditingController _formReminderNoteController = TextEditingController();
  final TextEditingController _modalReminderTimeController = TextEditingController(text: '08:00');
  final TextEditingController _modalReminderNoteController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();

  final List<_GoalItem> _goals = <_GoalItem>[];
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: "Hey! I'm AHVI, your AI life coach. Ask me about goals, motivation, or what to focus on next.",
      isUser: false,
    ),
  ];

  Timer? _toastTimer;
  Timer? _typingTimer;

  String _selectedFilter = 'All';
  String _selectedCategory = 'Health';
  bool _dropdownOpen = false;
  bool _formReminderOn = false;
  String _formFrequency = 'Daily';
  String _formReminderDay = 'Monday';
  bool _modalOpen = false;
  int? _editingGoalId;
  String _modalFrequency = 'Daily';
  String _modalReminderDay = 'Monday';
  bool _showToast = false;
  String _toastText = '';
  bool _chatOpen = false;
  bool _typing = false;
  bool _titleError = false;
  int _aiResponseIndex = 0;
  int? _hoveredSuggestionId;
  int? _pressedSuggestionId;
  int? _hoveredGoalId;
  String? _hoveredFilter;
  bool _hoveringBack = false;
  bool _pressingBack = false;
  bool _hoveringCategory = false;
  bool _flashingSuggestion = false;
  int _flashSuggestionId = -1;

  static const List<String> _aiResponses = <String>[
    'Start with a goal so small it feels almost impossible to skip.',
    'Pair that goal with a habit you already have. Habit stacking is incredibly effective!',
    "People who write goals down are more likely to achieve them. You're on the right track!",
    "Understanding your why keeps you going when motivation dips. What's driving this one?",
    'Consistency beats intensity every time. Small daily actions compound into massive change.',
    'Break it into smaller milestones and celebrate each one to keep momentum alive.',
    'Goals with deadlines are much more likely to be achieved. Have you set a target date?',
    'A mindfulness practice could complement your other goals beautifully.',
  ];

  TextStyle _sf({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      color: color ?? _text,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      fontFamilyFallback: const <String>[
        'SF Pro Display',
        'SF Pro Text',
        'Helvetica Neue',
        'Arial',
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint, {bool error = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _sf(size: 16, color: _muted),
      filled: true,
      fillColor: _panelSolid2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error ? _accent4 : _borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error ? _accent4 : _accent2),
      ),
    );
  }

  _DropdownOptionData get _selectedCategoryOption {
    return Screen4._dropdownOptions.firstWhere(
          (_DropdownOptionData option) => option.value == _selectedCategory,
      orElse: () => Screen4._dropdownOptions.first,
    );
  }

  List<_GoalItem> get _filteredGoals {
    if (_selectedFilter == 'All') {
      return _goals;
    }
    return _goals.where((_GoalItem goal) => goal.category == _selectedFilter).toList();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _typingTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _formReminderTimeController.dispose();
    _formReminderNoteController.dispose();
    _modalReminderTimeController.dispose();
    _modalReminderNoteController.dispose();
    _chatController.dispose();
    _titleFocusNode.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _addGoal() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = true;
      });
      _titleFocusNode.requestFocus();
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _titleError = false;
        });
      });
      return;
    }

    final _GoalReminder? reminder = _formReminderOn
        ? _GoalReminder(
      frequency: _formFrequency,
      time: _formReminderTimeController.text,
      day: _formReminderDay,
      note: _formReminderNoteController.text.trim(),
    )
        : null;

    setState(() {
      _goals.add(
        _GoalItem(
          id: DateTime.now().microsecondsSinceEpoch,
          title: title,
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          icon: _selectedCategoryOption.icon,
          accent: _goalAccent(_selectedCategory),
          cardBackground: _goalCardBackground(_selectedCategory),
          cardBorder: _goalCardBorder(_selectedCategory),
          progress: 0,
          reminder: reminder,
        ),
      );
      _selectedFilter = 'All';
    });
    _clearForm(showToast: false);
    _showToastMessage(reminder != null ? 'Goal + Reminder added!' : 'Goal added!');
  }

  void _quickAdd(_SuggestionData suggestion, int index) {
    setState(() {
      _goals.add(
        _GoalItem(
          id: DateTime.now().microsecondsSinceEpoch,
          title: suggestion.title,
          description: suggestion.description,
          category: suggestion.tag,
          icon: suggestion.icon,
          accent: _goalAccent(suggestion.tag),
          cardBackground: _goalCardBackground(suggestion.tag),
          cardBorder: _goalCardBorder(suggestion.tag),
          progress: 0,
          reminder: null,
        ),
      );
      _selectedFilter = 'All';
      _flashSuggestionId = index;
      _flashingSuggestion = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _flashingSuggestion = false;
      });
    });

    _showToastMessage('Goal added!');
  }

  void _clearForm({bool showToast = false}) {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = 'Health';
      _formReminderOn = false;
      _formFrequency = 'Daily';
      _formReminderDay = 'Monday';
      _formReminderTimeController.text = '08:00';
      _formReminderNoteController.clear();
      _dropdownOpen = false;
      _titleError = false;
    });
    if (showToast) {
      _showToastMessage('Form cleared');
    }
  }

  void _toggleFormReminder() {
    setState(() {
      _formReminderOn = !_formReminderOn;
    });
  }

  void _pickFormFrequency(String frequency) {
    setState(() {
      _formFrequency = frequency;
    });
  }

  void _pickModalFrequency(String frequency) {
    setState(() {
      _modalFrequency = frequency;
    });
  }

  void _toggleDropdown() {
    setState(() {
      _dropdownOpen = !_dropdownOpen;
    });
  }

  void _selectCategory(_DropdownOptionData option) {
    setState(() {
      _selectedCategory = option.value;
      _dropdownOpen = false;
    });
  }

  void _deleteGoal(int id) {
    setState(() {
      _goals.removeWhere((_GoalItem goal) => goal.id == id);
    });
  }

  void _setProgress(_GoalItem goal, String value) {
    final int parsed = int.tryParse(value) ?? goal.progress;
    setState(() {
      goal.progress = parsed.clamp(0, 100);
    });
  }

  void _openReminderModal(_GoalItem goal) {
    final _GoalReminder? reminder = goal.reminder;
    setState(() {
      _editingGoalId = goal.id;
      _modalFrequency = reminder?.frequency ?? 'Daily';
      _modalReminderDay = reminder?.day ?? 'Monday';
      _modalReminderTimeController.text = reminder?.time ?? '08:00';
      _modalReminderNoteController.text = reminder?.note ?? '';
      _modalOpen = true;
    });
  }

  void _closeReminderModal() {
    setState(() {
      _modalOpen = false;
      _editingGoalId = null;
    });
  }

  void _saveReminder() {
    if (_editingGoalId == null) {
      return;
    }
    final _GoalItem goal = _goals.firstWhere((_GoalItem item) => item.id == _editingGoalId);
    setState(() {
      goal.reminder = _GoalReminder(
        frequency: _modalFrequency,
        time: _modalReminderTimeController.text,
        day: _modalReminderDay,
        note: _modalReminderNoteController.text.trim(),
      );
      _modalOpen = false;
      _editingGoalId = null;
    });
    _showToastMessage('Reminder saved!');
  }

  void _clearReminder() {
    if (_editingGoalId == null) {
      return;
    }
    final _GoalItem goal = _goals.firstWhere((_GoalItem item) => item.id == _editingGoalId);
    setState(() {
      goal.reminder = null;
      _modalOpen = false;
      _editingGoalId = null;
    });
    _showToastMessage('Reminder cleared');
  }

  void _showToastMessage(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastText = message;
      _showToast = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showToast = false;
      });
    });
  }

  void _toggleChat() {
    setState(() {
      _chatOpen = !_chatOpen;
    });
    if (_chatOpen) {
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        if (!mounted) {
          return;
        }
        _chatFocusNode.requestFocus();
        _scrollChatToBottom();
      });
    }
  }

  void _sendMessage() {
    final String text = _chatController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _chatController.clear();
      _typing = true;
    });
    _scrollChatToBottom();
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _typing = false;
        _messages.add(_ChatMessage(text: _aiResponses[_aiResponseIndex % _aiResponses.length], isUser: false));
        _aiResponseIndex++;
      });
      _scrollChatToBottom();
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) {
        return;
      }
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(String raw) {
    if (raw.isEmpty || !raw.contains(':')) {
      return raw;
    }
    final List<String> parts = raw.split(':');
    final int hour = int.tryParse(parts[0]) ?? 0;
    final int display = hour % 12 == 0 ? 12 : hour % 12;
    final String suffix = hour >= 12 ? 'PM' : 'AM';
    return '$display:${parts[1]} $suffix';
  }

  Color _goalAccent(String category) {
    switch (category) {
      case 'Health':
        return _accent3;
      case 'Relationships':
        return _accent4;
      case 'Finance':
        return _accent5;
      case 'Purpose':
        return _accent3;
      default:
        return _accent2;
    }
  }

  Color _goalCardBackground(String category) {
    switch (category) {
      case 'Health':
      case 'Purpose':
        return _accent3.withValues(alpha: 0.12);
      case 'Relationships':
        return _accent4.withValues(alpha: 0.12);
      case 'Finance':
        return _accent5.withValues(alpha: 0.14);
      case 'Creativity':
      case 'Mindfulness':
        return _accent.withValues(alpha: 0.10);
      default:
        return _accent2.withValues(alpha: 0.10);
    }
  }

  Color _goalCardBorder(String category) {
    switch (category) {
      case 'Health':
      case 'Purpose':
        return _accentBorder3;
      case 'Relationships':
        return _accentBorder4;
      case 'Finance':
        return _accentBorder5;
      case 'Creativity':
      case 'Mindfulness':
        return _accentBorder;
      default:
        return _accentBorder2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _GoalItem editingGoal = _editingGoalId == null
        ? _GoalItem.empty()
        : _goals.firstWhere((_GoalItem goal) => goal.id == _editingGoalId, orElse: () => _GoalItem.empty());

    return GestureDetector(
      onTap: () {
        if (_dropdownOpen) {
          setState(() {
            _dropdownOpen = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  _buildNav(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildAddPanel(),
                          _buildSectionHeader('My Goals', '${_goals.length} ${_goals.length == 1 ? 'goal' : 'goals'}'),
                          _buildFilters(),
                          _buildGoalsSection(),
                          _buildSectionHeader('AI Suggestions', 'Tap to add instantly'),
                          _buildSuggestions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 255,
                child: IgnorePointer(
                  ignoring: !_dropdownOpen,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _dropdownOpen ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      offset: _dropdownOpen ? Offset.zero : const Offset(0, -0.04),
                      child: _buildDropdown(),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_modalOpen,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _modalOpen ? 1 : 0,
                    child: GestureDetector(
                      onTap: _closeReminderModal,
                      child: _buildModalOverlay(editingGoal.id == -1 ? null : editingGoal),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !_chatOpen,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    offset: _chatOpen ? Offset.zero : const Offset(0, 1),
                    child: _buildChatDrawer(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: IgnorePointer(
                  ignoring: !_showToast,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showToast ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: _showToast ? Offset.zero : const Offset(0, 0.25),
                      child: _buildToast(),
                    ),
                  ),
                ),
              ),
              Positioned(right: 16, bottom: 16, child: _buildFab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    final double scale = _pressingBack ? 0.94 : (_hoveringBack ? 1.08 : 1);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _bg2.withValues(alpha: 0.92),
            border: Border(bottom: BorderSide(color: _accentBorder, width: 2)),
            boxShadow: <BoxShadow>[
              BoxShadow(color: _bg.withValues(alpha: 0.72), blurRadius: 20, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  MouseRegion(
                    onEnter: (_) => setState(() => _hoveringBack = true),
                    onExit: (_) => setState(() {
                      _hoveringBack = false;
                      _pressingBack = false;
                    }),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _pressingBack = true),
                      onTapUp: (_) => setState(() => _pressingBack = false),
                      onTapCancel: () => setState(() => _pressingBack = false),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hoveringBack ? _bg2.withValues(alpha: 0.6) : _accentSoft2,
                            shape: BoxShape.circle,
                            border: Border.all(color: _accentBorder2),
                          ),
                          child: Icon(Icons.chevron_left_rounded, color: _accent2, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Life Goals', style: _sf(size: 32, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPanel() {
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 28),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(color: _bg.withValues(alpha: 0.40), blurRadius: 28, offset: const Offset(0, 4)),
              BoxShadow(color: _bg.withValues(alpha: 0.70), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.add_circle_outline_rounded, color: _accent5, size: 20),
                  const SizedBox(width: 8),
                  Text('Add a New Goal', style: _sf(size: 17.6, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Goal Title *',
                icon: Icons.view_column_outlined,
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  decoration: _fieldDecoration('e.g. Run a 5K, Read 12 books...', error: _titleError),
                  style: _sf(size: 16),
                ),
              ),
              const SizedBox(height: 14),
              _buildField(
                label: 'Description (optional)',
                icon: Icons.notes_rounded,
                child: TextField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 4,
                  decoration: _fieldDecoration('Why does this goal matter to you?'),
                  style: _sf(size: 16),
                ),
              ),
              const SizedBox(height: 14),
              _buildField(label: 'Category', icon: Icons.sell_outlined, child: _buildCategoryTrigger()),
              const SizedBox(height: 10),
              _buildFormReminderSection(),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: _addGoal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _uiGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: _accentGlow2, blurRadius: 18, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.add_rounded, color: _text, size: 15),
                            const SizedBox(width: 7),
                            Text('Add Goal', style: _sf(size: 15.2, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _clearForm(showToast: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _accentBorder2),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.close_rounded, color: _muted, size: 14),
                          const SizedBox(width: 6),
                          Text('Clear', style: _sf(size: 14.4, weight: FontWeight.w600, color: _muted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: _accentBorder2,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTrigger() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveringCategory = true),
      onExit: (_) => setState(() => _hoveringCategory = false),
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _dropdownOpen ? _bg : (_hoveringCategory ? _panelSolid2.withValues(alpha: 0.8) : _panelSolid2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dropdownOpen ? _accent2 : (_hoveringCategory ? _accentBorder2 : _borderStrong),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: _uiGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_selectedCategoryOption.icon, color: _text, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_selectedCategoryOption.label, style: _sf(size: 16, weight: FontWeight.w500))),
              AnimatedRotation(
                turns: _dropdownOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(Icons.expand_more_rounded, color: _dropdownOpen ? _accent2 : _muted, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormReminderSection() {
    final bool showDay = _formFrequency == 'Weekly' || _formFrequency == 'Custom';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 220),
        crossFadeState: _formReminderOn ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: GestureDetector(
          onTap: _toggleFormReminder,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentBorder2, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.notifications_none_rounded, color: _muted, size: 15),
                const SizedBox(width: 8),
                Text('Add Reminder to this Goal', style: _sf(size: 13.76, weight: FontWeight.w600, color: _muted)),
              ],
            ),
          ),
        ),
        secondChild: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accentBorder2),
          ),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.notifications_active_outlined, color: _accent5, size: 14),
                      const SizedBox(width: 6),
                      Text('Reminder', style: _sf(size: 13.44, weight: FontWeight.w600)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _toggleFormReminder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _accentSoft4, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.close_rounded, color: _accent4, size: 13),
                          const SizedBox(width: 4),
                          Text('Remove', style: _sf(size: 12.48, weight: FontWeight.w600, color: _accent4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  for (final String frequency in const <String>['Daily', 'Weekly', 'Monthly', 'Custom']) ...<Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickFormFrequency(frequency),
                        child: _FrequencyPill(text: frequency, selected: _formFrequency == frequency),
                      ),
                    ),
                    if (frequency != 'Custom') const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _buildField(
                      label: 'Time',
                      icon: Icons.schedule_rounded,
                      child: TextField(
                        controller: _formReminderTimeController,
                        decoration: _fieldDecoration('08:00'),
                        style: _sf(size: 16),
                      ),
                    ),
                  ),
                  if (showDay) ...<Widget>[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        label: 'Day',
                        icon: Icons.calendar_today_outlined,
                        child: _buildDayDropdown(
                          value: _formReminderDay,
                          onChanged: (String? value) {
                            if (value == null) return;
                            setState(() => _formReminderDay = value);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              _buildField(
                label: 'Note (optional)',
                icon: Icons.message_outlined,
                child: TextField(
                  controller: _formReminderNoteController,
                  decoration: _fieldDecoration("e.g. Don't forget your morning session!"),
                  style: _sf(size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 11, color: _muted),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: _sf(size: 11.52, weight: FontWeight.w600, color: _muted, letterSpacing: 1.28),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildSectionHeader(String title, String meta) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _accentBorder2, width: 2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: _sf(size: 22.4, weight: FontWeight.w900)),
          Text(meta.toUpperCase(), style: _sf(size: 11.52, weight: FontWeight.w600, color: _accent2, letterSpacing: 1.6)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4),
        itemCount: Screen4._filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (BuildContext context, int index) {
          final _FilterChipData item = Screen4._filters[index];
          final bool selected = _selectedFilter == item.label;
          final bool hovered = _hoveredFilter == item.label;
          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredFilter = item.label),
            onExit: (_) => setState(() => _hoveredFilter = null),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = item.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, (selected || hovered) ? -1 : 0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected ? _uiGradient : null,
                  color: selected ? null : _bg,
                  borderRadius: BorderRadius.circular(20),
                  border: selected ? null : Border.all(color: hovered ? _accentBorder2 : _borderStrong, width: 1.5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: selected ? _accentGlow : (hovered ? _accentGlow2 : _bg.withValues(alpha: 0.54)),
                      blurRadius: selected ? 14 : (hovered ? 12 : 4),
                      offset: Offset(0, selected ? 4 : (hovered ? 3 : 1)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(item.icon, size: 13, color: selected ? _text : (hovered ? _accent2 : _muted)),
                    const SizedBox(width: 5),
                    Text(item.label, style: _sf(size: 12.8, weight: FontWeight.w600, color: selected ? _text : (hovered ? _accent2 : _muted))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalsSection() {
    if (_filteredGoals.isEmpty) {
      final bool noGoals = _goals.isEmpty;
      return _buildEmptyState(
        title: noGoals ? 'No goals yet' : 'No goals in this category',
        description: noGoals ? 'Add your first goal above or pick from AI suggestions below.' : 'Try a different filter or add a new goal above.',
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(children: _filteredGoals.map(_buildGoalCard).toList()),
    );
  }

  Widget _buildEmptyState({required String title, required String description}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 50),
      margin: const EdgeInsets.only(bottom: 36),
      child: Column(
        children: <Widget>[
          Icon(Icons.local_florist_outlined, color: _accent5, size: 48),
          const SizedBox(height: 12),
          Text(title, style: _sf(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center, style: _sf(size: 13.12, color: _muted, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(_GoalItem goal) {
    final bool hovered = _hoveredGoalId == goal.id;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredGoalId = goal.id),
      onExit: (_) => setState(() => _hoveredGoalId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 7),
        transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: goal.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: goal.cardBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _bg.withValues(alpha: 0.62),
              blurRadius: hovered ? 18 : 8,
              offset: Offset(0, hovered ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.72),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(goal.icon, size: 14, color: goal.accent),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sf(size: 13.12, weight: FontWeight.w700, color: _tileText)),
                      if (goal.description.isNotEmpty)
                        Text(goal.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sf(size: 11.2, color: _muted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteGoal(goal.id),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _t.card, borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.delete_outline_rounded, size: 12, color: _accent4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Container(
              height: 4,
              decoration: BoxDecoration(color: _bg.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: goal.progress / 100),
                duration: const Duration(milliseconds: 600),
                builder: (BuildContext context, double value, Widget? child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(decoration: BoxDecoration(color: goal.accent, borderRadius: BorderRadius.circular(10))),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _t.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Text(goal.category.toUpperCase(), style: _sf(size: 9.6, weight: FontWeight.w700, color: goal.accent, letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 6),
                    Text('${goal.progress}%', style: _sf(size: 10.72, weight: FontWeight.w600, color: _tileText)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 44,
                      height: 28,
                      child: TextFormField(
                        initialValue: '${goal.progress}',
                        onChanged: (String value) => _setProgress(goal, value),
                        keyboardType: TextInputType.number,
                        style: _sf(size: 11.52, weight: FontWeight.w600, color: _tileText),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          filled: true,
                          fillColor: _t.card,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: _cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: goal.accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _openReminderModal(goal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: goal.reminder != null ? _t.card : _t.card.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(goal.reminder != null ? Icons.notifications_active_outlined : Icons.notifications_none_outlined, size: 11, color: _tileText),
                            const SizedBox(width: 4),
                            Text(goal.reminder != null ? _formatTime(goal.reminder!.time) : 'Remind', style: _sf(size: 10.72, weight: FontWeight.w600, color: _tileText)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 14),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final _SuggestionData item = _suggestions[index];
          final bool hovered = _hoveredSuggestionId == index;
          final bool pressed = _pressedSuggestionId == index;
          final bool flashing = _flashingSuggestion && _flashSuggestionId == index;
          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredSuggestionId = index),
            onExit: (_) => setState(() {
              _hoveredSuggestionId = null;
              _pressedSuggestionId = null;
            }),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressedSuggestionId = index),
              onTapCancel: () => setState(() => _pressedSuggestionId = null),
              onTapUp: (_) => setState(() => _pressedSuggestionId = null),
              onTap: () => _quickAdd(item, index),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: pressed ? 0.96 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 195,
                  transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: flashing ? _accent2.withValues(alpha: 0.12) : item.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: item.cardBorder),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: _bg.withValues(alpha: 0.46), blurRadius: hovered ? 28 : 12, offset: Offset(0, hovered ? 6 : 2)),
                    ],
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(top: -16, left: -16, right: -16, child: Container(height: 4, color: item.stripe)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: _uiGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(item.icon, color: _text, size: 20),
                          ),
                          Text(item.title, style: _sf(size: 14.4, weight: FontWeight.w700, color: _tileText)),
                          const SizedBox(height: 5),
                          Text(item.description, style: _sf(size: 12.16, color: _muted, height: 1.5)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: item.tagBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(item.tag.toUpperCase(), style: _sf(size: 10.56, weight: FontWeight.w700, color: _tileText, letterSpacing: 0.64)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderStrong),
        boxShadow: <BoxShadow>[
          BoxShadow(color: _bg.withValues(alpha: 0.42), blurRadius: 48, offset: Offset(0, 16)),
          BoxShadow(color: _bg.withValues(alpha: 0.64), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: Screen4._dropdownOptions.length,
        itemBuilder: (BuildContext context, int index) {
          final _DropdownOptionData item = Screen4._dropdownOptions[index];
          final bool active = item.value == _selectedCategory;
          return GestureDetector(
            onTap: () => _selectCategory(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: active ? _accentSoft2 : _bg.withValues(alpha: 0), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(gradient: _uiGradient, borderRadius: BorderRadius.circular(10)),
                    child: Icon(item.icon, size: 16, color: _text),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.label, style: _sf(size: 15.2, weight: FontWeight.w500, color: active ? _accent2 : _text))),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: active ? 1 : 0,
                    child: Icon(Icons.check_rounded, size: 14, color: _accent2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalOverlay(_GoalItem? editingGoal) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: _scrim,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              offset: _modalOpen ? Offset.zero : const Offset(0, 1),
              child: _buildModal(editingGoal),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModal(_GoalItem? editingGoal) {
    final bool showDay = _modalFrequency == 'Weekly' || _modalFrequency == 'Custom';
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: _bg.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(2)))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(children: <Widget>[Icon(Icons.notifications_none_rounded, color: _accent5, size: 20), const SizedBox(width: 8), Text('Set Reminder', style: _sf(size: 19.2, weight: FontWeight.w600))]),
              GestureDetector(
                onTap: _closeReminderModal,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _bg.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.close_rounded, color: _muted, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: <Widget>[
                Icon(Icons.gps_fixed_rounded, color: _accent4, size: 14),
                const SizedBox(width: 7),
                RichText(
                  text: TextSpan(
                    style: _sf(size: 13.44),
                    children: <TextSpan>[
                      TextSpan(text: 'For: ', style: _sf(size: 13.44)),
                      TextSpan(text: editingGoal?.title ?? '-', style: _sf(size: 13.44, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildModalField(
            label: 'Frequency',
            icon: Icons.sync_alt_rounded,
            child: Row(
              children: <Widget>[
                for (final String frequency in const <String>['Daily', 'Weekly', 'Monthly', 'Custom']) ...<Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickModalFrequency(frequency),
                      child: _FrequencyPill(text: frequency, selected: _modalFrequency == frequency),
                    ),
                  ),
                  if (frequency != 'Custom') const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          _buildModalField(
            label: 'Reminder Time',
            icon: Icons.schedule_rounded,
            child: TextField(controller: _modalReminderTimeController, decoration: _fieldDecoration('08:00'), style: _sf(size: 16)),
          ),
          if (showDay)
            _buildModalField(
              label: 'Day of Week',
              icon: Icons.calendar_today_outlined,
              child: _buildDayDropdown(
                value: _modalReminderDay,
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _modalReminderDay = value);
                },
              ),
            ),
          _buildModalField(
            label: 'Note (optional)',
            icon: Icons.message_outlined,
            child: TextField(controller: _modalReminderNoteController, decoration: _fieldDecoration("e.g. Don't forget your morning run!"), style: _sf(size: 16)),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: _saveReminder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _uiGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: <BoxShadow>[BoxShadow(color: _accentGlow2, blurRadius: 18, offset: Offset(0, 5))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Icon(Icons.notifications_active_outlined, color: _text, size: 15), const SizedBox(width: 7), Text('Save Reminder', style: _sf(size: 15.2, weight: FontWeight.w600))]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _clearReminder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: _accentSoft4, borderRadius: BorderRadius.circular(14), border: Border.all(color: _accentBorder4)),
                  child: Row(children: <Widget>[Icon(Icons.notifications_off_outlined, color: _accent4, size: 14), const SizedBox(width: 6), Text('Clear', style: _sf(size: 13.76, weight: FontWeight.w600, color: _accent4))]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalField({required String label, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[Icon(icon, size: 11, color: _muted), const SizedBox(width: 5), Text(label.toUpperCase(), style: _sf(size: 11.2, weight: FontWeight.w600, color: _muted, letterSpacing: 1.28))]),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }

  Widget _buildDayDropdown({required String value, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: _panelSolid2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderStrong)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _bg2,
          icon: Icon(Icons.expand_more_rounded, color: _muted),
          isExpanded: true,
          style: _sf(size: 16),
          items: Screen4._days.map((String day) => DropdownMenuItem<String>(value: day, child: Text(day, style: _sf(size: 16)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToast() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: _scrimStrong, borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_outline_rounded, color: _text, size: 15),
            const SizedBox(width: 7),
            Text(_toastText, style: _sf(size: 13.76, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _toggleChat,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: _uiGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: <BoxShadow>[
            BoxShadow(color: _bg.withValues(alpha: 0.65), blurRadius: 24, offset: Offset(0, 6)),
            BoxShadow(color: _bg2.withValues(alpha: 0.45), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_outlined, color: _text, size: 16),
            const SizedBox(width: 8),
            Text('AHVI', style: _sf(size: 14.08, weight: FontWeight.w700, letterSpacing: 0.64)),
            const SizedBox(width: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _chatOpen ? _text.withValues(alpha: 0.70) : _accent3,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[BoxShadow(color: _accentGlow3, spreadRadius: 2), BoxShadow(color: _accent3.withValues(alpha: 0.55), blurRadius: 8)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatDrawer() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: Column(
        children: <Widget>[
          Container(width: 36, height: 4, margin: const EdgeInsets.fromLTRB(0, 10, 0, 0), decoration: BoxDecoration(color: _bg.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(2))),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cardBorder))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(gradient: _uiGradient, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('AH', style: _sf(size: 12, weight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('AHVI', style: _sf(size: 14.72, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Row(children: <Widget>[const _PulsingDot(), const SizedBox(width: 4), Text('Your AI Life Coach - Online', style: _sf(size: 11.2, color: _muted))]),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _toggleChat,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: _bg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.expand_more_rounded, color: _muted, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _chatScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: <Widget>[
                for (final _ChatMessage message in _messages)
                  Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: message.isUser ? _uiGradient : null,
                        color: message.isUser ? null : _panelSolid2,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomRight: Radius.circular(message.isUser ? 4 : 18),
                          bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                        ),
                        border: message.isUser ? null : Border.all(color: _cardBorder),
                      ),
                      child: Text(message.text, style: _sf(size: 14.08, height: 1.5)),
                    ),
                  ),
                if (_typing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: _panelSolid2, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4))),
                      child: const _TypingDots(),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: _cardBorder))),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: _fieldDecoration('Ask me anything...').copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: _borderStrong)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: _accentBorder2)),
                    ),
                    style: _sf(size: 14.72),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: _uiGradient,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[BoxShadow(color: _accentGlow2, blurRadius: 12, offset: Offset(0, 3))],
                    ),
                    child: Icon(Icons.send_rounded, color: _text, size: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyPill extends StatelessWidget {
  const _FrequencyPill({required this.text, this.selected = false});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? t.accent.secondary.withValues(alpha: 0.14) : t.accent.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? t.accent.secondary : t.accent.primary.withValues(alpha: 0.44)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? t.accent.secondary : t.mutedText,
          fontSize: 12.48,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: const <String>['SF Pro Display', 'SF Pro Text', 'Helvetica Neue', 'Arial'],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tkn = context.themeTokens;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value < 0.5 ? _controller.value * 2 : (1 - _controller.value) * 2;
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: tkn.accent.tertiary,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[BoxShadow(color: tkn.accent.tertiary.withValues(alpha: 0.34), spreadRadius: 2 + (2 * t))],
          ),
        );
      },
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tkn = context.themeTokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final double t = (_controller.value + (index * 0.2)) % 1.0;
              final double offset = t < 0.3 ? -6 * (t / 0.3) : (t < 0.6 ? -6 * (1 - ((t - 0.3) / 0.3)) : 0);
              return Transform.translate(offset: Offset(0, offset), child: child);
            },
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: tkn.mutedText, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    );
  }
}

class _FilterChipData {
  const _FilterChipData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _DropdownOptionData {
  const _DropdownOptionData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _SuggestionData {
  const _SuggestionData({
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
    required this.stripe,
    required this.tagBg,
    required this.cardBg,
    required this.cardBorder,
  });

  final String title;
  final String description;
  final String tag;
  final IconData icon;
  final Color stripe;
  final Color tagBg;
  final Color cardBg;
  final Color cardBorder;
}

class _GoalReminder {
  const _GoalReminder({
    required this.frequency,
    required this.time,
    required this.day,
    required this.note,
  });

  final String frequency;
  final String time;
  final String day;
  final String note;
}

class _GoalItem {
  _GoalItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.accent,
    required this.cardBackground,
    required this.cardBorder,
    required this.progress,
    required this.reminder,
  });

  _GoalItem.empty()
      : id = -1,
        title = '',
        description = '',
        category = '',
        icon = Icons.circle,
        accent = kTransparent,
        cardBackground = kTransparent,
        cardBorder = kTransparent,
        progress = 0,
        reminder = null;

  final int id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color accent;
  final Color cardBackground;
  final Color cardBorder;
  int progress;
  _GoalReminder? reminder;
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
