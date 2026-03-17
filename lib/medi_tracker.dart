import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:myapp/theme/theme_tokens.dart';

class MediTrackScreen extends StatefulWidget {
  const MediTrackScreen({super.key});

  @override
  State<MediTrackScreen> createState() => _MediTrackScreenState();
}

class _MediTrackScreenState extends State<MediTrackScreen>
    with TickerProviderStateMixin {

  // ── Dynamic color palette from theme tokens ──
  AppThemeTokens get _t => context.themeTokens;
  Color get bg         => _t.backgroundPrimary;
  Color get bg2        => _t.backgroundSecondary;
  Color get phoneShell  => _t.phoneShell;
  Color get phoneShell2 => _t.phoneShellInner;
  Color get panel       => _t.panel;
  Color get panel2      => _t.panelBorder;
  Color get cardBorder  => _t.cardBorder;
  Color get textColor   => _t.textPrimary;
  Color get muted       => _t.mutedText;
  Color get accent      => _t.accent.primary;
  Color get accent2     => _t.accent.secondary;
  Color get accent3     => _t.accent.tertiary;
  Color get accent4     => _t.accent.primary;   // maps to primary (pink variant)
  Color get accent5     => _t.accent.secondary;  // maps to secondary (gold variant)

  // ── Navigation state ──
  String activeScreen = 'home';

  // ── [PATCH B07] Medicine data model with mutable taken/left ──
  // Colors are assigned in didChangeDependencies since they come from the theme.
  List<Map<String, dynamic>> meds = [];
  bool _medsInitialised = false;

  // [PATCH B07] Log entries for taken/missed tracking
  final List<Map<String, dynamic>> _log = [];

  // [PATCH B21/B22] Calendar state
  late int _calYear;
  late int _calMonth;
  String? _selectedDay; // key "YYYY-M-D"

  // [PATCH B23] Log filter state
  String _logFilter = 'all';

  // [PATCH B04] Shimmer animation controller for progress card
  late AnimationController _shimmerCtrl;

  // [PATCH B05] Pulse animation controller for "Take Medicines" button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // [PATCH B31] Progress ring animation
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;
  double _prevRingProgress = 0.0;

  void _syncHomeAnimations() {
    final shouldAnimate = activeScreen == 'home';

    if (shouldAnimate) {
      if (!_shimmerCtrl.isAnimating) {
        _shimmerCtrl.repeat();
      }
      if (!_pulseCtrl.isAnimating) {
        _pulseCtrl.repeat(reverse: true);
      }
      return;
    }

    _shimmerCtrl.stop();
    _pulseCtrl.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_medsInitialised) {
      _medsInitialised = true;
      meds = [
        {'id': '1', 'name': 'Metformin',   'dose': '500mg',  'freq': 'Twice daily', 'time': '8:00 AM',  'cat': 'Diabetes',          'left': 28, 'total': 60, 'color': accent,  'taken': false, 'reminder': true},
        {'id': '2', 'name': 'Lisinopril',  'dose': '10mg',   'freq': 'Once daily',  'time': '9:00 AM',  'cat': 'Blood Pressure',     'left': 12, 'total': 30, 'color': accent2, 'taken': true,  'reminder': true},
        {'id': '3', 'name': 'Vitamin D3',  'dose': '2000IU', 'freq': 'Once daily',  'time': '10:00 AM', 'cat': 'Vitamin/Supplement', 'left': 45, 'total': 90, 'color': accent5, 'taken': false, 'reminder': false},
        {'id': '4', 'name': 'Atorvastatin','dose': '20mg',   'freq': 'Once daily',  'time': '8:00 PM',  'cat': 'Heart',              'left': 30, 'total': 30, 'color': accent3, 'taken': false, 'reminder': true},
      ];
      // Re-animate the ring now that meds are populated
      _animateRing(_computeRingProgress());
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calYear  = now.year;
    _calMonth = now.month;

    // [PATCH B04] Shimmer: 3.5s looping forward sweep
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // [PATCH B05] Pulse: 2.5s looping shadow pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // [PATCH B31] Ring: 700ms ease-out on mount
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringAnim = Tween<double>(begin: 0.0, end: _computeRingProgress())
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringCtrl.forward();
    _syncHomeAnimations();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // [PATCH B31] Compute ring progress from meds data
  double _computeRingProgress() {
    final remMeds = meds.where((m) => m['reminder'] == true).toList();
    if (remMeds.isEmpty) return 0.0;
    final taken = remMeds.where((m) => m['taken'] == true).length;
    return taken / remMeds.length;
  }

  // [PATCH B31] Re-animate ring when progress changes
  void _animateRing(double newProgress) {
    _ringAnim = Tween<double>(begin: _prevRingProgress, end: newProgress)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringCtrl.forward(from: 0);
    _prevRingProgress = newProgress;
  }

  // [PATCH B07] Mark a medicine as taken
  void _markTaken(String id) {
    setState(() {
      for (int i = 0; i < meds.length; i++) {
        if (meds[i]['id'] == id && meds[i]['taken'] == false) {
          meds[i] = {
            ...meds[i],
            'taken': true,
            'left': (meds[i]['left'] as int) > 0 ? (meds[i]['left'] as int) - 1 : 0,
          };
          _log.insert(0, {
            'medId': id,
            'medName': meds[i]['name'],
            'dose': meds[i]['dose'],
            'time': DateTime.now(),
            'status': 'taken',
          });
        }
      }
    });
    // [PATCH B31] Re-animate ring after state change
    _animateRing(_computeRingProgress());
    // [PATCH B30] Show toast confirmation
    _showToast('${meds.firstWhere((m) => m['id'] == id)['name']} marked as taken', '✅');
  }

  // [PATCH B30] Toast / SnackBar helper — replaces every `showToast()` call from HTML
  void _showToast(String message, String icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [PATCH B32] Time-based greeting — replaces hardcoded "Good morning! ☀️"
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5)  return 'Up late? 🌌';
    if (hour < 7)  return 'Early bird! 🌙';
    if (hour < 10) return 'Good morning! ☀️';
    if (hour < 12) return 'Good morning! 🌤️';
    if (hour < 13) return 'Good noon! 🌞';
    if (hour < 16) return 'Good afternoon! 🌈';
    if (hour < 18) return 'Good afternoon! 🌅';
    if (hour < 21) return 'Good evening! 🌆';
    if (hour < 23) return 'Good night! 🌙';
    return 'Up late? 🌌';
  }

  // [PATCH B32] Time-based subtitle
  String _getGreetingTitle() {
    final hour = DateTime.now().hour;
    if (hour < 5)  return "Don't forget your\nbedtime meds";
    if (hour < 7)  return 'Start your day\nwith your meds';
    if (hour < 10) return "Here's your\nmorning summary";
    if (hour < 12) return 'How are you\nfeeling today?';
    if (hour < 13) return 'Midday check-in,\nstay on track';
    if (hour < 16) return "Here's your\nafternoon summary";
    if (hour < 18) return 'Almost evening,\ncheck your doses';
    if (hour < 21) return "Evening check-in,\nhow'd it go?";
    return 'Wind down &\nreview your day';
  }

  void navTo(String screen) {
    setState(() {
      activeScreen = screen;
      _syncHomeAnimations();
      // [PATCH B21/B22] Reset calendar selection on log screen open
      if (screen == 'log') _selectedDay = null;
    });
  }

  void _handleBackNavigation() {
    if (activeScreen != 'home') {
      navTo('home');
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: activeScreen == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: phoneShell,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Container(
                      color: bg,
                      child: _buildActiveScreen(),
                    ),
                  ),
                ],
              ),
              // [PATCH B26] Chat FAB — connects to chat navigation
              Positioned(
                bottom: 30,
                right: 18,
                child: _buildChatFab(),
              ),
              if (activeScreen == 'medicines')
                Positioned(
                  bottom: 20,
                  right: 18,
                  // [PATCH B13] Add FAB now calls openAdd stub (B14 full sheet TBD)
                  child: _buildAddFab(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      decoration: BoxDecoration(
        color: phoneShell2,
        border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // [PATCH B01] Icon button with scale press animation
              _buildIconBtn(
                child: Icon(Icons.arrow_back, size: 17, color: textColor),
                onTap: _handleBackNavigation,
              ),
              const SizedBox(width: 13),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: accent2,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.medical_services_outlined, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 9),
              Text('MediTrack', style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w900)),
            ],
          ),
          // [PATCH B18] Bell button — stub (full overlay panel in B18 implementation plan)
          _buildIconBtn(
            child: Icon(Icons.notifications_outlined, size: 17, color: textColor),
            onTap: () => _showToast('Notifications coming soon', '🔔'),
            badge: true,
          ),
        ],
      ),
    );
  }

  // [PATCH B01] Animated icon button with scale press feedback
  Widget _buildIconBtn({
    required Widget child,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return _PressScaleButton(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: panel,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Center(child: child),
          ),
          if (badge)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: accent4,
                  shape: BoxShape.circle,
                  border: Border.all(color: phoneShell, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── ACTIVE SCREEN ROUTER ──
  Widget _buildActiveScreen() {
    switch (activeScreen) {
      case 'medicines': return _buildMedicinesScreen();
      case 'adherence': return _buildAdherenceScreen();
      case 'log':       return _buildLogScreen();
      default:          return _buildHomeScreen();
    }
  }

  // ── HOME SCREEN ──
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHomeHero(),
          _buildProgressCard(),
          _buildSectionHeader("Today's Schedule", 'See all →', onLink: () => navTo('medicines')),
          _buildTodayScroll(),
          const SizedBox(height: 14),
          _buildSectionHeader('Quick Stats', null),
          _buildQuickStats(),
          _buildSectionHeader('Quick Access', null),
          _buildNavCards(),
        ],
      ),
    );
  }

  Widget _buildHomeHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [PATCH B32] Dynamic greeting replaces hardcoded string
                Text(_getGreeting(), style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                // [PATCH B32] Dynamic subtitle
                Text(_getGreetingTitle(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, height: 1.2)),
                const SizedBox(height: 3),
                Text(_getHeroDate(), style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // [PATCH B02] Hero add button with spring rotate+scale animation
          _HeroAddButton(
            onTap: () => _showToast('Add Medicine coming soon', '💊'),
          ),
        ],
      ),
    );
  }

  String _getHeroDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildProgressCard() {
    // [PATCH B31] Compute live stats from meds data
    final remMeds = meds.where((m) => m['reminder'] == true).toList();
    final takenCount   = remMeds.where((m) => m['taken'] == true).length;
    final pendingCount = remMeds.length - takenCount;
    final pct          = remMeds.isEmpty ? 0 : (takenCount / remMeds.length * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2E6B91FF), Color(0x2E8D7DFF), Color(0x1F04D7C8)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6B91FF).withValues(alpha: 0.25), blurRadius: 32, offset: const Offset(0, 10))],
      ),
      // [PATCH B04] Shimmer overlay using AnimatedBuilder
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                // Shimmer sweep layer
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ShimmerPainter(progress: _shimmerCtrl.value),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // [PATCH B31] Animated progress ring
                SizedBox(
                  width: 82, height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ringAnim,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(82, 82),
                            painter: _RingPainter(
                              progress: _ringAnim.value,
                              trackColor: const Color(0x33C8607A),
                              progressColor: const Color(0xFFC8607A),
                              strokeWidth: 7,
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // [PATCH B31] Show live percentage
                          Text('$pct%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent, height: 1)),
                          Text('DONE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: muted, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Progress", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 6),
                      // [PATCH B31] Live taken count
                      _progStat(Colors.white.withValues(alpha: 0.9),  '$takenCount taken'),
                      const SizedBox(height: 5),
                      _progStat(Colors.white.withValues(alpha: 0.45), '$pendingCount pending'),
                      const SizedBox(height: 8),
                      // [PATCH B05] Pulsing "Take Medicines" button
                      _PulseTakeMedsButton(pulseAnim: _pulseAnim, onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progStat(Color dotColor, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String? linkText, {VoidCallback? onLink}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
          if (linkText != null)
            GestureDetector(
              onTap: onLink,
              child: Text(linkText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayScroll() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
        itemCount: meds.length,
        separatorBuilder: (_, i2) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = meds[i];
          return _buildPillCard(
            id:    p['id'] as String,
            name:  p['name'] as String,
            dose:  p['dose'] as String,
            time:  p['time'] as String,
            color: p['color'] as Color,
            taken: p['taken'] as bool,
          );
        },
      ),
    );
  }

  Widget _buildPillCard({
    required String id,
    required String name,
    required String dose,
    required String time,
    required Color color,
    required bool taken,
  }) {
    // [PATCH B06] Pill card with press scale animation
    return _PressScaleButton(
      onTap: () { if (!taken) _markTaken(id); },  // [PATCH B07] markTaken on card tap
      child: Container(
        decoration: BoxDecoration(
          color: taken ? const Color(0x1404D7C8) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: taken ? const Color(0x4D04D7C8) : cardBorder, width: 1.5),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: Text('💊', style: TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
                      Text(dose, style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w600)),
                      Row(children: [
                        Icon(Icons.access_time, size: 9, color: color),
                        const SizedBox(width: 3),
                        Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ]),
                      if (!taken) ...[
                        const SizedBox(height: 2),
                        // [PATCH B08] "Take" chip with independent onTap → markTaken
                        GestureDetector(
                          onTap: () => _markTaken(id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [accent4, accent2]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: const [
                              Icon(Icons.check, size: 9, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Take', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (taken)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: accent3, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {'icon': '💊', 'val': '${meds.length}',  'lbl': 'Medicines',   'sub': 'active',        'borderColor': accent4},
      {'icon': '📊', 'val': '92%',              'lbl': 'Adherence',   'sub': 'this week',     'borderColor': accent2},
      {'icon': '✅', 'val': '${meds.where((m) => m['taken'] == true).length}', 'lbl': 'Taken Today', 'sub': 'of ${meds.length}', 'borderColor': accent3},  // [PATCH B31] live count
      {'icon': '⚠️', 'val': '${meds.where((m) => (m['left'] as int) <= 7).length}', 'lbl': 'Low Supply', 'sub': 'refill soon', 'borderColor': accent5},
    ];

    final navTargets = ['medicines', 'adherence', 'medicines', 'medicines'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
        children: List.generate(stats.length, (i) {
          final s = stats[i];
          final bc = s['borderColor'] as Color;
          // [PATCH B10] Quick stat cards navigate on tap
          return _PressScaleButton(
            onTap: () => navTo(navTargets[i]),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bc.withValues(alpha: 0.18), bc.withValues(alpha: 0.10)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bc.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                    child: Center(child: Text(s['icon'] as String, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(height: 10),
                  Text(s['val'] as String, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, height: 1)),
                  const SizedBox(height: 2),
                  Text(s['lbl'] as String, style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(s['sub'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavCards() {
    final cards = [
      {'icon': Icons.folder_open,   'iconBg': [const Color(0xFFec4899), const Color(0xFFdb2777)], 'shadowColor': const Color(0x59EC4899), 'label': 'My Medicines', 'sub': 'View & manage all', 'screen': 'medicines'},
      {'icon': Icons.bar_chart,     'iconBg': [const Color(0xFF8b5cf6), const Color(0xFF6d28d9)], 'shadowColor': const Color(0x598B5CF6), 'label': 'Adherence',    'sub': 'Track progress',    'screen': 'adherence'},
      {'icon': Icons.calendar_today,'iconBg': [const Color(0xFF3b82f6), const Color(0xFF2563eb)], 'shadowColor': const Color(0x593B82F6), 'label': 'Medicine Log', 'sub': 'Calendar history',  'screen': 'log'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: cards.map((c) {
          final gradColors = c['iconBg'] as List<Color>;
          // [PATCH B25] Nav card with press animation
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NavCardAnimated(
              onTap: () => navTo(c['screen'] as String),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradColors),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [BoxShadow(color: c['shadowColor'] as Color, blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Icon(c['icon'] as IconData, size: 17, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                          Text(c['sub']   as String, style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // [PATCH B25] Arrow shifts on press via NavCardAnimated
                    Icon(Icons.chevron_right, size: 18, color: muted),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── MEDICINES SCREEN ──
  Widget _buildMedicinesScreen() {
    return Column(
      children: [
        _buildBackBar('My Medicines'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: meds.map((m) => _buildMedItem(m)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedItem(Map<String, dynamic> med) {
    final color    = med['color'] as Color;
    final left     = med['left'] as int;
    final total    = med['total'] as int;
    final progress = left / total;

    // [PATCH B11] Med item with horizontal slide press animation
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SlideXPressButton(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)),
                child: const Center(child: Text('💊', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      children: [
                        Text('${med['dose']}', style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600)),
                        Text('·', style: TextStyle(fontSize: 11, color: muted)),
                        Text('${med['freq']}', style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600)),
                        Text('·', style: TextStyle(fontSize: 11, color: muted)),
                        Text('${med['time']}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Supply', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: muted)),
                      Text('$left / $total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: muted)),
                    ]),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: panel2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  // [PATCH B12] Edit button with press scale + toast feedback
                  _PressScaleButton(
                    scaleFactor: 0.9,
                    onTap: () => _showToast('Edit ${med['name']} coming soon', '✏️'),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: Icon(Icons.edit_outlined, size: 15, color: color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // [PATCH B12] Delete button with press scale + toast feedback
                  _PressScaleButton(
                    scaleFactor: 0.9,
                    onTap: () {
                      setState(() => meds.removeWhere((m) => m['id'] == med['id']));
                      _showToast('${med['name']} removed', '🗑️');
                    },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: accent4.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent4.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: Icon(Icons.delete_outline, size: 15, color: accent4),
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

  // ── ADHERENCE SCREEN ──
  Widget _buildAdherenceScreen() {
    final items = [
      {'name': 'Metformin',    'dose': '500mg · Twice daily',  'pct': 95, 'sub': '19/20 doses taken', 'tag': 'Excellent', 'tagColor': accent3},
      {'name': 'Lisinopril',   'dose': '10mg · Once daily',    'pct': 80, 'sub': '8/10 doses taken',  'tag': 'Good',      'tagColor': accent},
      {'name': 'Vitamin D3',   'dose': '2000IU · Once daily',  'pct': 60, 'sub': '6/10 doses taken',  'tag': 'Fair',      'tagColor': accent5},
      {'name': 'Atorvastatin', 'dose': '20mg · Once daily',    'pct': 40, 'sub': '4/10 doses taken',  'tag': 'Poor',      'tagColor': accent4},
    ];

    return Column(
      children: [
        _buildBackBar('Adherence'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            // [PATCH B11] Adherence items also use slide-X press
            child: Column(
              children: items.map((item) {
                final pct      = item['pct'] as int;
                final tagColor = item['tagColor'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SlideXPressButton(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                                Text(item['dose'] as String, style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('$pct%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tagColor)),
                                Text(item['sub'] as String, style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(value: pct / 100, minHeight: 5, backgroundColor: panel2, valueColor: AlwaysStoppedAnimation<Color>(tagColor)),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: tagColor.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Text(item['tag'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tagColor)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── LOG / CALENDAR SCREEN ──
  Widget _buildLogScreen() {
    return Column(
      children: [
        _buildBackBar('Medicine Log'),
        _buildLogFilterBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                _buildCalCard(),
                const SizedBox(height: 14),
                _buildLogTimeline(),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogFilterBar() {
    // [PATCH B23] Filter bar with active state management
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterBtn('All',         'all',    _logFilter == 'all'),
            const SizedBox(width: 8),
            _buildFilterBtn('✅ Taken',    'taken',  _logFilter == 'taken'),
            const SizedBox(width: 8),
            _buildFilterBtn('❌ Missed',  'missed', _logFilter == 'missed'),
            const SizedBox(width: 8),
            _buildFilterBtn('+ Mark Missed', 'mark', false, isAction: true),
          ],
        ),
      ),
    );
  }

  // [PATCH B23] Filter button with animated active state
  Widget _buildFilterBtn(String label, String filter, bool active, {bool isAction = false}) {
    return GestureDetector(
      onTap: () {
        if (isAction) {
          _showToast('Mark Missed coming soon', '❌'); // [PATCH B24 stub]
        } else {
          setState(() => _logFilter = filter); // [PATCH B23] update filter state
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? accent
              : isAction ? const Color(0x1A8D7DFF) : panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? accent : isAction ? accent2 : cardBorder, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : isAction ? accent2 : muted,
          ),
        ),
      ),
    );
  }

  Widget _buildCalCard() {
    // [PATCH B22] Use dynamic _calYear/_calMonth
    const monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final monthLabel  = '${monthNames[_calMonth - 1]} $_calYear';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0, -1), end: Alignment(1, 1),
          colors: [Color(0x238B91FF), Color(0x1F8D7DFF), Color(0x1A04D7C8)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6B91FF).withValues(alpha: 0.16), blurRadius: 40, offset: const Offset(0, 12)),
          BoxShadow(color: const Color(0xFFFF8EC7).withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [PATCH B22] Previous month button
              _PressScaleButton(
                scaleFactor: 0.93,
                onTap: () {
                  setState(() {
                    _calMonth--;
                    if (_calMonth < 1) { _calMonth = 12; _calYear--; }
                    _selectedDay = null;
                  });
                },
                child: _calNavBtn(Icons.chevron_left),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(colors: [accent, accent4]).createShader(bounds),
                child: Text(monthLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              // [PATCH B22] Next month button
              _PressScaleButton(
                scaleFactor: 0.93,
                onTap: () {
                  setState(() {
                    _calMonth++;
                    if (_calMonth > 12) { _calMonth = 1; _calYear++; }
                    _selectedDay = null;
                  });
                },
                child: _calNavBtn(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(const Color(0xFF6dbf8a), 'Taken'),
                _legendItem(const Color(0xFFf07070), 'Missed'),
                _legendItem(const Color(0xFFc4b5fd), 'Pending'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCalGrid(),
          // [PATCH B21] Detail panel shown when a day is selected
          if (_selectedDay != null) ...[
            const SizedBox(height: 12),
            _buildDayDetailPanel(),
          ],
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [BoxShadow(color: const Color(0xFF6B91FF).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 18, color: accent2),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildCalGrid() {
    final now         = DateTime.now();
    final firstDay    = DateTime(_calYear, _calMonth, 1);
    final daysInMonth = DateTime(_calYear, _calMonth + 1, 0).day;
    final startWkDay  = firstDay.weekday % 7;
    const weekdays    = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Column(
      children: [
        Row(children: weekdays.map((d) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(d, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: muted, letterSpacing: 0.5)),
        ))).toList()),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.75,
          ),
          itemCount: startWkDay + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWkDay) return const SizedBox.shrink();
            final day      = index - startWkDay + 1;
            final isToday  = day == now.day && _calMonth == now.month && _calYear == now.year;
            final isFuture = DateTime(_calYear, _calMonth, day).isAfter(now);
            final dayKey   = '$_calYear-$_calMonth-$day';
            // [PATCH B21] Selection state
            final isSel    = _selectedDay == dayKey;

            return GestureDetector(
              // [PATCH B21] Tap toggles day selection
              onTap: () => setState(() {
                _selectedDay = _selectedDay == dayKey ? null : dayKey;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSel
                        ? [const Color(0x2EFF8EC7), const Color(0x1AFF8EC7)]
                        : isToday
                        ? [const Color(0x2E6B91FF), const Color(0x1A8D7DFF)]
                        : [const Color(0x146B91FF), const Color(0x0D8D7DFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? accent4 : isToday ? accent : cardBorder,
                    width: isSel || isToday ? 2 : 1,
                  ),
                  boxShadow: isSel
                      ? [BoxShadow(color: accent4.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))]
                      : isToday
                      ? [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Opacity(
                  opacity: isFuture ? 0.4 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
                    child: Column(children: [
                      Text('$day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isToday ? accent : textColor)),
                      const SizedBox(height: 3),
                      if (!isFuture && day < now.day)
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: day % 5 == 0 ? const Color(0xFFf07070) : const Color(0xFF6dbf8a),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      const SizedBox(height: 2),
                      if (!isFuture && day < now.day)
                        Text(day % 5 == 0 ? '3/4' : '4/4', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: muted)),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // [PATCH B21] Day detail panel shown below calendar on selection
  Widget _buildDayDetailPanel() {
    final parts = _selectedDay!.split('-');
    final day   = int.parse(parts[2]);
    final date  = DateTime(_calYear, _calMonth, day);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wdays  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final label  = '${wdays[date.weekday - 1]}, ${months[date.month - 1]} $day';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1A6B91FF), Color(0x148D7DFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today, size: 13, color: accent2),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
          ]),
          const SizedBox(height: 10),
          ...meds.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder, width: 1),
              ),
              child: Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: m['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(m['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor))),
                Text(m['dose'] as String, style: TextStyle(fontSize: 11, color: muted)),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLogTimeline() {
    // [PATCH B23] Filter log entries based on _logFilter
    final filtered = _logFilter == 'all'
        ? _log
        : _log.where((e) => e['status'] == _logFilter).toList();

    // Static demo entries if log is empty
    final entries = filtered.isEmpty
        ? [
      {'name': 'Lisinopril', 'dose': '10mg',   'time': '9:02 AM', 'status': 'taken',  'color': accent2},
      {'name': 'Metformin',  'dose': '500mg',  'time': '8:15 AM', 'status': 'taken',  'color': accent},
      {'name': 'Vitamin D3', 'dose': '2000IU', 'time': '—',       'status': 'missed', 'color': accent4},
    ]
        : filtered.map((e) => {
      'name':   e['medName'],
      'dose':   e['dose'],
      'time':   (e['time'] as DateTime).toLocal().toString().substring(11, 16),
      'status': e['status'],
      'color':  meds.firstWhere((m) => m['id'] == e['medId'], orElse: () => {'color': accent})['color'],
    }).toList();

    // [PATCH B23] Show empty state for filtered views
    if (_logFilter != 'all' && entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No ${_logFilter == 'taken' ? 'taken' : 'missed'} entries yet.', style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w700))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Timeline", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
        const SizedBox(height: 10),
        ...entries.map((e) {
          final color    = e['color'] as Color;
          final isMissed = e['status'] == 'missed';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: cardBorder, width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFF6B91FF).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: isMissed ? accent4 : color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(e['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor))),
              Text(e['dose'] as String, style: TextStyle(fontSize: 11, color: muted)),
              const SizedBox(width: 8),
              SizedBox(width: 46, child: Text(e['time'] as String, textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: muted))),
            ]),
          );
        }),
      ],
    );
  }

  // ── BACK BAR ──
  Widget _buildBackBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(children: [
        // [PATCH B01] Back button with scale animation
        _PressScaleButton(
          scaleFactor: 0.93,
          onTap: () => navTo('home'),
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: panel, shape: BoxShape.circle,
              border: Border.all(color: cardBorder, width: 1.5),
            ),
            child: Icon(Icons.chevron_left, size: 20, color: accent2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
      ]),
    );
  }

  // [PATCH B26] Chat FAB — navigates to chat (stub)
  Widget _buildChatFab() {
    return _PressScaleButton(
      onTap: () => _showToast('AHVI Chat coming soon', '🤖'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent2, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: const Color(0xFF6B91FF).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text('Ask AHVI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
        ]),
      ),
    );
  }

  // [PATCH B13] Add FAB — now shows toast stub instead of empty onTap
  Widget _buildAddFab() {
    return _PressScaleButton(
      onTap: () => _showToast('Add Medicine coming soon', '💊'),
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: accent, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  [PATCH B01] Generic press-scale animation widget
//  Replaces plain GestureDetector wherever tap feedback is needed
// ════════════════════════════════════════════════════════════
class _PressScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const _PressScaleButton({
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleFactor : 1.0,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  [PATCH B11] Horizontal slide press for med/adhere items
// ════════════════════════════════════════════════════════════
class _SlideXPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SlideXPressButton({required this.child, required this.onTap});

  @override
  State<_SlideXPressButton> createState() => _SlideXPressButtonState();
}

class _SlideXPressButtonState extends State<_SlideXPressButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:   (_) => setState(() => _hovered = true),
      onTapUp:     (_) => setState(() => _hovered = false),
      onTapCancel: ()  => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(_hovered ? 4.0 : 0.0, 0, 0),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  [PATCH B02] Hero add button with spring rotate + scale
// ════════════════════════════════════════════════════════════
class _HeroAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HeroAddButton({required this.onTap});

  @override
  State<_HeroAddButton> createState() => _HeroAddButtonState();
}

class _HeroAddButtonState extends State<_HeroAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim  = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(begin: 0.0, end: 0.25)   // 90° = 0.25 turns
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotateAnim.value * 2 * math.pi,
            child: child,
          ),
        ),
        child: Container(
          width: 40, height: 40,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6b91ff),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  [PATCH B25] Nav card with press translateX + scale
// ════════════════════════════════════════════════════════════
class _NavCardAnimated extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NavCardAnimated({required this.child, required this.onTap});

  @override
  State<_NavCardAnimated> createState() => _NavCardAnimatedState();
}

class _NavCardAnimatedState extends State<_NavCardAnimated> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(_pressed ? 0 : 3.0, 0, 0)
          ..multiply(Matrix4.diagonal3Values(_pressed ? 0.97 : 1.01, _pressed ? 0.97 : 1.01, 1.0)),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  [PATCH B05] Pulsing "Take Medicines" button
// ════════════════════════════════════════════════════════════
class _PulseTakeMedsButton extends StatelessWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _PulseTakeMedsButton({required this.pulseAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) {
        // Interpolate pulse spread from 0 → 6px
        final spread = pulseAnim.value * 6.0;
        final blurR  = 4 + pulseAnim.value * 10;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6b91ff).withValues(alpha: 0.4 * (1 - pulseAnim.value)),
                blurRadius: blurR,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check, size: 13, color: Color(0xFF6b91ff)),
              SizedBox(width: 6),
              Text('Take Medicines', style: TextStyle(color: Color(0xFF6b91ff), fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  [PATCH B04] Shimmer CustomPainter for progress card
// ════════════════════════════════════════════════════════════
class _ShimmerPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 from AnimationController

  const _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Map progress 0→1 to left offset -70%→130%
    final left = (-0.70 + progress * 2.0) * size.width;
    final shimmerW = size.width * 0.45;

    // Opacity fades in at 20% and out at 80%
    double opacity = 0.0;
    if (progress < 0.2)      { opacity = progress / 0.2; }
    else if (progress < 0.8) { opacity = 1.0; }
    else                     { opacity = 1.0 - (progress - 0.8) / 0.2; }
    opacity = (opacity * 0.22).clamp(0.0, 0.22);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: opacity),
        Colors.transparent,
      ],
    );

    final rect = Rect.fromLTWH(left, 0, shimmerW, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ════════════════════════════════════════════════════════════
//  Ring Painter (original, unchanged)
// ════════════════════════════════════════════════════════════
class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}
