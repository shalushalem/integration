// ignore_for_file: library_private_types_in_public_api
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

// ── Color tokens ──────────────────────────────────────────────────────────────
// Colors are resolved from theme tokens in widget builds.

// ── Data Models ───────────────────────────────────────────────────────────────
class MealPlan {
  final int id;
  final String name, desc, planType;
  final List<MealItem> meals;
  final int totalCal;
  const MealPlan({required this.id, required this.name, required this.desc,
    required this.planType, required this.meals, required this.totalCal});
}

class MealItem {
  final String type, icon, cls, name, desc;
  final int cal;
  const MealItem({required this.type, required this.icon, required this.cls,
    required this.name, required this.desc, required this.cal});
}

final List<MealPlan> kSeedPlans = [
  MealPlan(id: 1, name: 'Mediterranean Daily Plan',
      desc: 'Fresh, heart-healthy Mediterranean-inspired meals',
      planType: 'daily', totalCal: 1640,
      meals: [
        MealItem(type:'Breakfast',icon:'🌅',cls:'breakfast',name:'Greek yogurt parfait',desc:'Granola, honey, mixed berries',cal:380),
        MealItem(type:'Lunch',icon:'☀️',cls:'lunch',name:'Grilled chicken salad',desc:'Olives, feta, cucumber, lemon dressing',cal:520),
        MealItem(type:'Dinner',icon:'🌙',cls:'dinner',name:'Salmon with roasted veggies',desc:'Herbs, olive oil, lemon zest',cal:590),
        MealItem(type:'Snack',icon:'🍎',cls:'snack',name:'Hummus & veggies',desc:'Carrots, cucumber, pita',cal:150),
      ]),
  MealPlan(id: 2, name: 'High Protein Weekly Plan',
      desc: '7-day high-protein batch-prep plan for muscle gain',
      planType: 'weekly', totalCal: 3780,
      meals: [
        MealItem(type:'Breakfast',icon:'🌅',cls:'breakfast',name:'Scrambled eggs + smoked salmon',desc:'Whole grain toast, avocado',cal:480),
        MealItem(type:'Lunch',icon:'☀️',cls:'lunch',name:'Chicken + quinoa + broccoli',desc:'Serve as bowl, wrap or skillet',cal:560),
        MealItem(type:'Dinner',icon:'🌙',cls:'dinner',name:'Beef stir-fry + snap peas & rice',desc:'Lean beef, ginger-soy glaze',cal:580),
        MealItem(type:'Daily Snacks',icon:'🍎',cls:'snack',name:'Greek yogurt, boiled eggs, protein bars',desc:'~200 cal each',cal:200),
      ]),
];

// ── [F5] Blur helper ──────────────────────────────────────────────────────────
ImageFilter _buildBlur(double sigma) =>
    ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

// ─────────────────────────────────────────────────────────────────────────────
// Root Screen
// ─────────────────────────────────────────────────────────────────────────────
class Screen4 extends StatefulWidget {
  const Screen4({super.key});
  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> with TickerProviderStateMixin {
  final List<MealPlan> _plans = List.from(kSeedPlans);
  String _currentView = 'all';
  bool _chatOpen = false;
  bool _modalOpen = false;
  bool _deleteModalOpen = false;
  int? _deleteTargetId;
  String _deleteTargetName = '';

  // Form controllers
  final _planNameCtrl = TextEditingController();
  final _planDescCtrl = TextEditingController();
  String _selectedPlanType = 'daily';
  final _bNameCtrl = TextEditingController(); final _bDescCtrl = TextEditingController(); final _bCalCtrl = TextEditingController();
  final _lNameCtrl = TextEditingController(); final _lDescCtrl = TextEditingController(); final _lCalCtrl = TextEditingController();
  final _dNameCtrl = TextEditingController(); final _dDescCtrl = TextEditingController(); final _dCalCtrl = TextEditingController();
  final _sNameCtrl = TextEditingController(); final _sDescCtrl = TextEditingController(); final _sCalCtrl = TextEditingController();
  bool _planNameError = false;

  // Chat
  final List<_ChatMsg> _messages = [];
  final _chatInputCtrl = TextEditingController();
  final _messagesScrollCtrl = ScrollController();
  final Set<int> _expandedCards = {};

  // Animation controllers
  late AnimationController _chatAnimCtrl;
  late AnimationController _modalAnimCtrl;
  late AnimationController _deleteAnimCtrl;

  // [F1] Live clock
  Ticker? _ticker;
  String _liveTimeStr = '';
  Duration _lastTick = Duration.zero;

  bool get _overlayVisible => _modalOpen || _chatOpen || _deleteModalOpen;

  @override
  void initState() {
    super.initState();
    _chatAnimCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _modalAnimCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _deleteAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

    // [F1] Start live clock — mirrors HTML: setInterval(updateDateTime, 1000)
    _updateLiveTime();
    _ticker = createTicker((elapsed) {
      if ((elapsed - _lastTick).inMilliseconds >= 1000) {
        _lastTick = elapsed;
        _updateLiveTime();
      }
    })..start();

    _messages.add(_ChatMsg(isBot: true,
        text: 'Hey! 😊 Ask for a Mediterranean, High Protein, Vegan, Low Carb or Balanced plan — and say daily, weekly or monthly!'));
  }

  // [F1] Build live time string
  void _updateLiveTime() {
    final now = DateTime.now();
    final h    = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m    = now.minute.toString().padLeft(2, '0');
    final s    = now.second.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) setState(() => _liveTimeStr = '$h:$m:$s $ampm');
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _chatAnimCtrl.dispose(); _modalAnimCtrl.dispose(); _deleteAnimCtrl.dispose();
    _planNameCtrl.dispose(); _planDescCtrl.dispose();
    _bNameCtrl.dispose(); _bDescCtrl.dispose(); _bCalCtrl.dispose();
    _lNameCtrl.dispose(); _lDescCtrl.dispose(); _lCalCtrl.dispose();
    _dNameCtrl.dispose(); _dDescCtrl.dispose(); _dCalCtrl.dispose();
    _sNameCtrl.dispose(); _sDescCtrl.dispose(); _sCalCtrl.dispose();
    _chatInputCtrl.dispose(); _messagesScrollCtrl.dispose();
    super.dispose();
  }

  List<MealPlan> get _filteredPlans {
    if (_currentView == 'all') { return _plans; }
    return _plans.where((p) => p.planType == _currentView).toList();
  }

  void _openChat()   { setState(() => _chatOpen = true);   _chatAnimCtrl.forward(); }
  void _closeChat()  { _chatAnimCtrl.reverse().then((_) => setState(() => _chatOpen = false)); }
  void _openModal()  { setState(() => _modalOpen = true);  _modalAnimCtrl.forward(); }
  void _closeModal() {
    _modalAnimCtrl.reverse().then((_) { if (mounted) { setState(() {
      _modalOpen = false;
      _planNameCtrl.clear(); _planDescCtrl.clear();
      _bNameCtrl.clear(); _bDescCtrl.clear(); _bCalCtrl.clear();
      _lNameCtrl.clear(); _lDescCtrl.clear(); _lCalCtrl.clear();
      _dNameCtrl.clear(); _dDescCtrl.clear(); _dCalCtrl.clear();
      _sNameCtrl.clear(); _sDescCtrl.clear(); _sCalCtrl.clear();
      _selectedPlanType = 'daily'; _planNameError = false;
    }); }});
  }

  void _showDeleteConfirm(int id, String name) {
    setState(() { _deleteTargetId = id; _deleteTargetName = name; _deleteModalOpen = true; });
    _deleteAnimCtrl.forward();
  }
  void _cancelDelete() {
    _deleteAnimCtrl.reverse().then((_) => setState(() => _deleteModalOpen = false));
  }
  void _handleBackNavigation() {
    if (_deleteModalOpen) {
      _cancelDelete();
      return;
    }
    if (_chatOpen) {
      _closeChat();
      return;
    }
    if (_modalOpen) {
      _closeModal();
      return;
    }
    Navigator.of(context).maybePop();
  }
  void _confirmDelete() {
    setState(() => _plans.removeWhere((p) => p.id == _deleteTargetId));
    _cancelDelete();
  }

  void _saveCustomPlan() {
    final name = _planNameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _planNameError = true); return; }
    setState(() => _planNameError = false);
    final meals = <MealItem>[];
    if (_bNameCtrl.text.trim().isNotEmpty) meals.add(MealItem(type:'Breakfast',icon:'🌅',cls:'breakfast',name:_bNameCtrl.text.trim(),desc:_bDescCtrl.text.trim(),cal:int.tryParse(_bCalCtrl.text)??0));
    if (_lNameCtrl.text.trim().isNotEmpty) meals.add(MealItem(type:'Lunch',icon:'☀️',cls:'lunch',name:_lNameCtrl.text.trim(),desc:_lDescCtrl.text.trim(),cal:int.tryParse(_lCalCtrl.text)??0));
    if (_dNameCtrl.text.trim().isNotEmpty) meals.add(MealItem(type:'Dinner',icon:'🌙',cls:'dinner',name:_dNameCtrl.text.trim(),desc:_dDescCtrl.text.trim(),cal:int.tryParse(_dCalCtrl.text)??0));
    if (_sNameCtrl.text.trim().isNotEmpty) meals.add(MealItem(type:'Snack',icon:'🍎',cls:'snack',name:_sNameCtrl.text.trim(),desc:_sDescCtrl.text.trim(),cal:int.tryParse(_sCalCtrl.text)??0));
    if (meals.isEmpty) return;
    final totalCal = meals.fold(0, (a, m) => a + m.cal);
    setState(() => _plans.insert(0, MealPlan(id:DateTime.now().millisecondsSinceEpoch,name:name,desc:_planDescCtrl.text.trim(),planType:_selectedPlanType,meals:meals,totalCal:totalCal)));
    _closeModal();
  }

  // [F7] Typing indicator before bot reply — mirrors HTML showTyping() + setTimeout(600-1100ms)
  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() => _messages.add(_ChatMsg(isBot: false, text: text.trim())));
    _chatInputCtrl.clear();
    setState(() => _messages.add(_ChatMsg(isBot: true, text: '', isTyping: true)));
    _scrollChatToBottom();
    Future.delayed(Duration(milliseconds: 600 + Random().nextInt(500)), () {
      if (!mounted) return;
      final botMsg = _getBotReply(text.toLowerCase());
      setState(() { _messages.removeWhere((m) => m.isTyping); _messages.add(botMsg); });
      _scrollChatToBottom();
    });
  }

  void _scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_messagesScrollCtrl.hasClients) {
        _messagesScrollCtrl.animateTo(_messagesScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  _ChatMsg _getBotReply(String t) {
    if (t.contains('hi') || t.contains('hello') || t.contains('hey')) {
      return _ChatMsg(isBot: true, text: "Hey! 😊 Ask for a Mediterranean, High Protein, Vegan, Low Carb or Balanced plan — and say daily, weekly or monthly!");
    }
    String style = '';
    if (t.contains('mediterr'))                   { style = 'mediterranean'; }
    else if (t.contains('protein') || t.contains('muscle')) { style = 'protein'; }
    else if (t.contains('vegan') || t.contains('plant'))    { style = 'vegan'; }
    else if (t.contains('low carb') || t.contains('keto'))  { style = 'lowcarb'; }
    else if (t.contains('balance') || t.contains('normal')) { style = 'balanced'; }
    else { return _ChatMsg(isBot: true, text: "I'd love to help! Try: Mediterranean weekly, High Protein monthly, Vegan daily, Low Carb weekly, or Balanced monthly 🥗"); }

    String planType = 'daily';
    if (t.contains('week')) { planType = 'weekly'; }
    else if (t.contains('month')) { planType = 'monthly'; }

    final styleName = {'mediterranean':'Mediterranean','protein':'High Protein','vegan':'Vegan','lowcarb':'Low Carb','balanced':'Balanced'}[style]??'Mediterranean';
    final cap = '${planType[0].toUpperCase()}${planType.substring(1)}';
    return _ChatMsg(isBot: true,
      text: "Here's your $styleName $cap Plan! 🎉",
      suggestedPlan: MealPlan(
        id: DateTime.now().millisecondsSinceEpoch,
        name: '$styleName $cap Plan',
        desc: 'AI-suggested $styleName meal plan',
        planType: planType, totalCal: 1580,
        meals: [
          MealItem(type:'Breakfast',icon:'🌅',cls:'breakfast',name:'Nutritious breakfast bowl',desc:'Seasonal fruits, nuts & seeds',cal:380),
          MealItem(type:'Lunch',icon:'☀️',cls:'lunch',name:'Protein-packed lunch',desc:'Fresh vegetables, whole grains',cal:520),
          MealItem(type:'Dinner',icon:'🌙',cls:'dinner',name:'Light & filling dinner',desc:'Lean protein, roasted veggies',cal:540),
          MealItem(type:'Snack',icon:'🍎',cls:'snack',name:'Healthy snack',desc:'Nuts, fruit, yogurt',cal:140),
        ],
      ),
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${weekdays[now.weekday-1]}, ${months[now.month-1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final kBg = t.backgroundPrimary;
    final filtered = _filteredPlans;
    return PopScope(
      canPop: !_overlayVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
          // [F2] Animated background orbs (drift keyframe)
          RepaintBoundary(
            child: TickerMode(
              enabled: !_overlayVisible,
              child: const _BgOrbs(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 88),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // [F1][F3][F6] Header with live clock, back hover, add btn hover
                        _TopSection(dateStr: _getDateString(), liveTimeStr: _liveTimeStr, onAddTap: _openModal),
                        const SizedBox(height: 18),
                        // [F8] View tabs with hover opacity
                        _ViewTabs(currentView: _currentView, onTabChanged: (v) => setState(() => _currentView = v)),
                        const SizedBox(height: 18),
                        if (filtered.isEmpty && _plans.isEmpty)
                          const _EmptyState(icon: '🍽', message: 'No meal plans yet.\nAdd a custom plan or chat with the assistant!')
                        else if (filtered.isEmpty)
                          const _EmptyState(icon: '🔍', message: 'No plans for this view yet. Add one!')
                        else
                          Column(
                            children: filtered.map((plan) {
                              final idx = _plans.indexOf(plan);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                // [F9][F10][F11][F12] Card with shadow hover, edit btn, del red hover, pop-in
                                child: _VisualPlanCard(
                                  plan: plan, colorIndex: idx,
                                  isExpanded: _expandedCards.contains(plan.id),
                                  onToggle: () => setState(() {
                                    if (_expandedCards.contains(plan.id)) { _expandedCards.remove(plan.id); }
                                    else { _expandedCards.add(plan.id); }
                                  }),
                                  onDelete: () => _showDeleteConfirm(plan.id, plan.name),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // [F4] Chat FAB with scale hover
          Positioned(
            bottom: 20, right: 16,
            child: _ChatFab(onTap: _openChat),
          ),

          // [F5] Overlay with backdrop blur
          if (_modalOpen || _chatOpen || _deleteModalOpen)
            GestureDetector(
              onTap: () {
                if (_modalOpen) _closeModal();
                if (_chatOpen) _closeChat();
                if (_deleteModalOpen) _cancelDelete();
              },
              child: AnimatedOpacity(
                opacity: (_modalOpen || _chatOpen || _deleteModalOpen) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                // [F5] BackdropFilter blur(6px)
                child: BackdropFilter(
                  filter: _buildBlur(6.0),
                  child: Container(color: t.backgroundPrimary.withValues(alpha: 0.35)),
                ),
              ),
            ),

          // Add Meal Modal — [F13][F14][F15]
          if (_modalOpen)
            _AddMealModal(
              animation: _modalAnimCtrl,
              planNameCtrl: _planNameCtrl, planDescCtrl: _planDescCtrl,
              selectedPlanType: _selectedPlanType, planNameError: _planNameError,
              bNameCtrl: _bNameCtrl, bDescCtrl: _bDescCtrl, bCalCtrl: _bCalCtrl,
              lNameCtrl: _lNameCtrl, lDescCtrl: _lDescCtrl, lCalCtrl: _lCalCtrl,
              dNameCtrl: _dNameCtrl, dDescCtrl: _dDescCtrl, dCalCtrl: _dCalCtrl,
              sNameCtrl: _sNameCtrl, sDescCtrl: _sDescCtrl, sCalCtrl: _sCalCtrl,
              onClose: _closeModal, onSave: _saveCustomPlan,
              onPlanTypeChange: (t) => setState(() => _selectedPlanType = t),
            ),

          // Delete Modal — [F16][F17]
          if (_deleteModalOpen)
            _DeleteConfirmModal(
              animation: _deleteAnimCtrl, planName: _deleteTargetName,
              onCancel: _cancelDelete, onConfirm: _confirmDelete,
            ),

          // Chat Drawer — [F7][F18][F19][F20][F21]
          if (_chatOpen)
            _ChatDrawer(
              animation: _chatAnimCtrl, messages: _messages,
              inputCtrl: _chatInputCtrl, scrollCtrl: _messagesScrollCtrl,
              onClose: _closeChat, onSend: _sendChatMessage,
              onSavePlan: (plan) {
                setState(() => _plans.insert(0, plan));
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _messages.add(_ChatMsg(isBot: true, text: '✅ "${plan.name}" has been saved to your Meal Plans!')));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F2] Background Orbs — drift @keyframes
//   CSS: animation: drift 9s ease-in-out infinite alternate
//   orb2 delay 2.5s, orb3 delay 5s
// ─────────────────────────────────────────────────────────────────────────────
class _BgOrbs extends StatefulWidget {
  const _BgOrbs();
  @override
  State<_BgOrbs> createState() => _BgOrbsState();
}

class _BgOrbsState extends State<_BgOrbs> with TickerProviderStateMixin {
  late AnimationController _ctrl1;
  late AnimationController _ctrl2;
  late AnimationController _ctrl3;

  @override
  void initState() {
    super.initState();
    _ctrl1 = _makeCtrl(0);
    _ctrl2 = _makeCtrl(2500);
    _ctrl3 = _makeCtrl(5000);
  }

  AnimationController _makeCtrl(int delayMs) {
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000));
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _loopAlt(c);
    });
    return c;
  }

  void _loopAlt(AnimationController c) {
    c.forward().then((_) { if (mounted) c.reverse().then((_) { if (mounted) _loopAlt(c); }); });
  }

  @override
  void dispose() { _ctrl1.dispose(); _ctrl2.dispose(); _ctrl3.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            _AnimatedOrb(controller: _ctrl1, left: -80, top: -100, width: 320, height: 320, colors: [accent.secondary, accent.primary]),
            _AnimatedOrb(controller: _ctrl2, right: -60, bottom: -60, width: 260, height: 260, colors: [accent.tertiary, accent.primary]),
            _AnimatedOrb(controller: _ctrl3, top: 300, left: 200, width: 200, height: 200, colors: [accent.tertiary, accent.secondary]),
          ],
        ),
      ),
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  final AnimationController controller;
  final double width, height;
  final List<Color> colors;
  final double? left, top, right, bottom;

  const _AnimatedOrb({required this.controller, required this.width, required this.height,
    required this.colors, this.left, this.top, this.right, this.bottom});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = CurvedAnimation(parent: controller, curve: Curves.easeInOut).value;
        return Positioned(
          left:   left   != null ? left!   + t * 18 : null,
          right:  right  != null ? right!  - t * 18 : null,
          top:    top    != null ? top!    + t * 14 : null,
          bottom: bottom != null ? bottom! - t * 14 : null,
          child: Transform.scale(
            scale: 1.0 + t * 0.08,
            child: child,
          ),
        );
      },
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            colors[0].withValues(alpha: 0.25),
            colors[1].withValues(alpha: 0.0),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F1] Live clock · [F3] Back btn hover lift · [F6] Add btn hover lift
// ─────────────────────────────────────────────────────────────────────────────
class _TopSection extends StatefulWidget {
  final String dateStr, liveTimeStr;
  final VoidCallback onAddTap;
  const _TopSection({required this.dateStr, required this.liveTimeStr, required this.onAddTap});
  @override
  State<_TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<_TopSection> {
  bool _addBtnHovered  = false; // [F6]
  bool _backBtnHovered = false; // [F3]

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            const SizedBox(height: 6),
            Text('My Meal Plans',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.6)),
            const SizedBox(height: 4),
            Text('Save and organize your personalized meal plans',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: t.mutedText)),
            const SizedBox(height: 14),

            // [F6] Add button hover: translateY(-1px) + accent3 shadow
            MouseRegion(
              onEnter: (_) => setState(() => _addBtnHovered = true),
              onExit:  (_) => setState(() => _addBtnHovered = false),
              child: GestureDetector(
                onTap: widget.onAddTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  transform: Matrix4.translationValues(0, _addBtnHovered ? -1.0 : 0.0, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [accent.primary, accent.tertiary]),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(
                      color: _addBtnHovered ? accent.tertiary.withValues(alpha: 0.40) : accent.primary.withValues(alpha: 0.35),
                      blurRadius: _addBtnHovered ? 20 : 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CustomPaint(painter: _PlusCirclePainter(t.tileText))),
                      const SizedBox(width: 7),
                      Text('Add Custom Meal',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.tileText)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // [F1] Date pill with live clock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [accent.primary, accent.tertiary]),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: t.textPrimary.withValues(alpha: 0.85)),
                  const SizedBox(width: 5),
                  Text(
                    widget.liveTimeStr.isNotEmpty
                        ? '${widget.dateStr}  ·  ${widget.liveTimeStr}'
                        : widget.dateStr,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: t.tileText),
                  ),
                ],
              ),
            ),
          ],
        ),

        // [F3] Back button hover: translateY(-1px) + shadow-md
        Positioned(
          top: 0, left: 0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _backBtnHovered = true),
            onExit:  (_) => setState(() => _backBtnHovered = false),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(0, _backBtnHovered ? -1.0 : 0.0, 0),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: t.panel,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.cardBorder, width: 1),
                  boxShadow: [BoxShadow(
                    color: t.backgroundPrimary.withValues(alpha: _backBtnHovered ? 0.36 : 0.28),
                    blurRadius: _backBtnHovered ? 16 : 4,
                    offset: Offset(0, _backBtnHovered ? 4 : 1),
                  )],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: t.textPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F8] View Tabs — hover opacity 0.85
// ─────────────────────────────────────────────────────────────────────────────
class _ViewTabs extends StatelessWidget {
  final String currentView;
  final Function(String) onTabChanged;
  const _ViewTabs({required this.currentView, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6, runSpacing: 6,
      children: [
        _ViewTabBtn(id:'all',     label:'All Plans', icon:Icons.grid_view_rounded,          currentView:currentView, onTap:onTabChanged),
        _ViewTabBtn(id:'daily',   label:'Daily',     icon:Icons.wb_sunny_outlined,          currentView:currentView, onTap:onTabChanged),
        _ViewTabBtn(id:'weekly',  label:'Weekly',    icon:Icons.calendar_view_week_rounded, currentView:currentView, onTap:onTabChanged),
        _ViewTabBtn(id:'monthly', label:'Monthly',   icon:Icons.calendar_month_outlined,    currentView:currentView, onTap:onTabChanged),
      ],
    );
  }
}

class _ViewTabBtn extends StatefulWidget {
  final String id, label, currentView;
  final IconData icon;
  final Function(String) onTap;
  const _ViewTabBtn({required this.id, required this.label, required this.icon,
    required this.currentView, required this.onTap});
  @override
  State<_ViewTabBtn> createState() => _ViewTabBtnState();
}

class _ViewTabBtnState extends State<_ViewTabBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final active = widget.currentView == widget.id;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.id),
        child: AnimatedOpacity(
          // [F8] inactive tab fades to 85% on hover
          opacity: (!active && _hovered) ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: active ? LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[t.accent.primary, t.accent.tertiary]) : null,
              color: active ? null : t.panel,
              borderRadius: BorderRadius.circular(100),
              border: active ? null : Border.all(color: t.cardBorder, width: 1.5),
              boxShadow: active
                  ? [BoxShadow(color: t.accent.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))]
                  : [BoxShadow(color: t.backgroundPrimary.withValues(alpha: 0.28), blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: active ? t.tileText : t.mutedText),
                const SizedBox(width: 5),
                Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? t.tileText : t.mutedText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String icon, message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 38)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.mutedText, height: 1.6)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F9]  Card shadow hover
// [F10] Edit button (was missing) + gradient hover
// [F11] Delete button red hover + scale(1.08)
// [F12] Pop-in animation on card appear
// ─────────────────────────────────────────────────────────────────────────────
class _VisualPlanCard extends StatefulWidget {
  final MealPlan plan;
  final int colorIndex;
  final bool isExpanded;
  final VoidCallback onToggle, onDelete;
  const _VisualPlanCard({required this.plan, required this.colorIndex,
    required this.isExpanded, required this.onToggle, required this.onDelete});
  @override
  State<_VisualPlanCard> createState() => _VisualPlanCardState();
}

class _VisualPlanCardState extends State<_VisualPlanCard> with SingleTickerProviderStateMixin {
  bool _cardHovered   = false;
  bool _delHovered    = false;
  bool _editHovered   = false;

  // [F12] pop-in: opacity 0→1, scale 0.96→1 in 300ms
  late AnimationController _popCtrl;
  late Animation<double> _popAnim;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _popAnim = CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut);
    _popCtrl.forward();
  }

  @override
  void dispose() { _popCtrl.dispose(); super.dispose(); }

  Color _barCol1(AppThemeTokens t) => widget.plan.planType == 'weekly'
      ? t.accent.tertiary.withValues(alpha: 0.55)
      : widget.plan.planType == 'monthly'
          ? t.accent.primary.withValues(alpha: 0.55)
          : t.accent.secondary.withValues(alpha: 0.55);
  Color _barCol2(AppThemeTokens t) => widget.plan.planType == 'weekly'
      ? t.accent.tertiary.withValues(alpha: 0.45)
      : widget.plan.planType == 'monthly'
          ? t.accent.secondary.withValues(alpha: 0.45)
          : t.accent.tertiary.withValues(alpha: 0.45);
  Color _accentC(AppThemeTokens t) => widget.plan.planType == 'weekly'
      ? t.accent.tertiary
      : widget.plan.planType == 'monthly'
          ? t.accent.primary
          : t.accent.secondary;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accentC = _accentC(t);
    return AnimatedBuilder(
      animation: _popAnim,
      builder: (_, child) => Opacity(
        opacity: _popAnim.value,
        child: Transform.scale(scale: 0.96 + 0.04 * _popAnim.value, child: child),
      ),
      child: MouseRegion(
        // [F9] card shadow hover
        onEnter: (_) => setState(() => _cardHovered = true),
        onExit:  (_) => setState(() => _cardHovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: t.backgroundSecondary,
              boxShadow: [BoxShadow(
                color: t.backgroundPrimary.withValues(alpha: _cardHovered ? 0.55 : 0.45),
                blurRadius: _cardHovered ? 24 : 16,
                offset: Offset(0, _cardHovered ? 6 : 3),
              )],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[_barCol1(t), _barCol2(t)]),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(widget.plan.name.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: 0.9)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.textPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: accentC.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Text(widget.plan.planType.toUpperCase(),
                            style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: accentC, letterSpacing: 0.4)),
                      ),
                      const SizedBox(width: 6),

                      // [F10] Edit button — was missing; gradient bg + scale(1.08) on hover
                      MouseRegion(
                        onEnter: (_) => setState(() => _editHovered = true),
                        onExit:  (_) => setState(() => _editHovered = false),
                        child: GestureDetector(
                          onTap: () {}, // edit placeholder
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            transform: Matrix4.diagonal3Values(_editHovered ? 1.08 : 1.0, _editHovered ? 1.08 : 1.0, 1.0),
                            transformAlignment: Alignment.center,
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              gradient: _editHovered
                                  ? LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[t.accent.primary, t.accent.tertiary])
                                  : null,
                              color: _editHovered ? null : t.backgroundSecondary,
                              borderRadius: BorderRadius.circular(7),
                              border: _editHovered ? null : Border.all(color: t.cardBorder, width: 1),
                            ),
                            child: Icon(Icons.edit_outlined, size: 12, color: _editHovered ? t.tileText : t.mutedText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // [F11] Delete button: red bg tint + red icon + scale(1.08) on hover
                      MouseRegion(
                        onEnter: (_) => setState(() => _delHovered = true),
                        onExit:  (_) => setState(() => _delHovered = false),
                        child: GestureDetector(
                          onTap: widget.onDelete,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            transform: Matrix4.diagonal3Values(_delHovered ? 1.08 : 1.0, _delHovered ? 1.08 : 1.0, 1.0),
                            transformAlignment: Alignment.center,
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: _delHovered ? t.accent.tertiary.withValues(alpha: 0.15) : t.backgroundSecondary,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                  color: _delHovered ? t.accent.tertiary.withValues(alpha: 0.35) : t.cardBorder, width: 1),
                            ),
                            child: Icon(Icons.delete_outline_rounded, size: 12,
                                color: _delHovered ? t.accent.tertiary : t.mutedText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Chevron rotate on expand
                      AnimatedRotation(
                        turns: widget.isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 320),
                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: accentC),
                      ),
                    ],
                  ),
                ),

                // Preview pills (collapsed)
                if (!widget.isExpanded)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    color: accentC.withValues(alpha: 0.12),
                    child: Wrap(
                      spacing: 5, runSpacing: 4,
                      children: widget.plan.meals.map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.textPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: accentC.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Text('${m.icon} ${m.type}',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accentC)),
                      )).toList(),
                    ),
                  ),

                // Body (expanded)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _ExpandedBody(plan: widget.plan, accentColor: accentC),
                  crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 320),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded Body
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandedBody extends StatelessWidget {
  final MealPlan plan;
  final Color accentColor;
  const _ExpandedBody({required this.plan, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final guideItems = [
      {'num':'3','label':'MEALS PER DAY','sub':'structured'},
      {'num':'${plan.totalCal}','label':'CALORIES TOTAL','sub':'estimated'},
      {'num':'4','label':'FOOD GROUPS','sub':'balanced'},
    ];
    final breakfasts = plan.meals.where((m) => m.cls=='breakfast').toList();
    final lunches    = plan.meals.where((m) => m.cls=='lunch').toList();
    final dinners    = plan.meals.where((m) => m.cls=='dinner').toList();
    final snacks     = plan.meals.where((m) => m.cls=='snack').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          color: accentColor.withValues(alpha: 0.14),
          child: Row(
            children: [
              for (int i = 0; i < guideItems.length; i++) ...[
                if (i > 0) Container(width: 1, height: 20, color: accentColor.withValues(alpha: 0.25)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 4),
                    child: Row(
                      children: [
                        Text(guideItems[i]['num']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                            color: accentColor, fontStyle: FontStyle.italic)),
                        const SizedBox(width: 4),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(guideItems[i]['label']!, style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: 0.3)),
                          Text(guideItems[i]['sub']!,   style: TextStyle(fontSize: 6,   fontWeight: FontWeight.w500, color: t.mutedText)),
                        ])),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (breakfasts.isNotEmpty) _MealBlock(meals: breakfasts, cls:'breakfast', label:'BREAKFAST', isLunch: false),
        if (lunches.isNotEmpty)    _MealBlock(meals: lunches,    cls:'lunch',     label:'LUNCH',     isLunch: true),
        if (dinners.isNotEmpty)    _MealBlock(meals: dinners,    cls:'dinner',    label:'DINNER',    isLunch: false),
        if (snacks.isNotEmpty)     _MealBlock(meals: snacks,     cls:'snack',     label:'SNACK',     isLunch: false),
        if (plan.totalCal > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight,
                  colors:[accentColor.withValues(alpha: 0.35), accentColor.withValues(alpha: 0.25)]),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔥 Total Calories', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: 0.4)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.40), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Text('${plan.totalCal} cal', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: t.tileText)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MealBlock extends StatelessWidget {
  final List<MealItem> meals;
  final String cls, label;
  final bool isLunch;
  const _MealBlock({required this.meals, required this.cls, required this.label, required this.isLunch});

  Color _bgC(AppThemeTokens t) => switch(cls) {
    'breakfast' => t.accent.secondary.withValues(alpha: 0.10),
    'lunch' => t.accent.tertiary.withValues(alpha: 0.10),
    'dinner' => t.accent.secondary.withValues(alpha: 0.12),
    'snack' => t.accent.tertiary.withValues(alpha: 0.08),
    _ => t.accent.primary.withValues(alpha: 0.08),
  };
  Color _fgC(AppThemeTokens t) => switch(cls) {
    'breakfast' => t.accent.secondary,
    'lunch' => t.accent.tertiary,
    'dinner' => t.accent.primary,
    'snack' => t.accent.tertiary,
    _ => t.accent.primary,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final bgC = _bgC(t);
    final fgC = _fgC(t);
    return Container(
      color: bgC,
      constraints: const BoxConstraints(minHeight: 90),
      child: Stack(
        children: [
          Positioned(
            right: isLunch ? null : -8, left: isLunch ? -8 : null,
            top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fgC.withValues(alpha: 0.15),
                  border: Border.all(color: t.phoneShell, width: 3),
                  boxShadow: [BoxShadow(color: t.backgroundPrimary.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(meals.first.icon, style: const TextStyle(fontSize: 32))),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: isLunch ? 100 : 14, right: isLunch ? 14 : 100, top: 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: fgC, letterSpacing: 2)),
                const SizedBox(height: 6),
                ...meals.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(m.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.textPrimary)),
                      if (m.desc.isNotEmpty) ...[
                        Text(' · ', style: TextStyle(fontSize: 10.5, color: t.textPrimary)),
                        Text(m.desc, style: TextStyle(fontSize: 10.5, color: t.mutedText)),
                      ],
                      if (m.cal > 0)
                        Text(' ${m.cal} cal', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: t.accent.secondary)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F4] Chat FAB — scale(1.04) + accent3 shadow on hover
// ─────────────────────────────────────────────────────────────────────────────
class _ChatFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ChatFab({required this.onTap});
  @override
  State<_ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<_ChatFab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // [F4] scale(1.04) on hover
          transform: Matrix4.diagonal3Values(_hovered ? 1.04 : 1.0, _hovered ? 1.04 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[accent.primary, accent.tertiary]),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [BoxShadow(
              color: _hovered ? accent.tertiary.withValues(alpha: 0.45) : accent.primary.withValues(alpha: 0.45),
              blurRadius: _hovered ? 28 : 24, offset: const Offset(0, 8),
            )],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: t.tileText),
              const SizedBox(width: 7),
              Text('Ask Ahvi AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.tileText)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Meal Modal — [F13] submit hover · [F14] X btn hover · [F15] type-sel hover
// ─────────────────────────────────────────────────────────────────────────────
class _AddMealModal extends StatelessWidget {
  final AnimationController animation;
  final TextEditingController planNameCtrl, planDescCtrl;
  final String selectedPlanType;
  final bool planNameError;
  final TextEditingController bNameCtrl, bDescCtrl, bCalCtrl;
  final TextEditingController lNameCtrl, lDescCtrl, lCalCtrl;
  final TextEditingController dNameCtrl, dDescCtrl, dCalCtrl;
  final TextEditingController sNameCtrl, sDescCtrl, sCalCtrl;
  final VoidCallback onClose, onSave;
  final Function(String) onPlanTypeChange;

  const _AddMealModal({
    required this.animation, required this.planNameCtrl, required this.planDescCtrl,
    required this.selectedPlanType, required this.planNameError,
    required this.bNameCtrl, required this.bDescCtrl, required this.bCalCtrl,
    required this.lNameCtrl, required this.lDescCtrl, required this.lCalCtrl,
    required this.dNameCtrl, required this.dDescCtrl, required this.dCalCtrl,
    required this.sNameCtrl, required this.sDescCtrl, required this.sCalCtrl,
    required this.onClose, required this.onSave, required this.onPlanTypeChange,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Positioned.fill(
        child: Center(
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(scale: 0.95 + 0.05 * animation.value, child: child),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: t.phoneShell, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.cardBorder, width: 1),
            boxShadow: [BoxShadow(color: t.backgroundPrimary.withValues(alpha: 0.48), blurRadius: 40, offset: const Offset(0, 12))],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.cardBorder, width: 1))),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 16, color: accent.secondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Add Custom Meal Plan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.textPrimary))),
                    // [F14] Close btn with red-tint hover
                    _HoverCloseBtn(onTap: onClose),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldGroup(label: 'Plan Name',
                          child: _Field(ctrl: planNameCtrl, hint: 'e.g. Mediterranean Plan', hasError: planNameError)),
                      const SizedBox(height: 14),
                      _FieldGroup(label: 'Description',
                          child: _Field(ctrl: planDescCtrl, hint: 'e.g. Heart-healthy meals')),
                      const SizedBox(height: 14),
                      // [F15] Plan type selector with hover gradient
                      _FieldGroup(label: 'Plan Type', child: Row(children: [
                        _TypeSelBtn(id:'daily',   label:'Daily',   icon:Icons.wb_sunny_outlined,          selected:selectedPlanType, onTap:onPlanTypeChange),
                        const SizedBox(width: 8),
                        _TypeSelBtn(id:'weekly',  label:'Weekly',  icon:Icons.calendar_view_week_rounded, selected:selectedPlanType, onTap:onPlanTypeChange),
                        const SizedBox(width: 8),
                        _TypeSelBtn(id:'monthly', label:'Monthly', icon:Icons.calendar_month_outlined,    selected:selectedPlanType, onTap:onPlanTypeChange),
                      ])),
                      const SizedBox(height: 14),
                      _FieldGroup(label: 'Meals', child: Column(children: [
                        _MealInputRow(iconColor:accent.secondary, mealLabel:'Breakfast',         nameCtrl:bNameCtrl, descCtrl:bDescCtrl, calCtrl:bCalCtrl),
                        const SizedBox(height: 10),
                        _MealInputRow(iconColor:accent.tertiary, mealLabel:'Lunch',             nameCtrl:lNameCtrl, descCtrl:lDescCtrl, calCtrl:lCalCtrl),
                        const SizedBox(height: 10),
                        _MealInputRow(iconColor:accent.primary,                mealLabel:'Dinner',            nameCtrl:dNameCtrl, descCtrl:dDescCtrl, calCtrl:dCalCtrl),
                        const SizedBox(height: 10),
                        _MealInputRow(iconColor:accent.tertiary, mealLabel:'Snack (optional)',  nameCtrl:sNameCtrl, descCtrl:sDescCtrl, calCtrl:sCalCtrl),
                      ])),
                      const SizedBox(height: 14),
                      // [F13] Submit button with hover opacity 0.90 + translateY(-1px)
                      _SubmitBtn(onTap: onSave, label: 'Save Meal Plan'),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// [F14] Hover close button — red tint background + red icon on hover
//   .xbtn:hover { background: rgba(255,80,80,.15); color: #ff6060 }
// ─────────────────────────────────────────────────────────────────────────────
class _HoverCloseBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverCloseBtn({required this.onTap});
  @override
  State<_HoverCloseBtn> createState() => _HoverCloseBtnState();
}

class _HoverCloseBtnState extends State<_HoverCloseBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: _hovered ? t.accent.tertiary.withValues(alpha: 0.15) : t.backgroundSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: t.cardBorder, width: 1),
          ),
          child: Icon(Icons.close_rounded, size: 14,
              color: _hovered ? t.accent.tertiary : t.mutedText),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F13] Submit button — opacity 0.90 + translateY(-1px) on hover
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitBtn extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _SubmitBtn({required this.onTap, required this.label});
  @override
  State<_SubmitBtn> createState() => _SubmitBtnState();
}

class _SubmitBtnState extends State<_SubmitBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _hovered ? 0.90 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _hovered ? -1.0 : 0.0, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[accent.primary, accent.tertiary]),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: t.tileText),
                const SizedBox(width: 8),
                Text(widget.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.tileText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field helpers
// ─────────────────────────────────────────────────────────────────────────────
class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldGroup({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.mutedText, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      child,
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool hasError;
  const _Field({required this.ctrl, required this.hint, this.hasError = false});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return TextField(
      controller: ctrl,
      maxLines: 1,
      style: TextStyle(fontSize: 13.5, color: t.textPrimary),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: t.mutedText, fontSize: 13.5),
        filled: true, fillColor: t.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? t.accent.tertiary : t.cardBorder, width: 1.5)),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? t.accent.tertiary : t.cardBorder, width: 1.5)),
        focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.accent.primary, width: 1.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F15] Type selector button — accent border + gradient hint on hover
// ─────────────────────────────────────────────────────────────────────────────
class _TypeSelBtn extends StatefulWidget {
  final String id, label, selected;
  final IconData icon;
  final Function(String) onTap;
  const _TypeSelBtn({required this.id, required this.label, required this.icon,
    required this.selected, required this.onTap});
  @override
  State<_TypeSelBtn> createState() => _TypeSelBtnState();
}

class _TypeSelBtnState extends State<_TypeSelBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final active = widget.selected == widget.id;
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[t.accent.primary, t.accent.tertiary])
                  : _hovered
                  ? LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[t.accent.primary.withValues(alpha: 0.12), t.accent.tertiary.withValues(alpha: 0.10)])
                  : null,
              color: (active || _hovered) ? null : t.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? t.backgroundPrimary.withValues(alpha: 0.0) : (_hovered ? t.accent.primary : t.cardBorder), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(widget.icon, size: 22, color: active ? t.tileText : (_hovered ? t.accent.primary : t.mutedText)),
                const SizedBox(height: 4),
                Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: active ? t.tileText : (_hovered ? t.accent.primary : t.mutedText))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealInputRow extends StatelessWidget {
  final Color iconColor;
  final String mealLabel;
  final TextEditingController nameCtrl, descCtrl, calCtrl;
  const _MealInputRow({required this.iconColor, required this.mealLabel,
    required this.nameCtrl, required this.descCtrl, required this.calCtrl});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: t.backgroundSecondary, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.restaurant_menu_rounded, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(mealLabel, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.textPrimary)),
        ]),
        const SizedBox(height: 10),
        TextField(controller: nameCtrl, style: TextStyle(fontSize: 13, color: t.textPrimary), decoration: _deco(t, 'Meal name')),
        const SizedBox(height: 7),
        Row(children: [
          Expanded(child: TextField(controller: descCtrl, style: TextStyle(fontSize: 13, color: t.textPrimary), decoration: _deco(t, 'Short description'))),
          const SizedBox(width: 7),
          Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, style: TextStyle(fontSize: 13, color: t.textPrimary), decoration: _deco(t, 'Calories'))),
        ]),
      ]),
    );
  }

  InputDecoration _deco(AppThemeTokens t, String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: t.mutedText, fontSize: 13),
    filled: true, fillColor: t.backgroundSecondary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.cardBorder, width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.cardBorder, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.accent.primary, width: 1.5)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Confirm Modal — [F16] cancel hover · [F17] confirm hover opacity
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteConfirmModal extends StatelessWidget {
  final AnimationController animation;
  final String planName;
  final VoidCallback onCancel, onConfirm;
  const _DeleteConfirmModal({required this.animation, required this.planName,
    required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Positioned.fill(
        child: Center(
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(scale: 0.94 + 0.06 * animation.value, child: child),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: t.phoneShell, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.cardBorder, width: 1),
            boxShadow: [BoxShadow(color: t.backgroundPrimary.withValues(alpha: 0.48), blurRadius: 40, offset: const Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: accent.tertiary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.delete_outline_rounded, size: 26, color: accent.tertiary),
              ),
              const SizedBox(height: 14),
              Text('Delete Meal Plan?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: t.textPrimary)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Are you sure you want to delete\n',
                  style: TextStyle(fontSize: 13, color: t.mutedText, height: 1.55),
                  children: [
                    WidgetSpan(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(6)),
                      child: Text(planName, style: TextStyle(fontWeight: FontWeight.w700, color: t.textPrimary, fontSize: 13)),
                    )),
                    const TextSpan(text: '?\nThis action cannot be undone.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  // [F16] Cancel hover: background panel-2
                  Expanded(child: _HoverCancelBtn(onTap: onCancel)),
                  const SizedBox(width: 10),
                  // [F17] Delete hover: opacity 0.88
                  Expanded(child: _HoverDeleteBtn(onTap: onConfirm)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F16] Cancel button — hover: background panel-2
// ─────────────────────────────────────────────────────────────────────────────
class _HoverCancelBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverCancelBtn({required this.onTap});
  @override
  State<_HoverCancelBtn> createState() => _HoverCancelBtnState();
}

class _HoverCancelBtnState extends State<_HoverCancelBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // [F16] hover → panel-2 = rgba(255,255,255,.12)
            color: _hovered ? t.panelBorder : t.panel,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: t.cardBorder, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close_rounded, size: 14, color: t.mutedText),
              SizedBox(width: 4),
              Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F17] Delete confirm button — hover: opacity 0.88
// ─────────────────────────────────────────────────────────────────────────────
class _HoverDeleteBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverDeleteBtn({required this.onTap});
  @override
  State<_HoverDeleteBtn> createState() => _HoverDeleteBtnState();
}

class _HoverDeleteBtnState extends State<_HoverDeleteBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.88 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.tertiary,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(color: accent.tertiary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline_rounded, size: 14, color: t.textPrimary),
                SizedBox(width: 4),
                Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat
// ─────────────────────────────────────────────────────────────────────────────
class _ChatMsg {
  final bool isBot, isTyping;
  final String text;
  final MealPlan? suggestedPlan;
  _ChatMsg({required this.isBot, required this.text, this.suggestedPlan, this.isTyping = false});
}

class _ChatDrawer extends StatefulWidget {
  final AnimationController animation;
  final List<_ChatMsg> messages;
  final TextEditingController inputCtrl;
  final ScrollController scrollCtrl;
  final VoidCallback onClose;
  final Function(String) onSend;
  final Function(MealPlan) onSavePlan;

  const _ChatDrawer({required this.animation, required this.messages, required this.inputCtrl,
    required this.scrollCtrl, required this.onClose, required this.onSend, required this.onSavePlan});
  @override
  State<_ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<_ChatDrawer> {
  final Set<int> _savedIndices = {};

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (_, child) => Positioned(
        left: 0, right: 0, bottom: 0,
        child: Transform.translate(offset: Offset(0, (1 - widget.animation.value) * 600), child: child),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.76),
        decoration: BoxDecoration(
          color: t.phoneShell,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: t.backgroundPrimary.withValues(alpha: 0.45), blurRadius: 40, offset: Offset(0, -8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.cardBorder, width: 1))),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: accent.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.psychology_rounded, size: 20, color: accent.secondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ahvi AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.textPrimary)),
                    Text("I'll suggest daily, weekly or monthly plans", style: TextStyle(fontSize: 11.5, color: t.mutedText)),
                  ])),
                  // [F14] Red-tint hover on close
                  _HoverCloseBtn(onTap: widget.onClose),
                ],
              ),
            ),

            // Messages
            Flexible(
              child: ListView.builder(
                controller: widget.scrollCtrl,
                padding: const EdgeInsets.all(14),
                itemCount: widget.messages.length,
                itemBuilder: (context, i) {
                  final msg = widget.messages[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
                        child: Column(
                          crossAxisAlignment: msg.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            // [F12] Pop-in on each message bubble
                            _PopInWidget(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: msg.isBot ? t.panel : t.accent.primary,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                                    bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                                  ),
                                  border: msg.isBot ? Border.all(color: t.cardBorder, width: 1) : null,
                                  boxShadow: msg.isBot ? null : [BoxShadow(color: t.accent.primary.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 4))],
                                ),
                                // [F7] Typing indicator or text
                                child: msg.isTyping
                                    ? const _TypingDots()
                                    : Text(msg.text, style: TextStyle(fontSize: 13, height: 1.55, color: msg.isBot ? t.textPrimary : t.tileText)),
                              ),
                            ),
                            if (msg.suggestedPlan != null)
                            // [F21] Save plan card with hover animation
                              _SuggestedPlanCard(
                                plan: msg.suggestedPlan!,
                                isSaved: _savedIndices.contains(i),
                                onSave: () {
                                  setState(() => _savedIndices.add(i));
                                  widget.onSavePlan(msg.suggestedPlan!);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick reply chips — [F20] hover opacity 0.82
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: t.cardBorder, width: 1))),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  _QuickBtn(label:'🫒 Mediterranean',         onTap:() => widget.onSend('Mediterranean daily plan')),
                  _QuickBtn(label:'💪 High Protein',          onTap:() => widget.onSend('High protein daily plan')),
                  _QuickBtn(label:'🌱 Vegan',                 onTap:() => widget.onSend('Vegan daily plan')),
                  _QuickBtn(label:'🥑 Low Carb Weekly',       onTap:() => widget.onSend('Low carb weekly plan')),
                  _QuickBtn(label:'⚖️ Balanced Weekly',       onTap:() => widget.onSend('Balanced weekly plan')),
                  _QuickBtn(label:'📅 Mediterranean Monthly', onTap:() => widget.onSend('Mediterranean monthly plan')),
                  _QuickBtn(label:'🏋️ Protein Monthly',       onTap:() => widget.onSend('High protein monthly plan')),
                ],
              ),
            ),

            // Input row
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: t.cardBorder, width: 1))),
              child: Row(
                children: [
                  // [F18] Mic button hover accent
                  const _MicBtn(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.inputCtrl,
                      style: TextStyle(fontSize: 13.5, color: t.textPrimary),
                      onSubmitted: widget.onSend,
                      decoration: InputDecoration(
                        hintText: 'Ask for a meal plan…',
                        hintStyle: TextStyle(color: t.mutedText, fontSize: 13.5),
                        filled: true, fillColor: t.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: t.cardBorder, width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: t.cardBorder, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: t.accent.primary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // [F19] Send button hover opacity 0.88
                  _SendBtn(onTap: () => widget.onSend(widget.inputCtrl.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F7] Typing dots — 3 staggered blink animations
//   .dot { animation: blink 1.2s infinite } delays: 0, 0.2s, 0.4s
//   opacity: 0.3 → 1 → 0.3
// ─────────────────────────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)));
    _anims = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut)).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _loop(_ctrls[i]);
      });
    }
  }

  void _loop(AnimationController c) {
    c.forward().then((_) { if (mounted) c.reverse().then((_) { if (mounted) _loop(c); }); });
  }

  @override
  void dispose() { for (final c in _ctrls) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedBuilder(
          animation: _anims[i],
          builder: (_, _) => Opacity(
            opacity: 0.3 + _anims[i].value * 0.7,
            child: Container(width: 6, height: 6,
                decoration: BoxDecoration(color: t.mutedText, shape: BoxShape.circle)),
          ),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F12] Pop-in wrapper — opacity 0→1, scale 0.96→1 in 250ms
// ─────────────────────────────────────────────────────────────────────────────
class _PopInWidget extends StatefulWidget {
  final Widget child;
  const _PopInWidget({required this.child});
  @override
  State<_PopInWidget> createState() => _PopInWidgetState();
}

class _PopInWidgetState extends State<_PopInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: _anim.value,
        child: Transform.scale(scale: 0.96 + 0.04 * _anim.value, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F18] Mic button — accent border + icon color on hover
//   .meal-mic-btn:hover { border-color: accent; color: accent }
// ─────────────────────────────────────────────────────────────────────────────
class _MicBtn extends StatefulWidget {
  const _MicBtn();
  @override
  State<_MicBtn> createState() => _MicBtnState();
}

class _MicBtnState extends State<_MicBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: t.backgroundSecondary,
          shape: BoxShape.circle,
          border: Border.all(color: _hovered ? accent.primary : t.cardBorder, width: 1.5),
        ),
        child: Icon(Icons.mic_none_rounded, size: 16, color: _hovered ? accent.primary : t.mutedText),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F19] Send button — hover opacity 0.88
// ─────────────────────────────────────────────────────────────────────────────
class _SendBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _SendBtn({required this.onTap});
  @override
  State<_SendBtn> createState() => _SendBtnState();
}

class _SendBtnState extends State<_SendBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.88 : 1.0,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[accent.primary, accent.tertiary]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: Icon(Icons.send_rounded, size: 16, color: t.tileText),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F20] Quick reply chip — hover opacity 0.82
//   .qr:hover { opacity: 0.82 }
// ─────────────────────────────────────────────────────────────────────────────
class _QuickBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});
  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.82 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[accent.primary, accent.tertiary]),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.tileText)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [F21] Suggested plan card — save btn hover: opacity 0.88 + translateY(-1px)
//   .save-plan-btn:hover { opacity: 0.88; transform: translateY(-1px) }
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestedPlanCard extends StatefulWidget {
  final MealPlan plan;
  final bool isSaved;
  final VoidCallback onSave;
  const _SuggestedPlanCard({required this.plan, required this.isSaved, required this.onSave});
  @override
  State<_SuggestedPlanCard> createState() => _SuggestedPlanCardState();
}

class _SuggestedPlanCardState extends State<_SuggestedPlanCard> {
  bool _saveHovered = false;

  Color _mealTypeColor(AppThemeTokens t, String cls) => switch(cls) {
    'breakfast' => t.accent.secondary,
    'lunch' => t.accent.tertiary,
    'dinner' => t.accent.primary,
    'snack' => t.accent.tertiary,
    _ => t.accent.primary,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: t.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: t.backgroundPrimary.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight,
                  colors:[accent.primary.withValues(alpha: 0.35), accent.secondary.withValues(alpha: 0.28)]),
            ),
            child: Row(
              children: [
                Expanded(child: Text(widget.plan.name,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.2))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(100)),
                  child: Text(widget.plan.planType.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: t.mutedText, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(13, 6, 13, 2), color: t.backgroundSecondary,
            child: Text(widget.plan.desc, style: TextStyle(fontSize: 11, color: t.mutedText, fontStyle: FontStyle.italic)),
          ),
          ...widget.plan.meals.map((m) => Container(
            padding: const EdgeInsets.fromLTRB(13, 7, 13, 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.cardBorder, width: 1)), color: t.backgroundSecondary),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: _mealTypeColor(t, m.cls))),
              const SizedBox(height: 2),
              Text(m.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textPrimary, height: 1.35)),
              if (m.desc.isNotEmpty) Text(m.desc, style: TextStyle(fontSize: 10.5, color: t.mutedText)),
            ]),
          )),
          // Calories footer
          Container(
            padding: const EdgeInsets.fromLTRB(13, 7, 13, 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight,
                  colors:[accent.primary.withValues(alpha: 0.25), accent.secondary.withValues(alpha: 0.18)]),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔥 Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.mutedText)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: accent.secondary, borderRadius: BorderRadius.circular(100)),
                  child: Text('${widget.plan.totalCal} cal',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: t.tileText)),
                ),
              ],
            ),
          ),
          // [F21] Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
            child: MouseRegion(
              onEnter: (_) => setState(() => _saveHovered = true),
              onExit:  (_) => setState(() => _saveHovered = false),
              child: GestureDetector(
                onTap: widget.isSaved ? null : widget.onSave,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: (!widget.isSaved && _saveHovered) ? 0.88 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    // [F21] translateY(-1px) on hover
                    transform: Matrix4.translationValues(0, (!widget.isSaved && _saveHovered) ? -1.0 : 0.0, 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: widget.isSaved ? null
                          : LinearGradient(begin:Alignment.topLeft, end:Alignment.bottomRight, colors:[accent.primary, accent.tertiary]),
                      color: widget.isSaved ? t.backgroundSecondary : null,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: widget.isSaved ? null
                          : [BoxShadow(color: accent.primary.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                            size: 14, color: widget.isSaved ? t.mutedText : t.tileText),
                        const SizedBox(width: 7),
                        Text(widget.isSaved ? 'Saved' : 'Save to My Plans',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                                color: widget.isSaved ? t.mutedText : t.tileText)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────
class _PlusCirclePainter extends CustomPainter {
  final Color color;
  const _PlusCirclePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ..strokeWidth = 2
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2 - 1, paint);
    canvas.drawLine(Offset(center.dx - 4, center.dy), Offset(center.dx + 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 4), Offset(center.dx, center.dy + 4), paint);
  }
  @override
  bool shouldRepaint(covariant _PlusCirclePainter old) => old.color != color;
}
