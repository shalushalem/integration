import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/meal_planner.dart' as meal_planner;
import 'package:myapp/medi_tracker.dart' as medi_tracker;
import 'package:myapp/bills_page.dart' as bills;
import 'package:myapp/theme/theme_tokens.dart';

// ─────────────────────────────────────────────
//  CUSTOM PAINTERS (unchanged from original)
// ─────────────────────────────────────────────

/// Back arrow  ←
class _BackArrowPainter extends CustomPainter {
  final Color color;
  const _BackArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    canvas.drawLine(
      Offset(w * 19 / 24, h / 2),
      Offset(w * 5  / 24, h / 2),
      paint,
    );
    final path = Path()
      ..moveTo(w * 12 / 24, h *  5 / 24)
      ..lineTo(w *  5 / 24, h / 2)
      ..lineTo(w * 12 / 24, h * 19 / 24);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


// ─────────────────────────────────────────────
//  HOME & UTILITIES SCREEN — Premium upgrade
//  • Uses AppThemeTokens for consistent theming
//  • Staggered entrance animation on header + tabs
//  • Haptic feedback on tab switches
//  • Custom styled header (matching boards.dart)
// ─────────────────────────────────────────────
class HomeUtilitiesScreen extends StatefulWidget {
  const HomeUtilitiesScreen({super.key});

  @override
  State<HomeUtilitiesScreen> createState() => _HomeUtilitiesScreenState();
}

class _HomeUtilitiesScreenState extends State<HomeUtilitiesScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // ── Entrance animation ──
  late final AnimationController _entranceCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _tabsFade;
  late final Animation<Offset> _tabsSlide;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      } else if (mounted) {
        setState(() {});
      }
    });

    // Staggered entrance: header 0–50%, tabs 25–75%
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    _tabsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _tabsSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;

    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      body: Column(
        children: [
          // ── Custom header (replaces plain AppBar) ──
          AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (context, child) => FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: child,
              ),
            ),
            child: _buildHeader(t),
          ),

          // ── Custom tab bar ──
          AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (context, child) => FadeTransition(
              opacity: _tabsFade,
              child: SlideTransition(
                position: _tabsSlide,
                child: child,
              ),
            ),
            child: _buildTabBar(t),
          ),

          // ── Tab content ──
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: const [
                RepaintBoundary(child: meal_planner.Screen4()),
                RepaintBoundary(child: medi_tracker.MediTrackScreen()),
                RepaintBoundary(child: bills.Screen4()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(AppThemeTokens t) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        14,
      ),
      child: Row(
        children: [
          // Back button with press scale
          _PressScaleButton(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.panel,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: t.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: t.backgroundPrimary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(
                    painter: _BackArrowPainter(
                      t.mutedText.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Home & ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: 'Utilities',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w300,
                    color: t.accent.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──
  Widget _buildTabBar(AppThemeTokens t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.accent.primary,
              t.accent.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: t.accent.primary.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: t.tileText,
        unselectedLabelColor: t.mutedText,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Meals'),
          Tab(text: 'Medi'),
          Tab(text: 'Bills'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Press-scale feedback button
// ─────────────────────────────────────────────
class _PressScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
