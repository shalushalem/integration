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

// ── Color constants ──────────────────────────────────────────────────────────

// ── Data model ───────────────────────────────────────────────────────────────
class LookItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final String? imageUrl;
  final String filter;
  final LookBadgeStyle badge;
  final LookBgStyle bg;

  const LookItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.imageUrl,
    required this.filter,
    required this.badge,
    required this.bg,
  });
}

enum LookBadgeStyle { streetwear, athleisure, boho, minimalist, vintage, monochrome, cottagecore, defaultBadge }
enum LookBgStyle { streetwear, athleisure, boho, minimalist, vintage, monochrome, cottagecore, defaultBg }

final List<LookItem> kSampleLooks = [
  const LookItem(
    id: '1', title: 'Urban Street Layers',
    description: 'Oversized bomber, cargo pants & chunky sneakers',
    emoji: '🧢', category: 'Streetwear', filter: 'streetwear',
    badge: LookBadgeStyle.streetwear, bg: LookBgStyle.streetwear,
  ),
  const LookItem(
    id: '2', title: 'Gym-to-Street Fit',
    description: 'Matching athleisure set with a zip hoodie',
    emoji: '🏃', category: 'Athleisure', filter: 'athleisure',
    badge: LookBadgeStyle.athleisure, bg: LookBgStyle.athleisure,
  ),
  const LookItem(
    id: '3', title: 'Coastal Boho Vibes',
    description: 'Flowy maxi dress with crochet details',
    emoji: '🌻', category: 'Boho', filter: 'boho',
    badge: LookBadgeStyle.boho, bg: LookBgStyle.boho,
  ),
  const LookItem(
    id: '4', title: 'Clean & Simple',
    description: 'Neutral tones, structured silhouettes',
    emoji: '◻', category: 'Minimalist', filter: 'minimalist',
    badge: LookBadgeStyle.minimalist, bg: LookBgStyle.minimalist,
  ),
  const LookItem(
    id: '5', title: 'Retro Revival',
    description: '90s-inspired thrift finds and classic cuts',
    emoji: '🎞', category: 'Vintage', filter: 'vintage',
    badge: LookBadgeStyle.vintage, bg: LookBgStyle.vintage,
  ),
];

// ── Filter pill data ─────────────────────────────────────────────────────────
class FilterPillData {
  final String label;
  final String filter;
  const FilterPillData(this.label, this.filter);
}

const List<FilterPillData> kFilters = [
  FilterPillData('All', 'all'),
  FilterPillData('🧢 Streetwear', 'streetwear'),
  FilterPillData('🏃 Athleisure', 'athleisure'),
  FilterPillData('🌻 Boho', 'boho'),
  FilterPillData('◻ Minimalist', 'minimalist'),
  FilterPillData('🎞 Vintage', 'vintage'),
  FilterPillData('🖤 Monochrome', 'monochrome'),
  FilterPillData('🌷 Cottagecore', 'cottagecore'),
];

// ── Main Screen ──────────────────────────────────────────────────────────────
class Screen4 extends StatefulWidget {
  const Screen4({super.key});

  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> {
  AppThemeTokens get _t => context.themeTokens;
  Color get _bg => _t.backgroundPrimary;
  Color get _bg2 => _t.backgroundSecondary;
  Color get _phoneShell => _t.phoneShell;
  Color get _text => _t.textPrimary;

  String _activeFilter = 'all';
  String? _toastMessage;
  final List<LookItem> _looks = List.from(kSampleLooks);

  List<LookItem> get _filtered =>
      _activeFilter == 'all' ? _looks : _looks.where((l) => l.filter == _activeFilter).toList();

  void _setFilter(String f) => setState(() => _activeFilter = f);

  void _deleteLook(String id) => setState(() => _looks.removeWhere((l) => l.id == id));

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final countText = _looks.isEmpty
        ? 'No looks saved yet'
        : '${filtered.length} look${filtered.length != 1 ? 's' : ''} saved';

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
                colors: [_bg, _bg2, _bg],
              ),
            ),
          ),
          Column(
            children: [
              // ── HEADER ──
              _Header(countText: countText),
              // ── FILTER ROW ──
              _FilterRow(activeFilter: _activeFilter, onFilter: _setFilter),
              // ── GRID SCROLL AREA ──
              Expanded(
                child: Container(
                  color: _bg,
                  child: _looks.isEmpty
                      ? _EmptyState()
                      : filtered.isEmpty
                      ? _NoResultsState()
                      : _LooksGrid(
                    looks: filtered,
                    onDelete: _deleteLook,
                    onShare: (look) => _showToast('Copied!'),
                  ),
                ),
              ),
            ],
          ),
          // ── TOAST ──
          if (_toastMessage != null)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: _phoneShell,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _toastMessage!,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _text,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String countText;
  const _Header({required this.countText});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [t.phoneShellInner, t.phoneShell, t.backgroundSecondary],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Radial glow top-right
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.tertiary.withValues(alpha: 0.30), t.backgroundPrimary.withValues(alpha: 0.0)],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          // Radial glow bottom-left
          Positioned(
            bottom: -20,
            left: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [t.accent.primary.withValues(alpha: 0.22), t.backgroundPrimary.withValues(alpha: 0.0)],
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
                    'Everything else',
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
                    'Your saved style inspirations',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: t.accent.tertiary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countText,
                    style: TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
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
          border: Border.all(color: t.cardBorder, width: 1),
        ),
        child: Center(
          child: Icon(
            Icons.chevron_left_rounded,
            size: 16,
            color: t.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Filter Row ───────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilter;
  const _FilterRow({required this.activeFilter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      color: t.backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: kFilters.map((f) {
            final isActive = activeFilter == f.filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterPill(
                label: f.label,
                isActive: isActive,
                onTap: () => onFilter(f.filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? t.accent.tertiary : t.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? t.accent.tertiary : t.cardBorder,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: t.accent.tertiary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? t.tileText : t.mutedText,
          ),
        ),
      ),
    );
  }
}

// ── Looks Grid ───────────────────────────────────────────────────────────────
class _LooksGrid extends StatelessWidget {
  final List<LookItem> looks;
  final ValueChanged<String> onDelete;
  final ValueChanged<LookItem> onShare;
  const _LooksGrid({required this.looks, required this.onDelete, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: _buildGrid(),
    );
  }

  Widget _buildGrid() {
    final List<Widget> rows = [];
    int i = 0;

    // First card is "featured" (full-width)
    if (looks.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LookCard(look: looks[0], featured: true, onDelete: onDelete, onShare: onShare),
        ),
      );
      i = 1;
    }

    // Remaining cards in 2-column pairs
    while (i < looks.length) {
      final left = looks[i];
      final right = i + 1 < looks.length ? looks[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _LookCard(look: left, featured: false, onDelete: onDelete, onShare: onShare)),
              const SizedBox(width: 8),
              Expanded(
                child: right != null
                    ? _LookCard(look: right, featured: false, onDelete: onDelete, onShare: onShare)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      i += 2;
    }

    return Column(children: rows);
  }
}

// ── Look Card ────────────────────────────────────────────────────────────────
class _LookCard extends StatefulWidget {
  final LookItem look;
  final bool featured;
  final ValueChanged<String> onDelete;
  final ValueChanged<LookItem> onShare;

  const _LookCard({
    required this.look,
    required this.featured,
    required this.onDelete,
    required this.onShare,
  });

  @override
  State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard> {
  bool _hovered = false;
  AppThemeTokens get _t => context.themeTokens;

  Gradient _bgGradient(LookBgStyle bg) {
    switch (bg) {
      case LookBgStyle.streetwear:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.secondary.withValues(alpha: 0.15),
            _t.accent.primary.withValues(alpha: 0.18),
          ],
        );
      case LookBgStyle.athleisure:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.tertiary.withValues(alpha: 0.18),
            _t.accent.primary.withValues(alpha: 0.15),
          ],
        );
      case LookBgStyle.boho:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.secondary.withValues(alpha: 0.22),
            _t.accent.tertiary.withValues(alpha: 0.16),
          ],
        );
      case LookBgStyle.minimalist:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.primary.withValues(alpha: 0.12),
            _t.accent.secondary.withValues(alpha: 0.10),
          ],
        );
      case LookBgStyle.vintage:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.secondary.withValues(alpha: 0.22),
            _t.accent.tertiary.withValues(alpha: 0.20),
          ],
        );
      case LookBgStyle.monochrome:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.phoneShell.withValues(alpha: 0.60),
            _t.phoneShellInner.withValues(alpha: 0.50),
          ],
        );
      case LookBgStyle.cottagecore:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.tertiary.withValues(alpha: 0.14),
            _t.accent.secondary.withValues(alpha: 0.20),
          ],
        );
      case LookBgStyle.defaultBg:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _t.accent.primary.withValues(alpha: 0.12),
            _t.accent.tertiary.withValues(alpha: 0.10),
          ],
        );
    }
  }

  Color _badgeColor(LookBadgeStyle badge) {
    switch (badge) {
      case LookBadgeStyle.streetwear: return _t.accent.secondary;
      case LookBadgeStyle.athleisure: return _t.accent.tertiary;
      case LookBadgeStyle.boho: return _t.accent.secondary;
      case LookBadgeStyle.minimalist: return _t.accent.primary;
      case LookBadgeStyle.vintage: return _t.accent.secondary;
      case LookBadgeStyle.monochrome: return _t.mutedText;
      case LookBadgeStyle.cottagecore: return _t.accent.tertiary;
      case LookBadgeStyle.defaultBadge: return _t.accent.tertiary;
    }
  }

  Color _badgeBg(LookBadgeStyle badge) {
    switch (badge) {
      case LookBadgeStyle.streetwear: return _t.accent.secondary.withValues(alpha: 0.15);
      case LookBadgeStyle.athleisure: return _t.accent.tertiary.withValues(alpha: 0.15);
      case LookBadgeStyle.boho: return _t.accent.secondary.withValues(alpha: 0.20);
      case LookBadgeStyle.minimalist: return _t.accent.primary.withValues(alpha: 0.15);
      case LookBadgeStyle.vintage: return _t.accent.secondary.withValues(alpha: 0.16);
      case LookBadgeStyle.monochrome: return _t.panel;
      case LookBadgeStyle.cottagecore: return _t.accent.tertiary.withValues(alpha: 0.14);
      case LookBadgeStyle.defaultBadge: return _t.panel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    final aspectRatio = widget.featured ? 2.0 : 1.0;
    final onAccent = Theme.of(context).colorScheme.onPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _t.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? _t.accent.tertiary : _t.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? _t.accent.tertiary.withValues(alpha: 0.18)
                    : _t.accent.tertiary.withValues(alpha: 0.08),
                blurRadius: _hovered ? 28 : 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / placeholder
              Stack(
                children: [
                  look.imageUrl != null
                      ? AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Image.network(
                      look.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      decoration: BoxDecoration(gradient: _bgGradient(look.bg)),
                      child: Center(
                        child: Text(look.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () => widget.onDelete(look.id),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _t.phoneShellInner.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _t.cardBorder, width: 1),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              size: 13,
                              color: _t.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Share button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () => widget.onShare(look),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _t.phoneShellInner.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _t.cardBorder, width: 1),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.share_outlined,
                              size: 13,
                              color: _t.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Card info
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 5, 7, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _badgeBg(look.badge),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${look.emoji} ${look.category}'.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06 * 7,
                          color: _badgeColor(look.badge),
                        ),
                      ),
                    ),
                    // Title
                    Text(
                      look.title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _t.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Description
                    Text(
                      look.description,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        color: _t.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Try On button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.5, 1.0],
                        colors: [
                          _t.accent.tertiary,
                          _t.accent.primary,
                          _t.accent.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _t.accent.tertiary.withValues(alpha: 0.40),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: _t.backgroundPrimary.withValues(alpha: 0.16),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: onAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Try On',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.04 * 10.5,
                            color: onAccent,
                          ),
                        ),
                      ],
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

// ── Empty / No-results states ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 52)),
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
            const SizedBox(height: 4),
            Text(
              'Save looks from the chat and they\'ll appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: t.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              'No looks in this category',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different filter or add a new look!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: t.mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
