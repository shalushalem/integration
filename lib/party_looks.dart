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
// ─── Data ────────────────────────────────────────────────────────────────────

class Look {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final String? imageUrl;
  final LookBg bg;

  const Look({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.imageUrl,
    required this.bg,
  });
}

enum LookBg { glam, cocktail, club, nightout, themed, birthday, casual, formal, dflt }

LinearGradient bgGradient(LookBg bg, AppThemeTokens t) {
  switch (bg) {
    case LookBg.glam:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.30), t.accent.tertiary.withValues(alpha: 0.25)],
      );
    case LookBg.cocktail:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.25), t.accent.tertiary.withValues(alpha: 0.22)],
      );
    case LookBg.club:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.tertiary.withValues(alpha: 0.20), t.accent.primary.withValues(alpha: 0.20)],
      );
    case LookBg.nightout:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.backgroundPrimary.withValues(alpha: 0.50), t.accent.primary.withValues(alpha: 0.20)],
      );
    case LookBg.themed:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.25), t.accent.secondary.withValues(alpha: 0.25)],
      );
    case LookBg.birthday:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.tertiary.withValues(alpha: 0.25), t.accent.secondary.withValues(alpha: 0.22)],
      );
    case LookBg.casual:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.tertiary.withValues(alpha: 0.15), t.accent.primary.withValues(alpha: 0.15)],
      );
    case LookBg.formal:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.backgroundPrimary.withValues(alpha: 0.40), t.accent.secondary.withValues(alpha: 0.20)],
      );
    case LookBg.dflt:
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [t.accent.primary.withValues(alpha: 0.16), t.accent.secondary.withValues(alpha: 0.12)],
      );
  }
}

// ─── Constants ───────────────────────────────────────────────────────────────

// Colors are resolved from theme tokens in widget state.

// ─── Sample data ─────────────────────────────────────────────────────────────

final _sampleLooks = [
  const Look(id: '1', title: 'Disco Queen',    description: 'Silver sequin mini dress',          emoji: '✨', category: 'Glam',     bg: LookBg.glam),
  const Look(id: '2', title: 'Midnight Glam',  description: 'Black bodycon with heels',           emoji: '🌙', category: 'Nightout', bg: LookBg.nightout),
  const Look(id: '3', title: 'Birthday Glow',  description: 'Sparkly pink birthday dress',        emoji: '🎂', category: 'Birthday', bg: LookBg.birthday),
  const Look(id: '4', title: 'Cocktail Hour',  description: 'Emerald wrap midi dress',            emoji: '🍸', category: 'Cocktail', bg: LookBg.cocktail),
  const Look(id: '5', title: 'Club Ready',     description: 'Neon bodycon with bold accessories', emoji: '🎧', category: 'Club',     bg: LookBg.club),
];

// ─── Root Screen ─────────────────────────────────────────────────────────────

class Screen4 extends StatefulWidget {
  const Screen4({super.key});
  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> {
  AppThemeTokens get _t => context.themeTokens;
  Color get _bg => _t.backgroundPrimary;
  Color get _bg2 => _t.backgroundSecondary;

  final List<Look> _looks = List.from(_sampleLooks);
  OverlayEntry? _toast;

  void _deleteLook(String id) => setState(() => _looks.removeWhere((l) => l.id == id));

  void _showToast(String msg) {
    _toast?.remove();
    _toast = OverlayEntry(
      builder: (_) => _ToastWidget(message: msg),
    );
    Overlay.of(context).insert(_toast!);
    Future.delayed(const Duration(milliseconds: 2200), () {
      _toast?.remove();
      _toast = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4, 0.7, 1.0],
            colors: [_bg, _bg2, _t.phoneShellInner, _bg2],
            transform: const GradientRotation(145 * 3.14159 / 180),
          ),
        ),
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: Container(
                color: _bg,
                child: _looks.isEmpty
                    ? _EmptyState()
                    : _LooksGrid(
                  looks: _looks,
                  onDelete: _deleteLook,
                  onShare: (look) => _showToast('Copied!'),
                  onTryOn: (look) => _showToast('✨ Try On: "${look.title}"'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [t.phoneShellInner, t.phoneShell, t.backgroundSecondary],
          transform: const GradientRotation(135 * 3.14159 / 180),
        ),
      ),
      child: Stack(
        children: [
          // top-right pink glow
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.tertiary.withValues(alpha: 0.30), t.backgroundPrimary.withValues(alpha: 0.0)],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          // bottom-left yellow glow
          Positioned(
            bottom: -20, left: 20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.secondary.withValues(alpha: 0.20), t.backgroundPrimary.withValues(alpha: 0.0)],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header-top
              Row(
                children: [
                  _BackButton(),
                  const SizedBox(width: 8),
                  Text(
                    'Party Looks 🪩',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // header-meta
              Text(
                'Your saved party inspiration',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: t.accent.tertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_sampleLooks.length} looks saved',
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 10,
                  color: t.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.panelBorder, width: 1),
        ),
        child: Center(
          child: Icon(Icons.chevron_left, color: t.textPrimary, size: 16),
        ),
      ),
    );
  }
}

// ─── Looks Grid ──────────────────────────────────────────────────────────────

class _LooksGrid extends StatelessWidget {
  final List<Look> looks;
  final void Function(String id) onDelete;
  final void Function(Look look) onShare;
  final void Function(Look look) onTryOn;

  const _LooksGrid({
    required this.looks,
    required this.onDelete,
    required this.onShare,
    required this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // featured card (index 0, full width)
          if (looks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LookCard(
                look: looks[0],
                featured: true,
                onDelete: () => onDelete(looks[0].id),
                onShare: () => onShare(looks[0]),
                onTryOn: () => onTryOn(looks[0]),
              ),
            ),
          // 2-column grid for remaining
          _buildTwoColumnGrid(looks.skip(1).toList()),
        ],
      ),
    );
  }

  Widget _buildTwoColumnGrid(List<Look> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LookCard(
                  look: items[i],
                  featured: false,
                  onDelete: () => onDelete(items[i].id),
                  onShare: () => onShare(items[i]),
                  onTryOn: () => onTryOn(items[i]),
                ),
              ),
              if (i + 1 < items.length) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _LookCard(
                    look: items[i + 1],
                    featured: false,
                    onDelete: () => onDelete(items[i + 1].id),
                    onShare: () => onShare(items[i + 1]),
                    onTryOn: () => onTryOn(items[i + 1]),
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ─── Look Card ───────────────────────────────────────────────────────────────

class _LookCard extends StatefulWidget {
  final Look look;
  final bool featured;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onTryOn;

  const _LookCard({
    required this.look,
    required this.featured,
    required this.onDelete,
    required this.onShare,
    required this.onTryOn,
  });

  @override
  State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? t.accent.primary : t.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? t.accent.primary.withValues(alpha: 0.20)
                    : t.accent.primary.withValues(alpha: 0.08),
                blurRadius: _hovered ? 28 : 12,
                offset: Offset(0, _hovered ? 8 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    // image / placeholder
                    widget.look.imageUrl != null
                        ? AspectRatio(
                      aspectRatio: widget.featured ? 2 / 1 : 1 / 1,
                      child: Image.network(
                        widget.look.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : _ImgPlaceholder(
                      look: widget.look,
                      featured: widget.featured,
                    ),
                    // share button (top-left)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _hovered ? 1.0 : 0.0,
                      child: Positioned(
                        top: 8, left: 8,
                        child: _IconOverlayBtn(
                          icon: Icons.share_outlined,
                          onTap: widget.onShare,
                          hoverColor: t.accent.tertiary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    // delete button (top-right)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _hovered ? 1.0 : 0.0,
                      child: Positioned(
                        top: 8, right: 8,
                        child: _IconOverlayBtn(
                          icon: Icons.close,
                          onTap: widget.onDelete,
                          hoverColor: t.accent.secondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                // card-info
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // cat-badge
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: t.panel,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${widget.look.emoji} ${widget.look.category.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            color: t.accent.tertiary,
                            letterSpacing: 0.06 * 7,
                          ),
                        ),
                      ),
                      // card-title
                      Text(
                        widget.look.title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                        height: 1.3,
                      ),
                    ),
                      const SizedBox(height: 2),
                      // card-desc
                      Text(
                        widget.look.description,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        color: t.mutedText,
                        height: 1.4,
                      ),
                    ),
                    ],
                  ),
                ),
                // try-on-btn
                _TryOnButton(onTap: widget.onTryOn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Image Placeholder ───────────────────────────────────────────────────────

class _ImgPlaceholder extends StatelessWidget {
  final Look look;
  final bool featured;

  const _ImgPlaceholder({required this.look, required this.featured});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return AspectRatio(
      aspectRatio: featured ? 2 / 1 : 1 / 1,
      child: Container(
        decoration: BoxDecoration(gradient: bgGradient(look.bg, t)),
        child: Center(
          child: Text(look.emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

// ─── Overlay Icon Button ─────────────────────────────────────────────────────

class _IconOverlayBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

  const _IconOverlayBtn({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
  });

  @override
  State<_IconOverlayBtn> createState() => _IconOverlayBtnState();
}

class _IconOverlayBtnState extends State<_IconOverlayBtn> {
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
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : t.phoneShellInner.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.cardBorder, width: 1),
          ),
          child: Icon(widget.icon, color: t.textPrimary, size: 11),
        ),
      ),
    );
  }
}

// ─── Try On Button ───────────────────────────────────────────────────────────

class _TryOnButton extends StatefulWidget {
  final VoidCallback onTap;
  const _TryOnButton({required this.onTap});

  @override
  State<_TryOnButton> createState() => _TryOnButtonState();
}

class _TryOnButtonState extends State<_TryOnButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: t.accent.secondary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: t.accent.secondary.withValues(alpha: 0.45),
                  blurRadius: _hovered ? 18 : 12,
                  offset: Offset(0, _hovered ? 6 : 3),
                ),
                BoxShadow(
                  color: t.backgroundPrimary.withValues(alpha: 0.16),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: onAccent, size: 12),
                const SizedBox(width: 5),
                Text(
                  'Try On',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: onAccent,
                    letterSpacing: 0.04 * 10.5,
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

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪩', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'No looks yet',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save party looks from the chat and they\'ll appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: t.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [t.accent.tertiary, t.accent.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: t.accent.tertiary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Back to Boards',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toast Widget ─────────────────────────────────────────────────────────────

class _ToastWidget extends StatelessWidget {
  final String message;
  const _ToastWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Positioned(
      bottom: 28,
      left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: t.backgroundSecondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
