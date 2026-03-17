// ============================================================
//  office_fit.dart  —  1:1 Flutter port of office_fit.html
//  All 7 missing features implemented (F001–F007)
// ============================================================

import 'package:flutter/material.dart';
import 'package:myapp/theme/base_theme.dart';
import 'package:myapp/theme/theme_tokens.dart';

// ─────────────────────────────────────────────────────────────
//  COLOUR TOKENS  (mirrors CSS :root variables)
// ─────────────────────────────────────────────────────────────
// Colors are resolved from theme tokens in widget builds.

// ─────────────────────────────────────────────────────────────
//  LOOK DATA MODEL + SEED DATA
// ─────────────────────────────────────────────────────────────
class LookData {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final String bg;

  const LookData({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.bg,
  });
}

// Mirrors JS autoEnrich() seed output
final _seedLooks = <LookData>[
  LookData(id:'1', title:'The Power Move',   description:'Tailored black blazer with trousers',       emoji:'💼', category:'Power Suit',   bg:'bg-power'),
  LookData(id:'2', title:'Monday Meeting',   description:'Crisp button-up with pencil skirt',          emoji:'📋', category:'Business',     bg:'bg-business'),
  LookData(id:'3', title:'Creative Friday',  description:'Bold print blouse with smart chinos',         emoji:'🎨', category:'Creative',     bg:'bg-creative'),
  LookData(id:'4', title:'Clean Minimal',    description:'White crisp shirt with neutral trousers',     emoji:'🤍', category:'Minimal',      bg:'bg-minimal'),
  LookData(id:'5', title:'Boardroom Ready',  description:'Pinstripe suit with loafers',                 emoji:'💼', category:'Power Suit',   bg:'bg-power'),
];

// CSS per-bg gradient
LinearGradient _bgGradient(String bg, AppThemeTokens t) {
  switch (bg) {
    case 'bg-power':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.secondary.withValues(alpha: 0.25),
        t.accent.primary.withValues(alpha: 0.18),
      ]);
    case 'bg-smart':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.primary.withValues(alpha: 0.22),
        t.accent.tertiary.withValues(alpha: 0.18),
      ]);
    case 'bg-formal':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.backgroundPrimary.withValues(alpha: 0.50),
        t.accent.primary.withValues(alpha: 0.16),
      ]);
    case 'bg-business':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.secondary.withValues(alpha: 0.22),
        t.accent.tertiary.withValues(alpha: 0.18),
      ]);
    case 'bg-creative':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.tertiary.withValues(alpha: 0.22),
        t.accent.secondary.withValues(alpha: 0.20),
      ]);
    case 'bg-minimal':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.secondary.withValues(alpha: 0.14),
        t.accent.primary.withValues(alpha: 0.14),
      ]);
    case 'bg-casual':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.tertiary.withValues(alpha: 0.18),
        t.accent.primary.withValues(alpha: 0.20),
      ]);
    case 'bg-workwear':
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.tertiary.withValues(alpha: 0.20),
        t.accent.secondary.withValues(alpha: 0.18),
      ]);
    default:
      return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors:[
        t.accent.primary.withValues(alpha: 0.16),
        t.accent.secondary.withValues(alpha: 0.12),
      ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────────────────────
class OfficeFitScreen extends StatefulWidget {
  const OfficeFitScreen({super.key});
  @override State<OfficeFitScreen> createState() => _OfficeFitScreenState();
}

class _OfficeFitScreenState extends State<OfficeFitScreen> {
  List<LookData> _looks = List.from(_seedLooks);
  OverlayEntry? _toastEntry;

  // ── delete look (mirrors JS deleteLook) ──────────────────
  void _deleteLook(String id) =>
      setState(() => _looks = _looks.where((l) => l.id != id).toList());

  // ── share / copy toast (mirrors JS shareLook + showToast) ─
  void _shareLook(LookData look) =>
      _showToast('Copied: ${look.title} — ${look.description}');

  // ── try-on (mirrors JS tryOn) ────────────────────────────
  void _tryOn(LookData look) =>
      _showToast('✨ Try On: "${look.title}" — Coming soon!');

  // ── toast (mirrors CSS #toast opacity 0→1 / show class) ──
  void _showToast(String msg) {
    _toastEntry?.remove();
    _toastEntry = null;
    final entry = OverlayEntry(builder: (_) => _Toast(message: msg));
    _toastEntry = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(milliseconds: 2500), () {
      entry.remove();
      if (_toastEntry == entry) _toastEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final bg = t.backgroundPrimary;
    final bg2 = t.backgroundSecondary;
    return Scaffold(
      backgroundColor: bg,
      body: Container(
        // body gradient: linear-gradient(145deg, bg 0%, bg2 40%, bg 70%, bg2 100%)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4, 0.7, 1.0],
            colors: [bg, bg2, bg, bg2],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── header ──────────────────────────────────────
            _Header(
              looksCount: _looks.length,
              onBack: () => Navigator.maybePop(context),
            ),
            // ── scroll-area ──────────────────────────────────
            Expanded(
              child: Container(
                color: bg2,
                child: _looks.isEmpty
                    ? _EmptyState(onBack: () => Navigator.maybePop(context))
                    : _LooksGrid(
                  looks:    _looks,
                  onDelete: _deleteLook,
                  onShare:  _shareLook,
                  onTryOn:  _tryOn,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int looksCount;
  final VoidCallback onBack;
  const _Header({required this.looksCount, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    final countText = looksCount == 0
        ? 'No fits saved yet'
        : '$looksCount fit${looksCount != 1 ? 's' : ''} saved';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [t.phoneShell, t.phoneShellInner],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header-top row
        Row(children: [
          // [F002] animated back button
          _BackButton(onTap: onBack),
          const SizedBox(width: 8),
          Text('Office Fit 💼',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 14,
                  fontWeight: FontWeight.w700, color: t.textPrimary,
                  letterSpacing: -0.4)),
        ]),
        const SizedBox(height: 4),
        // header-subtitle
        Text('Your saved workwear inspiration',
            style: TextStyle(fontFamily: 'DMSans', fontSize: 10,
                fontWeight: FontWeight.w400,
                color: accent.secondary.withValues(alpha: 0.85))),
        const SizedBox(height: 1),
        // header-count
        Text(countText,
            style: TextStyle(fontFamily: 'DMMono', fontSize: 9,
                color: t.mutedText)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  [F002]  BACK BUTTON
//  CSS: :hover → background panel-2, translateX(-2px)
//       :active → scale(0.92)
//       transition: background 0.2s, transform 0.15s
// ─────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final tx    = (_hovered && !_pressed) ? -2.0 : 0.0;
    final scale = _pressed ? 0.92 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTap:       widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(tx, 0.0, 0.0)..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
          transformAlignment: Alignment.center,
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: _hovered ? t.panelBorder : t.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.panelBorder, width: 1),
          ),
          child: Icon(Icons.chevron_left_rounded,
              color: t.textPrimary, size: 17),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOOKS GRID
//  Mirrors HTML grid-template-columns: 1fr 1fr
//  First card (index 0) is .featured → grid-column: 1 / -1
// ─────────────────────────────────────────────────────────────
class _LooksGrid extends StatelessWidget {
  final List<LookData> looks;
  final ValueChanged<String>   onDelete;
  final ValueChanged<LookData> onShare;
  final ValueChanged<LookData> onTryOn;
  const _LooksGrid({required this.looks, required this.onDelete,
    required this.onShare, required this.onTryOn});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Featured card (index 0) — full width
    rows.add(_LookCard(
      look: looks[0], featured: true, index: 0,
      onDelete: () => onDelete(looks[0].id),
      onShare:  () => onShare(looks[0]),
      onTryOn:  () => onTryOn(looks[0]),
    ));

    // Remaining cards in 2-column pairs
    for (int i = 1; i < looks.length; i += 2) {
      final a = looks[i];
      final b = (i + 1 < looks.length) ? looks[i + 1] : null;
      rows.add(const SizedBox(height: 6));
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _LookCard(look: a, featured: false, index: i,
            onDelete: () => onDelete(a.id), onShare: () => onShare(a), onTryOn: () => onTryOn(a))),
        const SizedBox(width: 6),
        Expanded(child: b != null
            ? _LookCard(look: b, featured: false, index: i + 1,
            onDelete: () => onDelete(b.id), onShare: () => onShare(b), onTryOn: () => onTryOn(b))
            : const SizedBox()),
      ]));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  [F001] [F003] [F004]  LOOK CARD
//
//  F001 — @keyframes fadeUp  opacity 0→1 + translateY(14px→0)
//          animation-delay = index * 0.07s
//  F003 — :hover  translateY(-3px) + bigger shadow + accent border
//  F004 — :active scale(0.96)
// ─────────────────────────────────────────────────────────────
class _LookCard extends StatefulWidget {
  final LookData  look;
  final bool      featured;
  final int       index;      // for stagger delay
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onTryOn;

  const _LookCard({
    required this.look, required this.featured, required this.index,
    required this.onDelete, required this.onShare, required this.onTryOn,
  });
  @override State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard> with TickerProviderStateMixin {

  // ── [F001] fadeUp entry ──────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryOpacity;
  late final Animation<double>   _entryY;

  // hover / press state
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    // [F001] 400ms ease, delayed by index * 70ms
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _entryOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryY = Tween(begin: 14.0, end: 0.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    final aspectRatio = widget.featured ? 2.0 : 1.0;

    // [F003] hover → translateY(-3px); [F004] press → scale(0.96)
    final ty    = (_hovered && !_pressed) ? -3.0 : 0.0;
    final scale = _pressed ? 0.96 : 1.0;

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (ctx, child) => Opacity(
        opacity: _entryOpacity.value,
        child: Transform.translate(offset: Offset(0, _entryY.value), child: child),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
        child: GestureDetector(
          onTap: () {}, // OPEN_LOOK placeholder
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) => setState(() => _pressed = false),
          onTapCancel: ()  => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // [F003] transform
            transform: Matrix4.translationValues(0.0, ty, 0.0)..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
            transformAlignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _hovered ? accent.primary : t.cardBorder, width: 1.5),
              // [F003] shadow enhancement on hover
              boxShadow: [BoxShadow(
                color: _hovered
                    ? accent.primary.withValues(alpha: 0.18)
                    : accent.primary.withValues(alpha: 0.08),
                blurRadius: _hovered ? 28 : 12,
                offset: Offset(0, _hovered ? 8 : 2),
              )],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ── image / placeholder area ─────────────────
              Stack(children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: _bgGradient(widget.look.bg, t)),
                    child: Center(child: Text(widget.look.emoji,
                        style: const TextStyle(fontSize: 20))),
                  ),
                ),
                // [F006] share btn — top-left, visible on parent hover
                Positioned(top: 8, left: 8,
                    child: _OverlayIconBtn(
                      visible:          _hovered,
                      icon:             Icons.share_rounded,
                      hoverBg:          accent.primary.withValues(alpha: 0.40),
                      hoverBorderColor: accent.primary,
                      onTap:            widget.onShare,
                    )),
                // [F005] delete btn — top-right, visible on parent hover
                Positioned(top: 8, right: 8,
                    child: _OverlayIconBtn(
                      visible:          _hovered,
                      icon:             Icons.close_rounded,
                      hoverBg:          accent.tertiary.withValues(alpha: 0.40),
                      hoverBorderColor: accent.tertiary,
                      onTap:            widget.onDelete,
                    )),
              ]),

              // ── card-info ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 5, 7, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // cat-badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                        color: t.panelBorder,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '${widget.look.emoji} ${widget.look.category}'.toUpperCase(),
                      style: TextStyle(fontFamily: 'DMSans', fontSize: 7,
                          fontWeight: FontWeight.w600, letterSpacing: 0.42,
                          color: accent.primary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // card-title
                  Text(widget.look.title,
                      style: TextStyle(fontFamily: 'DMSans', fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary, height: 1.2)),
                  const SizedBox(height: 1),
                  // card-desc
                  Text(widget.look.description,
                      style: TextStyle(fontFamily: 'DMSans', fontSize: 8,
                          color: t.mutedText, height: 1.3)),
                  const SizedBox(height: 6),
                ]),
              ),

              // [F007] try-on button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _TryOnButton(onTap: widget.onTryOn),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  [F005 / F006]  OVERLAY ICON BUTTONS  (delete & share)
//
//  CSS: opacity 0 normally, 1 when parent hovered (passed in)
//       :hover → custom bg + border colour
//       :active → scale(0.88)
//       transition: opacity 0.2s, transform 0.15s
// ─────────────────────────────────────────────────────────────
class _OverlayIconBtn extends StatefulWidget {
  final bool       visible;          // parent hover state drives opacity
  final IconData   icon;
  final Color      hoverBg;
  final Color      hoverBorderColor;
  final VoidCallback onTap;
  const _OverlayIconBtn({
    required this.visible, required this.icon,
    required this.hoverBg, required this.hoverBorderColor,
    required this.onTap,
  });
  @override State<_OverlayIconBtn> createState() => _OverlayIconBtnState();
}

class _OverlayIconBtnState extends State<_OverlayIconBtn> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final scale = _pressed ? 0.88 : 1.0; // [F005/F006] :active scale(0.88)

    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
          child: GestureDetector(
            onTap:       widget.onTap,
            onTapDown:   (_) => setState(() => _pressed = true),
            onTapUp:     (_) => setState(() => _pressed = false),
            onTapCancel: ()  => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              transformAlignment: Alignment.center,
              width: 26, height: 26,
              decoration: BoxDecoration(
                // default: rgba(8,17,31,0.72), hover: colour-coded
                color: _hovered
                    ? widget.hoverBg
                    : t.backgroundPrimary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _hovered ? widget.hoverBorderColor : t.cardBorder),
              ),
              child: Icon(widget.icon, color: t.textPrimary, size: 12),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  [F007]  TRY-ON BUTTON
//
//  CSS: background linear-gradient accent2→accent→accent2
//       :hover  → translateY(-2px), enhanced box-shadow
//       :hover::before → shimmer band sweeps left:-60% → left:130%
//                        over 0.55s ease
//       :active → scale(0.96) translateY(0)
//       transition: transform 0.18s, box-shadow 0.18s
// ─────────────────────────────────────────────────────────────
class _TryOnButton extends StatefulWidget {
  final VoidCallback onTap;
  const _TryOnButton({required this.onTap});
  @override State<_TryOnButton> createState() => _TryOnButtonState();
}

class _TryOnButtonState extends State<_TryOnButton>
    with SingleTickerProviderStateMixin {

  bool _hovered = false;
  bool _pressed = false;

  // shimmer controller — replays each time hover enters
  late final AnimationController _shimCtrl;
  late final Animation<double>   _shimPos; // 0 = left:-60%, 1 = left:130%

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _shimPos = Tween(begin: -0.6, end: 1.3)
        .animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _shimCtrl.dispose(); super.dispose(); }

  void _enter() {
    setState(() => _hovered = true);
    _shimCtrl.forward(from: 0); // replay shimmer
  }
  void _exit() {
    setState(() { _hovered = false; _pressed = false; });
    _shimCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    // [F007] hover lift; active cancels lift + squishes
    final ty    = (_hovered && !_pressed) ? -2.0 : 0.0;
    final scale = _pressed ? 0.96 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _enter(),
      onExit:  (_) => _exit(),
      child: GestureDetector(
        onTap:       widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0.0, ty, 0.0)..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
              colors: [accent.secondary, accent.primary, accent.secondary],
            ),
            boxShadow: [
              BoxShadow(
                // [F007] hover → enhanced shadow
                color: _hovered
                    ? accent.secondary.withValues(alpha: 0.50)
                    : accent.primary.withValues(alpha: 0.40),
                blurRadius: _hovered ? 18 : 12,
                offset:     Offset(0, _hovered ? 6 : 3),
              ),
              BoxShadow(
                  color: t.textPrimary.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: Offset(0, 1)),
            ],
          ),
          // ClipRRect keeps shimmer inside the rounded rect
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              // ── label row ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: t.textPrimary, size: 12),
                    const SizedBox(width: 5),
                    Text('Try On', style: TextStyle(
                        fontFamily: 'DMSans', fontSize: 10.5,
                        fontWeight: FontWeight.w700, color: t.textPrimary,
                        letterSpacing: 0.42)),
                  ],
                ),
              ),
              // ── [F007] shimmer band (::before pseudo) ──
              AnimatedBuilder(
                animation: _shimPos,
                builder: (_, _) => Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(_shimPos.value, 0),
                    child: Transform(
                      // skewX(-20deg) ≈ -tan(20°) ≈ -0.364
                      transform: Matrix4.skewX(-0.364),
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        widthFactor: 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              t.textPrimary.withValues(alpha: 0.0),
                              t.textPrimary.withValues(alpha: 0.20),
                              t.textPrimary.withValues(alpha: 0.0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE  (mirrors .empty-state HTML block)
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent = t.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('👔', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text('No fits yet',
              style: TextStyle(fontFamily: 'DMSans', fontSize: 16,
                  fontWeight: FontWeight.w700, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Save office fits from the chat and\nthey\'ll appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
                color: t.mutedText, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [accent.secondary, accent.primary]),
                boxShadow: [BoxShadow(
                    color: accent.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: Offset(0, 4))],
              ),
              child: Text('Back to Boards',
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
                      fontWeight: FontWeight.w600, color: t.textPrimary)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOAST  (mirrors CSS #toast / .show  — opacity 0↔1  0.3s)
// ─────────────────────────────────────────────────────────────
class _Toast extends StatefulWidget {
  final String message;
  const _Toast({required this.message});
  @override State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1900),
            () { if (mounted) _ctrl.reverse(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Positioned(
      bottom: 28, left: 0, right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: t.backgroundPrimary.withValues(alpha: 0.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: t.phoneShell,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.cardBorder),
              ),
              child: Text(widget.message,
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                      fontWeight: FontWeight.w500, color: t.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT  (remove / replace with your own main if needed)
// ─────────────────────────────────────────────────────────────
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Office Fit',
      debugShowCheckedModeBanner: false,
      theme: BaseTheme.dark,
      darkTheme: BaseTheme.dark,
      themeMode: ThemeMode.dark,
      home: const OfficeFitScreen(),
    );
  }
}
