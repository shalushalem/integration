// ════════════════════════════════════════════════════════════════════
//  bills_page.dart  –  AHVI My Bills Screen
//  Includes: slide-in bill cards, animated filter tabs, bottom-sheet
//  modals with slide-up animation, coupon manager, detail sheet,
//  dynamic totals that react to filter, add-bill form, delete bills,
//  FAB chat button, animated chat panel, toast notifications, and
//  pulsing dot animation.
// ════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── PALETTE (1:1 from CSS :root) ────────────────────────────────────
const Color kBg        = Color(0xFF08111F);
const Color kBg2       = Color(0xFF0F1A2D);
const Color kShell     = Color(0xFF192131);
const Color kShell2    = Color(0xFF111723);
const Color kText      = Color(0xFFF5F7FF);
const Color kMuted     = Color(0xB8E6EBFF);
const Color kAccent    = Color(0xFF6B91FF);
const Color kAccent2   = Color(0xFF8D7DFF);
const Color kAccent3   = Color(0xFF04D7C8);
const Color kAccent4   = Color(0xFFFF8EC7);
const Color kAccent5   = Color(0xFFFFD86E);
const Color kRed       = Color(0xFFFF6B7A);
const Color kPanel     = Color(0x14FFFFFF);
const Color kPanel2    = Color(0x1FFFFFFF);
const Color kBorder    = Color(0x1FFFFFFF);

// ════════════════════════════════════════════════════════════════════
//  ROOT WIDGET - RENAMED TO BillsScreen to avoid conflict with home.dart
// ════════════════════════════════════════════════════════════════════
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});
  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with TickerProviderStateMixin {

  // ── STATE ──────────────────────────────────────────────────────────
  String _activeFilter = 'all';
  bool   _chatOpen     = false;

  // Active add-bill mode: 'ai' or 'manual'
  String _addMode = 'ai';

  // Dropdown selections inside Add Bill form
  String _selCategory = 'Shopping';
  String _selPayment  = 'UPI';
  String _couponTypeVal = 'Percent';

  // Toast state
  String  _toastMsg    = '';
  bool    _toastVisible = false;
  late AnimationController _toastAnim;

  // FAB pulse animation for the chat dot
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // Chat panel slide animation
  late AnimationController _chatCtrl;
  late Animation<double>   _chatSlide;

  // Overlay slide animation (used for both Add Bill & Coupon sheets)
  late AnimationController _sheetCtrl;
  late Animation<double>   _sheetSlide;

  // Overlay type: 'add' | 'coupon' | ''
  String _overlayType = '';

  // Chat messages
  final List<Map<String, String>> _chatMessages = [
    {'from': 'ahvi', 'text': 'Hi! ✦ I\'m AHVI. Upload a bill photo for AI autofill, or enter details manually — I\'ve got you covered!'},
  ];
  final TextEditingController _chatInputCtrl = TextEditingController();

  // ── BILLS DATA ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _bills = [
    {
      'id': 'b1',
      'store': 'Swiggy',
      'amount': 485.0,
      'date': 'Mar 15, 2025',
      'category': 'food',
      'payment': 'UPI',
      'note': 'Dinner order - Burger & Fries',
      'catColor': kAccent5,
      'catBg': const Color(0x26FFD86E),
      'icon': '🍔',
    },
    {
      'id': 'b2',
      'store': 'Apollo Pharmacy',
      'amount': 1250.0,
      'date': 'Mar 12, 2025',
      'category': 'medical',
      'payment': 'Credit Card',
      'note': 'Monthly medicines',
      'catColor': kAccent4,
      'catBg': const Color(0x26FF8EC7),
      'icon': '💊',
    },
    {
      'id': 'b3',
      'store': 'Zara',
      'amount': 3499.0,
      'date': 'Mar 10, 2025',
      'category': 'shopping',
      'payment': 'Debit Card',
      'note': 'Summer collection',
      'catColor': kAccent2,
      'catBg': const Color(0x268D7DFF),
      'icon': '👗',
    },
    {
      'id': 'b4',
      'store': 'BESCOM',
      'amount': 890.0,
      'date': 'Mar 5, 2025',
      'category': 'utility',
      'payment': 'Net Banking',
      'note': 'Electricity bill - March',
      'catColor': kAccent3,
      'catBg': const Color(0x2604D7C8),
      'icon': '⚡',
    },
  ];

  // ── COUPONS DATA ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _coupons = [
    {'id': 'c1', 'code': 'SAVE10',   'type': 'percent', 'value': 10,  'note': '10% off anything',        'bigNum': '10%', 'unitTxt': 'OFF',      'gradient': [const Color(0xFF8D7DFF), const Color(0xFF6B91FF)]},
    {'id': 'c2', 'code': 'FLAT50',   'type': 'flat',    'value': 50,  'note': '₹50 flat discount',       'bigNum': '₹50', 'unitTxt': 'FLAT OFF', 'gradient': [const Color(0xFFFF8EC7), const Color(0xFFFFD86E)]},
    {'id': 'c3', 'code': 'AHVI15',   'type': 'percent', 'value': 15,  'note': 'AHVI exclusive 15% off',  'bigNum': '15%', 'unitTxt': 'OFF',      'gradient': [const Color(0xFF04D7C8), const Color(0xFF6B91FF)]},
    {'id': 'c4', 'code': 'FESTIVE25','type': 'percent', 'value': 25,  'note': 'Festive season deal',     'bigNum': '25%', 'unitTxt': 'OFF',      'gradient': [const Color(0xFF6B91FF), const Color(0xFF04D7C8)]},
  ];

  // ── COMPUTED ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredBills {
    if (_activeFilter == 'all') return _bills;
    return _bills.where((b) => b['category'] == _activeFilter).toList();
  }

  double get _totalAmount =>
      _filteredBills.fold(0.0, (sum, b) => sum + (b['amount'] as double));

  String get _avgBill {
    final list = _filteredBills;
    if (list.isEmpty) return '–';
    final avg = _totalAmount / list.length;
    return '₹${avg.toStringAsFixed(0)}';
  }

  String get _topCategory {
    if (_bills.isEmpty) return '–';
    final Map<String, double> totals = {};
    for (final b in _bills) {
      final cat = b['category'] as String;
      totals[cat] = (totals[cat] ?? 0) + (b['amount'] as double);
    }
    final top = totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const icons = {'food':'🍔','shopping':'🛍️','medical':'💊','utility':'⚡','other':'📄'};
    return icons[top] ?? '–';
  }

  String _formatAmount(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final parts = <String>[];
      var rem = s;
      while (rem.length > 3) {
        parts.insert(0, rem.substring(rem.length - 3));
        rem = rem.substring(0, rem.length - 3);
      }
      parts.insert(0, rem);
      return parts.join(',');
    }
    return v.toStringAsFixed(0);
  }

  // ── LIFECYCLE ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Pulse animation for chat dot
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Chat panel slide/scale animation
    _chatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _chatSlide = CurvedAnimation(parent: _chatCtrl, curve: Curves.easeOutBack);

    // Sheet slide-up animation
    _sheetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _sheetSlide = CurvedAnimation(parent: _sheetCtrl, curve: const Cubic(0.34, 1.2, 0.64, 1));

    // Toast animation
    _toastAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _chatCtrl.dispose();
    _sheetCtrl.dispose();
    _toastAnim.dispose();
    _chatInputCtrl.dispose();
    super.dispose();
  }

  // ── ACTIONS ───────────────────────────────────────────────────────
  void _toggleChat() {
    setState(() => _chatOpen = !_chatOpen);
    if (_chatOpen) {
      _chatCtrl.forward();
    } else {
      _chatCtrl.reverse();
    }
  }

  void _openOverlay(String type) {
    setState(() => _overlayType = type);
    _sheetCtrl.forward(from: 0);
  }

  void _closeOverlay() {
    _sheetCtrl.reverse().then((_) {
      setState(() => _overlayType = '');
    });
  }

  void _showToast(String msg) async {
    setState(() {
      _toastMsg = msg;
      _toastVisible = true;
    });
    await _toastAnim.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 2200));
    await _toastAnim.reverse();
    if (mounted) setState(() => _toastVisible = false);
  }

  void _deleteBill(String id) {
    setState(() => _bills.removeWhere((b) => b['id'] == id));
    _showToast('Bill removed');
  }

  void _deleteCoupon(String id) {
    setState(() => _coupons.removeWhere((c) => c['id'] == id));
    _showToast('Coupon removed');
  }

  void _addBill({
    required String store,
    required String amount,
    required String category,
    required String payment,
    required String note,
  }) {
    final amt = double.tryParse(amount) ?? 0;
    if (store.trim().isEmpty || amt <= 0) {
      _showToast('Please fill Store and Amount');
      return;
    }
    const catMeta = {
      'Shopping': {'cat': 'shopping', 'icon': '🛍️', 'color': kAccent2, 'bg': Color(0x268D7DFF)},
      'Food':     {'cat': 'food',     'icon': '🍽️', 'color': kAccent5, 'bg': Color(0x26FFD86E)},
      'Utility':  {'cat': 'utility',  'icon': '⚡', 'color': kAccent3, 'bg': Color(0x2604D7C8)},
      'Medical':  {'cat': 'medical',  'icon': '💊', 'color': kAccent4, 'bg': Color(0x26FF8EC7)},
      'Other':    {'cat': 'other',    'icon': '📄', 'color': kText,    'bg': Color(0x1AFFFFFF)},
    };
    final meta = catMeta[category] ?? catMeta['Other']!;
    setState(() {
      _bills.insert(0, {
        'id': 'b${DateTime.now().millisecondsSinceEpoch}',
        'store': store.trim(),
        'amount': amt,
        'date': _todayLabel(),
        'category': meta['cat'],
        'payment': payment,
        'note': note.trim().isEmpty ? '—' : note.trim(),
        'catColor': meta['color'],
        'catBg': meta['bg'],
        'icon': meta['icon'],
      });
    });
    _closeOverlay();
    _showToast('✦ Bill saved!');
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // ── BUILD ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            // ── MESH BACKGROUND
            _MeshBackground(),

            // ── MAIN SCREEN
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildScrollArea()),
                  _buildBottomActions(),
                ],
              ),
            ),

            // ── CHAT FAB
            Positioned(
              bottom: 108,
              right: 20,
              child: _buildChatFab(),
            ),

            // ── CHAT PANEL
            AnimatedBuilder(
              animation: _chatSlide,
              builder: (_, __) {
                return Positioned(
                  bottom: 170,
                  right: 24,
                  child: Opacity(
                    opacity: _chatSlide.value,
                    child: Transform(
                      alignment: Alignment.bottomRight,
                      transform: Matrix4.identity()
                        ..translate(0.0, 16.0 * (1 - _chatSlide.value))
                        ..scale(0.95 + 0.05 * _chatSlide.value),
                      child: IgnorePointer(
                        ignoring: !_chatOpen,
                        child: _buildChatPanel(),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── OVERLAY (Add Bill / Coupon Manager)
            if (_overlayType.isNotEmpty)
              AnimatedBuilder(
                animation: _sheetSlide,
                builder: (_, __) => _buildOverlayBackdrop(),
              ),

            // ── TOAST NOTIFICATION
            if (_toastVisible)
              AnimatedBuilder(
                animation: _toastAnim,
                builder: (_, __) => Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: _toastAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - _toastAnim.value)),
                        child: _buildToast(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  HEADER
  // ════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      color: Colors.transparent, // Adjusted so mesh background shows
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PressScaleButton(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 34, height: 34,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: kPanel,
                border: Border.all(color: kBorder, width: 1),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F6B91FF), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: kText, size: 13),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('My Bills', style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900,
                color: kText, height: 1.0, letterSpacing: -0.5,
              )),
              SizedBox(height: 4),
              Text('BY AHVI', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 3.2, color: kMuted,
              )),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  SCROLL AREA
  // ════════════════════════════════════════════════════════════════════
  Widget _buildScrollArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildSpendingCard(),
          const SizedBox(height: 14),
          _buildFilterTabs(),
          const SizedBox(height: 12),
          Text(
            _activeFilter == 'all' ? 'Recent Bills' : '${_toTitleCase(_activeFilter)} Bills',
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: kText,
            ),
          ),
          const SizedBox(height: 10),
          _buildBillsList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _toTitleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ════════════════════════════════════════════════════════════════════
  //  SPENDING CARD
  // ════════════════════════════════════════════════════════════════════
  Widget _buildSpendingCard() {
    final bills = _filteredBills;
    final total = _totalAmount;
    final count = bills.length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAccent2, kAccent, Color(0xD96B91FF)],
          stops: [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x476B91FF), blurRadius: 30, offset: Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(top: -30, right: -30,
              child: Container(width: 130, height: 130,
                  decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle))),
          Positioned(bottom: -50, left: -20,
              child: Container(width: 160, height: 160,
                  decoration: const BoxDecoration(color: Color(0x12FFFFFF), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL SPENDING', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 2.88, color: Color(0xBFFFFFFF),
                )),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    key: ValueKey(total),
                    alignment: Alignment.centerLeft,
                    child: RichText(text: TextSpan(children: [
                      const TextSpan(text: '₹', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xD9FFFFFF),
                      )),
                      TextSpan(text: _formatAmount(total), style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700,
                        color: Colors.white, height: 1.0,
                      )),
                    ])),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildStatPill('$count', 'Bills')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatPill(_avgBill, 'Avg Bill')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatPill(_topCategory, 'Top Cat.')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0x38FFFFFF),
        border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: Colors.white, height: 1.0,
          )),
          const SizedBox(height: 3),
          Text(label.toUpperCase(), style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600,
            color: Color(0xB3FFFFFF), letterSpacing: 1.28,
          )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  FILTER TABS
  // ════════════════════════════════════════════════════════════════════
  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all',      'label': 'All',      'color': Colors.white,  'bg': kBg2},
      {'key': 'shopping', 'label': 'Shopping', 'color': kAccent2,      'bg': const Color(0x268D7DFF)},
      {'key': 'food',     'label': 'Food',     'color': kAccent5,      'bg': const Color(0x26FFD86E)},
      {'key': 'utility',  'label': 'Utility',  'color': kAccent3,      'bg': const Color(0x2604D7C8)},
      {'key': 'medical',  'label': 'Medical',  'color': kAccent4,      'bg': const Color(0x26FF8EC7)},
      {'key': 'other',    'label': 'Other',    'color': kText,         'bg': kBg2},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final key      = tab['key'] as String;
          final isActive = _activeFilter == key;
          final color    = tab['color'] as Color;
          final bg       = tab['bg'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? bg : kPanel,
                  border: Border.all(
                    color: isActive ? color.withOpacity(0.6) : kBorder,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isActive ? color.withOpacity(0.14) : const Color(0x0F6B91FF),
                      blurRadius: isActive ? 14 : 8,
                      offset: Offset(0, isActive ? 4 : 2),
                    ),
                  ],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? color : kText,
                    letterSpacing: 0.2,
                  ),
                  child: Text(tab['label'] as String),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  BILLS LIST
  // ════════════════════════════════════════════════════════════════════
  Widget _buildBillsList() {
    final bills = _filteredBills;
    if (bills.isEmpty) return _buildEmptyState();

    return Column(
      children: bills.asMap().entries.map((entry) {
        final i    = entry.key;
        final bill = entry.value;
        return _AnimatedBillCard(
          key: ValueKey(bill['id']),
          bill: bill,
          delay: Duration(milliseconds: i * 60),
          onTap: () => _showDetailSheet(bill),
          onDelete: () => _deleteBill(bill['id'] as String),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: kShell,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Column(
        children: const [
          Text('🧾', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('No Bills Yet', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: kText,
          )),
          SizedBox(height: 6),
          Text('Tap "Add Bill" below to scan or\nmanually enter your first bill.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w500, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  BOTTOM ACTIONS
  // ════════════════════════════════════════════════════════════════════
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: _PressScaleButton(
              onTap: () => _openOverlay('add'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: kAccent2,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x668D7DFF), blurRadius: 30, offset: Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Add Bill', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PressScaleButton(
              onTap: () => _openOverlay('coupon'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: kAccent2,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(color: Color(0x598D7DFF), blurRadius: 30, offset: Offset(0, 10)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.local_offer_outlined, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('My Coupons', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                        )),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -6, right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 18,
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: kAccent4,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: kBg, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${_coupons.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
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

  // ════════════════════════════════════════════════════════════════════
  //  CHAT FAB 
  // ════════════════════════════════════════════════════════════════════
  Widget _buildChatFab() {
    return _PressScaleButton(
      onTap: _toggleChat,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 18, 11),
        decoration: BoxDecoration(
          color: kAccent2,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(color: Color(0x8C8D7DFF), blurRadius: 20, offset: Offset(0, 6)),
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26, height: 26,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _chatOpen ? Icons.close_rounded : Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18,
                    ),
                  ),
                  if (!_chatOpen)
                    Positioned(
                      top: -1, right: -1,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: kAccent5,
                              shape: BoxShape.circle,
                              border: Border.all(color: kAccent5.withOpacity(0.7), width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('ASK AHVI', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 0.96,
            )),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  CHAT PANEL 
  // ════════════════════════════════════════════════════════════════════
  Widget _buildChatPanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: kShell,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 60, offset: Offset(0, 20)),
          BoxShadow(color: kPanel2, blurRadius: 0, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x1A8D7DFF), Color(0x0FFF8EC7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: kBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [kAccent2, kAccent4]),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('A', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('AHVI', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: kText,
                        )),
                        Text('Online · Bills Assistant', style: TextStyle(
                          fontSize: 9, color: kMuted, fontWeight: FontWeight.w500,
                        )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleChat,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: kPanel, borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.close_rounded, color: kText, size: 13),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                itemCount: _chatMessages.length,
                itemBuilder: (_, i) {
                  final msg = _chatMessages[i];
                  final isAhvi = msg['from'] == 'ahvi';
                  return Align(
                    alignment: isAhvi ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      constraints: const BoxConstraints(maxWidth: 220),
                      decoration: BoxDecoration(
                        color: isAhvi
                            ? const Color(0xFF1E2D45)
                            : const Color(0xFF1A2038),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isAhvi ? 4 : 16),
                          bottomRight: Radius.circular(isAhvi ? 16 : 4),
                        ),
                        border: Border.all(color: kBorder, width: 1),
                      ),
                      child: Text(msg['text']!, style: const TextStyle(
                        fontSize: 12, color: kText, height: 1.5,
                      )),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: kPanel, borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mic_rounded, color: kMuted, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _chatInputCtrl,
                      style: const TextStyle(fontSize: 12, color: kText),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your bills…',
                        hintStyle: TextStyle(color: kMuted, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                      onSubmitted: (v) => _sendChatMsg(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendChatMsg(_chatInputCtrl.text),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: kAccent2, borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 13),
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

  void _sendChatMsg(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({'from': 'user', 'text': text.trim()});
      _chatMessages.add({'from': 'ahvi', 'text': 'Got it! I\'m reviewing your bills now… ✦'});
    });
    _chatInputCtrl.clear();
  }

  // ════════════════════════════════════════════════════════════════════
  //  OVERLAY (Add Bill + Coupon Manager)
  // ════════════════════════════════════════════════════════════════════
  Widget _buildOverlayBackdrop() {
    return GestureDetector(
      onTap: _closeOverlay,
      child: Container(
        color: Color.lerp(Colors.transparent, const Color(0xB808111F), _sheetSlide.value),
        child: GestureDetector(
          onTap: () {}, 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Transform.translate(
                offset: Offset(0, (1 - _sheetSlide.value) * 600),
                child: _overlayType == 'add'
                    ? _buildAddSheet()
                    : _buildCouponMgrSheet(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  ADD BILL SHEET
  // ════════════════════════════════════════════════════════════════════
  final _storeCtrl   = TextEditingController();
  final _amountCtrl  = TextEditingController();
  final _itemsCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  final _couponCtrl  = TextEditingController();

  Widget _buildAddSheet() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.93),
      decoration: const BoxDecoration(
        color: kBg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(top: BorderSide(color: kBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Color(0x266B91FF), blurRadius: 60, offset: Offset(0, -20)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const Text('Add a Bill', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: kText,
            )),
            const SizedBox(height: 3),
            const Text("Choose how you'd like to add your bill", style: TextStyle(
              fontSize: 11, color: kMuted, fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 14),

            _buildModeToggle(),
            const SizedBox(height: 16),

            if (_addMode == 'ai') ...[
              _buildUploadSection(),
              const SizedBox(height: 12),
            ],

            if (_addMode == 'manual') ...[
              _buildManualBanner(),
              const SizedBox(height: 12),
            ],

            _buildFormGroup('Store / Vendor *', child: _glassInput(
              controller: _storeCtrl,
              placeholder: 'e.g. Zara, Swiggy, Apollo…',
            )),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildFormGroup('Amount (₹) *', child: _glassInput(
                controller: _amountCtrl, placeholder: '0.00',
                inputType: const TextInputType.numberWithOptions(decimal: true),
              ))),
              const SizedBox(width: 10),
              Expanded(child: _buildFormGroup('Date *', child: _datePickerTrigger())),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildFormGroup('Category', child: _buildSelectField(
                value: _selCategory,
                items: ['Shopping', 'Food', 'Utility', 'Medical', 'Other'],
                onChanged: (v) => setState(() => _selCategory = v!),
              ))),
              const SizedBox(width: 10),
              Expanded(child: _buildFormGroup('Payment', child: _buildSelectField(
                value: _selPayment,
                items: ['UPI', 'Credit Card', 'Debit Card', 'Cash', 'Net Banking'],
                onChanged: (v) => setState(() => _selPayment = v!),
              ))),
            ]),
            const SizedBox(height: 10),
            _buildFormGroup('Items (optional)', child: _glassInput(
              controller: _itemsCtrl, placeholder: 'Shirt, Shoes, Watch…',
            )),
            const SizedBox(height: 10),
            _buildFormGroup('Notes (optional)', child: _glassInput(
              controller: _notesCtrl, placeholder: 'Any extra details…', maxLines: 3,
            )),
            const SizedBox(height: 10),

            _buildCouponRow(),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(flex: 1, child: _PressScaleButton(
                onTap: _closeOverlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: kPanel,
                    border: Border.all(color: kBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('Cancel', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kMuted,
                  ))),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _PressScaleButton(
                onTap: () => _addBill(
                  store: _storeCtrl.text,
                  amount: _amountCtrl.text,
                  category: _selCategory,
                  payment: _selPayment,
                  note: _notesCtrl.text,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4D6B91FF), blurRadius: 20, offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Center(child: Text('✦ Save Bill', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                  ))),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(color: kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: ['ai', 'manual'].map((mode) {
          final isActive = _addMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _addMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? (mode == 'ai' ? const Color(0x268D7DFF) : const Color(0x2604D7C8))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode == 'ai' ? Icons.auto_awesome : Icons.edit_outlined,
                      size: 14,
                      color: isActive
                          ? (mode == 'ai' ? kAccent2 : kAccent3)
                          : kMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      mode == 'ai' ? '✦ AI Autofill' : 'Enter Manually',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isActive
                            ? (mode == 'ai' ? kAccent2 : kAccent3)
                            : kMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPLOAD BILL PHOTO', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: kMuted, letterSpacing: 1.6,
        )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _uploadOptBtn(
            icon: Icons.camera_alt_outlined,
            iconColor: const Color(0xFFD4756E),
            bg: const Color(0x1FD4756E),
            border: const Color(0x33D4756E),
            label: 'Camera', sub: 'Take a photo',
          )),
          const SizedBox(width: 10),
          Expanded(child: _uploadOptBtn(
            icon: Icons.upload_file_outlined,
            iconColor: const Color(0xFF5A8FD8),
            bg: const Color(0x1F5A8FD8),
            border: const Color(0x335A8FD8),
            label: 'Upload File', sub: 'JPG, PNG or PDF',
          )),
        ]),
      ],
    );
  }

  Widget _uploadOptBtn({
    required IconData icon, required Color iconColor,
    required Color bg, required Color border,
    required String label, required String sub,
  }) {
    return _PressScaleButton(
      onTap: () => _showToast('Camera/Upload coming soon'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bg, border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: iconColor)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildManualBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1204D7C8),
        border: Border.all(color: const Color(0x2904D7C8), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.edit_rounded, color: kAccent3, size: 16),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Manual Entry Mode', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: kAccent3,
          )),
          Text('Fill in the details below — all * fields required', style: TextStyle(
            fontSize: 10, color: kMuted, fontWeight: FontWeight.w500,
          )),
        ]),
      ]),
    );
  }

  Widget _buildFormGroup(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: kMuted, letterSpacing: 0.4,
        )),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _glassInput({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? inputType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kShell, kShell2],
        ),
        border: Border.all(color: kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x146B91FF), blurRadius: 14, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: kMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _datePickerTrigger() {
    return GestureDetector(
      onTap: () async {
        await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: kAccent2, onPrimary: Colors.white,
                surface: kShell, onSurface: kText,
              ),
            ),
            child: child!,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kShell,
          border: Border.all(color: kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: const [
          Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFC4A0C8)),
          SizedBox(width: 8),
          Expanded(child: Text('Select date', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: kMuted,
          ))),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFC4A0C8)),
        ]),
      ),
    );
  }

  Widget _buildSelectField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kShell, kShell2],
        ),
        border: Border.all(color: kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: kShell,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFC4A0C8), size: 16),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
          items: items.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCouponRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Coupon Code', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: kMuted,
        )),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x0A8D7DFF),
                border: Border.all(color: const Color(0x598D7DFF), width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.local_offer_outlined, size: 14, color: kAccent2),
                ),
                Expanded(
                  child: TextField(
                    controller: _couponCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: kText, letterSpacing: 1.0,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter code',
                      hintStyle: TextStyle(color: kMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          _PressScaleButton(
            onTap: () {
              final code = _couponCtrl.text.trim().toUpperCase();
              if (code.isEmpty) { _showToast('Enter a coupon code'); return; }
              final found = _coupons.any((c) => c['code'] == code);
              if (found) {
                _showToast('✦ Coupon "$code" applied!');
              } else {
                _showToast('Coupon not found');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x1F8D7DFF),
                border: Border.all(color: const Color(0x388D7DFF), width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Apply', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: kAccent2,
              )),
            ),
          ),
        ]),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  COUPON MANAGER SHEET
  // ════════════════════════════════════════════════════════════════════
  final _newCodeCtrl  = TextEditingController();
  final _newValueCtrl = TextEditingController();
  final _newNoteCtrl  = TextEditingController();

  Widget _buildCouponMgrSheet() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: kBg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(top: BorderSide(color: kBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Color(0x2E8D7DFF), blurRadius: 60, offset: Offset(0, -20)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Column(
              children: [
                _sheetHandle(),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('My Coupons', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: kText,
                      )),
                      const SizedBox(height: 3),
                      Text('${_coupons.length} Saved Coupon${_coupons.length != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  _PressScaleButton(
                    onTap: _closeOverlay,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: kPanel, border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(Icons.close_rounded, color: kText, size: 15),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Column(
                children: [
                  _buildAddCouponForm(),
                  const SizedBox(height: 16),
                  if (_coupons.isEmpty) _buildCouponEmptyState(),
                  ..._coupons.asMap().entries.map((e) =>
                      _buildStoredCouponCard(e.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCouponForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: kShell,
        border: Border.all(color: kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _couponFieldLabel('COUPON CODE'),
        const SizedBox(height: 5),
        _couponInput(controller: _newCodeCtrl, placeholder: 'E.G. SAVE10', isBold: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _couponFieldLabel('TYPE'),
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                color: kPanel, border: Border.all(color: kBorder, width: 1.5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _couponTypeVal,
                  dropdownColor: kShell,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFC4A0C8), size: 16),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
                  items: ['Percent','Flat','Free']
                      .map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) => setState(() => _couponTypeVal = v!),
                ),
              ),
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _couponFieldLabel('VALUE'),
            const SizedBox(height: 5),
            _couponInput(
              controller: _newValueCtrl, placeholder: '0',
              inputType: TextInputType.number,
            ),
          ])),
        ]),
        const SizedBox(height: 10),
        _couponFieldLabel('NOTE (OPTIONAL)'),
        const SizedBox(height: 5),
        _couponInput(controller: _newNoteCtrl, placeholder: 'Short description…'),
        const SizedBox(height: 12),
        _PressScaleButton(
          onTap: _saveNewCoupon,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kAccent2, kAccent]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x528D7DFF), blurRadius: 16, offset: Offset(0, 5)),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text('Save Coupon', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  void _saveNewCoupon() {
    final code = _newCodeCtrl.text.trim().toUpperCase();
    final value = double.tryParse(_newValueCtrl.text) ?? 0;
    final note = _newNoteCtrl.text.trim();
    if (code.isEmpty) { _showToast('Enter a coupon code'); return; }
    if (_couponTypeVal != 'Free' && value <= 0) { _showToast('Enter a valid value'); return; }
    if (_coupons.any((c) => c['code'] == code)) { _showToast('Coupon already saved!'); return; }

    final palettes = [
      [const Color(0xFF8D7DFF), const Color(0xFF6B91FF)],
      [const Color(0xFFFF8EC7), const Color(0xFFFFD86E)],
      [const Color(0xFF04D7C8), const Color(0xFF6B91FF)],
      [const Color(0xFF6B91FF), const Color(0xFF04D7C8)],
    ];
    final grad = palettes[_coupons.length % palettes.length];
    final bigNum = _couponTypeVal == 'Free' ? '🎁' :
    (_couponTypeVal == 'Flat' ? '₹${value.toInt()}' : '${value.toInt()}%');
    final unitTxt = _couponTypeVal == 'Free' ? 'SPECIAL' :
    (_couponTypeVal == 'Flat' ? 'FLAT OFF' : 'OFF');

    setState(() {
      _coupons.insert(0, {
        'id': 'c${DateTime.now().millisecondsSinceEpoch}',
        'code': code,
        'type': _couponTypeVal.toLowerCase(),
        'value': value.toInt(),
        'note': note.isEmpty ? '' : note,
        'bigNum': bigNum,
        'unitTxt': unitTxt,
        'gradient': grad,
      });
    });
    _newCodeCtrl.clear();
    _newValueCtrl.clear();
    _newNoteCtrl.clear();
    _showToast('✦ Coupon "$code" saved!');
  }

  Widget _couponFieldLabel(String label) {
    return Text(label, style: const TextStyle(
      fontSize: 9.5, fontWeight: FontWeight.w700,
      letterSpacing: 1.6, color: kMuted,
    ));
  }

  Widget _couponInput({
    required TextEditingController controller,
    required String placeholder,
    bool isBold = false,
    TextInputType? inputType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kPanel, border: Border.all(color: kBorder, width: 1.5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        textCapitalization: isBold ? TextCapitalization.characters : TextCapitalization.none,
        style: TextStyle(
          fontSize: isBold ? 14 : 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: kText, letterSpacing: isBold ? 1.0 : 0,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: kMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        ),
      ),
    );
  }

  Widget _buildCouponEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: kShell,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 1.5, style: BorderStyle.solid),
      ),
      child: Column(children: const [
        Text('🏷️', style: TextStyle(fontSize: 40)),
        SizedBox(height: 10),
        Text('No coupons saved yet', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: kText,
        )),
        SizedBox(height: 5),
        Text('Add a coupon code above to save it here', style: TextStyle(
          fontSize: 11, color: kMuted, fontWeight: FontWeight.w500,
        )),
      ]),
    );
  }

  Widget _buildStoredCouponCard(Map<String, dynamic> coupon) {
    final gradientColors = coupon['gradient'] as List<Color>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x218050C8), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: Container(
              width: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(top: -18, right: -18,
                    child: Container(width: 56, height: 56,
                        decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle))),
                Positioned(bottom: -22, left: -10,
                    child: Container(width: 64, height: 64,
                        decoration: const BoxDecoration(color: Color(0x14FFFFFF), shape: BoxShape.circle))),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(coupon['bigNum'] as String,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(coupon['unitTxt'] as String,
                        style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Color(0xD9FFFFFF), letterSpacing: 0.64,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          SizedBox(
            width: 14,
            child: CustomPaint(painter: _PerforationPainter()),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: kShell,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                border: Border.all(color: kBorder, width: 1.5),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(coupon['code'] as String,
                        style: const TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: kText, letterSpacing: 1.28,
                        ),
                      ),
                      if ((coupon['note'] as String).isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(coupon['note'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10, color: kMuted, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: gradientColors.first.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.local_offer, size: 8, color: gradientColors.first),
                          const SizedBox(width: 3),
                          Text(
                            '${coupon['value']}${coupon['type'] == 'percent' ? '%' : '₹'} Off',
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 0.96, color: gradientColors.first,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                _PressScaleButton(
                  onTap: () => _deleteCoupon(coupon['id'] as String),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0x14FF6B7A),
                      border: Border.all(color: const Color(0x33FF6B7A), width: 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 13, color: Color(0x99FF6B7A)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  DETAIL SHEET 
  // ════════════════════════════════════════════════════════════════════
  void _showDetailSheet(Map<String, dynamic> bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(bill: bill, onDelete: (id) {
        Navigator.pop(context);
        _deleteBill(id);
      }),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  TOAST
  // ════════════════════════════════════════════════════════════════════
  Widget _buildToast() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF20F1A2D),
        border: Border.all(color: kBorder, width: 1),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20),
        ],
      ),
      child: Text(_toastMsg, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: kText,
      )),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: kPanel2, borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  ANIMATED BILL CARD
// ════════════════════════════════════════════════════════════════════
class _AnimatedBillCard extends StatefulWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Duration delay;

  const _AnimatedBillCard({
    super.key,
    required this.bill,
    required this.onTap,
    required this.onDelete,
    required this.delay,
  });

  @override
  State<_AnimatedBillCard> createState() => _AnimatedBillCardState();
}

class _AnimatedBillCardState extends State<_AnimatedBillCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _opacity;
  late Animation<Offset>   _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide   = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Cubic(0.34, 1.2, 0.64, 1)));

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
    final bill = widget.bill;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kShell,
                border: Border.all(color: kBorder, width: 1.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _pressed ? const Color(0x236B91FF) : const Color(0x40000000),
                    blurRadius: _pressed ? 24 : 12,
                    offset: Offset(0, _pressed ? 8 : 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52, height: 62,
                    decoration: BoxDecoration(
                      color: bill['catBg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1F7850B4), blurRadius: 9, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(bill['icon'] as String,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill['store'] as String,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: kText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(bill['date'] as String,
                            style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500, color: kMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: bill['catBg'] as Color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (bill['category'] as String).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                letterSpacing: 0.96, color: bill['catColor'] as Color,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(bill['note'] as String,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 10, color: kMuted, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_fmtAmount(bill['amount'] as double)}',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: kText, height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(bill['payment'] as String,
                        style: const TextStyle(
                          fontSize: 9, color: kMuted, fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0x26FF6B7A),
                            border: Border.all(color: const Color(0x4DFF6B7A), width: 1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 11, color: kRed),
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
    );
  }

  String _fmtAmount(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final parts = <String>[];
      var rem = s;
      while (rem.length > 3) {
        parts.insert(0, rem.substring(rem.length - 3));
        rem = rem.substring(0, rem.length - 3);
      }
      parts.insert(0, rem);
      return parts.join(',');
    }
    return v.toStringAsFixed(0);
  }
}

// ════════════════════════════════════════════════════════════════════
//  DETAIL SHEET 
// ════════════════════════════════════════════════════════════════════
class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> bill;
  final void Function(String id) onDelete;

  const _DetailSheet({required this.bill, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(top: BorderSide(color: kBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Color(0x2E6B91FF), blurRadius: 60, offset: Offset(0, -20)),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 700),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: kPanel2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 68, height: 80,
                  decoration: BoxDecoration(
                    color: bill['catBg'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x4DC4A0C8), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x247850B4), blurRadius: 14, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(bill['icon'] as String, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill['store'] as String,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
                    const SizedBox(height: 4),
                    Text(bill['date'] as String,
                        style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w500)),
                  ],
                )),
                Text(
                  '₹${_fmtAmount(bill['amount'] as double)}',
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w600, color: kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1F8D7DFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x388D7DFF), width: 1),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('✦', style: TextStyle(fontSize: 8, color: kAccent2)),
                SizedBox(width: 4),
                Text('AI Scanned', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: kAccent2,
                )),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 18, bottom: 10),
              child: Text('BILL DETAILS', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 2.4, color: kMuted,
              )),
            ),
            _detailRow('Category', (bill['category'] as String).toUpperCase()),
            _detailRow('Payment',  bill['payment'] as String),
            _detailRow('Amount',   '₹${_fmtAmount(bill['amount'] as double)}'),
            _detailRow('Date',     bill['date'] as String),
            const Padding(
              padding: EdgeInsets.only(top: 18, bottom: 10),
              child: Text('NOTES', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 2.4, color: kMuted,
              )),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x148D7DFF), Color(0x0DFF8EC7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0x238D7DFF), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(bill['note'] as String, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: kText, height: 1.6,
              )),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _detailBtn(context, 'Share', false)),
              const SizedBox(width: 9),
              Expanded(child: _detailBtn(context, 'Delete Bill', true,
                  onTap: () => onDelete(bill['id'] as String))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: kPanel, border: Border.all(color: kBorder, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
        ],
      ),
    );
  }

  Widget _detailBtn(BuildContext ctx, String label, bool isPrimary, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(ctx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: isPrimary ? const LinearGradient(
            colors: [Color(0xCCFF6B7A), Color(0xCCFF8EC7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ) : null,
          color: isPrimary ? null : kPanel,
          border: Border.all(color: kBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary ? const [
            BoxShadow(color: Color(0x47FF6B7A), blurRadius: 20, offset: Offset(0, 6)),
          ] : null,
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isPrimary ? Colors.white : kText,
        ))),
      ),
    );
  }

  String _fmtAmount(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final parts = <String>[];
      var rem = s;
      while (rem.length > 3) {
        parts.insert(0, rem.substring(rem.length - 3));
        rem = rem.substring(0, rem.length - 3);
      }
      parts.insert(0, rem);
      return parts.join(',');
    }
    return v.toStringAsFixed(0);
  }
}

// ════════════════════════════════════════════════════════════════════
//  MESH BACKGROUND
// ════════════════════════════════════════════════════════════════════
class _MeshBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _MeshPainter()),
    );
  }
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = kBg,
    );
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.8),
        radius: 1.0,
        colors: [const Color(0x2E6B91FF), Colors.transparent],
        stops: const [0.0, 0.6],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);

    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.6, 0.6),
        radius: 0.9,
        colors: [const Color(0x1F8D7DFF), Colors.transparent],
        stops: const [0.0, 0.55],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════════
//  PRESS SCALE BUTTON
// ════════════════════════════════════════════════════════════════════
class _PressScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScaleButton({required this.child, required this.onTap});

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PERFORATED DIVIDER
// ════════════════════════════════════════════════════════════════════
class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final notchPaint = Paint()
      ..color = kBg2
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, 0), 8, notchPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height), 8, notchPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 8, notchPaint);

    final dashPaint = Paint()
      ..color = kBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashH = 5.0;
    const dashGap = 5.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, min(y + dashH, size.height)),
        dashPaint,
      );
      y += dashH + dashGap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}