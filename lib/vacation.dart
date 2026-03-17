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

// ─── Color tokens ────────────────────────────────────────────────────────────

// ─── Data model ──────────────────────────────────────────────────────────────
class VacationLook {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final LookBg bg;

  const VacationLook({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.bg,
  });
}

enum LookBg { beach, pool, dinner, night, explore, brunch, resort, casual, def }

LinearGradient _bgGradient(LookBg bg, AppThemeTokens t) {
  switch (bg) {
    case LookBg.beach:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.30), t.accent.primary.withValues(alpha: 0.25)],
      );
    case LookBg.pool:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.tertiary.withValues(alpha: 0.30), t.accent.primary.withValues(alpha: 0.25)],
      );
    case LookBg.dinner:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.backgroundPrimary.withValues(alpha: 0.40), t.accent.secondary.withValues(alpha: 0.20)],
      );
    case LookBg.night:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.25), t.accent.tertiary.withValues(alpha: 0.22)],
      );
    case LookBg.explore:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.tertiary.withValues(alpha: 0.25), t.accent.secondary.withValues(alpha: 0.22)],
      );
    case LookBg.brunch:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.22), t.accent.tertiary.withValues(alpha: 0.18)],
      );
    case LookBg.resort:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.primary.withValues(alpha: 0.20), t.accent.tertiary.withValues(alpha: 0.20)],
      );
    case LookBg.casual:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.accent.secondary.withValues(alpha: 0.20), t.accent.primary.withValues(alpha: 0.20)],
      );
    case LookBg.def:
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [t.backgroundPrimary, t.backgroundSecondary],
      );
  }
}

// ─── Sample data (mirrors the JS defaults) ───────────────────────────────────
final _sampleLooks = [
  const VacationLook(id: '1', title: 'Golden Hour', description: 'Linen co-ord set', emoji: '🌴', category: 'Resort', bg: LookBg.resort),
  const VacationLook(id: '2', title: 'Midnight Blue', description: 'Silk slip dress for evening dinner', emoji: '🌙', category: 'Dinner', bg: LookBg.dinner),
  const VacationLook(id: '3', title: 'Jungle Walk', description: 'Utility cargo set', emoji: '🌿', category: 'Explorer', bg: LookBg.explore),
  const VacationLook(id: '4', title: 'Pool Bar Vibes', description: 'Floral bikini set', emoji: '🍹', category: 'Pool', bg: LookBg.pool),
  const VacationLook(id: '5', title: 'The Gold Hour', description: 'Sequin mini for night out', emoji: '✨', category: 'Nightout', bg: LookBg.night),
];

// ─── Root screen ─────────────────────────────────────────────────────────────
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.4, 0.7, 1.0],
            colors: [t.backgroundPrimary, t.backgroundSecondary, t.phoneShell, t.backgroundSecondary],
          ),
        ),
        child: Column(
          children: const [
            _Header(),
            Expanded(child: _ScrollArea()),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [t.phoneShellInner, t.phoneShell, t.backgroundSecondary],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      child: Stack(
        children: [
          // Radial orb top-right
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.primary.withValues(alpha: 0.30), t.backgroundPrimary.withValues(alpha: 0.0)],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          // Radial orb bottom-left
          Positioned(
            bottom: -15,
            left: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.tertiary.withValues(alpha: 0.25), t.backgroundPrimary.withValues(alpha: 0.0)],
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
                    'Vacation Looks 🌴',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your saved travel inspiration',
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
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.panelBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.chevron_left_rounded,
          color: t.textPrimary,
          size: 15,
        ),
      ),
    );
  }
}

// ─── Scroll area / grid ───────────────────────────────────────────────────────
class _ScrollArea extends StatelessWidget {
  const _ScrollArea();

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final looks = _sampleLooks;
    // Build rows: first card is featured (full width), rest are 2-col pairs
    final List<Widget> rows = [];

    for (int i = 0; i < looks.length; i++) {
      if (i == 0) {
        // Featured card – full width, aspect ratio 2:1
        rows.add(_LookCard(look: looks[i], featured: true));
        rows.add(const SizedBox(height: 8));
      } else {
        // Pair them 2 per row
        if ((i % 2) == 1) {
          final hasNext = i + 1 < looks.length;
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _LookCard(look: looks[i], featured: false)),
              const SizedBox(width: 8),
              if (hasNext)
                Expanded(child: _LookCard(look: looks[i + 1], featured: false))
              else
                const Expanded(child: SizedBox()),
            ],
          ));
          rows.add(const SizedBox(height: 8));
          i += hasNext ? 1 : 0; // skip next since we consumed it
        }
      }
    }

    return Container(
      color: t.backgroundPrimary,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: rows,
      ),
    );
  }
}

// ─── Look card ────────────────────────────────────────────────────────────────
class _LookCard extends StatefulWidget {
  final VacationLook look;
  final bool featured;
  const _LookCard({required this.look, required this.featured});

  @override
  State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = widget.featured ? 2.0 : 1.0;
    final t = context.themeTokens;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
              color: t.accent.primary.withValues(alpha: 0.10),
              blurRadius: _hovered ? 28 : 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image / placeholder
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _bgGradient(widget.look.bg, t),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.look.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
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
                          '${widget.look.emoji} ${widget.look.category}'.toUpperCase(),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // try-on-btn
                _TryOnButton(look: widget.look),
              ],
            ),
            // delete-btn (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: _IconActionButton(
                visible: _hovered,
                onTap: () {},
                child: Icon(Icons.close, color: t.textPrimary, size: 11),
              ),
            ),
            // share-btn (top-left)
            Positioned(
              top: 8,
              left: 8,
              child: _IconActionButton(
                visible: _hovered,
                onTap: () {},
                child: Icon(Icons.share_outlined, color: t.textPrimary, size: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Icon action button (delete / share) ─────────────────────────────────────
class _IconActionButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  final Widget child;
  const _IconActionButton({required this.visible, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: t.phoneShellInner.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.cardBorder, width: 1),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

// ─── Try-On button ───────────────────────────────────────────────────────────
class _TryOnButton extends StatelessWidget {
  final VacationLook look;
  const _TryOnButton({required this.look});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: t.accent.secondary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: t.accent.secondary.withValues(alpha: 0.45),
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
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
