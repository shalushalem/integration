import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data'; 

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/boards.dart';
import 'package:myapp/profile.dart' as profile;
import 'package:myapp/wardrobe.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/appwrite_service.dart'; 
import 'package:myapp/services/backend_service.dart'; 

// ─── Colors ──────────────────────────────────────────────

const _homeNavItems = <({IconData icon, String label})>[
  (icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
  (icon: Icons.dry_cleaning_outlined, label: 'Wardrobe'),
  (icon: Icons.search_rounded, label: 'Lens'),
  (icon: Icons.grid_view_rounded, label: 'Boards'),
  (icon: Icons.explore_outlined, label: 'Explore'),
];

Color _accent(AppThemeTokens t) => t.accent.primary;
Color _accentSecondary(AppThemeTokens t) => t.accent.secondary;
Color _accentTertiary(AppThemeTokens t) => t.accent.tertiary;

const _aiSuggestions = [
  "Your 2pm meeting is in 4 hrs — want to prep an outfit?",
  "It's 14°C and partly cloudy — shall I suggest a layered look?",
  "You haven't planned your week yet — want me to help?",
  "Feeling indecisive? I can style you in seconds.",
  "New drops match your saved style — want to see them?",
  "Your Friday dinner is coming up — let's plan the look.",
  "I noticed you love minimal styles — new picks are in.",
];

class Screen4 extends StatefulWidget {
  const Screen4({super.key});
  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> with TickerProviderStateMixin {
  AppThemeTokens get _t => context.themeTokens;
  Color get _bgPrimary => _t.backgroundPrimary;
  Color get _bgSecondary => _t.backgroundSecondary;
  Color get _surface => _t.phoneShellInner;
  Color get _textHeading => _t.textPrimary;
  Color get _textSub => _t.mutedText;
  Color get _textMuted => _t.mutedText;
  Color get _accent => _t.accent.primary;
  Color get _accentSecondary => _t.accent.secondary;
  Color get _accentTertiary => _t.accent.tertiary;
  Color get _panel => _t.panel;
  Color get _card => _t.card;
  Color get _phoneShell => _t.phoneShell;
  Color get _tileText => _t.tileText;
  Color get _shadowStrong => _bgPrimary.withValues(alpha: 0.35);
  Color get _shadowMedium => _bgPrimary.withValues(alpha: 0.20);
  Color get _shadowLight => _bgPrimary.withValues(alpha: 0.12);
  Color get _transparent => _bgPrimary.withValues(alpha: 0.0);
  Color get _onAccent => Theme.of(context).colorScheme.onPrimary;
  Color get _border => _t.cardBorder;
  LinearGradient get _accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_accent, _accentTertiary],
      );
  LinearGradient get _accentGradient2 => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_accent, _accentSecondary],
      );

  late AnimationController _aurora1Ctrl;
  late AnimationController _aurora2Ctrl;
  late AnimationController _aurora3Ctrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  int _activeNavIdx = 0;

  late AnimationController _floatBadgeCtrl;
  late AnimationController _breatheCtrl;
  late List<AnimationController> _heartPopCtrls;
  final List<bool> _likedState = [false, false, true, false];

  int _suggestionIdx = 0;
  double _suggestionOpacity = 1.0;
  Timer? _suggestionTimer;

  bool _micActive = false;
  late AnimationController _micGlowCtrl;

  bool _lensSheetOpen = false;
  late AnimationController _lensSheetCtrl;

  bool _toastVisible = false;
  Timer? _toastTimer;

  bool _pickSheetOpen = false;
  String _pickSheetName = '';
  String _pickSheetTag = '';
  late AnimationController _pickSheetCtrl;

  bool _seeAllOpen = false;
  late AnimationController _seeAllCtrl;

  late List<AnimationController> _navRiseCtrls;

  String _greetingWord = 'Morning';
  String _dateString = '';
  Timer? _clockTimer;

  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  bool _chatHasText = false;

  _OverlayState _overlayState = _OverlayState.idle;
  String? _activeIntent;
  String _chatPlaceholder = 'Ask AHVI anything…';
  bool _homeCollapsed = false;
  late AnimationController _homeCollapseCtrl;
  late AnimationController _overlayFadeCtrl;
  late AnimationController _thinkingCtrl;
  late AnimationController _tagsRevealCtrl;
  List<String> _overlaySuggestions = [];
  String _overlayBrandSub = '';
  _ResponseData? _responseData;
  List<String> _responseTags = [];
  bool _tagsRevealed = false;

  String _userName = '...';
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();

    _aurora1Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _aurora2Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat(reverse: true);
    _aurora3Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 22))
          ..repeat(reverse: true);
    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);

    _floatBadgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _heartPopCtrls = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );

    _micGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pickSheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _seeAllCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _lensSheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _navRiseCtrls = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
        value: i == 0 ? 1.0 : 0.0,
      ),
    );

    _suggestionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() => _suggestionOpacity = 0.0);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _suggestionIdx = (_suggestionIdx + 1) % _aiSuggestions.length;
          _suggestionOpacity = 1.0;
        });
      });
    });

    _homeCollapseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _overlayFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _thinkingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _tagsRevealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));

    _chatController.addListener(() {
      final hasText = _chatController.text.trim().isNotEmpty;
      if (hasText != _chatHasText) setState(() => _chatHasText = hasText);
    });

    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _updateClock());

    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    final user = await appwrite.getCurrentUser();

    if (user != null && mounted) {
      final firstName =
          user.name.isNotEmpty ? user.name.split(' ').first : 'Stylist';
      final avatar = await appwrite.getUserAvatar(user.name);

      setState(() {
        _userName = firstName;
        _avatarBytes = avatar;
      });
    }
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String greeting;
    if (now.hour >= 5 && now.hour < 12) {
      greeting = 'Morning';
    } else if (now.hour >= 12 && now.hour < 17) {
      greeting = 'Afternoon';
    } else if (now.hour >= 17 && now.hour < 21) {
      greeting = 'Evening';
    } else {
      greeting = 'Night';
    }
    setState(() {
      _greetingWord = greeting;
      _dateString = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
    });
  }

  @override
  void dispose() {
    _aurora1Ctrl.dispose();
    _aurora2Ctrl.dispose();
    _aurora3Ctrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _floatBadgeCtrl.dispose();
    _breatheCtrl.dispose();
    for (final c in _heartPopCtrls) {
      c.dispose();
    }
    _micGlowCtrl.dispose();
    _pickSheetCtrl.dispose();
    _seeAllCtrl.dispose();
    _lensSheetCtrl.dispose();
    for (final c in _navRiseCtrls) {
      c.dispose();
    }
    _homeCollapseCtrl.dispose();
    _overlayFadeCtrl.dispose();
    _thinkingCtrl.dispose();
    _tagsRevealCtrl.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _suggestionTimer?.cancel();
    _toastTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _showComingSoon() {
    setState(() => _toastVisible = true);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  void _handleNavTap(int idx) {
    if (idx == 0) {
      if (idx == _activeNavIdx) return;
      _navRiseCtrls[_activeNavIdx]
          .animateTo(0.0, curve: const Cubic(0.4, 0.0, 0.2, 1.0));
      _navRiseCtrls[idx]
          .animateTo(1.0, curve: const Cubic(0.34, 1.56, 0.64, 1.0));
      setState(() => _activeNavIdx = idx);
      return;
    }
    if (idx == 1) {
      _openNavScreen(const WardrobeScreen());
      return;
    }
    if (idx == 2) {
      _openLensSheet();
      return;
    }
    if (idx == 3) {
      _openNavScreen(const BoardsScreen());
      return;
    }
    if (idx == 4) {
      _showComingSoon();
      return;
    }
    if (idx == _activeNavIdx) return;

    _navRiseCtrls[_activeNavIdx]
        .animateTo(0.0, curve: const Cubic(0.4, 0.0, 0.2, 1.0));
    _navRiseCtrls[idx]
        .animateTo(1.0, curve: const Cubic(0.34, 1.56, 0.64, 1.0));

    setState(() => _activeNavIdx = idx);
  }

  void _openLensSheet() {
    setState(() => _lensSheetOpen = true);
    _lensSheetCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 420),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0));
  }

  void _closeLensSheet() {
    _lensSheetCtrl.reverse().then((_) {
      if (mounted) setState(() => _lensSheetOpen = false);
    });
  }

  void _openNavScreen(Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondary) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.22, 1.0, 0.36, 1.0),
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
      ),
    );
  }

  void _openPickSheet(String name, String tag) {
    setState(() {
      _pickSheetOpen = true;
      _pickSheetName = name;
      _pickSheetTag = tag;
    });
    _pickSheetCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 480),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0));
  }

  void _closePickSheet() {
    _pickSheetCtrl
        .animateTo(0.0,
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(0.4, 0.0, 1.0, 1.0))
        .then((_) {
      if (mounted) setState(() => _pickSheetOpen = false);
    });
  }

  void _openSeeAll() {
    setState(() => _seeAllOpen = true);
    _seeAllCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 400),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0));
  }

  void _closeSeeAll() {
    _seeAllCtrl
        .animateTo(0.0,
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.4, 0.0, 1.0, 1.0))
        .then((_) {
      if (mounted) setState(() => _seeAllOpen = false);
    });
  }

  void _toggleLike(int cardIdx) {
    setState(() => _likedState[cardIdx] = !_likedState[cardIdx]);
    _heartPopCtrls[cardIdx]
      ..reset()
      ..forward();
  }

  void _triggerIntent(String intent) {
    if (_overlayState != _OverlayState.idle) return;
    _activeIntent = intent;
    final cfg = _intentConfig[intent]!;
    _setPlaceholder(intent);
    setState(() {
      _homeCollapsed = true;
      _overlayBrandSub = cfg.brandSub;
    });
    _homeCollapseCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 600),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0));
    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() {
        _overlayState = _OverlayState.suggestions;
        _overlaySuggestions = cfg.suggestions;
        _responseData = null;
        _tagsRevealed = false;
      });
      _overlayFadeCtrl.animateTo(1.0,
          duration: const Duration(milliseconds: 380),
          curve: const Cubic(0.16, 1.0, 0.3, 1.0));
    });
  }

  void _submitQuery(String query) {
    if (query.isEmpty && _overlayState == _OverlayState.idle) {
      _triggerIntent('chat');
      return;
    }
    if (_overlayState == _OverlayState.idle) {
      _activeIntent = 'chat';
      final cfg = _intentConfig['chat']!;
      _setPlaceholder('chat');
      setState(() {
        _homeCollapsed = true;
        _overlayBrandSub = cfg.brandSub;
      });
      _homeCollapseCtrl.animateTo(1.0,
          duration: const Duration(milliseconds: 600),
          curve: const Cubic(0.16, 1.0, 0.3, 1.0));
      Future.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        setState(() {
          _overlayState = _OverlayState.suggestions;
          _overlaySuggestions = cfg.suggestions;
          _responseData = null;
          _tagsRevealed = false;
        });
        _overlayFadeCtrl.animateTo(1.0,
            duration: const Duration(milliseconds: 380),
            curve: const Cubic(0.16, 1.0, 0.3, 1.0));
        if (query.isNotEmpty) _handleQuery(query, 'chat');
      });
    } else if (_overlayState == _OverlayState.suggestions) {
      _handleQuery(query, _activeIntent ?? 'chat');
    } else if (_overlayState == _OverlayState.response) {
      // Allow continuous chatting from the response screen!
      _handleQuery(query, _activeIntent ?? 'chat');
    }
  }

  Future<void> _handleQuery(String question, String intent) async {
    if (_overlayState == _OverlayState.thinking) return;

    final cfg = _intentConfig[intent] ?? _intentConfig['chat']!;
    
    setState(() {
      _overlayState = _OverlayState.thinking;
      _overlaySuggestions = [];
      _responseTags = cfg.responseTags;
    });

    _ResponseData? resp = _responseMap[question];

    if (resp == null) {
      try {
        final backend = Provider.of<BackendService>(context, listen: false);
        final apiResult = await backend.sendChatQuery(question, 'user_$_userName');
        
        String aiText = "Could not parse response.";
        if (apiResult.containsKey('message') && apiResult['message'] != null) {
             aiText = apiResult['message']['content'] ?? "No content";
        } else if (apiResult.containsKey('error')) {
             aiText = apiResult['error'];
        }

        // 1. STRIP BACKEND TAGS FROM THE TEXT UI
        aiText = aiText.replaceAll(RegExp(r'\[CHIPS:.*?\]', caseSensitive: false), '');
        aiText = aiText.replaceAll(RegExp(r'\[STYLE_BOARD:.*?\]', caseSensitive: false), '');
        aiText = aiText.replaceAll(RegExp(r'\[PACK_LIST:.*?\]', caseSensitive: false), '');
        aiText = aiText.trim();

        // 2. OVERRIDE THE UI BUTTONS WITH DYNAMIC CHIPS
        if (apiResult.containsKey('chips') && apiResult['chips'] is List) {
          final List<dynamic> rawChips = apiResult['chips'];
          if (rawChips.isNotEmpty) {
            _responseTags = rawChips.map((e) => e.toString()).toList();
          }
        }

        resp = _ResponseData(
          type: 'text',
          question: question,
          intro: aiText,
        );
      } catch (e) {
        resp = _ResponseData(
          type: 'text',
          question: question,
          intro: "Sorry, I couldn't reach the Python backend. Make sure the server is running.\nError: $e",
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _overlayState = _OverlayState.response;
      _responseData = resp;
    });

    final tagDelay = resp!.type == 'outfits'
        ? 600
        : resp.type == 'week'
            ? 800
            : resp.type == 'plan'
                ? 700
                : resp.type == 'tasks'
                    ? 600
                    : 900;
                    
    Future.delayed(Duration(milliseconds: tagDelay), () {
      if (!mounted) return;
      setState(() => _tagsRevealed = true);
      _tagsRevealCtrl.animateTo(1.0,
          duration: const Duration(milliseconds: 380),
          curve: const Cubic(0.16, 1.0, 0.3, 1.0));
    });
  }

  void _dismissOverlay() {
    _overlayFadeCtrl.animateTo(0.0,
        duration: const Duration(milliseconds: 300),
        curve: const Cubic(0.4, 0.0, 1.0, 1.0));
    _homeCollapseCtrl.animateTo(0.0,
        duration: const Duration(milliseconds: 500),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0));
    _chatFocusNode.unfocus();
    setState(() {
      _overlayState = _OverlayState.idle;
      _activeIntent = null;
      _homeCollapsed = false;
      _overlaySuggestions = [];
      _responseData = null;
      _tagsRevealed = false;
      _chatPlaceholder = 'Ask AHVI anything…';
    });
  }

  void _setPlaceholder(String intent) {
    setState(() =>
        _chatPlaceholder = _intentPlaceholder[intent] ?? 'Ask AHVI anything…');
  }

  bool get _hasTransientUi =>
      _lensSheetOpen ||
      _pickSheetOpen ||
      _seeAllOpen ||
      _overlayState != _OverlayState.idle;

  void _handleBackNavigation() {
    if (_lensSheetOpen) {
      _closeLensSheet();
      return;
    }
    if (_pickSheetOpen) {
      _closePickSheet();
      return;
    }
    if (_seeAllOpen) {
      _closeSeeAll();
      return;
    }
    if (_overlayState != _OverlayState.idle) {
      _dismissOverlay();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasTransientUi,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: _bgPrimary,
        body: _buildPhoneScreen(),
      ),
    );
  }

  Widget _buildPhoneScreen() {
    return Container(
      decoration: BoxDecoration(color: _bgPrimary),
      child: Stack(
        children: [
          _buildAuroraLayer(),

          AnimatedBuilder(
            animation: _homeCollapseCtrl,
            builder: (context, child) {
              final curve = CurvedAnimation(
                parent: _homeCollapseCtrl,
                curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                reverseCurve: const Cubic(0.4, 0.0, 1.0, 1.0),
              );
              final t = curve.value;
              return Transform.translate(
                offset: Offset(0, -48 * t),
                child: Transform.scale(
                  scale: 1.0 - 0.02 * t,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child:
                        IgnorePointer(ignoring: _homeCollapsed, child: child),
                  ),
                ),
              );
            },
            child: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            _buildGreetingBlock(),
                            _buildPromptChipsRow(),
                            const SizedBox(height: 16),
                            _buildHeroCard(),
                            const SizedBox(height: 16),
                            _buildSecondaryRow(),
                            _buildSectionHead(),
                            _buildPicksStrip(),
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_overlayState != _OverlayState.idle) _buildAiOverlay(),

          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: _buildChatWrap(),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomNav(),
          ),

          if (_pickSheetOpen) _buildPickSheet(),
          if (_seeAllOpen) _buildSeeAllPanel(),
          if (_lensSheetOpen) _buildLensSheet(),
          _buildComingSoonToast(),
        ],
      ),
    );
  }

  Widget _buildAuroraLayer() {
    return Positioned.fill(
      child: RepaintBoundary(
        child: ClipRect(
          child: AnimatedBuilder(
            animation:
                Listenable.merge([_aurora1Ctrl, _aurora2Ctrl, _aurora3Ctrl]),
            builder: (context, _) {
              final t1 = _aurora1Ctrl.value;
              final t2 = _aurora2Ctrl.value;
              final t3 = _aurora3Ctrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (t1 * 90),
                    left: -80 + (t1 * 60),
                    child: _auroraOrb(
                        340, 340, _accent.withValues(alpha: 0.30)),
                  ),
                  Positioned(
                    bottom: -60 + (t2 * 60),
                    right: -60 + (t2 * 30),
                    child: _auroraOrb(
                        300, 300, _accentSecondary.withValues(alpha: 0.34)),
                  ),
                  Positioned(
                    top: 300 + (t3 * -60),
                    left: -40 + (t3 * 100),
                    child: _auroraOrb(
                        220, 220, _accentTertiary.withValues(alpha: 0.22)),
                  ),
                  Positioned(
                    top: 140 + (t1 * 80),
                    right: -30,
                    child: _auroraOrb(
                        180, 180, _accent.withValues(alpha: 0.18)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _auroraOrb(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AHVI',
            style: GoogleFonts.bebasNeue(
              color: _textHeading,
              fontSize: 36,
              fontWeight: FontWeight.w400,
              letterSpacing: 3.2,
            ),
          ),
          _buildProfileAvatar(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, animation, secondary) =>
                const profile.Screen4(),
            transitionsBuilder: (context, animation, secondary, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: const Cubic(0.22, 1.0, 0.36, 1.0),
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
          ),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _panel,
          border: Border.all(
            color: _accent.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _shadowMedium,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _avatarBytes == null
            ? Container(color: t.panel)
            : Image.memory(
                _avatarBytes!,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildGreetingBlock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateString.isEmpty ? 'Fri, 6 Mar' : _dateString,
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: _textHeading,
                letterSpacing: -0.56,
                height: 1.1,
              ),
              children: [
                TextSpan(text: '$_greetingWord, '),
                WidgetSpan(
                    child: _GradientText('$_userName.',
                        fontSize: 28, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _AnimatedPressable(
            liftY: -1.5,
            scalePressed: 0.98,
            onTap: () => _submitQuery(''),
            child: Container(
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(color: _shadowMedium, blurRadius: 10)
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _accent.withValues(alpha: 0.15),
                          _accentTertiary.withValues(alpha: 0.15)
                        ],
                      ),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (b) => _accentGradient.createShader(b),
                        child: Icon(Icons.auto_awesome,
                            color: _textHeading, size: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _suggestionOpacity,
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        _aiSuggestions[_suggestionIdx],
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: _accent.withValues(alpha: 0.65), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChipsRow() {
    final chips = [
      ('✦', 'Outfit idea', 'Suggest an outfit for today'),
      ('◎', 'Daily plan', 'Plan my day'),
      ('⊹', 'Workout', 'What workout should I do today?'),
      ('◈', 'Meal plan', 'Suggest a meal plan for this week'),
      ('◷', 'Schedule', "What's on my schedule today?"),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (_, i2) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return _AnimatedPressable(
            liftY: -2.0,
            scalePressed: 0.95,
            onTap: () => _submitQuery(chips[i].$3),
            child: Container(
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(color: _shadowMedium, blurRadius: 8),
                  BoxShadow(
                      color: _accent.withValues(alpha: 0.06), blurRadius: 8),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => _accentGradient.createShader(b),
                    child: Text(
                      chips[i].$1,
                      style: TextStyle(color: _textHeading, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    chips[i].$2,
                    style: TextStyle(
                      color: _textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.01,
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

  Widget _buildHeroCard() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation:
            Listenable.merge([_shimmerCtrl, _breatheCtrl, _floatBadgeCtrl]),
        builder: (context, _) {
          final breatheOpacity = 0.14 + 0.12 * _breatheCtrl.value;
          final badgeOffset = -2.5 * math.sin(_floatBadgeCtrl.value * math.pi);

          return _CardPressable(
            onTap: () => _triggerIntent('style'),
            builder: (_) => Container(
              height: 224,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: _surface,
                border: Border.all(
                    color: _accent.withValues(alpha: 0.20), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: _shadowStrong,
                      blurRadius: 56,
                      offset: Offset(0, 16)),
                  BoxShadow(
                      color: _shadowMedium,
                      blurRadius: 16,
                      offset: Offset(0, 4)),
                  BoxShadow(
                      color: _accent.withValues(alpha: 0.12), blurRadius: 30),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.8, 0.1),
                          radius: 1.2,
                          colors: [
                            _accentSecondary.withValues(alpha: 0.20),
                            _transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: _accent.withValues(alpha: breatheOpacity),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _transparent,
                            _accent.withValues(
                                alpha: 0.6 *
                                    (0.5 +
                                        0.5 *
                                            math.sin(_shimmerCtrl.value *
                                                math.pi *
                                                2))),
                            _accentTertiary.withValues(alpha: 0.55),
                            _transparent,
                          ],
                          stops: const [0.0, 0.28, 0.60, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 224,
                    child: Stack(
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=420&h=450&fit=crop&crop=top&auto=format',
                          width: 224,
                          height: 224,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          cacheWidth:
                              (224 * MediaQuery.of(context).devicePixelRatio)
                                  .round(),
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, ___) => Container(
                            color: _accent.withValues(alpha: 0.1),
                            child: Icon(Icons.image, color: _textMuted),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [_surface, _transparent],
                                stops: const [0.75, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 18 + badgeOffset,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: _accentTertiary.withValues(alpha: 0.35),
                            width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: _accentTertiary.withValues(alpha: 0.20),
                              blurRadius: 8),
                        ],
                      ),
                      child: Text(
                        'New Drops',
                        style: TextStyle(
                          color: _accentTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 220,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Stylist',
                                style: TextStyle(
                                  color: _accent.withValues(alpha: 0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ShaderMask(
                                shaderCallback: (b) =>
                                    _accentGradient.createShader(b),
                                child: Text(
                                  'Style',
                                  style: TextStyle(
                                    color: _textHeading,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -1.05,
                                    height: 0.93,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create outfits that feel like you.',
                                style: TextStyle(
                                  color: _textSub.withValues(alpha: 0.80),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                          _AnimatedPressable(
                            liftY: -2.0,
                            scalePressed: 0.95,
                            onTap: () => _triggerIntent('style'),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _accentGradient,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                      color: _accent.withValues(alpha: 0.40),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6)),
                                  BoxShadow(
                                      color: _accentTertiary.withValues(
                                          alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 17, vertical: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Start styling',
                                    style: TextStyle(
                                      color: _onAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.36,
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: _onAccent, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildSecondaryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: _buildSecCard(
            icon: Icons.grid_view_rounded,
            title: 'Organize',
            subtitle: 'Everything you already own',
            accentColor: _accent,
            intent: 'organize',
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _buildSecCard(
            icon: Icons.calendar_month_outlined,
            title: 'Plan',
            subtitle: 'Trips, events, daily plans',
            accentColor: _accentSecondary,
            intent: 'prepare',
          )),
        ],
      ),
    );
  }

  Widget _buildSecCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required String intent,
  }) {
    return _CardPressable(
      onTap: () => _triggerIntent(intent),
      builder: (isHovered) {
        return Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_surface, _bgSecondary],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: _shadowMedium,
                blurRadius: isHovered ? 52 : 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _accent.withValues(alpha: isHovered ? 0.15 : 0.05),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                          alpha: isHovered ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.15), width: 1),
                    ),
                    child: Icon(
                      icon,
                      color: isHovered ? _accent : _textMuted,
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: _textHeading,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: isHovered ? 0.18 : 0.06),
                    border: Border.all(
                      color: _accent.withValues(alpha: isHovered ? 0.30 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Transform.translate(
                    offset: Offset(isHovered ? 2.0 : 0.0, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isHovered ? _accent : _textMuted,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHead() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "Today's Picks",
                style: TextStyle(
                  color: _textHeading,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.18), width: 1),
                ),
                child: Text(
                  'AI Curated',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _openSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                  color: _textMuted, fontSize: 12, letterSpacing: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicksStrip() {
    final picks = [
      (
        'Minimal Chic',
        'Casual · Today',
        'https://images.unsplash.com/photo-1594938298603-c8148c4b9c2b?w=220&h=260&fit=crop&crop=top&auto=format'
      ),
      (
        'Street Edit',
        'Urban · Weekend',
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=220&h=260&fit=crop&crop=top&auto=format'
      ),
      (
        'Office Look',
        'Smart · Monday',
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=220&h=260&fit=crop&crop=top&auto=format'
      ),
      (
        'Evening',
        'Party · Dinner',
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=220&h=260&fit=crop&crop=top&auto=format'
      ),
    ];
    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: picks.length,
        separatorBuilder: (_, i2) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return _buildPickCard(
            cardIdx: i,
            name: picks[i].$1,
            tag: picks[i].$2,
            imageUrl: picks[i].$3,
            liked: _likedState[i],
          );
        },
      ),
    );
  }

  Widget _buildPickCard({
    required int cardIdx,
    required String name,
    required String tag,
    required String imageUrl,
    required bool liked,
  }) {
    return _AnimatedPressable(
      liftY: -4.0,
      scaleHover: 1.03,
      scalePressed: 0.97,
      onTap: () => _openPickSheet(name, tag),
      child: Container(
        width: 112,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_surface, _bgSecondary],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
                color: _shadowMedium, blurRadius: 20, offset: Offset(0, 6)),
            BoxShadow(
                color: _shadowLight, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth:
                          (112 * MediaQuery.of(context).devicePixelRatio).round(),
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, _, ___) => Container(
                        color: _accent.withValues(alpha: 0.1),
                        child: Icon(Icons.image, color: _textMuted),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildLikeButton(cardIdx, liked),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: _textHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tag,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton(int cardIdx, bool liked) {
    return AnimatedBuilder(
      animation: _heartPopCtrls[cardIdx],
      builder: (context, _) {
        final t = _heartPopCtrls[cardIdx].value;
        double scale = 1.0;
        if (t < 0.40) {
          scale = 1.0 + (0.38 * (t / 0.40));
        } else if (t < 0.70) {
          scale = 1.38 - (0.50 * ((t - 0.40) / 0.30));
        } else {
          scale = 0.88 + (0.12 * ((t - 0.70) / 0.30));
        }
        return GestureDetector(
          onTap: () => _toggleLike(cardIdx),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: liked
                    ? _accent.withValues(alpha: 0.20)
                    : _shadowStrong,
                border: liked
                    ? Border.all(
                        color: _accent.withValues(alpha: 0.50), width: 1)
                    : null,
              ),
              child: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked
                    ? _accentSecondary
                    : _textHeading.withValues(alpha: 0.7),
                size: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatWrap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
                color: _accent.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 6)),
            BoxShadow(
                color: _shadowMedium, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: SizedBox(
                width: 26,
                height: 26,
                child: Center(
                    child: Icon(Icons.add_rounded, color: _textMuted, size: 20)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _chatController,
                focusNode: _chatFocusNode,
                style: TextStyle(
                  color: _textHeading,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: _chatPlaceholder,
                  hintStyle: TextStyle(
                    color: _textMuted,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                textInputAction: TextInputAction.send,
                cursorColor: _accent,
                cursorWidth: 1.5,
                cursorRadius: const Radius.circular(1),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _submitQuery(value.trim());
                    _chatController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            _buildMicButton(),
            const SizedBox(width: 8),
            _AnimatedPressable(
              liftY: -1.5,
              scalePressed: 0.90,
              onTap: () {
                final text = _chatController.text.trim();
                if (text.isNotEmpty) {
                  _submitQuery(text);
                  _chatController.clear();
                } else {
                  _submitQuery('');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: _chatHasText
                      ? _accentGradient2
                      : LinearGradient(colors: [
                          _accent.withValues(alpha: 0.35),
                          _accentSecondary.withValues(alpha: 0.35),
                        ]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: _chatHasText
                      ? [
                          BoxShadow(
                              color: _accent.withValues(alpha: 0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 6)),
                          BoxShadow(
                              color: _accentSecondary.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ]
                      : null,
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    color: _onAccent, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _micGlowCtrl,
      builder: (context, _) {
        final glowScale = _micActive
            ? 1.0 + 0.18 * math.sin(_micGlowCtrl.value * math.pi * 2)
            : 1.0;
        return GestureDetector(
          onTap: () {
            setState(() => _micActive = !_micActive);
            if (_micActive) {
              _micGlowCtrl.repeat();
            } else {
              _micGlowCtrl.stop();
              _micGlowCtrl.reset();
            }
          },
          child: SizedBox(
            width: 26,
            height: 26,
            child: Center(
              child: Transform.scale(
                scale: glowScale,
                child: Icon(
                  Icons.mic_none_rounded,
                  color: _micActive ? _accent : _textMuted,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final items = _homeNavItems;
    const pillH = 64.0;
    const maxBulge = 18.0; 
    const totalH = pillH + maxBulge + 6.0;

    return SizedBox(
      height: totalH,
      child: AnimatedBuilder(
        animation: Listenable.merge(_navRiseCtrls),
        builder: (context, _) {
          final activeIdx = _activeNavIdx;
          final bulgeT = _navRiseCtrls[activeIdx].value;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: totalH,
                child: CustomPaint(
                  painter: _NavPillPainter(
                    activeIdx: activeIdx,
                    itemCount: items.length,
                    bulgeT: bulgeT,
                    pillH: pillH,
                    maxBulge: maxBulge,
                    fillColor: _surface,
                    borderColor: _border,
                    glowColor: _accent,
                    shadowColor: _shadowMedium,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: pillH,
                child: Row(
                  children: List.generate(items.length, (i) {
                    final active = activeIdx == i;
                    final rise = -10.0 * _navRiseCtrls[i].value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _handleNavTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(0, rise),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                width: 44,
                                height: 44,
                                decoration: active
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _accentGradient2,
                                        boxShadow: [
                                          BoxShadow(
                                              color: _accent.withValues(
                                                  alpha: 0.45),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4)),
                                          BoxShadow(
                                              color: _accent.withValues(
                                                  alpha: 0.25),
                                              blurRadius: 28),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  items[i].icon,
                                  color: active ? _onAccent : _textMuted,
                                  size: active ? 21 : 20,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(0, rise),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(
                                  color: active ? _textHeading : _textMuted,
                                  fontSize: 10,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  letterSpacing: -0.01,
                                ),
                                child: Text(items[i].label),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAiOverlay() {
    const bottomClearance = 170.0;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _overlayFadeCtrl,
        builder: (context, _) => Opacity(
          opacity: _overlayFadeCtrl.value,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissOverlay,
                  child: Container(color: _bgPrimary.withValues(alpha: 0.92)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomClearance,
                child: IgnorePointer(child: const SizedBox.expand()),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 60,
                bottom: bottomClearance,
                child: Column(
                  children: [
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              _accentGradient.createShader(b),
                          child: Text(
                            'AHVI',
                            style: TextStyle(
                              color: _textHeading,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_overlayBrandSub,
                            style: TextStyle(
                                color: _textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w300)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _EntryFadeSlide(
                          key: ValueKey(
                              '${_overlayState}_${_activeIntent ?? ''}'),
                          child: _buildOverlayContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    switch (_overlayState) {
      case _OverlayState.suggestions:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested for you',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 8),
            ..._overlaySuggestions.map((q) => _AnimatedPressable(
                  scalePressed: 0.97,
                  onTap: () => _handleQuery(q, _activeIntent ?? 'chat'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: _surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(color: _shadowMedium, blurRadius: 8)
                      ],
                    ),
                    child: Row(children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent.withValues(alpha: 0.55))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(q,
                              style: TextStyle(
                                  color: _textSub,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400))),
                    ]),
                  ),
                )),
          ],
        );

      case _OverlayState.thinking:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      _accent.withValues(alpha: 0.18),
                      _accentSecondary.withValues(alpha: 0.28)
                    ]),
                    border: Border.all(color: _accent.withValues(alpha: 0.30))),
                child: Center(
                    child: ShaderMask(
                        shaderCallback: (b) => _accentGradient.createShader(b),
                        child: Icon(Icons.auto_awesome,
                            color: _textHeading, size: 12)))),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _thinkingCtrl,
              builder: (_, _) {
                Widget dot(int i) {
                  const period = 1.0;
                  const phaseShift = 0.125;
                  final t = (_thinkingCtrl.value + i * phaseShift) % period;
                  final sine = math.sin(t * math.pi * 2);
                  final lift = sine > 0 ? sine : 0.0;
                  final dy = -5.0 * lift;
                  final opacity = 0.3 + 0.7 * lift;
                  return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5.0 : 0),
                      child: Transform.translate(
                          offset: Offset(0, dy),
                          child: Opacity(
                              opacity: opacity.clamp(0.3, 1.0),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: _accentGradient,
                                ),
                              ))));
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _surface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent.withValues(alpha: 0.20)),
                    boxShadow: [
                      BoxShadow(
                          color: _accent.withValues(alpha: 0.10),
                          blurRadius: 18)
                    ],
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [dot(0), dot(1), dot(2)]),
                );
              },
            ),
          ]),
        );

      case _OverlayState.response:
        if (_responseData == null) return const SizedBox();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
          switchOutCurve: const Cubic(0.4, 0.0, 1.0, 1.0),
          transitionBuilder: (child, anim) {
            final curved = CurvedAnimation(
              parent: anim,
              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_responseData!.question),
            child: _buildResponseContent(_responseData!),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildResponseContent(_ResponseData resp) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(
          alignment: Alignment.centerRight,
          child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                  color: _phoneShell,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4)),
                  border: Border.all(color: _accent.withValues(alpha: 0.15))),
              child: Text(resp.question,
                  style: TextStyle(
                      color: _textHeading,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.45)))),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  _accent.withValues(alpha: 0.18),
                  _accentSecondary.withValues(alpha: 0.28)
                ]),
                border: Border.all(color: _accent.withValues(alpha: 0.30))),
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => _accentGradient.createShader(b),
                child: Icon(Icons.auto_awesome, color: _textHeading, size: 10),
              ),
            )),
        Text('AHVI',
            style: TextStyle(
                color: _textHeading,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      if (resp.intro.isNotEmpty) ...[
        Text(resp.intro,
            style: TextStyle(
                color: _textSub,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6)),
        const SizedBox(height: 14),
      ],
      _buildResponseBody(resp),
      if (_tagsRevealed) ...[
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _tagsRevealCtrl,
          builder: (_, _) => Opacity(
            opacity: _tagsRevealCtrl.value,
            child: Transform.translate(
              offset: Offset(0, 7 * (1 - _tagsRevealCtrl.value)),
              child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _responseTags
                      .map((tag) => _AnimatedPressable(
                          scalePressed: 0.96,
                          liftY: -1.5,
                          // --- BUG FIX: Tags are now clickable! ---
                          onTap: () => _submitQuery(tag), 
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 6),
                              decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                      color: _accent.withValues(alpha: 0.20))),
                              child: Text(tag,
                                  style: TextStyle(
                                      color: _accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)))))
                      .toList()),
            ),
          ),
        ),
      ],
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildResponseBody(_ResponseData resp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (resp.type) {
      case 'outfits':
        return SizedBox(
            height: 155,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: resp.outfits.length,
                separatorBuilder: (_, i2) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final o = resp.outfits[i];
                  return Container(
                      width: 86,
                      decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                height: 96,
                                child: Image.network(o.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, _, ___) => Container(
                                        color:
                                            _accent.withValues(alpha: 0.1)))),
                            Padding(
                                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(o.name,
                                          style: TextStyle(
                                              color: isDark
                                                  ? _textHeading
                                                  : _tileText,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Wrap(
                                          spacing: 3,
                                          children: o.tags
                                              .map((t) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                      color: _accent.withValues(
                                                          alpha: 0.10),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100)),
                                                  child: Text(t,
                                                      style: TextStyle(
                                                          color: _textMuted,
                                                          fontSize: 8.5,
                                                          fontWeight: FontWeight
                                                              .w500))))
                                              .toList()),
                                    ])),
                          ]));
                }));

      case 'tasks':
        return Column(
            children: resp.tasks.map((t) {
          final dotColor = t.priority == 'high'
              ? _accent
              : t.priority == 'mid'
                  ? _accentSecondary
                  : _accentTertiary.withValues(alpha: 0.5);
          return Opacity(
              opacity: t.done ? 0.45 : 1.0,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: _border.withValues(alpha: 0.35)))),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: t.done
                                        ? _accentTertiary.withValues(alpha: 0.5)
                                        : _accent.withValues(alpha: 0.3)),
                                color: t.done
                                    ? _accentTertiary.withValues(alpha: 0.15)
                                    : _transparent),
                            child: t.done
                                ? Icon(Icons.check,
                                    color: _accentTertiary, size: 10)
                                : null),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(t.label,
                                  style: TextStyle(
                                      color: t.done
                                          ? _textMuted
                                          : _textHeading,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      decoration: t.done
                                          ? TextDecoration.lineThrough
                                          : null)),
                              const SizedBox(height: 2),
                              Text(t.due,
                                  style: TextStyle(
                                      color: t.priority == 'high'
                                          ? _accentTertiary
                                          : _textMuted,
                                      fontSize: 11)),
                            ])),
                        Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: dotColor)),
                      ])));
        }).toList());

      case 'week':
        return GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.52,
            children: resp.weekDays
                .map((d) => Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: d.isToday
                            ? _accent.withValues(alpha: 0.10)
                            : _bgPrimary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: d.isToday
                                ? _accent.withValues(alpha: 0.25)
                                : _border.withValues(alpha: 0.35))),
                    child: Column(children: [
                      Text(d.day,
                          style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              color: d.isToday ? _accent : _textMuted),
                          textAlign: TextAlign.center),
                      Text(d.label.split(' ').last,
                          style: TextStyle(
                              fontSize: 6.5, color: _textMuted),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 3),
                      ...d.items.take(2).map((it) => Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 1),
                          decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(3)),
                          child: Text(it,
                              style: TextStyle(
                                  fontSize: 5.5, color: _textSub),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center))),
                    ])))
                .toList());

      case 'plan':
        return Column(
            children: resp.planSections.map((s) {
          final c = s.color(context.themeTokens);
          return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: c, width: 2))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: TextStyle(
                            color: c,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...s.items.map((it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(it,
                            style: TextStyle(
                                color: _textSub,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                height: 1.5)))),
                  ]));
        }).toList());

      case 'text':
      default:
        return const SizedBox();
    }
  }

  Widget _buildPickSheet() {
    return GestureDetector(
      onTap: _closePickSheet,
      child: AnimatedBuilder(
        animation: _pickSheetCtrl,
        builder: (context, _) {
          final slideOffset = (1.0 - _pickSheetCtrl.value);
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: _bgPrimary.withValues(
                      alpha: 0.3 * _pickSheetCtrl.value),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(0, slideOffset * 300),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_surface, _bgSecondary],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.12), width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: _accent.withValues(alpha: 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, -8)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text(
                            _pickSheetName,
                            style: TextStyle(
                              color: _textHeading,
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.01,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pickSheetTag,
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _AnimatedPressable(
                                  scalePressed: 0.97,
                                  onTap: _closePickSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color:
                                              _accent.withValues(alpha: 0.20),
                                          width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Save to Board',
                                        style: TextStyle(
                                          color: _accent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AnimatedPressable(
                                  scalePressed: 0.97,
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: _accentGradient2,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                            color: _accent.withValues(
                                                alpha: 0.35),
                                            blurRadius: 18),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Style This ↗',
                                        style: TextStyle(
                                          color: _onAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeeAllPanel() {
    final seeAllPicks = [
      (
        'Minimal Chic',
        'Casual · Today',
        'https://images.unsplash.com/photo-1594938298603-c8148c4b9c2b?w=300&h=280&fit=crop&crop=top&auto=format'
      ),
      (
        'Street Edit',
        'Urban · Weekend',
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=300&h=280&fit=crop&crop=top&auto=format'
      ),
      (
        'Office Look',
        'Smart · Monday',
        'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=300&h=280&fit=crop&crop=top&auto=format'
      ),
      (
        'Evening',
        'Party · Dinner',
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300&h=280&fit=crop&crop=top&auto=format'
      ),
      (
        'Athleisure',
        'Sport · Morning',
        'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=300&h=280&fit=crop&crop=top&auto=format'
      ),
      (
        'Resort Wear',
        'Vacation · Breezy',
        'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=300&h=280&fit=crop&crop=top&auto=format'
      ),
    ];
    return AnimatedBuilder(
      animation: _seeAllCtrl,
      builder: (context, _) {
        final slideOffset = (1.0 - _seeAllCtrl.value);
        return Transform.translate(
          offset: Offset(MediaQuery.of(context).size.width * slideOffset, 0),
          child: Container(
            color: _bgPrimary,
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _closeSeeAll,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _panel,
                              border: Border.all(
                                  color: _accent.withValues(alpha: 0.20),
                                  width: 1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: _textMuted, size: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Today's Picks",
                          style: TextStyle(
                            color: _textHeading,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: seeAllPicks.length,
                    itemBuilder: (context, i) {
                      return _AnimatedPressable(
                        scalePressed: 0.97,
                        onTap: () {
                          _closeSeeAll();
                          Future.delayed(
                              const Duration(milliseconds: 380), () {
                            if (mounted) {
                              _openPickSheet(
                                  seeAllPicks[i].$1, seeAllPicks[i].$2);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: _surface,
                            border: Border.all(color: _border, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Image.network(
                                  seeAllPicks[i].$3,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, _, ___) => Container(
                                    color: _accent.withValues(alpha: 0.1),
                                    child: Icon(Icons.image, color: _textMuted),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      seeAllPicks[i].$1,
                                      style: TextStyle(
                                        color: _textHeading,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      seeAllPicks[i].$2,
                                      style: TextStyle(
                                        color: _textMuted,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLensSheet() {
    return GestureDetector(
      onTap: _closeLensSheet,
      child: AnimatedBuilder(
        animation: _lensSheetCtrl,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: _accent.withValues(alpha: 0.15 * _lensSheetCtrl.value),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(0, (1 - _lensSheetCtrl.value) * 400),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_surface, _bgSecondary],
                        ),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.15), width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: _accent.withValues(alpha: 0.15),
                              blurRadius: 48,
                              offset: const Offset(0, -12)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                            color: _accent.withValues(alpha: 0.25),
                                            width: 1),
                                      ),
                                      child: Icon(Icons.search,
                                          color: _accent, size: 17),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AHVI Lens',
                                      style: TextStyle(
                                        color: _textHeading,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _closeLensSheet,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _accent.withValues(alpha: 0.08),
                                      border: Border.all(
                                          color: _accent.withValues(alpha: 0.20),
                                          width: 1),
                                    ),
                                    child: Icon(Icons.close,
                                        color: _textMuted, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _panel,
                              border: Border.all(
                                  color: _accent.withValues(alpha: 0.15), width: 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _aurora1Ctrl,
                                  builder: (context, _) {
                                    return Transform.rotate(
                                      angle: _aurora1Ctrl.value * math.pi * 2,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: _accent.withValues(alpha: 0.5),
                                              width: 2),
                                          color: _accent.withValues(alpha: 0.08),
                                        ),
                                        child: Icon(Icons.circle,
                                            color: _accent, size: 12),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Visual AI Search',
                                        style: TextStyle(
                                            color: _textHeading,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Point at any item to find, save, or get styling advice.',
                                        style: TextStyle(
                                            color: _textMuted,
                                            fontSize: 11.5,
                                            height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...[
                            (
                              Icons.search,
                              'Find Similar',
                              'Discover items like this one',
                              _accent,
                              'find'
                            ),
                            (
                              Icons.add_photo_alternate_outlined,
                              'Add to Wardrobe',
                              'Save to your collection',
                              _accentSecondary,
                              'add'
                            ),
                            (
                              Icons.chat_bubble_outline_rounded,
                              'Ask AHVI',
                              'Get personalised styling tips',
                              _accentTertiary,
                              'chat'
                            ),
                          ].map((opt) => _buildLensOption(
                              opt.$1, opt.$2, opt.$3, opt.$4)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLensOption(
      IconData icon, String name, String desc, Color color) {
    return _AnimatedPressable(
      scalePressed: 0.98,
      onTap: () {},
      builder: (isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered ? color.withValues(alpha: 0.08) : _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? color.withValues(alpha: 0.30)
                  : _accent.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: color.withValues(alpha: 0.25), width: 1),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                          color: _textHeading,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      desc,
                      style: TextStyle(color: _textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                transform:
                    Matrix4.translationValues(isHovered ? 3.0 : 0.0, 0, 0),
                child: Icon(Icons.chevron_right_rounded,
                    color: isHovered ? color : _textMuted, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComingSoonToast() {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _toastVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 280),
          child: AnimatedSlide(
            offset: _toastVisible ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: _bgSecondary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: _shadowMedium, blurRadius: 28),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, color: _accent, size: 15),
                    SizedBox(width: 7),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                          color: _textHeading,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPillPainter extends CustomPainter {
  final int activeIdx;
  final int itemCount;
  final double bulgeT;
  final double pillH;
  final double maxBulge;
  final Color fillColor;
  final Color borderColor;
  final Color glowColor;
  final Color shadowColor;

  const _NavPillPainter({
    required this.activeIdx,
    required this.itemCount,
    required this.bulgeT,
    required this.pillH,
    required this.maxBulge,
    required this.fillColor,
    required this.borderColor,
    required this.glowColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pillTop = h - pillH;
    final r = pillH / 2;

    final itemW = w / itemCount;
    final cx = itemW * activeIdx + itemW / 2;

    final bulgeH = maxBulge * bulgeT;
    final peakY = pillTop - bulgeH;

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, pillTop, w, pillH),
      Radius.circular(r),
    );
    final pillPath = Path()..addRRect(pillRect);

    final hw = itemW * 0.38; 
    final tang = hw * 0.55;
    final lx = cx - hw;
    final rx = cx + hw;

    final bp = Path();
    bp.moveTo(lx, pillTop);
    bp.cubicTo(lx + tang, pillTop, cx - tang, peakY, cx, peakY);
    bp.cubicTo(cx + tang, peakY, rx - tang, pillTop, rx, pillTop);
    bp.close(); 

    final combined = Path.combine(PathOperation.union, pillPath, bp);

    canvas.drawPath(
      combined.shift(const Offset(0, 8)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    if (bulgeH > 1) {
      canvas.drawPath(
        combined,
        Paint()
          ..color = glowColor.withValues(alpha: 0.12 * bulgeT)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    canvas.drawPath(combined, Paint()..color = fillColor);

    canvas.drawPath(
      combined,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_NavPillPainter old) =>
      old.activeIdx != activeIdx ||
      old.bulgeT != bulgeT ||
      old.fillColor != fillColor ||
      old.shadowColor != shadowColor;
}

enum _OverlayState { idle, suggestions, thinking, response }

class _IntentConfig {
  final List<String> suggestions;
  final String brandSub;
  final List<String> responseTags;
  const _IntentConfig(
      {required this.suggestions,
      required this.brandSub,
      required this.responseTags});
}

class _ResponseData {
  final String type, question, intro;
  final List<_Outfit> outfits;
  final List<_Task> tasks;
  final List<_WeekDay> weekDays;
  final List<_PlanSection> planSections;
  const _ResponseData({
    required this.type,
    required this.question,
    this.intro = '',
    this.outfits = const [],
    this.tasks = const [],
    this.weekDays = const [],
    this.planSections = const [],
  });
}

class _Outfit {
  final String name, imageUrl;
  final List<String> tags;
  const _Outfit(this.name, this.tags, this.imageUrl);
}

class _Task {
  final String label, due, priority;
  final bool done;
  const _Task(this.label, this.due, this.priority, this.done);
}

class _WeekDay {
  final String day, label;
  final List<String> items;
  final bool done, isToday;
  const _WeekDay(this.day, this.label, this.items,
      {this.done = false, this.isToday = false});
}

class _PlanSection {
  final String title;
  final Color Function(AppThemeTokens) color;
  final List<String> items;
  const _PlanSection(this.title, this.color, this.items);
}

const _intentConfig = {
  'style': _IntentConfig(
    suggestions: [
      'What should I wear today?',
      'Build a rooftop party outfit',
      'Show trending casual looks'
    ],
    brandSub: 'Your AI Stylist',
    responseTags: ['Outfit Builder', 'Style Tips', 'Trending Now'],
  ),
  'organize': _IntentConfig(
    suggestions: [
      'What tasks are urgent?',
      'Show this week overview',
      'Plan my gym schedule'
    ],
    brandSub: 'Your AI Organiser',
    responseTags: ['Urgent Tasks', 'Weekly View', 'Gym Plan'],
  ),
  'prepare': _IntentConfig(
    suggestions: [
      'Plan a 3-day Goa trip',
      'Pack for business travel',
      'Create a wedding checklist'
    ],
    brandSub: 'Your AI Planner',
    responseTags: ['Trip Plans', 'Checklists', 'Pack Lists'],
  ),
  'chat': _IntentConfig(
    suggestions: [
      'Help me plan my day',
      'Suggest something for tonight',
      'What should I focus on?'
    ],
    brandSub: 'Always here for you',
    responseTags: ['Daily Plan', 'Tonight', 'Focus Mode'],
  ),
};

const _intentPlaceholder = {
  'chat': 'Ask AHVI anything…',
  'style': 'Describe your vibe or occasion…',
  'organize': 'What would you like to organize?',
  'prepare': 'What are you planning for?',
};

final _responseMap = <String, _ResponseData>{
  'What should I wear today?': _ResponseData(
      type: 'outfits',
      question: 'What should I wear today?',
      intro:
          "Based on today's 14°C partly cloudy weather, here are 3 looks curated for you:",
      outfits: [
        _Outfit(
            'Layered Minimal',
            ['Casual', 'Today'],
            'https://images.unsplash.com/photo-1594938298603-c8148c4b9c2b?w=220&h=260&fit=crop&crop=top&auto=format'),
        _Outfit(
            'Smart Casual',
            ['Office', 'Versatile'],
            'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=220&h=260&fit=crop&crop=top&auto=format'),
        _Outfit(
            'Street Edit',
            ['Urban', 'Fresh'],
            'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=220&h=260&fit=crop&crop=top&auto=format'),
      ]),
  'Build a rooftop party outfit': _ResponseData(
      type: 'outfits',
      question: 'Build a rooftop party outfit',
      intro: "Rooftop energy calls for elevated looks. Here's what works perfectly:",
      outfits: [
        _Outfit(
            'Evening Glow',
            ['Party', 'Night'],
            'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=220&h=260&fit=crop&crop=top&auto=format'),
        _Outfit(
            'Rooftop Chic',
            ['Elevated', 'Cool'],
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=220&h=260&fit=crop&crop=top&auto=format'),
        _Outfit(
            'Bold Statement',
            ['Trendy', 'Standout'],
            'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=220&h=260&fit=crop&crop=top&auto=format'),
      ]),
  'Show trending casual looks': _ResponseData(
      type: 'outfits',
      question: 'Show trending casual looks',
      intro: 'Quiet luxury and clean lines are having a moment. Top trending now:',
      outfits: [
        _Outfit(
            'Quiet Luxury',
            ['Trending', 'Minimal'],
            'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=220&h=260&fit=crop&crop=top&auto=format'),
        _Outfit(
            'Soft Tones',
            ['Casual', 'Neutral'],
            'https://images.unsplash.com/photo-1594938298603-c8148c4b9c2b?w=220&h=260&fit=crop&crop=top&auto=format'),
        _Outfit(
            'Classic Ease',
            ['Everyday', 'Fresh'],
            'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=220&h=260&fit=crop&crop=top&auto=format'),
      ]),
  'What tasks are urgent?': _ResponseData(
      type: 'tasks',
      question: 'What tasks are urgent?',
      intro: 'You have 3 urgent items that need attention today:',
      tasks: [
        _Task('Submit Q1 report', 'Due 5pm today', 'high', false),
        _Task('Reply to Meera re: proposal', 'Overdue · 2h ago', 'high', false),
        _Task('Book hotel for Bangalore trip', 'Due tomorrow', 'mid', false),
        _Task('Review design feedback', 'Due Friday', 'low', true),
      ]),
  'Show this week overview': _ResponseData(
      type: 'week',
      question: 'Show this week overview',
      intro: "Here's your week at a glance:",
      weekDays: [
        _WeekDay('Mon', 'Mar 3', ['9am Standup', '2pm Design'], done: true),
        _WeekDay('Tue', 'Mar 4', ['10am Client call', 'Submit draft'], done: true),
        _WeekDay('Wed', 'Mar 5', ['Free morning', '4pm Gym'], done: true),
        _WeekDay('Thu', 'Mar 6', ['9am Standup', '2pm Board meeting'], isToday: true),
        _WeekDay('Fri', 'Mar 7', ['11am 1:1', 'Team lunch']),
        _WeekDay('Sat', 'Mar 8', ['Personal day', 'Yoga 8am']),
        _WeekDay('Sun', 'Mar 9', ['Rest & prep']),
      ]),
  'Plan my gym schedule': _ResponseData(
      type: 'tasks',
      question: 'Plan my gym schedule',
      intro: '4 optimised sessions this week based on your routine:',
      tasks: [
        _Task('Monday — Push (Chest + Shoulders)', 'Morning · 7am', 'high', true),
        _Task('Wednesday — Pull (Back + Biceps)', 'Evening · 6pm', 'high', true),
        _Task('Friday — Legs', 'Morning · 7am', 'mid', false),
        _Task('Sunday — Active Recovery + Core', 'Flexible', 'low', false),
      ]),
  'Plan a 3-day Goa trip': _ResponseData(
      type: 'plan',
      question: 'Plan a 3-day Goa trip',
      intro: "Here's your expert-curated 3-day Goa itinerary:",
      planSections: [
        _PlanSection(
            'Day 1 — Arrival & North Goa',
            _accent,
            ['☀️ Arrive & check in', '🏖️ Baga Beach', '🍽️ Dinner at Thalassa', '🍹 Night — Tito\'s Lane']),
        _PlanSection(
            'Day 2 — Culture & South Goa',
            _accentSecondary,
            ['🏛️ Old Goa churches', '🚗 Drive to Palolem', '🏄 Kayaking', '🌅 Sunset at Cabo de Rama']),
        _PlanSection(
            'Day 3 — Relax & Depart',
            _accentTertiary,
            ['🧘 Morning yoga', '🛍️ Anjuna flea market', '🥥 Beachside lunch', '✈️ Airport by 4pm']),
      ]),
  'Pack for business travel': _ResponseData(
      type: 'plan',
      question: 'Pack for business travel',
      intro: 'Smart packing list — nothing missing, nothing extra:',
      planSections: [
        _PlanSection(
            '👔 Clothing',
            _accent,
            ['2× formal shirts (navy, white)', '1× blazer (charcoal)', '2× trousers', '1× casual outfit']),
        _PlanSection(
            '💼 Work Essentials',
            _accent,
            ['Laptop + charger + adapter', 'Notebook + 2 pens', 'Business cards', 'Portable battery']),
        _PlanSection(
            '🧴 Toiletries',
            _accentSecondary,
            ['Moisturiser, deodorant, perfume', 'Toothbrush + paste', 'Face wash + razor']),
      ]),
  'Create a wedding checklist': _ResponseData(
      type: 'plan',
      question: 'Create a wedding checklist',
      intro: 'Complete wedding checklist — 24 items across 4 categories:',
      planSections: [
        _PlanSection(
            '📅 6–12 Months Before',
            _accent,
            ['Set budget & guest list', 'Book venue & caterer', 'Book photographer', 'Send save-the-dates']),
        _PlanSection(
            '🎨 3–6 Months Before',
            _accentTertiary,
            ['Send invitations', 'Finalise menu & cake', 'Book hair & makeup', 'Order wedding outfits']),
        _PlanSection(
            '📋 1 Month Before',
            _accentSecondary,
            ['Confirm all vendor bookings', 'Finalise seating', 'Collect RSVPs']),
        _PlanSection(
            '✅ Week Of',
            _accentTertiary,
            ['Final dress fitting', 'Prepare wedding day kit', 'Brief photographer & MC', 'Rest & enjoy 🎉']),
      ]),
};

class _GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const _GradientText(this.text,
      {required this.fontSize, required this.fontWeight});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.primary, t.accent.tertiary],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          color: t.textPrimary,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.56,
          height: 1.1,
        ),
      ),
    );
  }
}

class _EntryFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double dy;
  final Duration delay;

  const _EntryFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
    this.dy = 20.0,
    this.delay = Duration.zero,
  });

  @override
  State<_EntryFadeSlide> createState() => _EntryFadeSlideState();
}

class _EntryFadeSlideState extends State<_EntryFadeSlide> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.biggest.height == 0
            ? 1.0
            : constraints.biggest.height;
        final frac = widget.dy / h;
        return AnimatedOpacity(
          opacity: _show ? 1.0 : 0.0,
          duration: widget.duration,
          curve: widget.curve,
          child: AnimatedSlide(
            offset: _show ? Offset.zero : Offset(0, frac),
            duration: widget.duration,
            curve: widget.curve,
            child: widget.child,
          ),
        );
      },
    );
  }
}

const _cardTapDuration = Duration(milliseconds: 200);
const _cardTapCurve = Cubic(0.34, 1.56, 0.64, 1.0);

class _CardPressable extends StatefulWidget {
  final Widget Function(bool isHovered) builder;
  final VoidCallback? onTap;
  final double pressedScale;
  final Offset pressedOffset;

  const _CardPressable({
    required this.builder,
    this.onTap,
    this.pressedScale = 0.97,
    this.pressedOffset = const Offset(0, -0.04),
  });

  @override
  State<_CardPressable> createState() => _CardPressableState();
}

class _CardPressableState extends State<_CardPressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedSlide(
          offset: _pressed ? widget.pressedOffset : Offset.zero,
          duration: _cardTapDuration,
          curve: _cardTapCurve,
          child: AnimatedScale(
            scale: _pressed ? widget.pressedScale : 1.0,
            duration: _cardTapDuration,
            curve: _cardTapCurve,
            child: widget.builder(_hovered),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPressable extends StatefulWidget {
  final Widget? child;
  final Widget Function(bool isHovered, bool isPressed)? builder;
  final VoidCallback? onTap;
  final double liftY;
  final double scaleHover;
  final double scalePressed;

  const _AnimatedPressable({
    this.child,
    this.builder,
    this.onTap,
    this.liftY = 0.0,
    this.scaleHover = 1.0,
    this.scalePressed = 0.97,
  }) : assert(child != null || builder != null);

  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<_AnimatedPressable> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    double dy = 0.0;
    if (_isPressed) {
      scale = widget.scalePressed;
    } else if (_isHovered) {
      scale = widget.scaleHover;
      dy = -widget.liftY;
    }

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
          duration: _isPressed
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 340),
          curve: _isPressed
              ? const Cubic(0.4, 0.0, 1.0, 1.0)
              : const Cubic(0.34, 1.40, 0.64, 1.0),
          transform: Matrix4.translationValues(0.0, _isPressed ? 0.0 : dy, 0.0)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
          transformAlignment: Alignment.center,
          child: widget.builder != null
              ? widget.builder!(_isHovered, _isPressed)
              : widget.child!,
        ),
      ),
    );
  }
}