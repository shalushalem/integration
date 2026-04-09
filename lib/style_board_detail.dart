import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/services/appwrite_service.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:provider/provider.dart';

class StyleBoardDetailPage extends StatefulWidget {
  const StyleBoardDetailPage({
    super.key,
    required this.board,
    this.boards = const <Map<String, dynamic>>[],
    this.initialIndex = 0,
  });

  final Map<String, dynamic> board;
  final List<Map<String, dynamic>> boards;
  final int initialIndex;

  @override
  State<StyleBoardDetailPage> createState() => _StyleBoardDetailPageState();
}

class _StyleBoardDetailPageState extends State<StyleBoardDetailPage> {
  late List<Map<String, dynamic>> _boards;
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, bool> _isSavingByIndex = <int, bool>{};
  final Map<int, bool> _isSavedByIndex = <int, bool>{};
  final Map<int, Future<List<Map<String, dynamic>>>> _itemsFutureByIndex = <int, Future<List<Map<String, dynamic>>>>{};

  @override
  void initState() {
    super.initState();
    _boards = widget.boards.isNotEmpty
        ? widget.boards.map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[Map<String, dynamic>.from(widget.board)];
    _currentIndex = widget.initialIndex.clamp(0, _boards.isEmpty ? 0 : _boards.length - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
    for (var i = 0; i < _boards.length; i++) {
      final b = _boards[i];
      final id = (b[r'$id'] ?? '').toString().trim();
      final userId = (b['userId'] ?? b['user_id'] ?? '').toString().trim();
      _isSavedByIndex[i] = id.isNotEmpty && userId.isNotEmpty && !id.startsWith('preview-');
      _itemsFutureByIndex[i] = _loadItemsForBoard(i);
    }
    _precacheForIndex(_currentIndex);
    _precacheForIndex(_currentIndex + 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      var s = value.trim();
      if (s.isEmpty) return const <String>[];
      if (s.startsWith('[') && s.endsWith(']')) {
        s = s.substring(1, s.length - 1);
      }
      return s
          .split(',')
          .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static String _pickUrl(Map<String, dynamic> item) {
    for (final key in const [
      'masked_url',
      'maskedUrl',
      'image_masked_url',
      'processed_image_url',
      'image_url',
      'imageUrl',
      'raw_image_url',
    ]) {
      final value = (item[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static bool _isRenderableImageUrl(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return false;
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('data:image/');
  }

  static bool _isSavableRemoteUrl(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  static String _pickLabel(Map<String, dynamic> item) {
    return (item['sub_category'] ??
            item['subCategory'] ??
            item['category'] ??
            item['name'] ??
            'item')
        .toString()
        .trim();
  }

  Map<String, dynamic> get _currentBoard => _boards[_currentIndex];

  List<String> _itemIdsForBoard(Map<String, dynamic> board) =>
      _asStringList(board['itemIds'] ?? board['item_ids']);

  List<Map<String, String>> _previewSlotsFromBoard(Map<String, dynamic> root) {
    final preview = root['preview'] is Map
        ? Map<String, dynamic>.from(root['preview'] as Map)
        : const <String, dynamic>{};
    final out = <Map<String, String>>[];

    Map<String, dynamic> readPart(String key) {
      final p = preview[key] ?? root[key];
      if (p is Map) return Map<String, dynamic>.from(p);
      return const <String, dynamic>{};
    }

    final parts = <Map<String, dynamic>>[
      readPart('top'),
      readPart('bottom'),
      readPart('shoes'),
      readPart('accessory1'),
      readPart('accessory2'),
      if (preview.isNotEmpty) preview,
    ];

    for (final part in parts) {
      if (part.isEmpty) continue;
      final url = _pickUrl(part);
      if (!_isRenderableImageUrl(url)) continue;
      out.add({
        'url': url,
        'label': _pickLabel(part),
      });
    }
    return out;
  }

  List<Map<String, String>> _fallbackSlotsFromBoard(Map<String, dynamic> root) {
    final out = <Map<String, String>>[];
    final seen = <String>{};

    void addUrl(String raw, {String label = 'item'}) {
      final url = raw.trim();
      if (!_isRenderableImageUrl(url) || seen.contains(url)) return;
      seen.add(url);
      out.add({'url': url, 'label': label});
    }

    for (final key in const [
      'masked_url',
      'maskedUrl',
      'image_url',
      'imageUrl',
      'raw_image_url',
      'rawImageUrl',
    ]) {
      addUrl((root[key] ?? '').toString(), label: 'outfit');
    }

    final listCandidates = [
      root['images'],
      root['imageUrls'],
      root['image_urls'],
    ];
    for (final list in listCandidates) {
      if (list is! List) continue;
      for (final entry in list) {
        if (entry is Map) {
          final m = Map<String, dynamic>.from(entry);
          addUrl(_pickUrl(m), label: _pickLabel(m));
        } else {
          addUrl((entry ?? '').toString(), label: 'item');
        }
      }
    }

    return out;
  }

  Future<List<Map<String, dynamic>>> _loadItemsForBoard(int index) async {
    if (index < 0 || index >= _boards.length) return const <Map<String, dynamic>>[];
    final board = _boards[index];
    final appwrite = Provider.of<AppwriteService>(context, listen: false);
    final ids = _itemIdsForBoard(board).toSet().toList();
    if (ids.isEmpty) return const <Map<String, dynamic>>[];
    final docs = await Future.wait(ids.map(appwrite.getWardrobeItemById));
    return docs.whereType<Map<String, dynamic>>().where((doc) => doc.isNotEmpty).toList();
  }

  String _firstRenderableUrlFromBoard(Map<String, dynamic> board) {
    final previewSlots = _previewSlotsFromBoard(board);
    if (previewSlots.isNotEmpty) {
      final u = (previewSlots.first['url'] ?? '').trim();
      if (u.isNotEmpty) return u;
    }
    final fallbackSlots = _fallbackSlotsFromBoard(board);
    if (fallbackSlots.isNotEmpty) {
      final u = (fallbackSlots.first['url'] ?? '').trim();
      if (u.isNotEmpty) return u;
    }
    return '';
  }

  Future<void> _precacheForIndex(int index) async {
    if (!mounted || index < 0 || index >= _boards.length) return;
    final board = _boards[index];
    final urls = <String>{};
    for (final row in _previewSlotsFromBoard(board)) {
      final u = (row['url'] ?? '').trim();
      if (_isRenderableImageUrl(u)) urls.add(u);
    }
    for (final row in _fallbackSlotsFromBoard(board)) {
      final u = (row['url'] ?? '').trim();
      if (_isRenderableImageUrl(u)) urls.add(u);
    }
    for (final u in urls.take(6)) {
      try {
        await precacheImage(CachedNetworkImageProvider(u), context);
      } catch (_) {}
    }
  }

  Future<void> _saveStyleBoard() async {
    final board = _currentBoard;
    final itemIds = _itemIdsForBoard(board);
    if ((_isSavingByIndex[_currentIndex] ?? false) || (_isSavedByIndex[_currentIndex] ?? false)) return;
    setState(() => _isSavingByIndex[_currentIndex] = true);
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      final items = await (_itemsFutureByIndex[_currentIndex] ?? _loadItemsForBoard(_currentIndex));
      final urls = items.map(_pickUrl).where((e) => _isRenderableImageUrl(e)).toList();
      final primary = (urls.isNotEmpty ? urls.first : _firstRenderableUrlFromBoard(board)).trim();
      if (!_isSavableRemoteUrl(primary)) {
        throw Exception('Missing valid image URL');
      }
      final payload = <String, dynamic>{
        'imageUrl': primary,
        'occasion': (board['occasion'] ?? 'Occasion').toString().trim(),
        if (itemIds.isNotEmpty) 'itemIds': itemIds,
      };
      await appwrite.createSavedBoard(payload);
      if (!mounted) return;
      setState(() {
        _isSavedByIndex[_currentIndex] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Style board saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save style board')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingByIndex[_currentIndex] = false);
      }
    }
  }

  Widget _boardCanvas(AppThemeTokens t, Map<String, dynamic> board, List<Map<String, dynamic>> items) {
    final itemSlots = items
        .map((item) => {
              'url': _pickUrl(item),
              'label': _pickLabel(item),
            })
        .where((slot) => _isRenderableImageUrl(slot['url'] ?? ''))
        .toList();
    final previewSlots = _previewSlotsFromBoard(board);
    final fallbackSlots = _fallbackSlotsFromBoard(board);
    final slotsData = itemSlots.isNotEmpty
        ? itemSlots
        : (previewSlots.isNotEmpty ? previewSlots : fallbackSlots);
    final slots = [
      const Rect.fromLTWH(0.16, 0.03, 0.68, 0.42), // top center
      const Rect.fromLTWH(0.18, 0.42, 0.64, 0.42), // bottom center
      const Rect.fromLTWH(0.03, 0.58, 0.28, 0.30), // left shoe/accent
      const Rect.fromLTWH(0.69, 0.58, 0.28, 0.30), // right shoe/accent
      const Rect.fromLTWH(0.04, 0.08, 0.24, 0.24), // accessory 1
      const Rect.fromLTWH(0.72, 0.08, 0.24, 0.24), // accessory 2
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final dpr = MediaQuery.of(context).devicePixelRatio;
        return Stack(
          children: [
            for (var i = 0; i < slotsData.length && i < slots.length; i++)
              Positioned(
                left: slots[i].left * w,
                top: slots[i].top * h,
                width: slots[i].width * w,
                height: slots[i].height * h,
                child: Column(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: (slotsData[i]['url'] ?? '').toString(),
                        fit: BoxFit.contain,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: ((slots[i].width * w) * dpr).round(),
                        memCacheHeight: ((slots[i].height * h) * dpr).round(),
                        maxWidthDiskCache: ((slots[i].width * w) * dpr).round(),
                        maxHeightDiskCache: ((slots[i].height * h) * dpr).round(),
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.6),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.cardBorder),
                          ),
                          child: Icon(Icons.broken_image_outlined, color: t.mutedText, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (slotsData[i]['label'] ?? 'item').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (slotsData.isEmpty)
              Center(
                child: Text(
                  'No item images found for this style board.',
                  style: TextStyle(color: t.mutedText, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final board = _currentBoard;
    final occasion = (board['occasion'] ?? 'Occasion').toString().trim();
    final title = (board['title'] ?? board['name'] ?? '$occasion Style Board').toString().trim();
    final isSaving = _isSavingByIndex[_currentIndex] ?? false;
    final isSaved = _isSavedByIndex[_currentIndex] ?? false;

    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: t.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: t.textPrimary),
        title: Text(
          _boards.length > 1 ? 'Style Board ${_currentIndex + 1}/${_boards.length}' : 'Style Board',
          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _boards.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _precacheForIndex(index + 1);
                _precacheForIndex(index - 1);
              },
              itemBuilder: (context, index) {
                final pageBoard = _boards[index];
                final pageFuture = _itemsFutureByIndex[index] ??= _loadItemsForBoard(index);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.92),
                    border: Border.all(color: t.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.transparent,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: pageFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: t.accent.primary,
                              ),
                            );
                          }
                          final items = snapshot.data ?? const <Map<String, dynamic>>[];
                          return _boardCanvas(t, pageBoard, items);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_boards.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_boards.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: active ? t.accent.primary : t.cardBorder,
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            title.isEmpty ? '$occasion Style Board' : title,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: t.accent.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              occasion.isEmpty ? 'Occasion' : occasion,
              style: TextStyle(
                color: t.accent.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: isSaving || isSaved ? null : _saveStyleBoard,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: (isSaving || isSaved)
                      ? LinearGradient(
                          colors: [t.accent.tertiary, t.accent.tertiary],
                        )
                      : LinearGradient(
                          colors: [t.accent.tertiary, t.accent.primary],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSaving
                      ? 'Saving...'
                      : (isSaved ? 'Style Board Saved' : 'Save Style Board'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
