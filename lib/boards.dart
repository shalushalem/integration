// boards.dart — Premium UX Upgrade
// Implements all F1–F12 animations + haptics + iOS scroll + DRY refactor

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/app_localizations.dart';
import 'package:myapp/calendar.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:myapp/daily_wear.dart' as daily_wear;
// ── Master Board Import ──
import 'package:myapp/occasion.dart'; // Handles Daily Wear, Office, Party, Vacation, etc.

// ── Specific Board Imports ──
import 'package:myapp/everything_else.dart' as everything_else;
import 'package:myapp/home_and_utilities.dart' as home_utils;
import 'package:myapp/skincare.dart';
import 'package:myapp/widgets/ahvi_home_text.dart';
import 'package:myapp/diet_fitness.dart' as diet_fitness;
import 'package:myapp/services/appwrite_service.dart';
import 'package:provider/provider.dart';

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
  final Color iconColor;

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
    required this.iconColor,
  });

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  final int _totalPlans = 0;
  final int _todayPlans = 0;

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CalendarShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _GlassCard(
        borderColor: widget.borderColor,
        glow: widget.accent.withValues(alpha: 0.28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _S.base,
            _S.base,
            _S.base,
            _S.base,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openCalendar,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: widget.iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.t(context, 'boards_schedule_calendar'),
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
                          color: widget.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.mutedColor,
                  size: 20,
                ),
              ],
            ),
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
                context.themeTokens.accent.secondary.withValues(alpha: 0.85),
                context.themeTokens.accent.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: context.themeTokens.accent.primary.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 1,
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
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATION CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _A {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration entry = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 600);

  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve pageEntry = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve ease = Curves.easeOutCubic;
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
  Color get _bg2 => _theme.backgroundSecondary;
  Color get _panel => _theme.panel;
  Color get _panelBorder => _theme.panelBorder;
  Color get _card => _theme.card;
  Color get _cardBorder => _theme.cardBorder;
  Color get _text => _theme.textPrimary;
  Color get _muted => _theme.mutedText;
  Color get _accent => _theme.accent.primary;
  Color get _accent2 => _theme.accent.secondary;
  Color get _shell => _theme.phoneShell;
  Color get _cardIconColor => Theme.of(context).brightness == Brightness.light
      ? Colors.black
      : Colors.white;

  bool _isLifeTab = true;
  bool _hasStartedAnimations =
      false; // <-- FIX: Tracks if entry animations fired
  bool _isLoadingDynamicBoards = true;
  String? _dynamicBoardsError;
  List<_DynamicBoardGroup> _lifeBoardGroups = const [];
  List<_DynamicBoardGroup> _styleBoardGroups = const [];

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;

  late final AnimationController _toggleCtrl;
  late final Animation<double> _toggleOpacity;
  late final Animation<Offset> _toggleSlide;

  late final AnimationController _sectionCtrl;
  late final Animation<double> _sectionOpacity;
  late final Animation<Offset> _sectionSlide;

  static const Set<String> _lifeCategoryKeys = <String>{
    'daily wear',
    'dailywear',
    'home',
    'home utilities',
    'homeandutilities',
    'skincare',
    'diet fitness',
    'diet and fitness',
    'fitness',
    'workout',
    'health',
    'med tracker',
    'medicine',
  };

  static const List<List<Color>> _boardGradientPalette = <List<Color>>[
    [Color(0xFFFFB08F), Color(0xFFFF8F72)],
    [Color(0xFFFFE07E), Color(0xFFFFC956)],
    [Color(0xFF9AF0D3), Color(0xFF58DCB0)],
    [Color(0xFF9DCBFF), Color(0xFF77A8FF)],
    [Color(0xFFD2B7FF), Color(0xFFA586FF)],
    [Color(0xFFFFB7D4), Color(0xFFFF8FC4)],
  ];

  static const List<String> _defaultLifeCategories = <String>[
    'Daily Wear',
    'Home Utilities',
    'Skincare',
    'Diet Fitness',
  ];

  static const List<String> _defaultStyleCategories = <String>[
    'Party',
    'Office',
    'Vacation',
    'Occasion',
  ];

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: _A.page);
    _headerOpacity = CurvedAnimation(parent: _headerCtrl, curve: _A.pageEntry);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: _A.pageEntry));

    _toggleCtrl = AnimationController(vsync: this, duration: _A.page);
    _toggleOpacity = CurvedAnimation(parent: _toggleCtrl, curve: _A.pageEntry);
    _toggleSlide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _toggleCtrl, curve: _A.pageEntry));

    _sectionCtrl = AnimationController(vsync: this, duration: _A.slow);
    _sectionOpacity = CurvedAnimation(parent: _sectionCtrl, curve: Curves.ease);
    _sectionSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sectionCtrl, curve: Curves.ease));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasStartedAnimations) return;
      _hasStartedAnimations = true;
      _headerCtrl.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _toggleCtrl.forward();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _sectionCtrl.forward();
      });
    });
    _loadDynamicBoards();
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
        opaque: false,
        transitionDuration: _A.slow,
        reverseTransitionDuration: _A.slow,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          // `secondary` intentionally ignored — boards page stays fully
          // visible behind the incoming screen with no fade-out.
          final curved = CurvedAnimation(
            parent: animation,
            curve: _A.pageEntry,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        maintainState: true,
      ),
    );
  }

  String _normalizeCategory(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isLifeCategory(String category, {String? boardType}) {
    final normalizedType = _normalizeCategory(boardType ?? '');
    if (normalizedType == 'life' || normalizedType == 'life board') {
      return true;
    }
    if (normalizedType == 'style' || normalizedType == 'style board') {
      return false;
    }
    return _lifeCategoryKeys.contains(_normalizeCategory(category));
  }

  String _labelFromCategory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Uncategorized';
    final words = trimmed.split(RegExp(r'\s+'));
    return words
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  IconData _iconForCategory(String category, {required bool isLife}) {
    final normalized = _normalizeCategory(category);
    if (normalized.contains('party')) return Icons.celebration_rounded;
    if (normalized.contains('office')) return Icons.business_center_rounded;
    if (normalized.contains('vacation') || normalized.contains('travel')) {
      return Icons.beach_access_rounded;
    }
    if (normalized.contains('daily')) return Icons.checkroom_rounded;
    if (normalized.contains('home')) return Icons.home_rounded;
    if (normalized.contains('skin')) return Icons.water_drop_rounded;
    if (normalized.contains('diet') || normalized.contains('fitness') || normalized.contains('workout')) {
      return Icons.monitor_heart_rounded;
    }
    return isLife ? Icons.auto_awesome_rounded : Icons.grid_view_rounded;
  }

  Widget _pageForCategory(String category, {required bool isLife}) {
    final normalized = _normalizeCategory(category);
    if (isLife) {
      if (normalized.contains('daily')) return const daily_wear.DailyWearScreen();
      if (normalized.contains('home')) return const home_utils.HomeUtilitiesScreen();
      if (normalized.contains('skin')) return const SkincareScreen();
      if (normalized.contains('diet') || normalized.contains('fitness') || normalized.contains('workout')) {
        return const diet_fitness.DietAndFitnessScreen();
      }
    }
    return OccasionBoard(
      occasion: category,
      titleLabel: _labelFromCategory(category),
      subtitleLabel: '${isLife ? 'Life' : 'Style'} board',
      emptyEmoji: isLife ? '🌿' : '✨',
    );
  }

  _BoardCardConfig _toBoardCardConfig(_DynamicBoardGroup group, int index) {
    final colors = _boardGradientPalette[index % _boardGradientPalette.length];
    return _BoardCardConfig(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      shadowColor: colors[1].withValues(alpha: 0.28),
      iconBg: _panel,
      icon: _iconForCategory(group.category, isLife: group.isLife),
      title: group.label,
      subtitle: '${group.count} saved looks',
      onTap: () => _push(_pageForCategory(group.category, isLife: group.isLife)),
    );
  }

  List<_DynamicBoardGroup> _mergedGroups({
    required List<_DynamicBoardGroup> dynamicGroups,
    required List<String> defaults,
    required bool isLife,
  }) {
    final byKey = <String, _DynamicBoardGroup>{
      for (final group in dynamicGroups) _normalizeCategory(group.category): group,
    };
    for (final category in defaults) {
      final key = _normalizeCategory(category);
      byKey.putIfAbsent(
        key,
        () => _DynamicBoardGroup(
          category: category,
          label: _labelFromCategory(category),
          count: 0,
          isLife: isLife,
        ),
      );
    }
    final merged = byKey.values.toList();
    merged.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return merged;
  }

  Future<void> _loadDynamicBoards() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDynamicBoards = true;
      _dynamicBoardsError = null;
    });

    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final docs = await appwrite.getAllSavedBoards();
      final lifeMap = <String, _DynamicBoardGroup>{};
      final styleMap = <String, _DynamicBoardGroup>{};

      for (final doc in docs) {
        final rawOccasion = (doc.data['occasion'] ?? doc.data['boardType'] ?? '').toString();
        final normalized = _normalizeCategory(rawOccasion);
        if (normalized.isEmpty) continue;
        final boardType = (doc.data['boardType'] ?? doc.data['board_type'] ?? '').toString();
        final isLife = _isLifeCategory(rawOccasion, boardType: boardType);
        final targetMap = isLife ? lifeMap : styleMap;
        final existing = targetMap[normalized];
        if (existing == null) {
          targetMap[normalized] = _DynamicBoardGroup(
            category: rawOccasion.trim(),
            label: _labelFromCategory(rawOccasion),
            count: 1,
            isLife: isLife,
          );
        } else {
          targetMap[normalized] = existing.copyWith(count: existing.count + 1);
        }
      }

      List<_DynamicBoardGroup> sortGroups(Map<String, _DynamicBoardGroup> source) {
        final list = source.values.toList();
        list.sort((a, b) {
          final byCount = b.count.compareTo(a.count);
          if (byCount != 0) return byCount;
          return a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });
        return list;
      }

      if (!mounted) return;
      setState(() {
        _lifeBoardGroups = sortGroups(lifeMap);
        _styleBoardGroups = sortGroups(styleMap);
        _isLoadingDynamicBoards = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingDynamicBoards = false;
        _dynamicBoardsError = AppLocalizations.t(context, 'error');
      });
    }
  }

  Widget _buildBoardCard(
    _BoardCardConfig config, {
    required bool fullWidth,
    required int delayMs,
  }) {
    return _StaggeredCard(
      delay: Duration(milliseconds: delayMs),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: _VCard(
              fullWidth: fullWidth,
              gradient: config.gradient,
              shadowColor: config.shadowColor,
              badge: null,
              badgeTextColor: Colors.transparent,
              badgeBg: Colors.transparent,
              badgeBorderColor: Colors.transparent,
              iconBg: config.iconBg,
              iconWidget: Icon(config.icon, size: 26, color: _cardIconColor),
              title: config.title,
              titleColor: Colors.white,
              titleSize: 15,
              subtitle: config.subtitle,
              subtitleColor: Colors.white,
              arrowBg: config.iconBg,
              arrowColor: _cardIconColor,
              shellColor: _shell,
              onTap: config.onTap,
            ),
          ),
          if (config.onDelete != null)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: config.onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnBoardGrid(
    List<_BoardCardConfig> cards, {
    int startDelayMs = 80,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    var cardIndex = 0;

    while (cardIndex < cards.length) {
      final remaining = cards.length - cardIndex;

      if (remaining == 1) {
        rows.add(
          _buildBoardCard(
            cards[cardIndex],
            fullWidth: true,
            delayMs: startDelayMs + (cardIndex * 80),
          ),
        );
        cardIndex += 1;
      } else {
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildBoardCard(
                  cards[cardIndex],
                  fullWidth: false,
                  delayMs: startDelayMs + (cardIndex * 80),
                ),
              ),
              const SizedBox(width: _S.md),
              Expanded(
                child: _buildBoardCard(
                  cards[cardIndex + 1],
                  fullWidth: false,
                  delayMs: startDelayMs + ((cardIndex + 1) * 80),
                ),
              ),
            ],
          ),
        );
        cardIndex += 2;
      }

      if (cardIndex < cards.length) {
        rows.add(const SizedBox(height: _S.md));
      }
    }

    return Column(children: rows);
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
                    20,
                    _S.xs,
                    20,
                    132,
                  ),
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
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
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

  // _buildCreateBoardOverlay removed — now uses showDialog via _openCreateBoardDialog

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
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
          child: AhviHomeText(
            color: _text,
            fontSize: 30.0,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w400,
          ),
        ),
        Row(
          children: [
            Text(
              AppLocalizations.t(context, 'boards_planner'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -0.8,
                color: _text,
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.sm),
        Text(
          AppLocalizations.t(context, 'boards_life_tagline'),
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
              label: AppLocalizations.t(context, 'boards_life'),
              icon: Icons.auto_awesome_rounded,
              isActive: _isLifeTab,
              activeShellColor: _text,
              activeTextColor: _theme.backgroundPrimary,
              inactiveTextColor: _muted,
              accentColor: _accent,
              onTap: () => _switchTab(true),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: AppLocalizations.t(context, 'boards_boards'),
              icon: Icons.grid_view_rounded,
              isActive: !_isLifeTab,
              activeShellColor: _text,
              activeTextColor: _theme.backgroundPrimary,
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
    final mergedLifeGroups = _mergedGroups(
      dynamicGroups: _lifeBoardGroups,
      defaults: _defaultLifeCategories,
      isLife: true,
    );
    final lifeCards = mergedLifeGroups
        .asMap()
        .entries
        .map((entry) => _toBoardCardConfig(entry.value, entry.key))
        .toList();

    return Column(
      children: [
        _StaggeredCard(
          delay: const Duration(milliseconds: 100),
          child: CalendarCard(
            cardColor: _card,
            borderColor: _cardBorder,
            panelColor: _panel,
            panelBorder: _panelBorder,
            textColor: Colors.white,
            mutedColor: _muted,
            accent: const Color(0xFFB48EFF),
            accentSoft: const Color(0xFFD4B8FF),
            shellColor: _shell,
            iconColor: _cardIconColor,
          ),
        ),
        const SizedBox(height: _S.md),
        if (_isLoadingDynamicBoards)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_dynamicBoardsError != null)
          _InlineInfoCard(
            message: _dynamicBoardsError!,
            muted: _muted,
            borderColor: _cardBorder,
            panelColor: _panel,
            onRetry: _loadDynamicBoards,
          )
        else
          _buildTwoColumnBoardGrid(lifeCards, startDelayMs: 140),
      ],
    );
  }

  Widget _buildBoardsSection() {
    final mergedStyleGroups = _mergedGroups(
      dynamicGroups: _styleBoardGroups,
      defaults: _defaultStyleCategories,
      isLife: false,
    );
    final styleCards = mergedStyleGroups
        .asMap()
        .entries
        .map((entry) => _toBoardCardConfig(entry.value, entry.key))
        .toList();

    return Column(
      children: [
        if (_isLoadingDynamicBoards)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_dynamicBoardsError != null)
          _InlineInfoCard(
            message: _dynamicBoardsError!,
            muted: _muted,
            borderColor: _cardBorder,
            panelColor: _panel,
            onRetry: _loadDynamicBoards,
          )
        else ...[
          _buildTwoColumnBoardGrid(styleCards, startDelayMs: 100),
          const SizedBox(height: _S.md),
        ],
        _StaggeredCard(
          delay: const Duration(milliseconds: 320),
          child: _EverythingElseCard(
            gradientStart: const Color(0xFFFFBFDC),
            gradientEnd: const Color(0xFFFF96C7),
            cardColor: _card,
            textColor: Colors.white,
            iconColor: _cardIconColor,
            panelColor: _panel,
            shellColor: _shell,
            onTap: () => _push(const everything_else.EverythingElseScreen()),
          ),
        ),
      ],
    );
  }
}

class _BoardCardConfig {
  final Gradient gradient;
  final Color shadowColor;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _BoardCardConfig({
    required this.gradient,
    required this.shadowColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onDelete,
  });
}

class _DynamicBoardGroup {
  final String category;
  final String label;
  final int count;
  final bool isLife;

  const _DynamicBoardGroup({
    required this.category,
    required this.label,
    required this.count,
    required this.isLife,
  });

  _DynamicBoardGroup copyWith({
    String? category,
    String? label,
    int? count,
    bool? isLife,
  }) {
    return _DynamicBoardGroup(
      category: category ?? this.category,
      label: label ?? this.label,
      count: count ?? this.count,
      isLife: isLife ?? this.isLife,
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  final String message;
  final Color muted;
  final Color borderColor;
  final Color panelColor;
  final VoidCallback onRetry;

  const _InlineInfoCard({
    required this.message,
    required this.muted,
    required this.borderColor,
    required this.panelColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
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
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: _A.spring));
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
          color: widget.isActive ? widget.activeShellColor : Colors.transparent,
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
  final double minHeight;
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
    this.minHeight = 130,
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
    _iconCtrl = AnimationController(vsync: this, duration: _A.normal);
    _iconRotate = Tween<double>(
      begin: 0.0,
      end: -6 * math.pi / 180,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: _A.spring));
    _iconScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: _A.spring));
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
          constraints: BoxConstraints(minHeight: widget.minHeight),
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
            _S.base,
            _S.base + _S.xs,
            _S.base,
            _S.base,
          ),
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
                      horizontal: 7,
                      vertical: 2,
                    ),
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
                    _isHovered ? 2.0 : 0.0,
                    0.0,
                    0.0,
                  ),
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
  final Color iconColor;
  final Color panelColor;
  final Color shellColor;
  final VoidCallback? onTap;

  const _EverythingElseCard({
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardColor,
    required this.textColor,
    required this.iconColor,
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
            _S.base,
            _S.base + _S.xs,
            _S.base,
            _S.base,
          ),
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
                  child: Icon(
                    Icons.explore_rounded,
                    size: 26,
                    color: widget.iconColor,
                  ),
                ),
              ),
              const SizedBox(width: _S.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.t(context, 'boards_everything_else'),
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
                      AppLocalizations.t(context, 'boards_everything_else_sub'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Colors.white,
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
                  _isHovered ? 2.0 : 0.0,
                  0.0,
                  0.0,
                ),
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
                        : widget.iconColor,
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

// Staggered entrance animation used for board cards.
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
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _A.entry);
    _opacity = CurvedAnimation(parent: _ctrl, curve: _A.pageEntry);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: _A.pageEntry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasStarted) return;
      _hasStarted = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _HoverPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  // ignore: unused_element_parameter
  final double hoverScale;
  final double pressScale;

  const _HoverPressButton({
    required this.child,
    required this.onTap,
    this.hoverScale = 1.05,
    this.pressScale = 0.95,
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
// ── Create Board Dialog ────────────────────────────────────────────────────────
class _CreateBoardDialog extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final Color card;
  final Color cardBorder;
  final Color text;
  final Color muted;
  final VoidCallback onSubmit;

  const _CreateBoardDialog({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.card,
    required this.cardBorder,
    required this.text,
    required this.muted,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use explicit opaque colors so dialog never bleeds background cards through
    final dialogBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final inputFill = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F3F7);

    return Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.t(context, 'boards_create_own'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.t(context, 'boards_create_own_sub'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: muted,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: text),
                decoration: InputDecoration(
                  labelText: AppLocalizations.t(context, 'boards_name_it'),
                  labelStyle: TextStyle(fontFamily: 'Inter', color: muted, fontSize: 13),
                  hintText: AppLocalizations.t(context, 'boards_enter_name'),
                  hintStyle: TextStyle(fontFamily: 'Inter', color: muted),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: Text(
                      AppLocalizations.t(context, 'common_cancel'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: onSubmit,
                    child: Text(
                      AppLocalizations.t(context, 'common_create'),
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
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
