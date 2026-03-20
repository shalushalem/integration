// boards.dart — Premium UX Upgrade
// Implements all F1–F12 animations + haptics + iOS scroll + DRY refactor

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myapp/calendar.dart';
import 'package:myapp/theme/theme_tokens.dart';

// ── Master Board Import ──
import 'package:myapp/occasion.dart'; // Handles Daily Wear, Workout, Office, Party, Vacation, etc.

// ── Specific Board Imports ──
import 'package:myapp/everything_else.dart' as everything_else;
import 'package:myapp/home_and_utilities.dart' as home_utils;
import 'package:myapp/bills_page.dart' as bills;
import 'package:myapp/skincare.dart';

class ShellBackNavigationNotification extends Notification {
  const ShellBackNavigationNotification();
}

// ─────────────────────────────────────────────────────────────────────────────
//  CALENDAR CARD (glass + inline expandable panel)
// ─────────────────────────────────────────────────────────────────────────────
class CalendarCard extends StatefulWidget {
  final Color cardColor;
  final Color borderColor;
  final Color panelColor;
  final Color panelBorder;
  final Color textColor;
  final Color mutedColor;
  final Color accent;
  final Color accentSoft;
  final Color shellColor;

  const CalendarCard({
    super.key,
    required this.cardColor,
    required this.borderColor,
    required this.panelColor,
    required this.panelBorder,
    required this.textColor,
    required this.mutedColor,
    required this.accent,
    required this.accentSoft,
    required this.shellColor,
  });

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard>
    with SingleTickerProviderStateMixin {
  bool _calendarOpen = false;
  int _totalPlans = 0;
  int _todayPlans = 0;

  void _toggleCalendar() {
    setState(() => _calendarOpen = !_calendarOpen);
  }

  void _updateCounts(int total, int today) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _totalPlans = total;
        _todayPlans = today;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _GlassCard(
        borderColor: widget.borderColor,
        glow: widget.accent.withValues(alpha: 0.28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_S.base, _S.base, _S.base, _S.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleCalendar,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.panelColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.panelBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule / Calendar',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.textColor,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '• $_totalPlans outfit plans • $_todayPlans today',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFE6EBFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: _A.normal,
                curve: _A.ease,
                alignment: Alignment.topCenter,
                child: _calendarOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: _S.base),
                        child: ExpandableCalendarPanel(
                          onCountsChanged: _updateCounts,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color glow;

  const _GlassCard({
    required this.child,
    required this.borderColor,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPACING CONSTANTS  (4-pt grid)
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _S {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 24;
  static const double xl   = 32;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATION CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _A {
  static const Duration fast    = Duration(milliseconds: 150);
  static const Duration medium  = Duration(milliseconds: 250);
  static const Duration normal  = Duration(milliseconds: 300);
  static const Duration slow    = Duration(milliseconds: 350);
  static const Duration entry   = Duration(milliseconds: 500);
  static const Duration page    = Duration(milliseconds: 600);

  static const Curve spring     = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve pageEntry  = Cubic(0.22, 1.0,  0.36, 1.0);
  static const Curve ease       = Curves.easeOutCubic;
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOARDS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});

  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen>
    with TickerProviderStateMixin {

  AppThemeTokens get _theme => context.themeTokens;
  Color get _bg2         => _theme.backgroundSecondary;
  Color get _panel       => _theme.panel;
  Color get _panelBorder => _theme.panelBorder;
  Color get _card        => _theme.card;
  Color get _cardBorder  => _theme.cardBorder;
  Color get _text        => _theme.textPrimary;
  Color get _muted       => _theme.mutedText;
  Color get _accent      => _theme.accent.primary;
  Color get _accent2     => _theme.accent.secondary;
  Color get _shell       => _theme.phoneShell;

  bool _isLifeTab = true;
  bool _hasStartedAnimations = false; // <-- FIX: Tracks if entry animations fired

  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerOpacity;
  late final Animation<Offset>   _headerSlide;

  late final AnimationController _toggleCtrl;
  late final Animation<double>   _toggleOpacity;
  late final Animation<Offset>   _toggleSlide;

  late final AnimationController _sectionCtrl;
  late final Animation<double>   _sectionOpacity;
  late final Animation<Offset>   _sectionSlide;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: _A.page);
    _headerOpacity = CurvedAnimation(parent: _headerCtrl, curve: _A.pageEntry);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _A.pageEntry));

    _toggleCtrl = AnimationController(vsync: this, duration: _A.page);
    _toggleOpacity = CurvedAnimation(parent: _toggleCtrl, curve: _A.pageEntry);
    _toggleSlide = Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _toggleCtrl, curve: _A.pageEntry));

    _sectionCtrl = AnimationController(vsync: this, duration: _A.slow);
    _sectionOpacity = CurvedAnimation(parent: _sectionCtrl, curve: Curves.ease);
    _sectionSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sectionCtrl, curve: Curves.ease));

    // REMOVED immediate .forward() calls here to fix the IndexedStack bug!
  }

  // <-- THE FIX: Only play animations when the tab actually becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context) && !_hasStartedAnimations) {
      _hasStartedAnimations = true;
      _headerCtrl.forward();
      Future.delayed(const Duration(milliseconds: 100),
              () { if (mounted) _toggleCtrl.forward(); });
      Future.delayed(const Duration(milliseconds: 200),
              () { if (mounted) _sectionCtrl.forward(); });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _toggleCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool isLife) {
    if (_isLifeTab == isLife) return;
    HapticFeedback.selectionClick(); 
    setState(() => _isLifeTab = isLife);
    _sectionCtrl
      ..reset()
      ..forward();
  }

  void _push(Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: _A.slow,
        reverseTransitionDuration: _A.slow,
        pageBuilder: (context, animation, secondary) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation, curve: _A.pageEntry,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0), end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg2,
      body: Stack(
        children: [
          Positioned.fill(child: _buildAmbientBg()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      _S.base, _S.xl, _S.base, 132),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeTransition(
                        opacity: _headerOpacity,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: _buildHeader(),
                        ),
                      ),
                      const SizedBox(height: _S.lg),
                      FadeTransition(
                        opacity: _toggleOpacity,
                        child: SlideTransition(
                          position: _toggleSlide,
                          child: _buildToggle(),
                        ),
                      ),
                      const SizedBox(height: _S.base + _S.xs), 
                      FadeTransition(
                        opacity: _sectionOpacity,
                        child: SlideTransition(
                          position: _sectionSlide,
                          child: AnimatedSwitcher(
                            duration: _A.slow,
                            switchInCurve: _A.ease,
                            switchOutCurve: _A.ease,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: KeyedSubtree(
                              key: ValueKey(_isLifeTab),
                              child: _isLifeTab
                                  ? _buildLifeSection()
                                  : _buildBoardsSection(),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBg() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -0.8),
              radius: 1.0,
              colors: [
                _accent2.withValues(alpha: 0.20),
                _card.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.6, 0.6),
              radius: 1.0,
              colors: [
                _accent2.withValues(alpha: 0.14),
                _card.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HoverPressButton(
              onTap: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                  return;
                }
                const ShellBackNavigationNotification().dispatch(context);
              },
              hoverScale: 0.95,
              pressScale: 0.90,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _panelBorder, width: 1),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _S.md),
            Text(
              'Boards',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 38,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -1.0, 
                color: _text,
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.sm),
        Text(
          'Your life, organised visually.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _muted,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _panelBorder, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(_S.xs),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Life',
              icon: Icons.auto_awesome_rounded,
              isActive: _isLifeTab,
              activeShellColor: _shell,
              activeTextColor: _text,
              inactiveTextColor: _muted,
              accentColor: _accent,
              onTap: () => _switchTab(true),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Boards',
              icon: Icons.grid_view_rounded,
              isActive: !_isLifeTab,
              activeShellColor: _shell,
              activeTextColor: _text,
              inactiveTextColor: _muted,
              accentColor: _accent,
              onTap: () => _switchTab(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeSection() {
    final lifeContentColor = _text;

    return Column(
      children: [
        _StaggeredCard(
          delay: const Duration(milliseconds: 100),
          child: CalendarCard(
            cardColor: _card,
            borderColor: _cardBorder,
            panelColor: _panel,
            panelBorder: _panelBorder,
            textColor: lifeContentColor,
            mutedColor: _muted,
            accent: const Color(0xFF77A8FF),
            accentSoft: const Color(0xFF9DCBFF),
            shellColor: _shell,
          ),
        ),
        const SizedBox(height: _S.md),

        Row(
          children: [
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 170),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB08F), Color(0xFFFF8F72)],
                  ),
                  shadowColor: const Color(0xFFFF8F72).withValues(alpha: 0.30),
                  badge: '12',
                  badgeTextColor: _accent,
                  badgeBg: _card,
                  badgeBorderColor: _accent.withValues(alpha: 0.25),
                  iconBg: _card,
                  iconWidget: Icon(Icons.checkroom_rounded, size: 32, color: lifeContentColor),
                  title: 'Daily Wear',
                  titleColor: lifeContentColor,
                  subtitle: "Today's outfits",
                  subtitleColor: lifeContentColor,
                  arrowBg: _card,
                  arrowColor: lifeContentColor,
                  shellColor: _shell,
                  onTap: () => _push(const OccasionBoard(
                    occasion: 'Daily Wear',
                    title: 'Daily Wear',
                    subtitle: "Today's outfits",
                    emptyEmoji: '👕',
                  )),
                ),
              ),
            ),
            const SizedBox(width: _S.md),
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 240),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE07E), Color(0xFFFFC956)],
                  ),
                  shadowColor: const Color(0xFFFFC956).withValues(alpha: 0.30),
                  badge: '5',
                  badgeTextColor: _accent2,
                  badgeBg: _card,
                  badgeBorderColor: _accent2.withValues(alpha: 0.25),
                  iconBg: _card,
                  iconWidget: Icon(Icons.home_rounded, size: 32, color: lifeContentColor),
                  title: 'Home / Utilities',
                  titleColor: lifeContentColor,
                  subtitle: 'Bills & stuff',
                  subtitleColor: lifeContentColor,
                  arrowBg: _card,
                  arrowColor: lifeContentColor,
                  shellColor: _shell,
                  onTap: () => _push(const home_utils.HomeUtilitiesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.md),

        Row(
          children: [
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 310),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF9AF0D3), Color(0xFF58DCB0)],
                  ),
                  shadowColor: const Color(0xFF58DCB0).withValues(alpha: 0.30),
                  badge: '3×/wk',
                  badgeTextColor: _accent,
                  badgeBg: _panelBorder,
                  badgeBorderColor: _cardBorder,
                  iconBg: _panel,
                  iconWidget: Icon(Icons.fitness_center_rounded, size: 32, color: lifeContentColor),
                  title: 'Work Out',
                  titleColor: lifeContentColor,
                  subtitle: 'Gym & yoga',
                  subtitleColor: lifeContentColor,
                  arrowBg: _panel,
                  arrowColor: lifeContentColor,
                  shellColor: _shell,
                  onTap: () => _push(const OccasionBoard(
                    occasion: 'Workout',
                    title: 'Work Out',
                    subtitle: 'Gym & yoga',
                    emptyEmoji: '🏃',
                  )),
                ),
              ),
            ),
            const SizedBox(width: _S.md),
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 380),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF9DCBFF), Color(0xFF77A8FF)],
                  ),
                  shadowColor: const Color(0xFF77A8FF).withValues(alpha: 0.30),
                  badge: '8',
                  badgeTextColor: _accent,
                  badgeBg: _panelBorder,
                  badgeBorderColor: _cardBorder,
                  iconBg: _panel,
                  iconWidget: Icon(Icons.track_changes_rounded, size: 32, color: lifeContentColor),
                  title: 'Life Goals',
                  titleColor: lifeContentColor,
                  subtitle: 'Habits & goals',
                  subtitleColor: lifeContentColor,
                  arrowBg: _panel,
                  arrowColor: lifeContentColor,
                  shellColor: _shell,
                  // <-- FIX: updated from bills.Screen4() to bills.BillsScreen()
                  onTap: () => _push(const bills.BillsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.md),

        _StaggeredCard(
          delay: const Duration(milliseconds: 380),
          child: _VCard(
            fullWidth: true,
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFFFBFDC), Color(0xFFFF96C7)],
            ),
            shadowColor: const Color(0xFFFF96C7).withValues(alpha: 0.30),
            badge: 'AM · PM',
            badgeTextColor: _accent,
            badgeBg: _panelBorder,
            badgeBorderColor: _cardBorder,
            iconBg: _panel,
            iconWidget: Icon(Icons.water_drop_rounded, size: 32, color: lifeContentColor),
            title: 'Skincare',
            titleColor: lifeContentColor,
            subtitle: 'Morning & night routine',
            subtitleColor: lifeContentColor,
            arrowBg: _panel,
            arrowColor: lifeContentColor,
            shellColor: _shell,
            onTap: () => _push(const SkincareScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 80),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB08F), Color(0xFFFF8F72)],
                  ),
                  shadowColor: const Color(0xFFFF8F72).withValues(alpha: 0.30),
                  badge: null,
                  badgeTextColor: Colors.transparent,
                  badgeBg: Colors.transparent,
                  badgeBorderColor: Colors.transparent,
                  iconBg: _panel,
                  iconWidget: const Icon(Icons.celebration_rounded, size: 26, color: Color(0xFFFF8F72)),
                  title: 'Party Looks',
                  titleColor: _text,
                  titleSize: 15,
                  subtitle: 'Evening & cocktail',
                  subtitleColor: const Color(0xFFFF8F72),
                  arrowBg: _panel,
                  arrowColor: const Color(0xFFFF8F72),
                  shellColor: _shell,
                  onTap: () => _push(const OccasionBoard(
                    occasion: 'Party',
                    title: 'Party Looks',
                    subtitle: 'Evening & cocktail',
                    emptyEmoji: '🎊',
                  )),
                ),
              ),
            ),
            const SizedBox(width: _S.md),
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 160),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE07E), Color(0xFFFFC956)],
                  ),
                  shadowColor: const Color(0xFFFFC956).withValues(alpha: 0.30),
                  badge: null,
                  badgeTextColor: Colors.transparent,
                  badgeBg: Colors.transparent,
                  badgeBorderColor: Colors.transparent,
                  iconBg: _panel,
                  iconWidget: const Icon(Icons.business_center_rounded, size: 26, color: Color(0xFFFFC956)),
                  title: 'Office Fits',
                  titleColor: _text,
                  titleSize: 15,
                  subtitle: 'Work-ready looks',
                  subtitleColor: const Color(0xFFFFC956),
                  arrowBg: _panel,
                  arrowColor: const Color(0xFFFFC956),
                  shellColor: _shell,
                  onTap: () => _push(const OccasionBoard(
                    occasion: 'Office',
                    title: 'Office Fits',
                    subtitle: 'Work-ready looks',
                    emptyEmoji: '💼',
                  )),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.md),

        Row(
          children: [
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 160),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF9AF0D3), Color(0xFF58DCB0)],
                  ),
                  shadowColor: const Color(0xFF58DCB0).withValues(alpha: 0.25),
                  badge: null,
                  badgeTextColor: Colors.transparent,
                  badgeBg: Colors.transparent,
                  badgeBorderColor: Colors.transparent,
                  iconBg: _panel,
                  iconWidget: const Icon(Icons.beach_access_rounded, size: 26, color: Color(0xFF58DCB0)),
                  title: 'Vacation',
                  titleColor: _text,
                  titleSize: 15,
                  subtitle: 'Travel outfits',
                  subtitleColor: const Color(0xFF58DCB0),
                  arrowBg: _panel,
                  arrowColor: const Color(0xFF58DCB0),
                  shellColor: _shell,
                  onTap: () => _push(const OccasionBoard(
                    occasion: 'Vacation',
                    title: 'Vacation',
                    subtitle: 'Travel outfits',
                    emptyEmoji: '✈️',
                  )),
                ),
              ),
            ),
            const SizedBox(width: _S.md),
            Expanded(
              child: _StaggeredCard(
                delay: const Duration(milliseconds: 240),
                child: _VCard(
                  fullWidth: false,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF9DCBFF), Color(0xFF77A8FF)],
                  ),
                  shadowColor: const Color(0xFF77A8FF).withValues(alpha: 0.28),
                  badge: null,
                  badgeTextColor: Colors.transparent,
                  badgeBg: Colors.transparent,
                  badgeBorderColor: Colors.transparent,
                  iconBg: _card,
                  iconWidget: const Icon(Icons.auto_awesome_rounded, size: 26, color: Color(0xFF77A8FF)),
                  title: 'Occasion',
                  titleColor: _text,
                  titleSize: 15,
                  subtitle: 'Special events',
                  subtitleColor: const Color(0xFF77A8FF),
                  arrowBg: _card,
                  arrowColor: const Color(0xFF77A8FF),
                  shellColor: _shell,
                  onTap: () => _push(const OccasionBoard(
                    occasion: 'Occasion',
                    title: 'Occasion',
                    subtitle: 'Special events',
                    emptyEmoji: '✨',
                  )),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.md),

        _StaggeredCard(
          delay: const Duration(milliseconds: 240),
          child: _EverythingElseCard(
            gradientStart: const Color(0xFFFFBFDC),
            gradientEnd: const Color(0xFFFF96C7),
            cardColor: _card,
            textColor: _text,
            panelColor: _panel,
            shellColor: _shell,
            onTap: () => _push(const everything_else.Screen4()),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeShellColor;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeShellColor,
    required this.activeTextColor,
    required this.inactiveTextColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: _A.slow,
      value: widget.isActive ? 1.0 : 0.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: _A.spring),
    );
  }

  @override
  void didUpdateWidget(_ToggleButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      if (widget.isActive) {
        _scaleCtrl.forward();
      } else {
        _scaleCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: _A.slow,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.activeShellColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: widget.isActive
              ? [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isActive
                    ? widget.activeTextColor
                    : widget.inactiveTextColor,
              ),
              const SizedBox(width: 7),
              AnimatedDefaultTextStyle(
                duration: _A.slow,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive
                      ? widget.activeTextColor
                      : widget.inactiveTextColor,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Matrix4 _scaleTranslate(double scale, double dy) {
  return Matrix4.translationValues(0.0, dy, 0.0)
    ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
}

class _VCard extends StatefulWidget {
  final bool fullWidth;
  final Gradient gradient;
  final Color shadowColor;
  final String? badge;
  final Color badgeTextColor;
  final Color badgeBg;
  final Color badgeBorderColor;
  final Color iconBg;
  final Widget iconWidget;
  final String title;
  final Color titleColor;
  final double titleSize;
  final String subtitle;
  final Color subtitleColor;
  final Color arrowBg;
  final Color arrowColor;
  final Color shellColor;
  final VoidCallback? onTap;

  const _VCard({
    required this.fullWidth,
    required this.gradient,
    required this.shadowColor,
    required this.badge,
    required this.badgeTextColor,
    required this.badgeBg,
    required this.badgeBorderColor,
    required this.iconBg,
    required this.iconWidget,
    required this.title,
    required this.titleColor,
    this.titleSize = 13.5,
    required this.subtitle,
    required this.subtitleColor,
    required this.arrowBg,
    required this.arrowColor,
    required this.shellColor,
    this.onTap,
  });

  @override
  State<_VCard> createState() => _VCardState();
}

class _VCardState extends State<_VCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  late final AnimationController _iconCtrl;
  late final Animation<double> _iconRotate;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: _A.normal,
    );
    _iconRotate = Tween<double>(begin: 0.0, end: -6 * math.pi / 180).animate(
      CurvedAnimation(parent: _iconCtrl, curve: _A.spring),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _iconCtrl, curve: _A.spring),
    );
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _isHovered = true);
    _iconCtrl.forward();
  }

  void _onExit() {
    setState(() {
      _isHovered = false;
      _isPressed = false;
    });
    _iconCtrl.reverse();
  }

  double get _scale {
    if (_isPressed) return 0.97;
    if (_isHovered) return 1.02;
    return 1.0;
  }

  double get _yOffset => _isHovered && !_isPressed ? -4.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: _A.normal,
          curve: _A.spring,
          width: widget.fullWidth ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 130),
          transform: _scaleTranslate(_scale, _yOffset),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: _isHovered
                    ? math.max(0.0, (widget.fullWidth ? 28 : 20) + 18.0)
                    : (widget.fullWidth ? 28.0 : 20.0),
                offset: Offset(0, widget.fullWidth ? 8 : 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(
              _S.base, _S.base + _S.xs, _S.base, _S.base),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _iconCtrl,
                    builder: (_, child) => Transform.rotate(
                      angle: _iconRotate.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: widget.iconWidget),
                    ),
                  ),
                  const SizedBox(height: _S.sm + _S.xs),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.titleSize,
                      fontWeight: FontWeight.w700,
                      color: widget.titleColor,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: _S.xs),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: widget.subtitleColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: _S.xl),
                ],
              ),
              if (widget.badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.badgeBorderColor),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.badgeTextColor,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: _A.medium,
                  curve: _A.spring,
                  width: 22,
                  height: 22,
                  transform: Matrix4.translationValues(
                      _isHovered ? 2.0 : 0.0, 0.0, 0.0),
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.shellColor : widget.arrowBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: _A.fast,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        key: ValueKey(_isHovered),
                        size: 14,
                        color: _isHovered
                            ? context.themeTokens.textPrimary
                            : widget.arrowColor,
                      ),
                    ),
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

class _EverythingElseCard extends StatefulWidget {
  final Color gradientStart;
  final Color gradientEnd;
  final Color cardColor;
  final Color textColor;
  final Color panelColor;
  final Color shellColor;
  final VoidCallback? onTap;

  const _EverythingElseCard({
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardColor,
    required this.textColor,
    required this.panelColor,
    required this.shellColor,
    this.onTap,
  });

  @override
  State<_EverythingElseCard> createState() => _EverythingElseCardState();
}

class _EverythingElseCardState extends State<_EverythingElseCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _scale {
    if (_isPressed) return 0.97;
    if (_isHovered) return 1.02;
    return 1.0;
  }

  double get _yOffset => _isHovered && !_isPressed ? -4.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: _A.normal,
          curve: _A.spring,
          transform: _scaleTranslate(_scale, _yOffset),
          transformAlignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [widget.gradientStart, widget.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.gradientEnd.withValues(alpha: 0.30),
                blurRadius: _isHovered ? 46 : 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(
              _S.base, _S.base + _S.xs, _S.base, _S.base),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(Icons.explore_rounded,
                      size: 26, color: widget.gradientEnd),
                ),
              ),
              const SizedBox(width: _S.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Everything Else',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: _S.xs - 1),
                    Text(
                      'Outfits for other events',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: widget.gradientEnd,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: _A.medium,
                curve: _A.spring,
                width: 22,
                height: 22,
                transform: Matrix4.translationValues(
                    _isHovered ? 2.0 : 0.0, 0.0, 0.0),
                decoration: BoxDecoration(
                  color: _isHovered ? widget.shellColor : widget.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: _isHovered
                        ? context.themeTokens.textPrimary
                        : widget.gradientEnd,
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

// <-- THE FIX: TickerMode dependency injection ensures these don't run while hidden
class _StaggeredCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _StaggeredCard({required this.child, required this.delay});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _hasStarted = false; // Tracks if animation fired

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _A.entry);
    _opacity = CurvedAnimation(parent: _ctrl, curve: _A.pageEntry);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: _A.pageEntry));
    // REMOVED immediate .forward() call
  }

  // Trigger animation ONLY when TickerMode enables this widget
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context) && !_hasStarted) {
      _hasStarted = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _HoverPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double hoverScale;
  final double pressScale;

  const _HoverPressButton({
    required this.child,
    required this.onTap,
    this.hoverScale = 0.95,
    this.pressScale = 0.90,
  });

  @override
  State<_HoverPressButton> createState() => _HoverPressButtonState();
}

class _HoverPressButtonState extends State<_HoverPressButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _scale {
    if (_isPressed) return widget.pressScale;
    if (_isHovered) return widget.hoverScale;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: _A.fast,
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(_scale, _scale, 1.0),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}