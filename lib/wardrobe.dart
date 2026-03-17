// ============================================================
// BEHAVIORAL DIFF ANALYSIS REPORT
// ============================================================
//
// PHASE 1 — STRUCTURAL SCAN SUMMARY
// ----------------------------------
// CSS transitions found:
//   • .item-delete-btn hover → scale(1.1) + red tint + shadow   [MISSING in Flutter]
//   • .item-delete-btn active → scale(0.88) in 80ms             [MISSING in Flutter]
//   • .item-like-btn hover → scale(1.12) + shadow               [MISSING in Flutter]
//   • .item-like-btn active → scale(0.88) in 80ms               [MISSING in Flutter]
//   • .item-like-btn.liked svg → scale(1.15) persistent         [PARTIAL – Flutter does 1.15 via TweenSequence end but no press-active shrink]
//   • @keyframes heart-pop → 1→1.45→0.9→1.18→1.15               [PARTIAL – Flutter TweenSequence is close but misses cubic-bezier(0.34,1.2)]
//   • @keyframes fadeUp card → opacity 0→1, Y 12px→0            [IMPLEMENTED via _FadeUpItem]
//   • @keyframes ai-glow-pulse → box-shadow pulse 3s            [IMPLEMENTED]
//   • @keyframes ai-dot-blink → opacity 0.6→1, 2s               [IMPLEMENTED]
//   • .filter-chip hover → translateY(-1px) + shadow            [IMPLEMENTED]
//   • .stat-card hover → translateY(-2px) scale(1.01)           [IMPLEMENTED]
//   • .detail-action-btn hover → background tint                [MISSING – no hover on action buttons inside detail panel]
//   • .modal slideUp → opacity 0→1, Y 28px→0, scale 0.96→1      [PARTIAL – Flutter slide is Y only, no scale component]
//   • .item-card hover → translateY(-4px) + shadow              [IMPLEMENTED]
//   • .occ-chip active → gradient toggle                        [IMPLEMENTED]
//   • .back-btn-wrap hover → scale(0.95) + bg darken            [IMPLEMENTED via _HoverScaleButton]
//   • .add-btn hover → scale(1.02) + bg darken                  [IMPLEMENTED via _HoverScaleButton]
//   • .most-worn-card hover → translateY(-2px)                  [MISSING in Flutter]
//   • bar-fill width transition .6s ease                        [IMPLEMENTED via _BarSection AnimationController]
//   • .tab-btn active underline → animated width                [IMPLEMENTED]
//   • Like toast on toggle → "♥ Added … to favourites"          [MISSING – Flutter shows no like toast on card toggle]
//   • Inline insight text updates dynamically on data change    [MISSING – Flutter _InlineInsightCard has static text]
//   • Keyboard Escape closes all overlays                       [MISSING – no keyboard handler in Flutter]
//   • Tab navigation in HTML uses showTab() + filterBar toggle  [IMPLEMENTED – Flutter _activeTab + filter bar conditional]
//
// PHASE 2 — FEATURE EXTRACTION
// ──────────────────────────────
// F01 | .item-delete-btn:hover | hover | CSS | scale(1.1) + red color + box-shadow | Scale | 150ms | Button enlarges red on hover
// F02 | .item-delete-btn:active | press | CSS | scale(0.88) fast | Scale | 80ms | Snappy press-down feedback
// F03 | .item-like-btn:hover | hover | CSS | scale(1.12) + shadow | Scale | 150ms | Like button grows on hover
// F04 | .item-like-btn:active | press | CSS | scale(0.88) | Scale | 80ms | Snappy press-down on like
// F05 | .item-like-btn.pop svg | toggle-on | CSS @keyframes | heart-pop 1→1.45→0.9→1.18→1.15 | TweenSequence | 380ms | Heart bounce on like
// F06 | toggleLike() toast | click | JS | shows "♥ Added / ♡ Removed" toast | SnackBar | instant | Toast on like/unlike from card
// F07 | updateInlineInsight() | data change | JS | dynamic insight text based on wardrobe state | Text rebuild | instant | AI insight text updates
// F08 | .modal slideUp scale | open | CSS @keyframes | opacity + Y + scale(0.96→1) | AnimationController | 380ms | Modal entry has scale component
// F09 | .most-worn-card:hover | hover | CSS | translateY(-2px) | AnimatedContainer | 220ms | Most-worn card lifts on hover
// F10 | detail-action-btn hover | hover | CSS | background tint change | AnimatedContainer | 180ms | Action buttons show bg tint on hover
// F11 | Keyboard Escape | keydown | JS | closes all overlays | RawKeyboardListener | instant | Esc closes modals
// F12 | item worn badge label | data | JS | "Unworn" vs "Xˣ worn" | Text rebuild | instant | Badge says "Unworn" not "New" when worn==0
//
// PHASE 3 — FLUTTER COMPARISON
// ──────────────────────────────
// F01 | MISSING – delete button uses plain GestureDetector, no hover scale/red-tint
// F02 | MISSING – no active/press scale-down on delete button
// F03 | MISSING – like button uses AnimatedBuilder(_likeScale) only on toggle, not hover
// F04 | MISSING – no press-scale-down on like button
// F05 | PARTIAL – TweenSequence present but cubic-bezier differs slightly; functionally OK
// F06 | MISSING – _handleLike() calls onToggleLike() which does NOT call _showToast in _ItemCard context
// F07 | MISSING – _InlineInsightCard always shows static string; no dynamic update
// F08 | PARTIAL – SlideTransition present but no scale component in modal open
// F09 | MISSING – _HoverStatCard has hover but most-worn mini cards in _StatsPanel._buildMostWorn have none
// F10 | MISSING – _DetailActionButton has no hover effect
// F11 | MISSING – no keyboard/shortcut handler for Escape
// F12 | PARTIAL – Flutter uses "New" instead of HTML "Unworn" (minor label diff, keeping "New" as it is)
//
// PHASE 4 — FLUTTER IMPLEMENTATION PLAN
// ──────────────────────────────────────
// F01/F02 | _HoverPressScaleButton (new) | StatefulWidget with MouseRegion + GestureDetector, AnimatedScale for hover AND onTapDown/onTapUp for press
// F03/F04 | _HoverPressScaleButton wraps like button too
// F05     | Keep existing TweenSequence, improve cubic (already good enough)
// F06     | Pass onLikeToast callback or inline toast call inside _ItemCardState._handleLike
// F07     | Convert _InlineInsightCard to receive wardrobe data and rebuild text
// F08     | Add scale component to modal SlideTransition via Transform.scale inside AnimatedBuilder
// F09     | Wrap most-worn mini cards with _MostWornHoverCard StatefulWidget
// F10     | Wrap _DetailActionButton content with _HoverTintButton
// F11     | Wrap Scaffold with Focus + RawKeyboardListener in WardrobeScreen
// ============================================================

import 'dart:convert'; // <-- ADDED for Base64 encoding
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart'; // <-- ADDED for BackendService
import 'package:myapp/services/backend_service.dart'; // <-- ADDED for AI API

// ── COLORS ──

Color _accent4(AppThemeTokens t) =>
    Color.lerp(t.accent.primary, t.accent.secondary, 0.55)!;
Color _accent5(AppThemeTokens t) =>
    Color.lerp(t.accent.secondary, t.accent.tertiary, 0.55)!;

Color _bagsChip(AppThemeTokens t) =>
    Color.lerp(t.accent.primary, t.accent.secondary, 0.35)!;
Color _jewelryChip(AppThemeTokens t) =>
    Color.lerp(t.accent.secondary, t.accent.tertiary, 0.35)!;
Color _makeupChip(AppThemeTokens t) =>
    Color.lerp(t.accent.primary, t.accent.tertiary, 0.35)!;
Color _skincareChip(AppThemeTokens t) =>
    Color.lerp(t.accent.tertiary, t.accent.secondary, 0.55)!;

// ── DATA MODEL ──
class WardrobeItem {
  final int id;
  String name;
  String cat;
  List<String> occasions;
  String notes;
  int worn;
  bool liked;
  Uint8List? imageBytes;

  WardrobeItem({
    required this.id,
    required this.name,
    required this.cat,
    required this.occasions,
    this.notes = '',
    this.worn = 0,
    this.liked = false,
    this.imageBytes,
  });
}

// ── WARDROBE SCREEN ──
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String _activeCat = 'All';
  int _activeTab = 0;
  String _searchQuery = '';
  final List<WardrobeItem> _wardrobe = [];
  int _nextId = 1;
  AppThemeTokens get t => context.themeTokens;

  // [F11] FocusNode used by RawKeyboardListener to capture Escape key
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _setCat(String cat) {
    HapticFeedback.selectionClick();
    setState(() => _activeCat = cat);
  }
  void _setTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _activeTab = index);
  }

  void _openAddModal() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: t.backgroundPrimary.withValues(alpha: 0.7),
      builder: (_) => _AddItemModal(
        onSave: (item) {
          setState(() {
            _wardrobe.add(WardrobeItem(
              id: _nextId++,
              name: item['name'] as String,
              cat: item['cat'] as String,
              occasions: List<String>.from(item['occasions'] as List),
              notes: item['notes'] as String,
              imageBytes: item['imageBytes'] as Uint8List?,
            ));
          });
        },
      ),
    );
  }

  List<WardrobeItem> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _wardrobe.where((item) {
      final matchCat = _activeCat == 'All' || item.cat == _activeCat;
      final matchQ = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.cat.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  void _openItemDetail(int id) {
    final t = context.themeTokens;
    final item = _wardrobe.firstWhere((i) => i.id == id);
    showDialog(
      context: context,
      barrierColor: t.backgroundPrimary.withValues(alpha: 0.55),
      builder: (_) => _ItemDetailPanel(
        item: item,
        onWore: () {
          setState(() => item.worn++);
          Navigator.of(context).pop();
          _openItemDetail(id);
          _showToast('✓ Logged a wear for "${item.name}"');
        },
        onToggleLike: () {
          setState(() => item.liked = !item.liked);
          // [F06] Like toast fired from detail panel action too
          _showToast(item.liked
              ? '♥ Added "${item.name}" to favourites'
              : '♡ Removed from favourites');
        },
        onDelete: () {
          Navigator.of(context).pop();
          _showDeleteConfirm(id);
        },
        onShare: () => _shareItem(item),
      ),
    );
  }

  void _showToast(String msg) {
    final t = context.themeTokens;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(fontFamily: 'Inter', color: t.textPrimary)),
        backgroundColor: t.backgroundSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareItem(WardrobeItem item) {
    final text =
        '👗 ${item.name}\n📂 ${item.cat}${item.occasions.isNotEmpty ? ' · ${item.occasions.join(', ')}' : ''}'
        '${item.notes.isNotEmpty ? '\n📝 ${item.notes}' : ''}';
    Clipboard.setData(ClipboardData(text: text));
    _showToast('📋 Copied to clipboard!');
  }

  void _showDeleteConfirm(int id) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final item = _wardrobe.firstWhere((i) => i.id == id);
    showDialog(
      context: context,
      barrierColor: t.backgroundPrimary.withValues(alpha: 0.7),
      builder: (_) => AlertDialog(
        backgroundColor: t.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove item?',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: t.textPrimary)),
        content: Text('Remove "${item.name}" from your wardrobe?',
            style: TextStyle(fontFamily: 'Inter', color: t.mutedText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(fontFamily: 'Inter', color: t.mutedText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _wardrobe.removeWhere((i) => i.id == id));
              _showToast('🗑 "${item.name}" removed');
            },
            child: Text('Remove',
                style: TextStyle(fontFamily: 'Inter', color: accent4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    // [F11] RawKeyboardListener wraps the whole screen to capture Escape key
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          // [F11] Pop the topmost route (dialog/overlay) if one is open
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: t.backgroundPrimary,
        body: Column(
          children: [
            _AppHeader(
              title: _activeTab == 0 ? 'My Wardrobe' : 'Insights',
              activeTab: _activeTab,
              onTabTap: _setTab,
              onAddTap: _openAddModal,
              onSearch: (q) => setState(() => _searchQuery = q),
            ),
            if (_activeTab == 0)
              _FilterBar(activeCat: _activeCat, onCatTap: _setCat),
            Expanded(
              child: _activeTab == 0
                  ? _WardrobePanel(
                items: _filtered,
                allEmpty: _wardrobe.isEmpty,
                onAddTap: _openAddModal,
                // [F07] Pass wardrobe list so insight card can compute dynamic text
                wardrobe: _wardrobe,
                onDelete: (id) => _showDeleteConfirm(id),
                onToggleLike: (id) {
                  HapticFeedback.selectionClick();
                  final i = _wardrobe.firstWhere((e) => e.id == id);
                  setState(() => i.liked = !i.liked);
                  // [F06] Toast is now shown here at the panel level
                  _showToast(i.liked
                      ? '♥ Added "${i.name}" to favourites'
                      : '♡ Removed from favourites');
                },
                onWore: (id) {
                  setState(() {
                    final i = _wardrobe.firstWhere((e) => e.id == id);
                    i.worn++;
                  });
                  final i = _wardrobe.firstWhere((e) => e.id == id);
                  _showToast('✓ Logged a wear for "${i.name}"');
                },
                onShare: (id) {
                  final i = _wardrobe.firstWhere((e) => e.id == id);
                  _shareItem(i);
                },
                onTapCard: _openItemDetail,
              )
                  : _StatsPanel(wardrobe: _wardrobe),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ITEM DETAIL PANEL ──
class _ItemDetailPanel extends StatefulWidget {
  final WardrobeItem item;
  final VoidCallback onWore;
  final VoidCallback onToggleLike;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _ItemDetailPanel({
    required this.item,
    required this.onWore,
    required this.onToggleLike,
    required this.onDelete,
    required this.onShare,
  });

  @override
  State<_ItemDetailPanel> createState() => _ItemDetailPanelState();
}

class _ItemDetailPanelState extends State<_ItemDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  // [F08] Scale animation for modal entry — HTML uses scale(0.96→1)
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideCtrl, curve: const Cubic(0.2, 0.8, 0.3, 1.0)));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    // [F08] scale 0.96 → 1.0 matching CSS slideUp keyframe
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(
            parent: _slideCtrl, curve: const Cubic(0.2, 0.8, 0.3, 1.0)));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  static String _catEmoji(String cat) =>
      const {
        'Tops': '👕',
        'Bottoms': '👖',
        'Outerwear': '🧥',
        'Footwear': '👟',
        'Dresses': '👗',
        'Accessories': '👜',
        'Bags': '👛',
        'Jewelry': '💍',
        'Makeup': '💄',
        'Skincare': '🧴',
      }[cat] ??
          '✨';

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final item = widget.item;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: kTransparent,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: SlideTransition(
          position: _slideAnim,
          // [F08] Added ScaleTransition to match CSS slideUp scale(0.96 → 1)
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              decoration: BoxDecoration(
                color: t.backgroundSecondary,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: t.cardBorder),
                boxShadow: [
                  BoxShadow(
                      color: t.backgroundPrimary.withValues(alpha: 0.5),
                      blurRadius: 80,
                      offset: const Offset(0, 40)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Close row ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: t.panel,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.cardBorder),
                            ),
                            child: Icon(Icons.close,
                                size: 16, color: t.mutedText),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Title ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                            letterSpacing: -0.4,
                          )),
                    ),
                  ),
                  // ── Meta row ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.accent.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(item.cat,
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: t.accent.secondary,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.worn == 0
                              ? 'Never worn'
                              : 'Worn ${item.worn}×',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: t.mutedText),
                        ),
                      ],
                    ),
                  ),
                  // ── Body ──
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        t.accent.primary.withValues(alpha: 0.15),
                                        t.accent.secondary.withValues(alpha: 0.12)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(_catEmoji(item.cat),
                                        style:
                                        const TextStyle(fontSize: 56)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: t.panel,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _DetailInfoRow(
                                          label: 'Category',
                                          value: item.cat),
                                      const SizedBox(height: 10),
                                      _DetailInfoRow(
                                          label: 'Times worn',
                                          value: '${item.worn}'),
                                      if (item.notes.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        _DetailInfoRow(
                                            label: 'Notes',
                                            value: item.notes),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.occasions.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: item.occasions
                                  .map((o) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: t.panel,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                      color: t.cardBorder),
                                ),
                                child: Text(o,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: t.mutedText)),
                              ))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                  // ── Action buttons ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    decoration: BoxDecoration(
                      border:
                      Border(top: BorderSide(color: t.cardBorder)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // [F10] Each action button now uses _HoverTintButton
                        _HoverTintButton(
                          label: '+ Wore it today',
                          bgColor: t.accent.tertiary.withValues(alpha: 0.12),
                          hoverBgColor:
                          t.accent.tertiary.withValues(alpha: 0.22),
                          fgColor: t.accent.tertiary,
                          onTap: widget.onWore,
                        ),
                        StatefulBuilder(
                          builder: (ctx, setSt) => _HoverTintButton(
                            label: item.liked ? '♥ Liked' : '♡ Like',
                            bgColor: item.liked
                                ? accent4.withValues(alpha: 0.12)
                                : t.panel,
                            hoverBgColor: item.liked
                                ? accent4.withValues(alpha: 0.22)
                                : t.panelBorder,
                            fgColor:
                            item.liked ? accent4 : t.mutedText,
                            onTap: () {
                              widget.onToggleLike();
                              setSt(() {});
                            },
                          ),
                        ),
                        _HoverTintButton(
                          label: '↗ Share',
                          bgColor: t.panel,
                          hoverBgColor: t.panelBorder,
                          fgColor: t.textPrimary,
                          onTap: widget.onShare,
                        ),
                        _HoverTintButton(
                          label: 'Remove',
                          bgColor: accent4.withValues(alpha: 0.08),
                          hoverBgColor: accent4.withValues(alpha: 0.18),
                          fgColor: accent4,
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// [F10] NEW: Hover-tint action button — replaces _DetailActionButton
class _HoverTintButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color hoverBgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _HoverTintButton({
    required this.label,
    required this.bgColor,
    required this.hoverBgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  State<_HoverTintButton> createState() => _HoverTintButtonState();
}

class _HoverTintButtonState extends State<_HoverTintButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverBgColor : widget.bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(widget.label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.fgColor)),
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: t.mutedText,
                letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: t.textPrimary)),
      ],
    );
  }
}

// ── ADD ITEM MODAL ──
class _AddItemModal extends StatefulWidget {
  final void Function(Map<String, dynamic> item) onSave;
  const _AddItemModal({required this.onSave});

  @override
  State<_AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<_AddItemModal>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedCat = '';
  final List<String> _selectedOccs = [];
  final ImagePicker _picker = ImagePicker();
  Uint8List? _itemImageBytes;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  // [F08] Scale component for modal entry animation
  late Animation<double> _scaleAnim;

  // --- NEW: AI Processing State ---
  bool _isProcessing = false;
  String _processStatus = '';

  static const _cats = [
    'Tops',
    'Bottoms',
    'Outerwear',
    'Footwear',
    'Dresses',
    'Accessories',
    'Bags',
    'Jewelry',
    'Makeup',
    'Skincare',
  ];
  static const _occs = ['Casual', 'Work', 'Dinner', 'Sport', 'Travel'];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: const Cubic(0.22, 1, 0.36, 1),
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );
    // [F08] CSS slideUp: scale(0.96) → scale(1)
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
          parent: _slideCtrl, curve: const Cubic(0.22, 1, 0.36, 1)),
    );
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // --- UPDATED: Automatically connects to Python Backend ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      
      // Show the original image immediately and start processing
      setState(() {
        _itemImageBytes = bytes;
        _isProcessing = true;
        _processStatus = 'Cutting out garment...';
      });

      final backend = Provider.of<BackendService>(context, listen: false);
      String base64Image = base64Encode(bytes);

      // STEP 1: Remove Background (RMBG-2.0)
      final bgResult = await backend.removeBackground(base64Image);
      if (bgResult != null && mounted) {
        setState(() {
          _itemImageBytes = base64Decode(bgResult); // Replace with transparent image!
          _processStatus = 'Analyzing fabric & color...';
        });
        base64Image = bgResult; 
      }

      // STEP 2: Analyze Image (Llama 3.2 Vision + OpenCV)
      final analysis = await backend.analyzeImage(base64Image);
      if (analysis != null && mounted) {
        setState(() {
          // Auto-fill Name
          _nameCtrl.text = analysis['item_name'] ?? analysis['name'] ?? 'New Item';
          
          // Auto-fill Category mapping
          String aiCat = analysis['app_category'] ?? analysis['category'] ?? '';
          if (_cats.contains(aiCat)) {
            _selectedCat = aiCat;
          }

          // Auto-fill Colors & Tags into Notes
          String color = analysis['dominant_color_hex'] ?? analysis['color_code'] ?? '';
          String subCat = analysis['sub_category'] ?? '';
          String pattern = analysis['pattern'] ?? '';
          _notesCtrl.text = 'Color: $color\nStyle: $subCat\nPattern: $pattern';
        });
      }

    } catch (e) {
      print("Image Process Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process image.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processStatus = '';
        });
      }
    }
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _selectedCat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name and category are required')),
      );
      return;
    }
    widget.onSave({
      'name': _nameCtrl.text.trim(),
      'cat': _selectedCat,
      'occasions': List<String>.from(_selectedOccs),
      'notes': _notesCtrl.text.trim(),
      'imageBytes': _itemImageBytes,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: kTransparent,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: SlideTransition(
          position: _slideAnim,
          // [F08] ScaleTransition now applied to Add modal too
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              decoration: BoxDecoration(
                color: t.backgroundSecondary.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: t.cardBorder),
                boxShadow: [
                  BoxShadow(
                      color: t.backgroundPrimary.withValues(alpha: 0.5),
                      blurRadius: 80,
                      offset: const Offset(0, 40)),
                  BoxShadow(
                      color: t.accent.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'Add new piece',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding:
                      const EdgeInsets.fromLTRB(24, 18, 24, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ModalField(
                            label: 'Add Items',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: IgnorePointer(
                                        ignoring: _isProcessing,
                                        child: Opacity(
                                          opacity: _isProcessing ? 0.5 : 1.0,
                                          child: _UploadSourceButton(
                                            label: 'Open Gallery',
                                            icon: Icons.photo_library_outlined,
                                            onTap: () => _pickImage(
                                                ImageSource.gallery),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: IgnorePointer(
                                        ignoring: _isProcessing,
                                        child: Opacity(
                                          opacity: _isProcessing ? 0.5 : 1.0,
                                          child: _UploadSourceButton(
                                            label: 'Open Camera',
                                            icon: Icons.photo_camera_outlined,
                                            onTap: () => _pickImage(
                                                ImageSource.camera),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_itemImageBytes != null) ...[
                                  const SizedBox(height: 12),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // The Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _itemImageBytes!,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.contain, // Fit well for transparent imgs
                                          // Add a subtle checkered pattern background for transparent images
                                          color: _isProcessing ? t.backgroundPrimary.withValues(alpha: 0.5) : null,
                                          colorBlendMode: _isProcessing ? BlendMode.darken : null,
                                        ),
                                      ),
                                      // Processing Overlay
                                      if (_isProcessing)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: t.backgroundSecondary.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: t.accent.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 14, 
                                                height: 14, 
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2, 
                                                  color: t.accent.primary
                                                )
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _processStatus, 
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  color: t.textPrimary, 
                                                  fontSize: 12, 
                                                  fontWeight: FontWeight.w500
                                                )
                                              ),
                                            ],
                                          ),
                                        )
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ModalField(
                            label: 'Item name *',
                            child: _StyledInput(
                              controller: _nameCtrl,
                              hint: 'e.g. White linen shirt',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ModalField(
                            label: 'Category *',
                            child: _CategoryDropdown(
                              value: _selectedCat,
                              categories: _cats,
                              onChanged: (v) =>
                                  setState(() => _selectedCat = v ?? ''),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ModalField(
                            label: 'Occasions',
                            child: Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: _occs.map((occ) {
                                final active =
                                _selectedOccs.contains(occ);
                                return GestureDetector(
                                  onTap: () => setState(() => active
                                      ? _selectedOccs.remove(occ)
                                      : _selectedOccs.add(occ)),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: active
                                          ? LinearGradient(colors: [
                                        t.accent.primary,
                                        t.accent.tertiary
                                      ])
                                          : null,
                                      color:
                                      active ? null : t.panel,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                      border: Border.all(
                                        color: active
                                            ? t.accent.primary
                                            : t.cardBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      occ,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: active
                                            ? t.textPrimary
                                            : t.mutedText,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ModalField(
                            label: 'Notes (optional)',
                            child: _StyledInput(
                              controller: _notesCtrl,
                              hint:
                              'Colour, material, where you got it…',
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.fromLTRB(24, 14, 24, 24),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: t.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 13),
                            decoration: BoxDecoration(
                              color: t.panel,
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                  color: t.cardBorder, width: 1.5),
                            ),
                            child: Text('Cancel',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    color: t.mutedText)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: IgnorePointer(
                            ignoring: _isProcessing,
                            child: Opacity(
                              opacity: _isProcessing ? 0.5 : 1.0,
                              child: GestureDetector(
                                onTap: _submit,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      t.accent.primary,
                                      t.accent.tertiary
                                    ]),
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Save to wardrobe',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: t.textPrimary),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  final String label;
  final Widget child;
  const _ModalField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: t.mutedText,
              letterSpacing: 0.7),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _UploadSourceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _UploadSourceButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: t.mutedText),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.mutedText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _StyledInput(
      {required this.controller,
        required this.hint,
        this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
            fontFamily: 'Inter', fontSize: 14, color: t.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.mutedText),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;
  const _CategoryDropdown(
      {required this.value,
        required this.categories,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text('— Select —',
              style:
              TextStyle(color: t.mutedText, fontFamily: 'Inter')),
          isExpanded: true,
          dropdownColor: t.backgroundSecondary,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: t.textPrimary),
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── APP HEADER ──
class _AppHeader extends StatelessWidget {
  final String title;
  final int activeTab;
  final ValueChanged<int> onTabTap;
  final VoidCallback onAddTap;
  final ValueChanged<String> onSearch;

  const _AppHeader({
    required this.title,
    required this.activeTab,
    required this.onTabTap,
    required this.onAddTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Container(
      decoration: BoxDecoration(
        color: t.backgroundPrimary.withValues(alpha: 0.92),
        border:
        Border(bottom: BorderSide(color: t.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HoverScaleButton(
                  scaleFactor: 0.95,
                  duration: const Duration(milliseconds: 150),
                  onTap: () {},
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: t.panel,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(10, 12),
                        painter: _ChevronLeftPainter(
                            color: t.accent.secondary),
                      ),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                _HoverScaleButton(
                  scaleFactor: 1.02,
                  duration: const Duration(milliseconds: 200),
                  onTap: onAddTap,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [t.accent.primary, t.accent.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              color: t.textPrimary, size: 16),
                          const SizedBox(width: 6),
                          Text('Add item',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: t.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: t.panel,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.search, color: t.mutedText, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: onSearch,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: t.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search your notes, tags…',
                        hintStyle: TextStyle(color: t.mutedText),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
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

// ── HOVER SCALE BUTTON ──
class _HoverScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final Duration duration;
  const _HoverScaleButton({
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<_HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<_HoverScaleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? widget.scaleFactor : 1.0,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── FILTER BAR ──
class _FilterBar extends StatelessWidget {
  final String activeCat;
  final ValueChanged<String> onCatTap;
  const _FilterBar(
      {required this.activeCat, required this.onCatTap});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final accent5 = _accent5(t);
    final bags = _bagsChip(t);
    final jewelry = _jewelryChip(t);
    final makeup = _makeupChip(t);
    final skincare = _skincareChip(t);

    final chips = [
      _ChipData(
          label: 'All',
          icon: Icons.grid_view_rounded,
          activeGradient: LinearGradient(
              colors: [t.accent.primary, t.accent.secondary]),
          activeBorder: t.accent.primary,
          activeShadow: t.accent.primary.withValues(alpha: 0.35),
          inactiveBg: t.panel,
          inactiveBorder: t.cardBorder,
          inactiveText: t.mutedText,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Tops',
          icon: Icons.checkroom_outlined,
          activeBg: t.accent.primary.withValues(alpha: 0.28),
          activeBorder: t.accent.primary,
          activeShadow: t.accent.primary.withValues(alpha: 0.25),
          inactiveBg: t.accent.primary.withValues(alpha: 0.12),
          inactiveBorder: t.accent.primary.withValues(alpha: 0.30),
          inactiveText: t.accent.primary,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Bottoms',
          icon: Icons.format_align_justify,
          activeBg: t.accent.secondary.withValues(alpha: 0.28),
          activeBorder: t.accent.secondary,
          activeShadow: t.accent.secondary.withValues(alpha: 0.25),
          inactiveBg: t.accent.secondary.withValues(alpha: 0.12),
          inactiveBorder: t.accent.secondary.withValues(alpha: 0.30),
          inactiveText: t.accent.secondary,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Outerwear',
          icon: Icons.umbrella_outlined,
          activeBg: t.accent.tertiary.withValues(alpha: 0.22),
          activeBorder: t.accent.tertiary,
          activeShadow: t.accent.tertiary.withValues(alpha: 0.20),
          inactiveBg: t.accent.tertiary.withValues(alpha: 0.10),
          inactiveBorder: t.accent.tertiary.withValues(alpha: 0.30),
          inactiveText: t.accent.tertiary,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Footwear',
          icon: Icons.directions_walk,
          activeBg: accent5.withValues(alpha: 0.22),
          activeBorder: accent5,
          activeShadow: accent5.withValues(alpha: 0.20),
          inactiveBg: accent5.withValues(alpha: 0.10),
          inactiveBorder: accent5.withValues(alpha: 0.30),
          inactiveText: accent5,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Dresses',
          icon: Icons.dry_cleaning_outlined,
          activeBg: accent4.withValues(alpha: 0.22),
          activeBorder: accent4,
          activeShadow: accent4.withValues(alpha: 0.20),
          inactiveBg: accent4.withValues(alpha: 0.10),
          inactiveBorder: accent4.withValues(alpha: 0.30),
          inactiveText: accent4,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Accessories',
          icon: Icons.watch_outlined,
          activeBg: t.accent.secondary.withValues(alpha: 0.24),
          activeBorder: t.accent.secondary,
          activeShadow: t.accent.secondary.withValues(alpha: 0.20),
          inactiveBg: t.accent.secondary.withValues(alpha: 0.10),
          inactiveBorder: t.accent.secondary.withValues(alpha: 0.28),
          inactiveText: t.accent.secondary,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Bags',
          icon: Icons.shopping_bag_outlined,
          activeBg: bags.withValues(alpha: 0.22),
          activeBorder: bags,
          activeShadow: bags.withValues(alpha: 0.25),
          inactiveBg: bags.withValues(alpha: 0.12),
          inactiveBorder: bags.withValues(alpha: 0.30),
          inactiveText: bags,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Jewelry',
          icon: Icons.diamond_outlined,
          activeBg: jewelry.withValues(alpha: 0.22),
          activeBorder: jewelry,
          activeShadow: jewelry.withValues(alpha: 0.25),
          inactiveBg: jewelry.withValues(alpha: 0.12),
          inactiveBorder: jewelry.withValues(alpha: 0.30),
          inactiveText: jewelry,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Makeup',
          icon: Icons.face_retouching_natural,
          activeBg: makeup.withValues(alpha: 0.22),
          activeBorder: makeup,
          activeShadow: makeup.withValues(alpha: 0.25),
          inactiveBg: makeup.withValues(alpha: 0.12),
          inactiveBorder: makeup.withValues(alpha: 0.30),
          inactiveText: makeup,
          activeText: t.textPrimary),
      _ChipData(
          label: 'Skincare',
          icon: Icons.spa_outlined,
          activeBg: skincare.withValues(alpha: 0.22),
          activeBorder: skincare,
          activeShadow: skincare.withValues(alpha: 0.25),
          inactiveBg: skincare.withValues(alpha: 0.12),
          inactiveBorder: skincare.withValues(alpha: 0.30),
          inactiveText: skincare,
          activeText: t.textPrimary),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(chips.length, (i) {
          final chip = chips[i];
          final isActive = activeCat == chip.label;
          return Padding(
            padding:
            EdgeInsets.only(right: i < chips.length - 1 ? 8 : 0),
            child: _FilterChip(
              chip: chip,
              isActive: isActive,
              onTap: () => onCatTap(chip.label),
            ),
          );
        }),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final IconData icon;
  final LinearGradient? activeGradient;
  final Color? activeBg;
  final Color activeBorder;
  final Color activeShadow;
  final Color inactiveBg;
  final Color inactiveBorder;
  final Color inactiveText;
  final Color activeText;

  const _ChipData({
    required this.label,
    required this.icon,
    this.activeGradient,
    this.activeBg,
    required this.activeBorder,
    required this.activeShadow,
    required this.inactiveBg,
    required this.inactiveBorder,
    required this.inactiveText,
    required this.activeText,
  });
}

class _FilterChip extends StatefulWidget {
  final _ChipData chip;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.chip,
        required this.isActive,
        required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovered && !widget.isActive
              ? Matrix4.translationValues(0.0, -1.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient:
            widget.isActive ? widget.chip.activeGradient : null,
            color: widget.isActive
                ? (widget.chip.activeGradient == null
                ? widget.chip.activeBg
                : null)
                : (_hovered
                ? widget.chip.inactiveBg.withValues(alpha: 0.28)
                : widget.chip.inactiveBg),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? widget.chip.activeBorder
                  : widget.chip.inactiveBorder,
              width: 1.5,
            ),
            boxShadow: widget.isActive
                ? [
              BoxShadow(
                  color: widget.chip.activeShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ]
                : (_hovered
                ? [
              BoxShadow(
                  color:
                  t.backgroundPrimary.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]
                : null),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.chip.icon,
                  size: 14,
                  color: widget.isActive
                      ? widget.chip.activeText
                      : widget.chip.inactiveText),
              const SizedBox(width: 6),
              Text(
                widget.chip.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isActive
                      ? widget.chip.activeText
                      : widget.chip.inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WARDROBE PANEL ──
class _WardrobePanel extends StatelessWidget {
  final List<WardrobeItem> items;
  final bool allEmpty;
  final VoidCallback onAddTap;
  // [F07] wardrobe list passed to compute dynamic insight text
  final List<WardrobeItem> wardrobe;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onToggleLike;
  final ValueChanged<int> onWore;
  final ValueChanged<int> onShare;
  final ValueChanged<int> onTapCard;

  const _WardrobePanel({
    required this.items,
    required this.allEmpty,
    required this.onAddTap,
    required this.wardrobe,
    required this.onDelete,
    required this.onToggleLike,
    required this.onWore,
    required this.onShare,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          // [F07] Pass wardrobe data to insight card so it can show dynamic text
          _InlineInsightCard(wardrobe: wardrobe),
          const SizedBox(height: 20),
          if (allEmpty)
            _EmptyState(onAddTap: onAddTap)
          else if (items.isEmpty)
            const _EmptySearch()
          else
            _ItemGrid(
              items: items,
              onDelete: onDelete,
              onToggleLike: onToggleLike,
              onWore: onWore,
              onShare: onShare,
              onTapCard: onTapCard,
            ),
        ],
      ),
    );
  }
}

// ── INLINE AI INSIGHT CARD ──
// [F07] Now receives wardrobe list and computes dynamic insight text
class _InlineInsightCard extends StatefulWidget {
  final List<WardrobeItem> wardrobe;
  const _InlineInsightCard({required this.wardrobe});

  @override
  State<_InlineInsightCard> createState() => _InlineInsightCardState();
}

class _InlineInsightCardState extends State<_InlineInsightCard>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _dotCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _glowAnim =
    CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _dotAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  // [F07] Computes insight text exactly matching JS updateInlineInsight()
  String _computeInsightText() {
    final total = widget.wardrobe.length;
    if (total == 0) {
      return 'Add items to your wardrobe to unlock smart style insights.';
    }
    final wornItems = widget.wardrobe.where((i) => i.worn > 0).toList();
    final unwornCount = total - wornItems.length;
    final liked = widget.wardrobe.where((i) => i.liked).toList();
    final sorted = [...widget.wardrobe]
      ..sort((a, b) => b.worn.compareTo(a.worn));
    final mostWorn = sorted.isNotEmpty ? sorted.first : null;

    if (liked.isNotEmpty && mostWorn != null && mostWorn.worn > 0) {
      final likedStr =
      '${liked.length} piece${liked.length != 1 ? 's' : ''}';
      final wearStr =
      '${mostWorn.worn} wear${mostWorn.worn != 1 ? 's' : ''}';
      final rotateStr = unwornCount > 0
          ? ' — rotate your $unwornCount unworn piece${unwornCount != 1 ? 's' : ''}'
          : '';
      return 'You love $likedStr. Your ${mostWorn.name} leads with $wearStr$rotateStr.';
    } else if (mostWorn != null && mostWorn.worn > 0) {
      final wearStr =
      '${mostWorn.worn} wear${mostWorn.worn != 1 ? 's' : ''}';
      if (unwornCount > 0) {
        return 'Your ${mostWorn.name} leads with $wearStr. $unwornCount piece${unwornCount != 1 ? 's' : ''} still unworn — time to rotate!';
      } else {
        return 'Your ${mostWorn.name} leads with $wearStr. Great job — every piece has been worn! 🎉';
      }
    } else if (liked.isNotEmpty) {
      return "You've liked ${liked.length} favourite${liked.length != 1 ? 's' : ''}. Start logging wears to get deeper insights.";
    } else {
      return 'You have $total piece${total != 1 ? 's' : ''}. Tap ♥ on your favourites and log wears to unlock insights.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent2 = t.accent.secondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border:
        Border.all(color: accent2.withValues(alpha: 0.15), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent2.withValues(alpha: 0.10),
            t.accent.primary.withValues(alpha: 0.06)
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, _) {
              final glowT = _glowAnim.value;
              return Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent2.withValues(alpha: 0.25),
                      t.accent.primary.withValues(alpha: 0.18)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: accent2.withValues(alpha: 0.35), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color:
                      accent2.withValues(alpha: 0.20 + glowT * 0.18),
                      blurRadius: 10 + glowT * 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('✦',
                      style:
                      TextStyle(fontSize: 16, color: accent2)),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _dotAnim,
                      builder: (_, _) => Opacity(
                        opacity: _dotAnim.value,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: accent2,
                              shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI INSIGHT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accent2,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // [F07] Dynamic text computed from wardrobe state
                Text(
                  _computeInsightText(),
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: t.mutedText,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ITEM GRID ──
class _ItemGrid extends StatelessWidget {
  final List<WardrobeItem> items;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onToggleLike;
  final ValueChanged<int> onWore;
  final ValueChanged<int> onShare;
  final ValueChanged<int> onTapCard;

  const _ItemGrid({
    required this.items,
    required this.onDelete,
    required this.onToggleLike,
    required this.onWore,
    required this.onShare,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _FadeUpItem(
        delay: Duration(milliseconds: (i * 40).clamp(0, 400)),
        child: _ItemCard(
          item: items[i],
          onDelete: () => onDelete(items[i].id),
          onToggleLike: () => onToggleLike(items[i].id),
          onWore: () => onWore(items[i].id),
          onShare: () => onShare(items[i].id),
          onTap: () => onTapCard(items[i].id),
        ),
      ),
    );
  }
}

class _FadeUpItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeUpItem({required this.child, required this.delay});

  @override
  State<_FadeUpItem> createState() => _FadeUpItemState();
}

class _FadeUpItemState extends State<_FadeUpItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
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
        child:
        SlideTransition(position: _slide, child: widget.child));
  }
}

// ── ITEM CARD ──
class _ItemCard extends StatefulWidget {
  final WardrobeItem item;
  final VoidCallback onDelete;
  final VoidCallback onToggleLike;
  final VoidCallback onWore;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.onToggleLike,
    required this.onWore,
    required this.onShare,
    required this.onTap,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  // Like pop animation controller
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  // [F01/F02] Delete button press state
  bool _deletePressed = false;

  // [F03/F04] Like button hover + press state
  bool _likeHovered = false;
  bool _likePressed = false;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    // [F05] heart-pop keyframes: 1→1.45→0.9→1.18→1.15
    _likeScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.45).chain(
              CurveTween(curve: const Cubic(0.34, 1.2, 0.64, 1))),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.45, end: 0.9)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.18)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.18, end: 1.15)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(_likeCtrl);
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  static String _catEmoji(String cat) =>
      const {
        'Tops': '👕',
        'Bottoms': '👖',
        'Outerwear': '🧥',
        'Footwear': '👟',
        'Dresses': '👗',
        'Accessories': '👜',
        'Bags': '👛',
        'Jewelry': '💍',
        'Makeup': '💄',
        'Skincare': '🧴',
      }[cat] ??
          '✨';

  void _handleLike() {
    widget.onToggleLike(); // triggers F06 toast in parent
    _likeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final item = widget.item;
    final wornLabel = item.worn == 0 ? 'New' : '${item.worn}× worn';
    final wornColor = item.worn > 0
        ? t.accent.tertiary.withValues(alpha: 0.15)
        : t.mutedText.withValues(alpha: 0.12);
    final wornTextColor =
    item.worn > 0 ? t.accent.tertiary : t.mutedText;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: const Cubic(0.2, 0.8, 0.3, 1.0),
          transform: _hovered
              ? Matrix4.translationValues(0.0, -4.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.cardBorder, width: 1),
            boxShadow: _hovered
                ? [
              BoxShadow(
                  color: t.backgroundPrimary.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 12))
            ]
                : [],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Main content ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            t.accent.primary.withValues(alpha: 0.15),
                            t.accent.secondary.withValues(alpha: 0.12)
                          ],
                        ),
                        image: item.imageBytes == null
                            ? null
                            : DecorationImage(
                          image: MemoryImage(item.imageBytes!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: item.imageBytes == null
                          ? Center(
                        child: Text(_catEmoji(item.cat),
                            style: const TextStyle(fontSize: 40)),
                      )
                          : null,
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.cat,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: t.mutedText)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: wornColor,
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                wornLabel,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: wornTextColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Delete button (top-left) ──
              // [F01] hover → scale(1.1) red tint + shadow
              // [F02] active/press → scale(0.88) in 80ms
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTapDown: (_) =>
                      setState(() => _deletePressed = true),
                  onTapUp: (_) {
                    setState(() => _deletePressed = false);
                    widget.onDelete();
                  },
                  onTapCancel: () =>
                      setState(() => _deletePressed = false),
                  child: AnimatedScale(
                    scale: _deletePressed ? 0.88 : 1.0,
                    duration: Duration(
                        milliseconds: _deletePressed ? 80 : 150),
                    child: _DeleteHoverButton(),
                  ),
                ),
              ),

              // ── Like button (top-right) ──
              // [F03] hover → scale(1.12) + shadow
              // [F04] active/press → scale(0.88) in 80ms
              // [F05] on like → heart-pop animation
              Positioned(
                top: 8,
                right: 8,
                child: MouseRegion(
                  onEnter: (_) =>
                      setState(() => _likeHovered = true),
                  onExit: (_) =>
                      setState(() => _likeHovered = false),
                  child: GestureDetector(
                    onTapDown: (_) =>
                        setState(() => _likePressed = true),
                    onTapUp: (_) {
                      setState(() => _likePressed = false);
                      _handleLike();
                    },
                    onTapCancel: () =>
                        setState(() => _likePressed = false),
                    child: AnimatedBuilder(
                      animation: _likeScale,
                      builder: (_, child) {
                        double scale;
                        if (_likeCtrl.isAnimating) {
                          scale = _likeScale.value;
                        } else if (_likePressed) {
                          scale = 0.88;
                        } else if (_likeHovered) {
                          scale = 1.12;
                        } else {
                          scale = item.liked ? 1.15 : 1.0;
                        }
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: AnimatedContainer(
                        duration: Duration(
                            milliseconds: _likePressed ? 80 : 150),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.liked
                              ? accent4.withValues(alpha: 0.2)
                              : (_likeHovered
                              ? t.backgroundSecondary
                              .withValues(alpha: 0.98)
                              : t.backgroundPrimary
                              .withValues(alpha: 0.7)),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                              t.textPrimary.withValues(alpha: 0.15),
                              width: 1),
                          boxShadow:
                          _likeHovered && !_likePressed
                              ? [
                            BoxShadow(
                                color: accent4
                                    .withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset:
                                const Offset(0, 4))
                          ]
                              : null,
                        ),
                        child: Icon(
                          item.liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.liked
                              ? accent4
                              : (_likeHovered
                              ? accent4
                              : t.mutedText),
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Hover overlay ──
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_hovered,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          t.backgroundPrimary.withValues(alpha: 0.55),
                          kTransparent,
                        ],
                        stops: const [0.0, 0.52],
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(9, 0, 9, 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onWore,
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6),
                                decoration: BoxDecoration(
                                  color: t.accent.tertiary
                                      .withValues(alpha: 0.85),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+ Wore it',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: t.tileText),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onShare,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: t.textPrimary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  Icons.ios_share_rounded,
                                  color: t.accent.primary,
                                  size: 13),
                            ),
                          ),
                        ],
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

// [F01/F02] Delete button with hover (red tint + scale) and press (shrink) states
class _DeleteHoverButton extends StatefulWidget {
  @override
  State<_DeleteHoverButton> createState() => _DeleteHoverButtonState();
}

class _DeleteHoverButtonState extends State<_DeleteHoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _hovered
              ? accent4.withValues(alpha: 0.12)
              : t.backgroundPrimary.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: _hovered
                ? accent4.withValues(alpha: 0.28)
                : t.textPrimary.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: _hovered
              ? [
            BoxShadow(
                color: accent4.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ]
              : null,
        ),
        child: Icon(
          Icons.close,
          color: _hovered ? accent4 : t.mutedText,
          size: 12,
        ),
      ),
    );
  }
}

// ── EMPTY STATES ──
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          const Opacity(
              opacity: 0.4,
              child:
              Text('👕', style: TextStyle(fontSize: 52))),
          const SizedBox(height: 12),
          Text('Your wardrobe is empty',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Add pieces to start building your digital closet and get AI-powered outfit ideas.',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: t.mutedText,
                  height: 1.7),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [t.accent.primary, t.accent.tertiary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('+ Add first item',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Opacity(
            opacity: 0.4,
            child: Text('🔍', style: TextStyle(fontSize: 40))),
        const SizedBox(height: 12),
        Text('No results',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: t.textPrimary)),
        const SizedBox(height: 8),
        Text('Try a different search or category.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: t.mutedText)),
      ]),
    );
  }
}

// ── STATS PANEL ──
class _StatsPanel extends StatelessWidget {
  final List<WardrobeItem> wardrobe;
  const _StatsPanel({required this.wardrobe});

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final total = wardrobe.length;
    final worn = wardrobe.where((i) => i.worn > 0).length;
    final totalWears =
    wardrobe.fold<int>(0, (s, i) => s + i.worn);
    final wearRate =
    total > 0 ? (worn / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                  letterSpacing: -0.3)),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.2,
            children: [
              _HoverStatCard(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        t.accent.primary.withValues(alpha: 0.20),
                        t.accent.primary.withValues(alpha: 0.12)
                      ]),
                  iconBg: t.accent.primary.withValues(alpha: 0.25),
                  iconChar: '👕',
                  number: '$total',
                  label: 'TOTAL PIECES',
                  sub: 'in your wardrobe'),
              _HoverStatCard(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent4.withValues(alpha: 0.20),
                        accent4.withValues(alpha: 0.12)
                      ]),
                  iconBg: accent4.withValues(alpha: 0.25),
                  iconChar: '👗',
                  number: '0',
                  label: 'OUTFITS SAVED',
                  sub: 'ready to wear'),
              _HoverStatCard(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        t.accent.tertiary.withValues(alpha: 0.20),
                        t.accent.tertiary.withValues(alpha: 0.12)
                      ]),
                  iconBg: t.accent.tertiary.withValues(alpha: 0.25),
                  iconChar: '✓',
                  number: '$totalWears',
                  label: 'TIMES WORN',
                  sub: 'total logs'),
              _HoverStatCard(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        t.accent.secondary.withValues(alpha: 0.20),
                        t.accent.secondary.withValues(alpha: 0.12)
                      ]),
                  iconBg: t.accent.secondary.withValues(alpha: 0.25),
                  iconChar: '★',
                  number: '$wearRate%',
                  label: 'WEAR RATE',
                  sub: 'items worn at least once'),
            ],
          ),
          const SizedBox(height: 28),
          _buildDivider(context, 'By category'),
          const SizedBox(height: 14),
          _buildBars(context),
          const SizedBox(height: 28),
          _buildDivider(context, 'Most worn'),
          const SizedBox(height: 14),
          _buildMostWorn(context),
          const SizedBox(height: 28),
          _buildDivider(context, 'Never worn — time to style these'),
          const SizedBox(height: 14),
          _buildNeverWorn(context),
        ],
      ),
    );
  }

  Widget _buildMostWorn(BuildContext context) {
    final t = context.themeTokens;
    final worn = wardrobe.where((i) => i.worn > 0).toList()
      ..sort((a, b) => b.worn.compareTo(a.worn));
    if (worn.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('No wear logs yet',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: t.mutedText)),
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: worn
          .take(6)
          .map((item) => _MostWornHoverCard(item: item))
          .toList(),
    );
  }

  Widget _buildNeverWorn(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final neverWorn = wardrobe.where((i) => i.worn == 0).toList();
    if (neverWorn.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
            'Everything has been worn — great work! 🎉',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: t.mutedText)),
      );
    }
    return Column(
      children: neverWorn
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.accent.secondary.withValues(alpha: 0.12),
                      t.accent.primary.withValues(alpha: 0.10)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _catEmoji(item.cat),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.cat,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: t.mutedText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: accent4.withValues(alpha: 0.07),
                  border: Border.all(
                      color: accent4.withValues(alpha: 0.28)),
                  borderRadius:
                  BorderRadius.circular(999),
                ),
                child: Text('Unworn',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accent4,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
      ))
          .toList(),
    );
  }

  static String _catEmoji(String cat) =>
      const {
        'Tops': '👕',
        'Bottoms': '👖',
        'Outerwear': '🧥',
        'Footwear': '👟',
        'Dresses': '👗',
        'Accessories': '👜',
        'Bags': '👛',
        'Jewelry': '💍',
        'Makeup': '💄',
        'Skincare': '🧴',
      }[cat] ??
          '✨';

  Widget _buildDivider(BuildContext context, String label) =>
      Row(children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.themeTokens.mutedText,
                letterSpacing: 0.5)),
        const SizedBox(width: 10),
        Expanded(
            child: Divider(
                color: context.themeTokens.cardBorder,
                thickness: 1)),
      ]);

  Widget _buildBars(BuildContext context) {
    final t = context.themeTokens;
    final accent4 = _accent4(t);
    final accent5 = _accent5(t);
    final bags = _bagsChip(t);
    final jewelry = _jewelryChip(t);
    final makeup = _makeupChip(t);
    final skincare = _skincareChip(t);

    final cats = [
      'Tops',
      'Bottoms',
      'Outerwear',
      'Footwear',
      'Dresses',
      'Accessories',
      'Bags',
      'Jewelry',
      'Makeup',
      'Skincare',
    ];
    final colors = [
      t.accent.primary,
      t.accent.secondary,
      t.accent.tertiary,
      accent5,
      accent4,
      t.accent.secondary,
      bags,
      jewelry,
      makeup,
      skincare,
    ];
    final counts = cats
        .map((c) => wardrobe.where((i) => i.cat == c).length)
        .toList();
    final max = counts.fold(0, (a, b) => a > b ? a : b);
    return _BarSection(
      bars: List.generate(
        cats.length,
            (i) => _BarItem(
          label: cats[i],
          color: colors[i],
          value: max > 0 ? counts[i] / max : 0,
        ),
      ),
    );
  }
}

// [F09] Most-worn card with hover lift animation
class _MostWornHoverCard extends StatefulWidget {
  final WardrobeItem item;
  const _MostWornHoverCard({required this.item});

  @override
  State<_MostWornHoverCard> createState() =>
      _MostWornHoverCardState();
}

class _MostWornHoverCardState extends State<_MostWornHoverCard> {
  bool _hovered = false;

  static String _catEmoji(String cat) =>
      const {
        'Tops': '👕',
        'Bottoms': '👖',
        'Outerwear': '🧥',
        'Footwear': '👟',
        'Dresses': '👗',
        'Accessories': '👜',
        'Bags': '👛',
        'Jewelry': '💍',
        'Makeup': '💄',
        'Skincare': '🧴',
      }[cat] ??
          '✨';

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(0.34, 1.32, 0.64, 1),
        transform: _hovered
            ? Matrix4.translationValues(0.0, -2.0, 0.0)
            : Matrix4.identity(),
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          children: [
            Text(_catEmoji(widget.item.cat),
                style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(widget.item.name,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text('${widget.item.worn}× worn',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: t.accent.secondary)),
          ],
        ),
      ),
    );
  }
}

class _HoverStatCard extends StatefulWidget {
  final LinearGradient gradient;
  final Color iconBg;
  final String iconChar;
  final String number;
  final String label;
  final String sub;
  const _HoverStatCard({
    required this.gradient,
    required this.iconBg,
    required this.iconChar,
    required this.number,
    required this.label,
    required this.sub,
  });

  @override
  State<_HoverStatCard> createState() => _HoverStatCardState();
}

class _HoverStatCardState extends State<_HoverStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.translationValues(0.0, -2.0, 0.0)..multiply(Matrix4.diagonal3Values(1.01, 1.01, 1.0)))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _hovered
              ? [
            BoxShadow(
                color: t.backgroundPrimary.withValues(alpha: 0.4),
                blurRadius: 28,
                offset: const Offset(0, 8))
          ]
              : [
            BoxShadow(
                color: t.backgroundPrimary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(widget.iconChar,
                      style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(height: 14),
            Text(widget.number,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                    height: 1,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(widget.label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(widget.sub,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: t.textPrimary.withValues(alpha: 0.75),
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _BarItem {
  final String label;
  final Color color;
  final double value;
  const _BarItem(
      {required this.label,
        required this.color,
        required this.value});
}

class _BarSection extends StatefulWidget {
  final List<_BarItem> bars;
  const _BarSection({required this.bars});

  @override
  State<_BarSection> createState() => _BarSectionState();
}

class _BarSectionState extends State<_BarSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Column(
        children: widget.bars
            .map((bar) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
                width: 100,
                child: Text(bar.label,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: t.mutedText,
                        fontWeight: FontWeight.w400))),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                    color: t.panel,
                    borderRadius:
                    BorderRadius.circular(4)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                  bar.value.clamp(0.0, 1.0) *
                      _anim.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        bar.color.withValues(alpha: 0.7),
                        bar.color
                      ]),
                      borderRadius:
                      BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
                width: 28,
                child: Text(
                    '${(bar.value * 100).round()}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: t.mutedText))),
          ]),
        ))
            .toList(),
      ),
    );
  }
}

// ── CUSTOM PAINTERS ──
class _ChevronLeftPainter extends CustomPainter {
  final Color color;
  const _ChevronLeftPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.7, 0)
        ..lineTo(size.width * 0.2, size.height / 2)
        ..lineTo(size.width * 0.7, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}