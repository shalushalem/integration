// ============================================================
// WARDROBE.DART - DUAL R2 UPLOAD + APPWRITE FETCH/SAVE
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/theme/theme_tokens.dart';

// ?? Backend & Providers
import 'package:provider/provider.dart';
import 'package:myapp/services/backend_service.dart';
import 'package:myapp/services/appwrite_service.dart';

// -- COLORS --

part 'wardrobe_parts.dart';

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

const Color kTransparent = Colors.transparent;

// -- DATA MODEL --
class WardrobeItem {
  final String id; 
  String name;
  String cat;
  List<String> occasions;
  String notes;
  int worn;
  bool liked;
  Uint8List? imageBytes;
  
  // Dual URLs to match your Database
  String? imageUrl; // Raw image URL
  String? maskedUrl; // Processed PNG URL

  WardrobeItem({
    required this.id,
    required this.name,
    required this.cat,
    required this.occasions,
    this.notes = '',
    this.worn = 0,
    this.liked = false,
    this.imageBytes,
    this.imageUrl,
    this.maskedUrl,
  });

  // Helper to always show the processed image first, falling back to raw
  String? get displayUrl => maskedUrl ?? imageUrl;
}

// -- WARDROBE SCREEN --
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
  
  bool _isLoading = true; // ? Loader state for initial fetch
  
  AppThemeTokens get t => context.themeTokens;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchWardrobeItems(); 
  }

  // ?? Fetch from Appwrite
  Future<void> _fetchWardrobeItems() async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final response = await appwrite.getWardrobeItems();

      final fetchedItems = response.map((doc) {
        return WardrobeItem(
          id: (doc['id'] ?? '').toString(),
          name: (doc['name'] ?? '').toString(),
          cat: (doc['category'] ?? '').toString(),
          occasions: doc['occasions'] != null ? List<String>.from(doc['occasions']) : [],
          notes: (doc['notes'] ?? '').toString(),
          worn: doc['worn'] ?? 0,
          liked: doc['liked'] ?? false,
          imageUrl: doc['image_url']?.toString(),
          maskedUrl: doc['masked_url']?.toString(), 
        );
      }).toList();

      if (mounted) {
        setState(() {
          _wardrobe.clear();
          _wardrobe.addAll(fetchedItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("? Failed to fetch wardrobe: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
            _wardrobe.insert(0, WardrobeItem(
              id: item['id'] as String,
              name: item['name'] as String,
              cat: item['cat'] as String,
              occasions: List<String>.from(item['occasions'] as List),
              notes: item['notes'] as String,
              imageBytes: item['imageBytes'] as Uint8List?,
              imageUrl: item['imageUrl'] as String?,
              maskedUrl: item['maskedUrl'] as String?,
              worn: item['worn'] as int? ?? 0,
              liked: item['liked'] as bool? ?? false,
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

  void _openItemDetail(String id) {
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
          _showToast('? Logged a wear for "${item.name}"');
        },
        onToggleLike: () {
          setState(() => item.liked = !item.liked);
          _showToast(item.liked
              ? '? Added "${item.name}" to favourites'
              : '? Removed from favourites');
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
        '?? ${item.name}\n?? ${item.cat}${item.occasions.isNotEmpty ? ' · ${item.occasions.join(', ')}' : ''}'
        '${item.notes.isNotEmpty ? '\n?? ${item.notes}' : ''}';
    Clipboard.setData(ClipboardData(text: text));
    _showToast('?? Copied to clipboard!');
  }

  void _showDeleteConfirm(String id) {
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
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _wardrobe.removeWhere((i) => i.id == id));
              _showToast('?? "${item.name}" removed');
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
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
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
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: t.accent.primary)) 
                  : _activeTab == 0
                  ? _WardrobePanel(
                items: _filtered,
                allEmpty: _wardrobe.isEmpty,
                onAddTap: _openAddModal,
                wardrobe: _wardrobe,
                onDelete: (id) => _showDeleteConfirm(id),
                onToggleLike: (id) {
                  HapticFeedback.selectionClick();
                  final i = _wardrobe.firstWhere((e) => e.id == id);
                  setState(() => i.liked = !i.liked);
                  _showToast(i.liked
                      ? '? Added "${i.name}" to favourites'
                      : '? Removed from favourites');
                },
                onWore: (id) {
                  setState(() {
                    final i = _wardrobe.firstWhere((e) => e.id == id);
                    i.worn++;
                  });
                  final i = _wardrobe.firstWhere((e) => e.id == id);
                  _showToast('? Logged a wear for "${i.name}"');
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

// -- ITEM DETAIL PANEL --
