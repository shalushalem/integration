import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:myapp/services/appwrite_service.dart'; // <-- Added Appwrite import

// ── Color constants ──────────────────────────────────────────────────────────
const Color kBg = Color(0xFF08111F);
const Color kBg2 = Color(0xFF0F1A2D);
const Color kPanel = Color(0x14FFFFFF);
const Color kPanel2 = Color(0x1FFFFFFF);
const Color kCard = Color(0x14FFFFFF);
const Color kCardBorder = Color(0x1FFFFFFF);
const Color kText = Color(0xFFF5F7FF);
const Color kMuted = Color(0xB7E6EBFF);
const Color kTileText = Color(0xFF10131B);
const Color kAccent = Color(0xFF6B91FF);
const Color kAccent2 = Color(0xFF8D7DFF);
const Color kAccent3 = Color(0xFF04D7C8);
const Color kAccent4 = Color(0xFFFF8EC7);
const Color kAccent5 = Color(0xFFFFD86E);
const Color kPhoneShell = Color(0xFF192131);
const Color kPhoneShell2 = Color(0xFF111723);

// ── Data Models ──────────────────────────────────────────────────────────────
class GoalModel {
  final String id;
  final String title;
  final String description;
  final String category;
  int progress;
  final int target; // Added target for % calculation
  Color accent;

  GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.progress,
    required this.target,
    required this.accent,
  });
}

// ── Suggestion data ───────────────────────────────────────────────────────────
class SuggModel {
  final String emoji;
  final String title;
  final String desc;
  final String tag;
  final List<Color> stripeColors;
  final List<Color> iconColors;
  final Color tagColor;

  const SuggModel({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.tag,
    required this.stripeColors,
    required this.iconColors,
    required this.tagColor,
  });
}

const List<SuggModel> kSuggestions = [
  SuggModel(emoji: '🏃', title: 'Daily Movement', desc: '30 min of exercise every day to boost energy and mood.', tag: 'HEALTH', stripeColors: [kAccent3, kAccent2], iconColors: [kAccent3, kAccent2], tagColor: kAccent3),
  SuggModel(emoji: '📚', title: 'Read Daily', desc: 'Just 20 pages a day adds up to 12 books a year.', tag: 'LEARNING', stripeColors: [kAccent, kAccent3], iconColors: [kAccent, kAccent3], tagColor: kAccent),
  SuggModel(emoji: '💰', title: 'Save 20%', desc: 'Automate savings to build financial freedom.', tag: 'FINANCE', stripeColors: [kAccent5, kAccent2], iconColors: [kAccent5, kAccent2], tagColor: kAccent5),
  SuggModel(emoji: '🧘', title: 'Meditate', desc: 'Daily mindfulness for clarity and calm.', tag: 'MINDFULNESS', stripeColors: [kAccent2, kAccent], iconColors: [kAccent2, kAccent], tagColor: kAccent2),
];

// ── Typing Indicator Widget ──────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}
class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _dot(double delay) {
    final Animation<double> anim = CurvedAnimation(parent: _ctrl, curve: Interval(delay, delay + 0.5, curve: Curves.easeInOut));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -6 * anim.value * (1 - anim.value) * 4),
        child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: kMuted, shape: BoxShape.circle)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: kPanel2,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [_dot(0.0), const SizedBox(width: 4), _dot(0.17), const SizedBox(width: 4), _dot(0.33)]),
      ),
    );
  }
}

// ── Toast Overlay Helper ─────────────────────────────────────────
class _ToastManager {
  static OverlayEntry? _entry;
  static bool _showing = false;

  static void show(BuildContext context, String message) {
    if (_showing) { _entry?.remove(); _showing = false; }
    final overlay = Overlay.of(context);
    final controller = AnimationController(vsync: Navigator.of(context), duration: const Duration(milliseconds: 300));
    final slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 90, left: 0, right: 0,
        child: Center(
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: kPhoneShell, borderRadius: BorderRadius.circular(24), border: Border.all(color: kCardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline, color: kAccent3, size: 15),
                  const SizedBox(width: 7),
                  Text(message, style: const TextStyle(color: kText, fontSize: 13.76, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    _showing = true;
    controller.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      controller.reverse().then((_) { _entry?.remove(); _entry = null; _showing = false; controller.dispose(); });
    });
  }
}

// ── Pulsing Online Dot Widget ────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: kAccent3, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: kAccent3.withValues(alpha: 0.15 + 0.15 * _anim.value), blurRadius: 0, spreadRadius: 2 + 2 * _anim.value)],
        ),
      ),
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class LifeGoalsScreen extends StatefulWidget {
  const LifeGoalsScreen({super.key});
  @override
  State<LifeGoalsScreen> createState() => _LifeGoalsScreenState();
}

class _LifeGoalsScreenState extends State<LifeGoalsScreen> with TickerProviderStateMixin {

  AppThemeTokens get _t => context.themeTokens;
  Color get _themeAccent => _t.accent.primary;
  Color get _themeAccent2 => _t.accent.secondary;
  Color get _themeAccent3 => _t.accent.tertiary;
  Color get _themeAccent4 => Color.lerp(_themeAccent2, _themeAccent, 0.55)!;
  Color get _themeAccent5 => Color.lerp(_themeAccent, _themeAccent3, 0.45)!;

  Color _accentForCategory(String category) {
    switch (category) {
      case 'Health': case 'Health & Wellness': return _themeAccent3;
      case 'Learning': return _themeAccent;
      case 'Finance': return _themeAccent5;
      case 'Mindfulness': return _themeAccent2;
      case 'Creativity': return _themeAccent4;
      default: return _themeAccent;
    }
  }

  // ── Database State ──
  List<GoalModel> _goals = [];
  bool _isLoading = true;

  String _activeFilter = 'All';
  bool _chatOpen = false;
  bool _reminderOpen = false;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController(text: '100'); // Default target
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();
  String _selectedCategory = 'Health & Wellness';
  String _formFreq = 'Daily';

  bool _showTyping = false;
  bool _titleError = false;
  bool _fabPressed = false;
  bool _addPressed = false;
  bool _clearPressed = false;
  final Map<int, bool> _suggPressed = {};

  final List<Map<String, String>> _chatMessages = [
    {'role': 'ai', 'text': "Hey! 👋 I'm AHVI, your AI life coach. Ask me about goals, motivation, or what to focus on next."},
  ];

  final List<String> _filters = ['All', 'Health & Wellness', 'Relationships', 'Career', 'Learning', 'Finance', 'Creativity', 'Mindfulness'];
  final Map<String, AnimationController> _cardAnimControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  // ── APPWRITE LOGIC ──
  Future<void> _fetchGoals() async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final docs = await appwrite.getLifeGoals();
      if (mounted) {
        setState(() {
          _goals = docs.map((d) => GoalModel(
            id: d.$id,
            title: d.data['title'],
            description: d.data['description'] ?? '',
            category: d.data['category'],
            progress: d.data['progress'] ?? 0,
            target: d.data['target'] ?? 100,
            accent: _accentForCategory(d.data['category']),
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching goals: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initCardAnim(String id) {
    if (_cardAnimControllers.containsKey(id)) return;
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _cardAnimControllers[id] = ctrl;
    final idx = _goals.indexWhere((g) => g.id == id);
    if(idx != -1) {
      Future.delayed(Duration(milliseconds: idx * 40), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    for (final c in _cardAnimControllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.backgroundPrimary,
      body: Stack(
          children: [
            Column(
              children: [
                _buildNav(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddPanel(),
                        const SizedBox(height: 4),
                        _buildSectionHeader('My Goals', '${_goals.length} goals'),
                        const SizedBox(height: 16),
                        _buildFilters(),
                        _buildGoalsGrid(),
                        const SizedBox(height: 8),
                        _buildSectionHeader('Suggested Goals', 'IDEAS'),
                        const SizedBox(height: 16),
                        _buildSuggestionsScroll(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: _themeAccent,
                  backgroundColor: Colors.transparent,
                ),
              ),
            Positioned(bottom: 16, right: 16, child: _buildFab()),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              bottom: _chatOpen ? 0 : -420, left: 0, right: 0,
              child: _buildChatDrawer(),
            ),
          ],
        ),
    );
  }

  Widget _buildNav(BuildContext context) {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _t.phoneShellInner,
        boxShadow: [BoxShadow(color: _themeAccent.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 2))],
        border: const Border(bottom: BorderSide(color: Colors.transparent, width: 2)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -16, right: -16, bottom: -2,
            child: Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [_themeAccent, _themeAccent2, _themeAccent3, _themeAccent5]))),
          ),
          Row(
            children: [
              _BackButton(onTap: () => Navigator.maybePop(context)),
              const SizedBox(width: 12),
              Text('Life Goals', style: TextStyle(color: _t.textPrimary, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title, style: TextStyle(color: _t.textPrimary, fontSize: 22.4, fontWeight: FontWeight.w900)),
            Text(badge, style: TextStyle(color: _themeAccent, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.6)),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(height: 2, color: _t.cardBorder),
            Container(height: 2, width: 200, decoration: BoxDecoration(gradient: LinearGradient(colors: [_themeAccent, _themeAccent2, Colors.transparent], stops: const [0, 0.6, 1]))),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: kPhoneShell, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCardBorder),
        boxShadow: [BoxShadow(color: kAccent.withValues(alpha: 0.1), blurRadius: 28, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [kAccent2, kAccent4, kAccent5, kAccent3]))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 21, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.add_circle_outline_rounded, color: kAccent5, size: 20),
                    const SizedBox(width: 8),
                    const Text('Add a New Goal', style: TextStyle(color: kText, fontSize: 17.6, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: 'Goal Title *',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: kPanel, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _titleError ? kAccent4 : kCardBorder, width: _titleError ? 1.5 : 1.0),
                        boxShadow: _titleError ? [BoxShadow(color: kAccent4.withValues(alpha: 0.2), blurRadius: 8)] : [],
                      ),
                      child: TextField(controller: _titleCtrl, style: const TextStyle(color: kText, fontSize: 16), decoration: _inputDecorationBorderless('e.g. Run a 5K')),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFormField(
                          label: 'Description (optional)',
                          child: TextField(controller: _descCtrl, maxLines: 1, style: const TextStyle(color: kText, fontSize: 16), decoration: _inputDecoration('Why does this matter?')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: _buildFormField(
                          label: 'Target',
                          child: TextField(controller: _targetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: kText, fontSize: 16), decoration: _inputDecoration('100')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildFormField(label: 'Category', child: _buildGlassSelectTrigger()),
                  const SizedBox(height: 10),
                  _buildReminderSection(),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _buildAddButton()),
                    const SizedBox(width: 10),
                    _buildClearButton(),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.28)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: kMuted.withValues(alpha: 0.5), fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true, fillColor: kPanel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kCardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kCardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
    );
  }

  InputDecoration _inputDecorationBorderless(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: kMuted.withValues(alpha: 0.5), fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true, fillColor: Colors.transparent,
      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
    );
  }

  Widget _buildGlassSelectTrigger() {
    return GestureDetector(
      onTap: _showCategorySheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: kPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: kCardBorder),
          boxShadow: [BoxShadow(color: kAccent.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kAccent3, kAccent2]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(_selectedCategory, style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w500))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: kMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet() {
    final categories = [
      {'label': 'Health & Wellness', 'colors': <Color>[kAccent3, kAccent2]},
      {'label': 'Relationships', 'colors': <Color>[kAccent4, kAccent2]},
      {'label': 'Career', 'colors': <Color>[kAccent, kAccent2]},
      {'label': 'Learning', 'colors': <Color>[kAccent, kAccent3]},
      {'label': 'Finance', 'colors': <Color>[kAccent5, kAccent2]},
      {'label': 'Creativity', 'colors': <Color>[kAccent4, kAccent5]},
      {'label': 'Mindfulness', 'colors': <Color>[kAccent2, kAccent]},
    ];

    showModalBottomSheet(
      context: context, backgroundColor: kPhoneShell,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 24), shrinkWrap: true, itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final label = cat['label'] as String;
          final isActive = _selectedCategory == label;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 180 + i * 30), curve: Curves.easeOut,
            builder: (_, val, child) => Transform.translate(offset: Offset(-6 * (1 - val), 0), child: Opacity(opacity: val, child: child)),
            child: GestureDetector(
              onTap: () { setState(() => _selectedCategory = label); Navigator.pop(context); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150), margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: isActive ? kAccent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cat['colors'] as List<Color>), borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(label, style: TextStyle(color: isActive ? kAccent : kText, fontSize: 15.2, fontWeight: FontWeight.w500))),
                    AnimatedOpacity(opacity: isActive ? 1.0 : 0.0, duration: const Duration(milliseconds: 150), child: const Text('✓', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderSection() {
    if (!_reminderOpen) {
      return GestureDetector(
        onTap: () => setState(() => _reminderOpen = true),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: kAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccent.withValues(alpha: 0.35), width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.notifications_outlined, color: kMuted, size: 15), SizedBox(width: 8),
            Text('Add Reminder to this Goal', style: TextStyle(color: kMuted, fontSize: 13.76, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [Icon(Icons.notifications_active, color: kAccent5, size: 14), SizedBox(width: 5), Text('Reminder', style: TextStyle(color: kText, fontSize: 13.44, fontWeight: FontWeight.w600))]),
              GestureDetector(
                onTap: () => setState(() => _reminderOpen = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: kAccent4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: const [Icon(Icons.close, color: kAccent4, size: 13), SizedBox(width: 4), Text('Remove', style: TextStyle(color: kAccent4, fontSize: 12.48, fontWeight: FontWeight.w600))]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Daily', 'Weekly', 'Monthly'].map((f) {
              final isOn = _formFreq == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _formFreq = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(color: isOn ? kAccent.withValues(alpha: 0.15) : kPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: isOn ? kAccent : kAccent.withValues(alpha: 0.25))),
                    child: Text(f, textAlign: TextAlign.center, style: TextStyle(color: isOn ? kAccent : kMuted, fontSize: 12.48, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _addPressed = true),
      onTapUp: (_) { setState(() => _addPressed = false); _handleAddGoal(); },
      onTapCancel: () => setState(() => _addPressed = false),
      child: AnimatedScale(
        scale: _addPressed ? 0.97 : 1.0, duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kAccent, kAccent2, kAccent3]),
            borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: kAccent.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 5))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.add, color: kTileText, size: 15), SizedBox(width: 7),
            Text('Add Goal', style: TextStyle(color: kTileText, fontSize: 15.2, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  void _handleAddGoal() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = true);
      Future.delayed(const Duration(milliseconds: 1500), () { if (mounted) setState(() => _titleError = false); });
      return;
    }

    final target = int.tryParse(_targetCtrl.text.trim()) ?? 100;

    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      await appwrite.createLifeGoal({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'progress': 0,
        'target': target,
        'unit': '%',
      });
      
      _titleCtrl.clear();
      _descCtrl.clear();
      _targetCtrl.text = '100';
      setState(() => _reminderOpen = false);
      _showToast('Goal added!');
      _fetchGoals(); // Refresh list

    } catch (e) {
      _showToast('Error adding goal. Try again.');
    }
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _clearPressed = true),
      onTapUp: (_) {
        setState(() => _clearPressed = false);
        _titleCtrl.clear(); _descCtrl.clear(); _targetCtrl.text = '100';
        setState(() { _reminderOpen = false; _titleError = false; });
      },
      onTapCancel: () => setState(() => _clearPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _clearPressed ? kPanel2 : kPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCardBorder)),
        child: Row(children: const [Icon(Icons.close, color: kMuted, size: 14), SizedBox(width: 6), Text('Clear', style: TextStyle(color: kMuted, fontSize: 14.4, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final f = entry.value;
          final isOn = _activeFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 7), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isOn ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kAccent, kAccent2]) : null,
                color: isOn ? null : kPanel, borderRadius: BorderRadius.circular(20), border: isOn ? null : Border.all(color: kCardBorder, width: 1.5),
                boxShadow: isOn ? [BoxShadow(color: kAccent.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))] : [BoxShadow(color: kAccent.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(f, style: TextStyle(color: isOn ? kTileText : kMuted, fontSize: 12.8, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalsGrid() {
    final filtered = _activeFilter == 'All' ? _goals : _goals.where((g) => g.category == _activeFilter).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20), alignment: Alignment.center,
        child: Column(children: const [
          Icon(Icons.flag_outlined, color: kMuted, size: 48), SizedBox(height: 12),
          Text('No goals yet', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w600)), SizedBox(height: 6),
          Text('Add your first goal above to get started.', textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13.12)),
        ]),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 14),
        ...filtered.map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _buildAnimatedGoalCard(goal),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAnimatedGoalCard(GoalModel goal) {
    _initCardAnim(goal.id);
    final ctrl = _cardAnimControllers[goal.id];
    if (ctrl == null) return _buildGoalCard(goal);

    final fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    final scale = Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));

    return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: _buildGoalCard(goal)));
  }

  Widget _buildGoalCard(GoalModel goal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
      decoration: BoxDecoration(
        color: goal.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.flag_rounded, color: goal.accent, size: 14),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(goal.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kText, fontSize: 13.12, fontWeight: FontWeight.w700)),
                  if (goal.description.isNotEmpty)
                    Text(goal.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.2, height: 1.3)),
                ]),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  try {
                    await Provider.of<AppwriteService>(context, listen: false).deleteLifeGoal(goal.id);
                    _fetchGoals();
                    _showToast('Goal removed');
                  } catch(e) { _showToast('Error removing goal'); }
                },
                child: Container(width: 24, height: 24, decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close, color: kAccent4, size: 13)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: (goal.progress / goal.target).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600), curve: const Cubic(0.4, 0.0, 0.2, 1.0),
            builder: (_, value, __) => Container(
              height: 4, decoration: BoxDecoration(color: kPanel2, borderRadius: BorderRadius.circular(10)),
              child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: value, child: Container(decoration: BoxDecoration(color: goal.accent, borderRadius: BorderRadius.circular(10)))),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCardBorder)),
                child: Text(goal.category.toUpperCase(), style: TextStyle(color: goal.accent, fontSize: 9.6, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
              Row(
                children: [
                  Text('/ ${goal.target} ', style: const TextStyle(color: kMuted, fontSize: 11)),
                  SizedBox(
                    width: 52, height: 26,
                    child: TextField(
                      controller: TextEditingController(text: '${goal.progress}'),
                      keyboardType: TextInputType.number, textAlign: TextAlign.center,
                      style: const TextStyle(color: kText, fontSize: 11.52, fontWeight: FontWeight.w600),
                      onSubmitted: (val) async {
                        final n = int.tryParse(val);
                        if (n != null) {
                          try {
                            await Provider.of<AppwriteService>(context, listen: false).updateLifeGoalProgress(goal.id, n);
                            _fetchGoals(); // Update UI
                          } catch (e) {
                            _showToast('Update failed');
                          }
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), filled: true, fillColor: kPanel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kCardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kCardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kAccent)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsScroll() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: kSuggestions.asMap().entries.map((e) => _buildSuggCard(e.value, e.key)).toList()),
    );
  }

  Widget _buildSuggCard(SuggModel s, int index) {
    final isPressed = _suggPressed[index] ?? false;
    return GestureDetector(
      onTapDown: (_) => setState(() => _suggPressed[index] = true),
      onTapUp: (_) {
        setState(() => _suggPressed[index] = false);
        _titleCtrl.text = s.title;
        _descCtrl.text = s.desc;
        _selectedCategory = s.tag == 'HEALTH' ? 'Health & Wellness' : s.tag == 'FINANCE' ? 'Finance' : s.tag == 'LEARNING' ? 'Learning' : 'Mindfulness';
        _chatScrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      },
      onTapCancel: () => setState(() => _suggPressed[index] = false),
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0, duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), width: 195, margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isPressed ? kAccent.withValues(alpha: 0.10) : kPhoneShell, borderRadius: BorderRadius.circular(18), border: Border.all(color: kCardBorder),
            boxShadow: [BoxShadow(color: kAccent.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, child: Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: s.stripeColors)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s.iconColors), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(height: 12),
                    Text(s.title, style: const TextStyle(color: kText, fontSize: 14.4, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(s.desc, style: const TextStyle(color: kMuted, fontSize: 12.16, height: 1.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: s.tagColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(s.tag, style: TextStyle(color: s.tagColor, fontSize: 10.56, fontWeight: FontWeight.w700, letterSpacing: 0.64)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _fabPressed = true),
      onTapUp: (_) { setState(() { _fabPressed = false; _chatOpen = !_chatOpen; }); },
      onTapCancel: () => setState(() => _fabPressed = false),
      child: AnimatedScale(
        scale: _fabPressed ? 0.96 : 1.0, duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), height: 50, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _chatOpen ? [kAccent4, kAccent2] : [kPhoneShell2, kAccent]),
            borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: kText, size: 16), const SizedBox(width: 8),
              const Text('AHVI', style: TextStyle(color: kText, fontSize: 14.08, fontWeight: FontWeight.w700, letterSpacing: 0.64)),
              if (!_chatOpen) Container(width: 7, height: 7, margin: const EdgeInsets.only(left: 4), decoration: const BoxDecoration(color: kAccent3, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatDrawer() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: kPhoneShell, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: kCardBorder)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, -8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: kCardBorder, borderRadius: BorderRadius.circular(2))),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kCardBorder))),
            child: Row(
              children: [
                Container(width: 38, height: 38, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kAccent, kAccent2, kAccent3]), shape: BoxShape.circle), child: const Center(child: Text('AH', style: TextStyle(color: kTileText, fontSize: 12, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('AHVI', style: TextStyle(color: kText, fontSize: 14.72, fontWeight: FontWeight.w700)), Row(children: [_PulsingDot(), SizedBox(width: 4), Text('Your AI Life Coach · Online', style: TextStyle(color: kMuted, fontSize: 11.2))])]),
                const Spacer(),
                GestureDetector(onTap: () => setState(() => _chatOpen = false), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.keyboard_arrow_down_rounded, color: kMuted, size: 18))),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              controller: _chatScrollCtrl, padding: const EdgeInsets.all(12),
              itemCount: _chatMessages.length + (_showTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_showTyping && i == _chatMessages.length) return const _TypingIndicator();
                final msg = _chatMessages[i];
                final isAi = msg['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(gradient: isAi ? null : const LinearGradient(colors: [kAccent, kAccent2]), color: isAi ? kPanel2 : null, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isAi ? 4 : 16), bottomRight: Radius.circular(isAi ? 16 : 4))),
                    child: Text(msg['text'] ?? '', style: TextStyle(color: isAi ? kText : kTileText, fontSize: 13.76, height: 1.5)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: kCardBorder))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl, style: const TextStyle(color: kText, fontSize: 14.4), onSubmitted: (_) => _sendChatMessage(),
                    decoration: InputDecoration(hintText: 'Ask me anything…', hintStyle: TextStyle(color: kMuted.withValues(alpha: 0.6)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), filled: true, fillColor: kPanel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kCardBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kCardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kAccent))),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendChatMessage,
                  child: Container(width: 44, height: 44, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kAccent, kAccent2]), shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: kTileText, size: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendChatMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _chatMessages.add({'role': 'user', 'text': text}); _chatCtrl.clear(); _showTyping = true; });
    _scrollChatToBottom();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() { _showTyping = false; _chatMessages.add({'role': 'ai', 'text': 'Great question! Focus on one goal at a time for the best results.'}); });
      _scrollChatToBottom();
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) _chatScrollCtrl.animateTo(_chatScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _showToast(String msg) => _ToastManager.show(context, msg);
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  State<_BackButton> createState() => _BackButtonState();
}
class _BackButtonState extends State<_BackButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0, duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), width: 40, height: 40,
          decoration: BoxDecoration(color: _pressed ? kPanel2 : kPanel, shape: BoxShape.circle, border: Border.all(color: kCardBorder)),
          child: const Icon(Icons.chevron_left_rounded, color: kAccent, size: 20),
        ),
      ),
    );
  }
}
