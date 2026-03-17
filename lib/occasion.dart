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

class LookItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final String? imageUrl;
  final BadgeStyle badge;
  final PlaceholderBg bg;

  const LookItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.imageUrl,
    required this.badge,
    required this.bg,
  });
}

enum BadgeStyle { wedding, gala, formal, garden, brunch, date, defaultBadge }
enum PlaceholderBg { wedding, gala, formal, garden, brunch, date, defaultBg }

// ─── Colors / tokens ─────────────────────────────────────────────────────────


// ─── Sample data (mirrors the JS defaults) ───────────────────────────────────

final _sampleLooks = [
  LookItem(
    id: '1', title: 'Garden Wedding Guest',
    description: 'Floral midi in blush & ivory',
    emoji: '🌸', category: 'Garden Party',
    badge: BadgeStyle.garden, bg: PlaceholderBg.garden,
  ),
  LookItem(
    id: '2', title: 'Black Tie Gala',
    description: 'Floor-length emerald gown with gold',
    emoji: '✨', category: 'Gala',
    badge: BadgeStyle.gala, bg: PlaceholderBg.gala,
  ),
  LookItem(
    id: '3', title: 'Sunday Brunch',
    description: 'Linen wrap dress in sage green',
    emoji: '☀️', category: 'Brunch',
    badge: BadgeStyle.brunch, bg: PlaceholderBg.brunch,
  ),
  LookItem(
    id: '4', title: 'Rooftop Date Night',
    description: 'Sleek silk slip with strappy heels',
    emoji: '🌙', category: 'Date Night',
    badge: BadgeStyle.date, bg: PlaceholderBg.date,
  ),
  LookItem(
    id: '5', title: 'Bridal Shower',
    description: 'Soft white lace tea-length dress',
    emoji: '💍', category: 'Wedding',
    badge: BadgeStyle.wedding, bg: PlaceholderBg.wedding,
  ),
  LookItem(
    id: '6', title: 'Award Ceremony',
    description: 'Tailored navy blazer dress with pearls',
    emoji: '🥂', category: 'Formal',
    badge: BadgeStyle.formal, bg: PlaceholderBg.formal,
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class Screen4 extends StatelessWidget {
  const Screen4({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.6, -1),
            end: const Alignment(0.6, 1),
            colors: [t.backgroundPrimary, t.backgroundSecondary, t.backgroundPrimary],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: _ScrollArea(looks: _sampleLooks),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [t.phoneShellInner, t.phoneShell, t.backgroundSecondary],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ::before  – yellow radial glow top-right
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.secondary.withValues(alpha: 0.30), t.backgroundPrimary.withValues(alpha: 0.0)],
                  stops: const [0, 0.65],
                ),
              ),
            ),
          ),
          // ::after  – pink radial glow bottom-left
          Positioned(
            bottom: -20,
            left: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.tertiary.withValues(alpha: 0.20), t.backgroundPrimary.withValues(alpha: 0.0)],
                  stops: const [0, 0.65],
                ),
              ),
            ),
          ),
          // Actual content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header-top
                  Row(
                    children: [
                      // back-btn
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: t.panel,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.cardBorder, width: 1),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: t.textPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // header-title
                      Text(
                        'Occasion Looks 💍',
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
                    'Your saved occasion inspiration',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: t.accent.secondary,
                      height: 1,
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
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scroll area + grid ───────────────────────────────────────────────────────

class _ScrollArea extends StatelessWidget {
  final List<LookItem> looks;
  const _ScrollArea({required this.looks});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      color: t.backgroundPrimary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8),
        child: _LooksGrid(looks: looks),
      ),
    );
  }
}

class _LooksGrid extends StatelessWidget {
  final List<LookItem> looks;
  const _LooksGrid({required this.looks});

  @override
  Widget build(BuildContext context) {
    // Featured card (index 0) spans full width; rest are 2-column pairs.
    final List<Widget> rows = [];

    for (int i = 0; i < looks.length; i++) {
      if (i == 0) {
        // featured – full width
        rows.add(_LookCard(look: looks[i], featured: true));
        rows.add(const SizedBox(height: 8));
      } else if (i % 2 == 1) {
        // start of a pair
        final hasNext = i + 1 < looks.length;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _LookCard(look: looks[i], featured: false)),
                if (hasNext) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _LookCard(look: looks[i + 1], featured: false)),
                ],
              ],
            ),
          ),
        );
        rows.add(const SizedBox(height: 8));
      }
      // index i+1 already rendered above in the pair
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ─── Look card ────────────────────────────────────────────────────────────────

class _LookCard extends StatefulWidget {
  final LookItem look;
  final bool featured;
  const _LookCard({required this.look, required this.featured});

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
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: t.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? t.accent.primary : t.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? t.accent.primary.withValues(alpha: 0.22)
                    : t.accent.primary.withValues(alpha: 0.10),
                blurRadius: _hovered ? 28 : 12,
                offset:  Offset(0, _hovered ? 8 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  _PlaceholderImage(
                    look: widget.look,
                    featured: widget.featured,
                  ),
                  // delete btn (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                      child: _OverlayIconBtn(
                        visible: _hovered,
                        onTap: () {},
                        hoverColor: t.accent.tertiary.withValues(alpha: 0.40),
                        child: Icon(Icons.close, color: t.textPrimary, size: 11),
                      ),
                    ),
                  // share btn (top-left)
                  Positioned(
                    top: 8,
                    left: 8,
                      child: _OverlayIconBtn(
                        visible: _hovered,
                        onTap: () {},
                        hoverColor: t.accent.primary.withValues(alpha: 0.40),
                        child: Icon(Icons.share_outlined, color: t.textPrimary, size: 11),
                      ),
                    ),
                ],
              ),
              _CardInfo(look: widget.look),
              _TryOnButton(onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Placeholder image ────────────────────────────────────────────────────────

class _PlaceholderImage extends StatelessWidget {
  final LookItem look;
  final bool featured;
  const _PlaceholderImage({required this.look, required this.featured});

  LinearGradient _bgGradient(AppThemeTokens t) {
    switch (look.bg) {
      case PlaceholderBg.wedding:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.tertiary.withValues(alpha: 0.20), t.accent.secondary.withValues(alpha: 0.18)],
        );
      case PlaceholderBg.gala:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.secondary.withValues(alpha: 0.20), t.accent.secondary.withValues(alpha: 0.16)],
        );
      case PlaceholderBg.formal:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.primary.withValues(alpha: 0.20), t.accent.secondary.withValues(alpha: 0.16)],
        );
      case PlaceholderBg.garden:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.tertiary.withValues(alpha: 0.18), t.accent.primary.withValues(alpha: 0.14)],
        );
      case PlaceholderBg.brunch:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.secondary.withValues(alpha: 0.20), t.accent.tertiary.withValues(alpha: 0.14)],
        );
      case PlaceholderBg.date:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.secondary.withValues(alpha: 0.16), t.accent.tertiary.withValues(alpha: 0.18)],
        );
      case PlaceholderBg.defaultBg:
        return LinearGradient(
          begin: Alignment(-1, -1), end: Alignment(1, 1),
          colors: [t.accent.primary.withValues(alpha: 0.14), t.accent.secondary.withValues(alpha: 0.12)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return AspectRatio(
      aspectRatio: featured ? 2 / 1 : 1 / 1,
      child: look.imageUrl != null
          ? Image.network(look.imageUrl!, fit: BoxFit.cover)
          : Container(
        decoration: BoxDecoration(gradient: _bgGradient(t)),
        child: Center(
          child: Text(look.emoji,
              style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

// ─── Card info ────────────────────────────────────────────────────────────────

class _CardInfo extends StatelessWidget {
  final LookItem look;
  const _CardInfo({required this.look});

  _BadgeColors _badgeColors(AppThemeTokens t) {
    switch (look.badge) {
      case BadgeStyle.wedding:
        return _BadgeColors(bg: t.accent.tertiary.withValues(alpha: 0.20), text: t.accent.tertiary);
      case BadgeStyle.gala:
        return _BadgeColors(bg: t.accent.secondary.withValues(alpha: 0.20), text: t.accent.secondary);
      case BadgeStyle.formal:
        return _BadgeColors(bg: t.accent.primary.withValues(alpha: 0.20), text: t.accent.primary);
      case BadgeStyle.garden:
        return _BadgeColors(bg: t.accent.tertiary.withValues(alpha: 0.18), text: t.accent.tertiary);
      case BadgeStyle.brunch:
        return _BadgeColors(bg: t.accent.secondary.withValues(alpha: 0.20), text: t.accent.secondary);
      case BadgeStyle.date:
        return _BadgeColors(bg: t.accent.tertiary.withValues(alpha: 0.16), text: t.accent.tertiary);
      case BadgeStyle.defaultBadge:
        return _BadgeColors(bg: t.cardBorder.withValues(alpha: 0.40), text: t.accent.secondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final bc = _badgeColors(t);
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: bc.bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${look.emoji} ${look.category}'.toUpperCase(),
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 7,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06 * 7,
                color: bc.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // title
          Text(
            look.title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          // description
          Text(
            look.description,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 9,
              color: t.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeColors {
  final Color bg;
  final Color text;
  const _BadgeColors({required this.bg, required this.text});
}

// ─── Try-On button ────────────────────────────────────────────────────────────

class _TryOnButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TryOnButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: [t.accent.secondary, t.accent.primary, t.accent.secondary],
              stops: const [0, 0.5, 1],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: t.accent.primary.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 3),
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
    );
  }
}

// ─── Overlay icon button (delete / share) ─────────────────────────────────────

class _OverlayIconBtn extends StatefulWidget {
  final bool visible;
  final VoidCallback onTap;
  final Widget child;
  final Color hoverColor;
  const _OverlayIconBtn({
    required this.visible,
    required this.onTap,
    required this.child,
    required this.hoverColor,
  });

  @override
  State<_OverlayIconBtn> createState() => _OverlayIconBtnState();
}

class _OverlayIconBtnState extends State<_OverlayIconBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.visible ? 1 : 0,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: t.phoneShellInner.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.cardBorder, width: 1),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
