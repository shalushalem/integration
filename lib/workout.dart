import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [ADDED B33: clipboard]
import 'package:myapp/theme/theme_tokens.dart';

// ─── Color constants (unchanged) ──────────────────────────────────
// Colors are resolved from theme tokens in widget builds.

// ─── [ADDED B31] Global Toast OverlayEntry helper ─────────────────
void showToast(BuildContext context, String message) {
  final t = context.themeTokens;
  final accent = t.accent;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  // [ADDED B31] Use AnimationController via vsync-less ticker
  final controller = AnimationController(
    vsync: Navigator.of(context),
    duration: const Duration(milliseconds: 300),
  );
  final anim = CurvedAnimation(parent: controller, curve: Curves.elasticOut);

  entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Positioned(
        bottom: 28 + (1 - anim.value) * 80, // [ADDED B31] slide up
        left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
              color: t.panelBorder,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: t.cardBorder),
              boxShadow: [
                BoxShadow(
                    color: accent.primary.withValues(alpha: 0.18),
                    blurRadius: 28),
              ],
              ),
            child: Text(message,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            ),
          ),
      ),
    ),
  );
  overlay.insert(entry);
  controller.forward(); // [ADDED B31] animate in
  Future.delayed(const Duration(milliseconds: 2400), () {
    controller.reverse().then((_) { // [ADDED B31] animate out
      entry.remove();
      controller.dispose();
    });
  });
}

// ─── Entry point ──────────────────────────────────────────────────
class Screen4 extends StatefulWidget {
  const Screen4({super.key});
  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> with TickerProviderStateMixin { // [ADDED B09: TickerProviderStateMixin for page transitions]
  int _page = 0;

  // [ADDED B09] Page transition animation
  late AnimationController _pageAnimCtrl;
  late Animation<double> _pageOpacity;
  late Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    // [ADDED B09] Initialize page transition animation
    _pageAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pageOpacity = CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOut));
    _pageAnimCtrl.forward();
  }

  @override
  void dispose() {
    _pageAnimCtrl.dispose(); // [ADDED B09]
    super.dispose();
  }

  void _goHome() {
    setState(() => _page = 0);
    _pageAnimCtrl.forward(from: 0); // [ADDED B09] replay animation
  }

  void _goChat() {
    setState(() => _page = 1);
    _pageAnimCtrl.forward(from: 0); // [ADDED B09]
  }

  void _handleBackNavigation() {
    if (_page != 0) {
      _goHome();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final kBg = t.backgroundPrimary;

    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
          const _BgBlobs(),
          // [ADDED B09] Wrap pages in fade+slide transition
          FadeTransition(
            opacity: _pageOpacity,
            child: SlideTransition(
              position: _pageSlide,
              child: _page == 0
                  ? _HomePage(onChatTap: _goChat, onBack: _handleBackNavigation)
                  : _ChatPage(onBack: _goHome),
            ),
          ),
          if (_page == 0)
            Positioned(
              bottom: 28,
              right: 28,
              child: _AhviFab(onTap: _goChat),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Background blobs (unchanged) ─────────────────────────────────
class _BgBlobs extends StatelessWidget {
  const _BgBlobs();
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              stops: const [0.0, 0.3, 0.6, 1.0],
              colors: [
                t.backgroundPrimary,
                t.backgroundSecondary,
                t.backgroundPrimary,
                t.backgroundSecondary
              ],
            ),
          ),
        ),
        Positioned(top: -120, left: -120, child: Container(width: 520, height: 520,
            decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accent.primary.withValues(alpha: 0.25),
                  t.backgroundPrimary.withValues(alpha: 0.0),
                ], stops: const [0.0, 0.7])))),
        Positioned(bottom: -100, right: -100, child: Container(width: 420, height: 420,
            decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accent.secondary.withValues(alpha: 0.20),
                  t.backgroundPrimary.withValues(alpha: 0.0),
                ], stops: const [0.0, 0.7])))),
      ],
    );
  }
}

// ─── AHVI FAB ─────────────────────────────────────────────────────
class _AhviFab extends StatefulWidget { // [CHANGED B02: StatelessWidget → StatefulWidget]
  final VoidCallback onTap;
  const _AhviFab({required this.onTap});
  @override
  State<_AhviFab> createState() => _AhviFabState();
}

class _AhviFabState extends State<_AhviFab> {
  // [ADDED B02] Press scale state
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
      final kAccentGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent.secondary, accent.primary],
    );
    return GestureDetector(
      onTap: widget.onTap,
      // [ADDED B02] Press detection for scale feedback
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale( // [ADDED B02]
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 22, 10),
          decoration: BoxDecoration(
            gradient: kAccentGrad,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                  color: accent.primary.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: Offset(0, 8)),
              BoxShadow(
                  color: accent.secondary.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: t.panelBorder, shape: BoxShape.circle,
                        border: Border.all(color: t.cardBorder, width: 1.5)),
                    child: Center(
                        child: Icon(Icons.auto_awesome,
                            color: t.textPrimary, size: 22)),
                  ),
                  // [CHANGED B03: was a static Container, now animated pulse]
                  Positioned(top: 4, right: 4, child: _PulsingDot()),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ASK AHVI',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          height: 1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// [ADDED B03] Pulsing dot widget matching fabPulse keyframes
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // [ADDED B03] fabPulse: 2.2s, ease-in-out, infinite
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child2) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 9, height: 9,
            decoration: BoxDecoration(color: accent.tertiary, shape: BoxShape.circle,
                border: Border.all(color: t.cardBorder, width: 1.5)),
          ),
        ),
      ),
    );
  }
}

// ─── HOME PAGE ────────────────────────────────────────────────────
class _HomePage extends StatefulWidget {
  final VoidCallback onChatTap;
  final VoidCallback onBack;
  const _HomePage({required this.onChatTap, required this.onBack});
  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String _currentTab = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'running', 'label': 'Running', 'emoji': '🏃'},
    {'id': 'gym', 'label': 'Gym / Weights', 'emoji': '🏋️'},
    {'id': 'yoga', 'label': 'Yoga', 'emoji': '🧘'},
    {'id': 'hiit', 'label': 'HIIT / Cardio', 'emoji': '⚡'},
  ];

  // [CHANGED B08: made mutable for delete support]
  final List<Map<String, dynamic>> _outfits = [
    {'id': '1', 'name': 'Morning Run', 'emoji': '🏃', 'cat': 'running', 'tag': 'Running'},
    {'id': '2', 'name': 'Leg Day', 'emoji': '🏋️', 'cat': 'gym', 'tag': 'Gym'},
    {'id': '3', 'name': 'Yoga Flow', 'emoji': '🧘', 'cat': 'yoga', 'tag': 'Yoga'},
    {'id': '4', 'name': 'HIIT Session', 'emoji': '⚡', 'cat': 'hiit', 'tag': 'HIIT'},
    {'id': '5', 'name': 'Track Sprint', 'emoji': '🏃', 'cat': 'running', 'tag': 'Running'},
    {'id': '6', 'name': 'Push Day', 'emoji': '🏋️', 'cat': 'gym', 'tag': 'Gym'},
  ];

  List<Map<String, dynamic>> get _filteredOutfits => _currentTab == 'all'
      ? _outfits
      : _outfits.where((o) => o['cat'] == _currentTab).toList();

  // [ADDED B08] Delete outfit and show toast
  void _deleteOutfit(String id) {
    setState(() => _outfits.removeWhere((o) => o['id'] == id));
    showToast(context, 'Outfit removed');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 56),
            _TopBar(title: 'Workout', onBack: widget.onBack),
            const SizedBox(height: 20),
            _HeroBanner(),
            const SizedBox(height: 20),
            _TabsSection(
              categories: _categories,
              currentTab: _currentTab,
              outfitsCount: _outfits.length,
              onTabChanged: (t) => setState(() => _currentTab = t),
              // [CHANGED B13: wire modal open — shows Add Outfit dialog]
              onAddOutfit: () => _openAddOutfitModal(context),
            ),
            const SizedBox(height: 8),
            // [CHANGED B08/B10: pass onDelete callback and indices for stagger]
            _OutfitGrid(outfits: _filteredOutfits, onDelete: _deleteOutfit),
            const SizedBox(height: 32),
            _SavedSection(),
          ],
        ),
      ),
    );
  }

  // [ADDED B13/B14] Open Add Outfit as a full animated modal
  void _openAddOutfitModal(BuildContext context) {
    final t = context.themeTokens;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,      // [ADDED B14] click outside closes
      barrierLabel: 'Close',
      barrierColor: t.backgroundPrimary.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const _AddOutfitModal(onClose: null), // onClose wired below
      transitionBuilder: (ctx, anim, secondary, child) {
        // [ADDED B13] Scale + fade in (0.98 → 1.0 scale, 0 → 1 opacity)
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Top bar (unchanged) ──────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopBar({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: t.panel,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.cardBorder)),
              child: Center(child: Icon(Icons.arrow_back, color: t.mutedText, size: 16))),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: t.textPrimary, fontSize: 22,
            fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ],
    );
  }
}

// ─── Hero Banner (unchanged) ──────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
      final kAccentGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent.secondary, accent.primary],
    );
    return Container(
      height: 220,
      decoration: BoxDecoration(
          gradient: kAccentGrad,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.cardBorder)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(left: 24, top: 26, bottom: 28, width: MediaQuery.of(context).size.width * 0.5 - 40,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dress well,', style: TextStyle(color: t.textPrimary, fontSize: 28,
                    fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.12)),
                Text('train better.', style: TextStyle(color: t.textPrimary.withValues(alpha: 0.82), fontSize: 28,
                    fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.12)),
                const SizedBox(height: 10),
                Text('Organize your workout outfits. Chat with AHVI for AI-powered style advice.',
                    style: TextStyle(color: t.mutedText, fontSize: 12, fontWeight: FontWeight.w300, height: 1.55)),
              ])),
          Positioned(right: 0, bottom: 0, width: MediaQuery.of(context).size.width * 0.5, height: 220 * 1.2,
              child: Image.network('https://i.pinimg.com/736x/a0/1d/6e/a01d6eb20afe2f8e9aed9e32ac861bbc.jpg',
                  fit: BoxFit.contain, alignment: Alignment.bottomRight, errorBuilder: (ctx2, err, stack) => const SizedBox())),
        ],
      ),
    );
  }
}

// ─── Tabs section (unchanged) ─────────────────────────────────────
class _TabsSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String currentTab;
  final int outfitsCount;
  final ValueChanged<String> onTabChanged;
  final VoidCallback onAddOutfit;

  const _TabsSection({required this.categories, required this.currentTab, required this.outfitsCount, required this.onTabChanged, required this.onAddOutfit});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
      final kAccentGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent.secondary, accent.primary],
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text('YOUR OUTFITS', style: TextStyle(color: t.mutedText, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2)),
              const SizedBox(width: 4),
              Text('— ', style: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 11)),
              Text('$outfitsCount', style: TextStyle(color: t.mutedText, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(' saved', style: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 11)),
            ]),
            GestureDetector(
              onTap: onAddOutfit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 4))]),
                child: Text('+ Add Outfit', style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Tab(label: 'All', id: 'all', count: outfitsCount, isActive: currentTab == 'all', onTap: () => onTabChanged('all')),
              ...categories.map((cat) => _Tab(label: cat['label'] as String, id: cat['id'] as String, count: 0, isActive: currentTab == cat['id'], onTap: () => onTabChanged(cat['id'] as String))),
              const SizedBox(width: 4),
              _AddCategoryBtn(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label, id;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.id, required this.count, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer( // [CHANGED B12: was Container — now AnimatedContainer for smooth active state]
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? t.phoneShell : t.panel,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: isActive ? t.accent.primary : t.backgroundPrimary.withValues(alpha: 0.0)),
          boxShadow: isActive ? [
            BoxShadow(color: t.accent.primary.withValues(alpha: 0.14), blurRadius: 32, offset: const Offset(0, 8))
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isActive ? t.textPrimary : t.mutedText, fontSize: 13, fontWeight: isActive ? FontWeight.w500 : FontWeight.w400)),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(color: isActive ? t.mutedText : t.mutedText.withValues(alpha: 0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(50), border: Border.all(color: t.cardBorder)),
      child: Text('+ Add', style: TextStyle(color: t.mutedText, fontSize: 13)),
    );
  }
}

// ─── Outfit Grid ──────────────────────────────────────────────────
class _OutfitGrid extends StatelessWidget {
  final List<Map<String, dynamic>> outfits;
  // [ADDED B08] Delete callback
  final void Function(String id) onDelete;

  const _OutfitGrid({required this.outfits, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (outfits.isEmpty) return _EmptyGrid();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
      itemCount: outfits.length,
      // [CHANGED B10: pass index for stagger]
      itemBuilder: (context, i) => _OutfitCard(outfit: outfits[i], index: i, onDelete: onDelete),
    );
  }
}

// [CHANGED B05/B06/B07/B08/B10: full rework of OutfitCard]
class _OutfitCard extends StatefulWidget {
  final Map<String, dynamic> outfit;
  final int index; // [ADDED B10] for stagger
  final void Function(String id) onDelete; // [ADDED B08]
  const _OutfitCard({required this.outfit, required this.index, required this.onDelete});
  @override
  State<_OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<_OutfitCard> with SingleTickerProviderStateMixin {
  // [ADDED B05] hover state
  bool _isHovered = false;
  // [ADDED B07] delete button hover state
  bool _isDeleteHovered = false;

  Color _accentForCat(AppThemeTokens t, String cat) {
    switch (cat) {
      case 'gym':
        return t.accent.primary;
      case 'yoga':
        return t.accent.tertiary;
      case 'hiit':
        return t.accent.secondary;
      case 'running':
      default:
        return t.accent.secondary;
    }
  }

  double _bgOpacityForCat(String cat) {
    switch (cat) {
      case 'gym':
        return 0.20;
      case 'yoga':
        return 0.22;
      case 'hiit':
        return 0.22;
      case 'running':
      default:
        return 0.25;
    }
  }

  // [ADDED B10] stagger entrance animation
  late AnimationController _enterCtrl;
  late Animation<double> _enterOpacity;
  late Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    // [ADDED B10] cardIn animation with staggered delay
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _enterOpacity = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    // Stagger: i * 40ms delay matching HTML's i * 0.04s
    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) _enterCtrl.forward();
    });
  }

  @override
  void dispose() { _enterCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accentColor = _accentForCat(t, widget.outfit['cat'] as String);
    final bgColor = accentColor.withValues(alpha: 
        _bgOpacityForCat(widget.outfit['cat'] as String));

    // [ADDED B10] Wrap in entrance animation
    return FadeTransition(
      opacity: _enterOpacity,
      child: SlideTransition(
        position: _enterSlide,
        child: MouseRegion( // [ADDED B05] hover detection
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() { _isHovered = false; _isDeleteHovered = false; }),
          child: AnimatedContainer( // [ADDED B05] animated lift + border + shadow
            duration: const Duration(milliseconds: 220),
            transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0), // [ADDED B05]
            decoration: BoxDecoration(
              color: t.panelBorder,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _isHovered ? accentColor : t.cardBorder), // [ADDED B05]
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? accentColor.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.15), // [ADDED B05]
                  blurRadius: _isHovered ? 48 : 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 72, color: bgColor,
                        child: Center(child: Text(widget.outfit['emoji'] as String, style: const TextStyle(fontSize: 32)))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(50)),
                          child: Text(widget.outfit['tag'] as String, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 6),
                        Text(widget.outfit['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.textPrimary, fontSize: 12,
                                fontWeight: FontWeight.w600, height: 1.3)),
                      ]),
                    ),
                  ],
                ),
                // [ADDED B06] Delete button — visible only on hover
                Positioned(
                  top: 6, right: 6,
                  child: AnimatedOpacity( // [ADDED B06] fade in on hover
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isDeleteHovered = true), // [ADDED B07]
                      onExit: (_) => setState(() => _isDeleteHovered = false),
                      child: GestureDetector(
                        onTap: () => widget.onDelete(widget.outfit['id'] as String), // [ADDED B08]
                        child: AnimatedContainer( // [ADDED B07] red on hover
                          duration: const Duration(milliseconds: 150),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _isDeleteHovered
                                ? t.accent.tertiary.withValues(alpha: 0.75)
                                : t.backgroundPrimary.withValues(alpha: 0.50), // [ADDED B07]
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('×',
                              style: TextStyle(color: t.textPrimary, fontSize: 14, height: 1))),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(children: [
        Text('👕', style: TextStyle(fontSize: 40, color: t.textPrimary.withValues(alpha: 0.35))),
        const SizedBox(height: 12),
        Text('No outfits yet', style: TextStyle(color: t.mutedText, fontSize: 17, fontWeight: FontWeight.w400)),
        const SizedBox(height: 6),
        Text('Tap + Add Outfit to get started', style: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w300)),
      ]),
    );
  }
}

// ─── Saved section (unchanged, hover lift skipped — mobile context) ─
class _SavedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('🔖 SAVED BY AHVI', style: TextStyle(color: t.mutedText, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2)),
          GestureDetector(child: Text('Clear all', style: TextStyle(color: t.mutedText, fontSize: 11))),
        ]),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2),
          itemCount: 2,
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.cardBorder),
                boxShadow: [BoxShadow(color: t.accent.primary.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i == 0 ? 'Lightweight tank, shorts, mesh sneakers...' : 'Compression leggings, sports bra, hoodie...',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.textPrimary, fontSize: 11, height: 1.5)),
              const Spacer(),
              Text('Just now', style: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 0.3)),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── CHAT PAGE ────────────────────────────────────────────────────
class _ChatPage extends StatefulWidget {
  final VoidCallback onBack;
  const _ChatPage({required this.onBack});
  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // [ADDED B22] Track bot typing state
  bool _isTyping = false;

  // [ADDED B18] Track chips visibility
  bool _chipsVisible = true;

  // [ADDED B22] Chat history for context
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'bot',
      'text': 'Hi! I\'m AHVI, your AI outfit stylist ✨\n\nTell me what workout you\'re doing, your style preferences, or the weather — and I\'ll suggest the perfect outfit from head to toe!',
    }
  ];

  final List<String> _chips = [
    'Outfit for a morning run?', 'Best gym outfit for leg day?', 'Yoga outfit for hot weather?',
    'HIIT outfit for a woman?', 'What to wear for cycling?', 'Outfit for outdoor training?',
    'Comfortable gym outfit for men?', 'What to wear for Pilates?', 'Cold weather running outfit?',
  ];

  // [ADDED B22] Predefined QA matching HTML logic
  final List<Map<String, dynamic>> _predefinedQA = [
    {'q': RegExp(r'morning run|running outfit', caseSensitive: false), 'a': 'Perfect morning run outfit! 🏃‍♀️\n\n• Top: Moisture-wicking tank or lightweight long-sleeve\n• Bottom: 5" running shorts or compression tights\n• Shoes: Road running shoes with cushioning\n• Extras: Running cap, lightweight windbreaker\n\nTip: Layer up in the first mile — you\'ll warm up fast! 🌡️'},
    {'q': RegExp(r'leg day|gym.*leg|squat|deadlift', caseSensitive: false), 'a': 'Leg day outfit done right! 🏋️‍♀️\n\n• Top: Fitted crop top or breathable gym tee\n• Bottom: High-waist squat-proof leggings\n• Shoes: Flat-soled trainers or weightlifting shoes\n• Extras: Lifting belt (optional), ankle socks\n\nAvoid baggy shorts for leg day — leggings keep form visible! 💪'},
    {'q': RegExp(r'yoga|pilates|stretch', caseSensitive: false), 'a': 'Yoga & Pilates outfit essentials 🧘‍♀️\n\n• Top: Fitted crop top or flowy tank\n• Bottom: High-waist 7/8 leggings or yoga pants\n• Footwear: Barefoot or grip socks\n• Fabric tip: Opt for cotton blend or bamboo\n\nAvoid slippery fabrics! 🙏'},
    {'q': RegExp(r'hiit|cardio', caseSensitive: false), 'a': 'HIIT outfit for maximum performance! ⚡\n\n• Top: Moisture-wicking sports bra or crop top\n• Bottom: 3" to 5" shorts or compression shorts\n• Shoes: Cross-training shoes with lateral support\n• Extras: Sweat-wicking headband, grippy socks\n\nChoose 4-way stretch fabrics so nothing holds you back! 🔥'},
  ];

  String? _getPredefinedAnswer(String text) {
    for (final qa in _predefinedQA) {
      if ((qa['q'] as RegExp).hasMatch(text)) return qa['a'] as String;
    }
    return null;
  }

  @override
  void dispose() { _inputCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // [CHANGED B22: full send logic with typing state + predefined + fallback]
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text.trim()});
      _chipsVisible = false; // [ADDED B18] hide chips on first send
      _inputCtrl.clear();
      _isTyping = true; // [ADDED B22/B24]
    });
    _scrollToBottom();

    final predefined = _getPredefinedAnswer(text);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false; // [ADDED B22/B24]
        _messages.add({'role': 'bot', 'text': predefined ?? 'Great question! Here\'s my outfit recommendation for that workout. Focus on moisture-wicking fabrics and proper support for best performance. ✨'});
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _ChatHeader(onBack: widget.onBack),
          // [CHANGED B18: AnimatedOpacity to hide chips after send]
          AnimatedOpacity(
            opacity: _chipsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedSize( // [ADDED B18] collapse height after hiding
              duration: const Duration(milliseconds: 200),
              child: _chipsVisible
                  ? _SuggestionChips(chips: _chips, onTap: _sendMessage)
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            // [CHANGED B23: ListView replaced with _AnimatedMessageList]
            child: _AnimatedMessageList(
              messages: _messages,
              isTyping: _isTyping, // [ADDED B24]
              scrollController: _scrollCtrl,
            ),
          ),
          _ChatInputBar(
            controller: _inputCtrl,
            onSend: () => _sendMessage(_inputCtrl.text),
          ),
        ],
      ),
    );
  }
}

// [ADDED B23/B24] Message list with slide-in animation and typing indicator
class _AnimatedMessageList extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final bool isTyping;
  final ScrollController scrollController;
  const _AnimatedMessageList({required this.messages, required this.isTyping, required this.scrollController});
  @override
  State<_AnimatedMessageList> createState() => _AnimatedMessageListState();
}

class _AnimatedMessageListState extends State<_AnimatedMessageList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Map<String, dynamic>> _localMessages;

  @override
  void initState() {
    super.initState();
    _localMessages = List.from(widget.messages);
  }

  @override
  void didUpdateWidget(_AnimatedMessageList old) {
    super.didUpdateWidget(old);
    // [ADDED B23] Insert new messages with animation
    if (widget.messages.length > _localMessages.length) {
      final newCount = widget.messages.length - _localMessages.length;
      for (int i = 0; i < newCount; i++) {
        final index = _localMessages.length;
        _localMessages.add(widget.messages[index]);
        _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 300));
      }
    }
  }

  Widget _buildItem(Map<String, dynamic> msg, Animation<double> anim) {
    // [ADDED B23] msgIn: opacity + translateY(8px→0)
    return FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: _ChatMessage(role: msg['role'] as String, text: msg['text'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
      initialItemCount: _localMessages.length + (widget.isTyping ? 1 : 0),
      itemBuilder: (ctx, index, anim) {
        // [ADDED B24] Show typing indicator at end of list
        if (widget.isTyping && index == _localMessages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              _botAvatarSmall(context),
              const SizedBox(width: 10),
              _TypingIndicator(), // [ADDED B24]
            ]),
          );
        }
        if (index >= _localMessages.length) return const SizedBox();
        return _buildItem(_localMessages[index], anim);
      },
    );
  }

  Widget _botAvatarSmall(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.secondary, accent.primary],
          ),
          boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Center(child: Icon(Icons.auto_awesome, color: t.textPrimary, size: 14)),
    );
  }
}

// [ADDED B24] Animated typing indicator (3 bouncing dots)
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    // [ADDED B24] 3 dots, staggered 200ms each, matching typingDot CSS
    _ctrls = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)));
    _anims = _ctrls.map((c) => Tween(begin: 0.0, end: -5.0).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: t.panelBorder, borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(18)),
          border: Border.all(color: t.cardBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, child2) => Transform.translate(
            offset: Offset(0, _anims[i].value), // [ADDED B24] bounce translateY
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              width: 7, height: 7,
              decoration: BoxDecoration(color: t.accent.primary, shape: BoxShape.circle),
            ),
          ),
        )),
      ),
    );
  }
}

// ─── Chat header (unchanged) ──────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ChatHeader({required this.onBack});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
      child: Row(
        children: [
          GestureDetector(onTap: onBack,
              child: Container(width: 36, height: 36, decoration: BoxDecoration(color: t.panel, shape: BoxShape.circle, border: Border.all(color: t.cardBorder)),
                  child: Center(child: Icon(Icons.arrow_back, color: t.mutedText, size: 16)))),
          const SizedBox(width: 14),
          Stack(clipBehavior: Clip.none, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [accent.secondary, accent.primary]),
                boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 4))]),
                child: Center(child: Icon(Icons.auto_awesome, color: t.textPrimary, size: 20))),
            Positioned(bottom: 1, right: 1, child: Container(width: 11, height: 11,
                decoration: BoxDecoration(color: accent.tertiary, shape: BoxShape.circle, border: Border.all(color: t.phoneShell, width: 2)))),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AHVI', style: TextStyle(color: t.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, height: 1.2)),
            Text('Your AI outfit stylist · Online', style: TextStyle(color: t.mutedText, fontSize: 12, fontWeight: FontWeight.w300)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(50), border: Border.all(color: t.cardBorder)),
            child: Row(children: [
              Icon(Icons.phone, color: t.mutedText, size: 14),
              const SizedBox(width: 6),
              Text('Voice', style: TextStyle(color: t.mutedText, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestion chips ─────────────────────────────────────────────
class _SuggestionChips extends StatelessWidget {
  final List<String> chips;
  final ValueChanged<String> onTap;
  const _SuggestionChips({required this.chips, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, i2) => const SizedBox(width: 7),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => onTap(chips[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(50), border: Border.all(color: t.cardBorder)),
              child: Text(chips[i], style: TextStyle(color: t.mutedText, fontSize: 12)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chat message (unchanged structure) ───────────────────────────
class _ChatMessage extends StatelessWidget {
  final String role, text;
  const _ChatMessage({required this.role, required this.text});
  bool get isBot => role == 'bot';
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isBot
            ? [_botAvatar(context), const SizedBox(width: 10), Flexible(child: _bubble(context, t))]
            : [Flexible(child: _bubble(context, t)), const SizedBox(width: 10), _userAvatar(context)],
      ),
    );
  }

  Widget _botAvatar(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Container(width: 32, height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [accent.secondary, accent.primary]),
          boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Center(child: Icon(Icons.auto_awesome, color: t.textPrimary, size: 14)));
  }

  Widget _userAvatar(BuildContext context) {
    final t = context.themeTokens;
    return Container(width: 32, height: 32,
      decoration: BoxDecoration(color: t.panelBorder, shape: BoxShape.circle, border: Border.all(color: t.cardBorder)),
      child: Center(child: Text('👤', style: TextStyle(fontSize: 16))));

  }

  Widget _bubble(BuildContext context, AppThemeTokens t) => Column(
    crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBot ? t.panelBorder : t.phoneShell,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
              bottomLeft: isBot ? const Radius.circular(6) : const Radius.circular(18),
              bottomRight: isBot ? const Radius.circular(18) : const Radius.circular(6)),
          border: isBot ? Border.all(color: t.cardBorder) : null,
          boxShadow: [if (isBot) BoxShadow(color: t.accent.primary.withValues(alpha: 0.14), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Text(text, style: TextStyle(color: t.textPrimary, fontSize: 14, height: 1.55)),
      ),
      const SizedBox(height: 5),
      // [ADDED B32/B33] Save + Copy buttons on bot messages
      if (isBot)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _BotMessageActions(text: text),
        ),
      Text('now', style: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 10)),
    ],
  );
}

// [ADDED B32/B33] Save and Copy action buttons on bot messages
class _BotMessageActions extends StatefulWidget {
  final String text;
  const _BotMessageActions({required this.text});
  @override
  State<_BotMessageActions> createState() => _BotMessageActionsState();
}

class _BotMessageActionsState extends State<_BotMessageActions> {
  bool _isSaved = false;  // [ADDED B32]
  bool _isCopied = false; // [ADDED B33]

  void _save() {
    setState(() => _isSaved = true); // [ADDED B32] permanent save state
    showToast(context, 'Workout saved ✓');
  }

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text)); // [ADDED B33]
    setState(() => _isCopied = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _isCopied = false); // [ADDED B33] revert after 2s
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // [ADDED B32] Save button
        GestureDetector(
          onTap: _isSaved ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: _isSaved
                  ? accent.tertiary.withValues(alpha: 0.2)
                  : t.panel,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _isSaved ? accent.tertiary : accent.primary.withValues(alpha: 0.28)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bookmark_outlined, size: 11, color: _isSaved ? accent.tertiary : accent.primary),
              const SizedBox(width: 4),
              Text(_isSaved ? 'Saved!' : 'Save', style: TextStyle(color: _isSaved ? accent.tertiary : accent.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        // [ADDED B33] Copy button
        GestureDetector(
          onTap: _copy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.backgroundPrimary.withValues(alpha: 0.0),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _isCopied ? accent.tertiary.withValues(alpha: 0.3) : accent.primary.withValues(alpha: 0.18)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.copy, size: 10, color: _isCopied ? accent.tertiary : t.mutedText),
              const SizedBox(width: 4),
              Text(_isCopied ? 'Copied!' : 'Copy', style: TextStyle(color: _isCopied ? accent.tertiary : t.mutedText, fontSize: 11)),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Chat input bar (unchanged structure) ─────────────────────────
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatInputBar({required this.controller, required this.onSend});
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
      final kAccentGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent.secondary, accent.primary],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
        decoration: BoxDecoration(color: t.panelBorder, borderRadius: BorderRadius.circular(28), border: Border.all(color: t.cardBorder),
            boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.14), blurRadius: 32, offset: const Offset(0, 8)),
              BoxShadow(color: accent.secondary.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Expanded(child: TextField(controller: controller, style: TextStyle(color: t.textPrimary, fontSize: 14), maxLines: null,
                decoration: InputDecoration(hintText: 'Ask AHVI to suggest an outfit…', hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 14), border: InputBorder.none, isDense: true),
                onSubmitted: (_) => onSend())),
            const SizedBox(width: 8),
            Container(width: 40, height: 40, decoration: BoxDecoration(color: t.panel, shape: BoxShape.circle, border: Border.all(color: t.cardBorder)),
                child: Center(child: Icon(Icons.mic, color: t.mutedText, size: 16))),
            const SizedBox(width: 8),
            GestureDetector(onTap: onSend,
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: kAccentGrad,
                        boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 2))]),
                    child: Center(child: Icon(Icons.send, color: t.textPrimary, size: 16)))),
          ],
        ),
      ),
    );
  }
}

// ─── Add Outfit Modal ─────────────────────────────────────────────
// [CHANGED B13/B14/B34: now a proper dialog widget with close callback and auto-focus]
class _AddOutfitModal extends StatefulWidget {
  final VoidCallback? onClose;
  const _AddOutfitModal({this.onClose});
  @override
  State<_AddOutfitModal> createState() => _AddOutfitModalState();
}

class _AddOutfitModalState extends State<_AddOutfitModal> {
  final List<Map<String, dynamic>> _categories = [
    {'id': 'running', 'label': 'Running', 'emoji': '🏃'},
    {'id': 'gym', 'label': 'Gym', 'emoji': '🏋️'},
    {'id': 'yoga', 'label': 'Yoga', 'emoji': '🧘'},
    {'id': 'hiit', 'label': 'HIIT', 'emoji': '⚡'},
  ];
  String? _selectedCat;
  final List<String> _items = [];
  final TextEditingController _itemCtrl = TextEditingController();
  // [ADDED B34] FocusNode for auto-focus on open
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // [ADDED B34] Auto-focus name input 200ms after open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _nameFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() { _itemCtrl.dispose(); _nameFocusNode.dispose(); super.dispose(); }

  void _addItem() {
    if (_itemCtrl.text.trim().isNotEmpty) {
      setState(() { _items.add(_itemCtrl.text.trim()); _itemCtrl.clear(); });
    }
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop(); // [ADDED B14] close via Navigator when shown as dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    final kAccent = accent.primary;
      final kAccentGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent.secondary, accent.primary],
    );
    return Center(
      child: Material(
        color: t.backgroundPrimary.withValues(alpha: 0.0),
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(color: t.backgroundSecondary, borderRadius: BorderRadius.circular(28),
              border: Border.all(color: t.cardBorder), boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.15), blurRadius: 64, offset: const Offset(0, 24))]),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.cardBorder))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('New Outfit', style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    GestureDetector(onTap: _close, // [CHANGED B14: wired to _close]
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.cardBorder)),
                            child: Text('×', style: TextStyle(color: t.mutedText, fontSize: 18)))),
                  ])),
              SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _FormLabel(text: 'Outfit Name'),
                  const SizedBox(height: 8),
                  // [CHANGED B16/B34: pass focusNode to TextField wrapper]
                  _FormInputWithFocus(hint: 'e.g. Sunday Morning Run', focusNode: _nameFocusNode),
                  const SizedBox(height: 20),
                  const _FormLabel(text: 'Workout Type'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCat == cat['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCat = cat['id'] as String),
                        child: AnimatedContainer( // [CHANGED B15: was Container, now AnimatedContainer]
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? t.phoneShell : t.panel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? kAccent : t.cardBorder, width: 1.5),
                            boxShadow: isSelected ? [BoxShadow(color: accent.primary.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 6))] : null,
                          ),
                          child: Column(children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text(cat['emoji'] as String, style: const TextStyle(fontSize: 16)))),
                            const SizedBox(height: 6),
                            Text(cat['label'] as String, style: TextStyle(color: isSelected ? t.textPrimary : t.mutedText, fontSize: 10, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const _FormLabel(text: 'Clothing Items'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                        decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.cardBorder)),
                        child: TextField(controller: _itemCtrl, style: TextStyle(color: t.textPrimary, fontSize: 13),
                            decoration: InputDecoration(hintText: 'e.g. Lightweight tank top', hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 13), border: InputBorder.none, isDense: true),
                            onSubmitted: (_) => _addItem()))),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: _addItem,
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(color: accent.primary.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14), border: Border.all(color: accent.primary.withValues(alpha: 0.30))),
                            child: Text('+', style: TextStyle(color: kAccent, fontSize: 18)))),
                  ]),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: _items.map((item) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(50), border: Border.all(color: t.cardBorder)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(item, style: TextStyle(color: t.mutedText, fontSize: 12)),
                            const SizedBox(width: 7),
                            GestureDetector(onTap: () => setState(() => _items.remove(item)),
                                child: Text('×', style: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 13))),
                          ]),
                        )).toList()),
                  ],
                  const SizedBox(height: 20),
                  const _FormLabel(text: 'Notes'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.cardBorder)),
                    child: TextField(style: TextStyle(color: t.textPrimary, fontSize: 14), minLines: 3, maxLines: 5,
                        decoration: InputDecoration(hintText: 'e.g. Great for hot weather, breathable and light', hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 14), contentPadding: const EdgeInsets.all(14), border: InputBorder.none)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(gradient: kAccentGrad, borderRadius: BorderRadius.circular(50),
                        boxShadow: [BoxShadow(color: accent.primary.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 4))]),
                    child: ElevatedButton(
                      onPressed: () { showToast(context, 'Outfit saved ✓'); _close(); },
                      style: ElevatedButton.styleFrom(backgroundColor: t.backgroundPrimary.withValues(alpha: 0.0), shadowColor: t.backgroundPrimary.withValues(alpha: 0.0),
                          padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                      child: Text('Save Outfit', style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// [ADDED B16] TextField with focus glow animation
class _FormInputWithFocus extends StatefulWidget {
  final String hint;
  final FocusNode? focusNode;
  const _FormInputWithFocus({required this.hint, this.focusNode});
  @override
  State<_FormInputWithFocus> createState() => _FormInputWithFocusState();
}

class _FormInputWithFocusState extends State<_FormInputWithFocus> {
  late FocusNode _focus;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() => _hasFocus = _focus.hasFocus); // [ADDED B16]
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose(); // only dispose if we own it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return AnimatedContainer( // [ADDED B16] focus glow ring animation
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _hasFocus ? t.panelBorder : t.panel, // [ADDED B16]
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hasFocus ? accent.primary.withValues(alpha: 0.58) : t.cardBorder), // [ADDED B16]
        boxShadow: _hasFocus
            ? [BoxShadow(color: accent.primary.withValues(alpha: 0.12), blurRadius: 0, spreadRadius: 3)] // [ADDED B16] glow ring
            : null,
      ),
      child: TextField(
        focusNode: _focus,
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: InputDecoration(hintText: widget.hint, hintStyle: TextStyle(color: t.mutedText.withValues(alpha: 0.6), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: InputBorder.none),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(color: context.themeTokens.mutedText, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5));
}


