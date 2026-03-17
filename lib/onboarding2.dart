import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:myapp/app_routes.dart';
import 'package:myapp/profile.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Screen2(),
  ));
}

class Screen2 extends StatefulWidget {
  const Screen2({super.key});
  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;

  final Set<String> selected = {'sport', 'casual'};

  final List<Map<String, String>> styles = [
    {
      'key': 'party',
      'name': 'Party Wear',
      'sub': 'Gowns · Cocktail · Formal',
      'img':
      'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&q=85&fit=crop&crop=top',
    },
    {
      'key': 'sport',
      'name': 'Sport Wear',
      'sub': 'Active · Athletic · Gym',
      'img':
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=85&fit=crop&crop=top',
    },
    {
      'key': 'casual',
      'name': 'Casual Wear',
      'sub': 'Everyday · Weekend · Relaxed',
      'img':
      'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=400&q=85&fit=crop&crop=top',
    },
    {
      'key': 'ethnic',
      'name': 'Ethnic Wear',
      'sub': 'Kurta · Saree · Festive',
      'img':
      'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&q=85&fit=crop&crop=top',
    },
    {
      'key': 'street',
      'name': 'Street Wear',
      'sub': 'Urban · Hype · Oversized',
      'img':
      'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=400&q=85&fit=crop&crop=top',
    },
    {
      'key': 'office',
      'name': 'Office Wear',
      'sub': 'Business · Smart · Tailored',
      'img':
      'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=400&q=85&fit=crop&crop=top',
    },
  ];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void toggleCard(String key) {
    setState(() {
      if (selected.contains(key)) {
        selected.remove(key);
      } else {
        selected.add(key);
      }
    });
  }

  bool get _isValidSelection =>
      selected.length >= 2 && selected.length <= 3;

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _staggered(Widget child,
      {required double start, required double end}) {
    final anim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(start, end, curve: const Cubic(0.22, 1.0, 0.36, 1.0)),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position:
        Tween<Offset>(begin: const Offset(0, 0.055), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2D),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          Positioned.fill(
            child:
            IgnorePointer(child: CustomPaint(painter: _GrainPainter())),
          ),
          SafeArea(
            child: Column(
              children: [
                const _StatusBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _staggered(_Header(pulseCtrl: _pulseCtrl),
                            start: 0.00, end: 0.58),
                        _staggered(_TabBarWidget(),
                            start: 0.08, end: 0.66),
                        const SizedBox(height: 28),
                        _staggered(const _SectionHead(),
                            start: 0.14, end: 0.72),
                        const SizedBox(height: 8),
                        _staggered(
                            _SelectionBadge(count: selected.length),
                            start: 0.11,
                            end: 0.69),
                        const SizedBox(height: 12),
                        _staggered(const _HelperText(),
                            start: 0.18, end: 0.76),
                        const SizedBox(height: 20),
                        _staggered(
                          _StyleGrid(
                            styles: styles,
                            selected: selected,
                            hasSelection: selected.isNotEmpty,
                            onToggle: toggleCard,
                          ),
                          start: 0.23,
                          end: 0.81,
                        ),
                        const SizedBox(height: 28),
                        _staggered(_CtaSection(selected: selected),
                            start: 0.37, end: 0.95),
                        const SizedBox(height: 22),
                        _staggered(const _ProgressRow(),
                            start: 0.44, end: 1.00),
                      ],
                    ),
                  ),
                ),
                const _HomeIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();
    for (int i = 0; i < 6000; i++) {
      paint.color = rng.nextBool()
          ? const Color(0x06FFFFFF)
          : const Color(0x07000000);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width,
            rng.nextDouble() * size.height),
        0.55,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void r(Offset c, double rx, double ry, Color color) {
      final rect =
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    r(Offset(w * .5, h * .32), w * .46, h * .30, const Color(0x0FF5F7FF));
    r(Offset(w * -.14, h * -.08), w * .90, h * .68,
        const Color(0x476B91FF));
    r(Offset(w * 1.14, h * .32), w * .62, h * .52,
        const Color(0x388D7DFF));
    r(Offset(w * 1.18, h * 1.12), w * .82, h * .68,
        const Color(0x2E04D7C8));
    r(Offset(w * .5, h * .92), w * .72, h * .52, const Color(0x24FF8EC7));
    r(Offset(w * -.16, h * .72), w * .64, h * .74,
        const Color(0xCC0F1A2D));
    r(Offset(w * .04, h * 1.0), w * .52, h * .46, const Color(0x1F6B91FF));
    r(Offset(w * 1.02, h * .02), w * .44, h * .36,
        const Color(0x1404D7C8));
    r(Offset(w * .90, h * .58), w * .40, h * .34, const Color(0x0FFFD86E));
    r(Offset(w * .5, h * 0), w * .50, h * .30, const Color(0x298D7DFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Status Bar
// ─────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 14, 32, 0),
      child: SizedBox(
        height: 42,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('9:41',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF5F7FF),
                  letterSpacing: -0.013,
                )),
            Row(children: [
              _SignalIcon(),
              const SizedBox(width: 7),
              _WifiIcon(),
              const SizedBox(width: 7),
              const _BatteryWidget(),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SignalIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SBar(h: 5, op: 1.0),
          const SizedBox(width: 1),
          _SBar(h: 7.5, op: 1.0),
          const SizedBox(width: 1),
          _SBar(h: 10, op: 1.0),
          const SizedBox(width: 1),
          _SBar(h: 12, op: 0.28),
        ],
      ),
    );
  }
}

class _SBar extends StatelessWidget {
  final double h, op;
  const _SBar({required this.h, required this.op});
  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FF).withValues(alpha: op),
      borderRadius: BorderRadius.circular(0.8),
    ),
  );
}

class _WifiIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 16, height: 12, child: CustomPaint(painter: _WifiP()));
}

class _WifiP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFFF5F7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .0625, s.height * .375)
          ..quadraticBezierTo(
              s.width * .5, 0, s.width * .9375, s.height * .375),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .2, s.height * .567)
          ..quadraticBezierTo(
              s.width * .5, s.height * .25, s.width * .8, s.height * .567),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .344, s.height * .758)
          ..quadraticBezierTo(s.width * .5, s.height * .6, s.width * .656,
              s.height * .758),
        p);
    canvas.drawCircle(Offset(s.width * .5, s.height * .933), 0.9,
        Paint()..color = const Color(0xFFF5F7FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BatteryWidget extends StatelessWidget {
  const _BatteryWidget();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 23,
        height: 11.5,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF5F7FF), width: 1.5),
          borderRadius: BorderRadius.circular(3.5),
        ),
        padding: const EdgeInsets.all(1.5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.76,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
      Container(
        width: 2,
        height: 5.5,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius:
          const BorderRadius.horizontal(right: Radius.circular(1)),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _Header({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(9, 5, 13, 5),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1F6B91FF),
                    blurRadius: 32,
                    offset: Offset(0, 8)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (context, child) {
                  final t = pulseCtrl.value;
                  return Opacity(
                    opacity: 1.0 - t * 0.5,
                    child: Transform.scale(
                      scale: 1.0 - t * 0.25,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B91FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(
                                  107, 145, 255, 0.55 - t * 0.40),
                              blurRadius: 8.0 - t * 5.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 7),
              const Text('AHVI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B91FF),
                    letterSpacing: 1.32,
                  )),
            ]),
          ),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w400,
                color: Color(0xFFF5F7FF),
                letterSpacing: -0.936,
                height: 1.06,
              ),
              children: [
                TextSpan(text: 'Your '),
                TextSpan(
                  text: 'Style',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF6B91FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tell us about your style preferences.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: Color(0xB8E6EBFF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab Bar (decorative)
// ─────────────────────────────────────────────────────────────

class _TabBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A6B91FF),
              blurRadius: 32,
              offset: Offset(0, 8)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          top: 0,
          left: (MediaQuery.of(context).size.width - 48 - 8) / 3 + 4,
          child: Container(
            width: (MediaQuery.of(context).size.width - 48 - 8) / 3,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x296B91FF),
                    blurRadius: 18,
                    offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
        Row(children: [
          _Tab(label: 'Basics', isActive: false),
          _Tab(label: 'Style', isActive: true),
          _Tab(label: 'All Boards', isActive: false),
        ]),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  const _Tab({required this.label, required this.isActive});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFFF5F7FF)
                  : const Color(0xB8E6EBFF),
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Head
// ─────────────────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  const _SectionHead();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text('Style Preferences',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xB8E6EBFF),
            letterSpacing: 1.32,
          )),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0x476B91FF), Colors.transparent]),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Selection Badge
// ─────────────────────────────────────────────────────────────

class _SelectionBadge extends StatefulWidget {
  final int count;
  const _SelectionBadge({required this.count});
  @override
  State<_SelectionBadge> createState() => _SelectionBadgeState();
}

class _SelectionBadgeState extends State<_SelectionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 270));
    _scale = Tween<double>(begin: 1.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_SelectionBadge old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1F6B91FF),
              blurRadius: 32,
              offset: Offset(0, 8)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 11,
            height: 11,
            child: CustomPaint(painter: _CheckCircleP())),
        const SizedBox(width: 6),
        ScaleTransition(
          scale: _scale,
          child: Text('${widget.count}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B91FF),
              )),
        ),
        const SizedBox(width: 4),
        const Text('selected · choose 2–3',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xB8E6EBFF),
              fontWeight: FontWeight.w400,
            )),
      ]),
    );
  }
}

class _CheckCircleP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFF6B91FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), 4.25, p);
    canvas.drawPath(
        Path()
          ..moveTo(s.width * .318, s.height * .5)
          ..lineTo(s.width * .5, s.height * .682)
          ..lineTo(s.width * .682, s.height * .364),
        p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Helper Text
// ─────────────────────────────────────────────────────────────

class _HelperText extends StatelessWidget {
  const _HelperText();
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Color(0xB8E6EBFF),
          height: 1.5,
        ),
        children: [
          TextSpan(
              text:
              'Pick styles you wear most often. AHVI adapts to your '),
          TextSpan(
            text: 'actual wardrobe',
            style: TextStyle(
                color: Color(0xFFFFD86E),
                fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '.'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Style Grid
// ─────────────────────────────────────────────────────────────

class _StyleGrid extends StatelessWidget {
  final List<Map<String, String>> styles;
  final Set<String> selected;
  final bool hasSelection;
  final void Function(String) onToggle;

  const _StyleGrid({
    required this.styles,
    required this.selected,
    required this.hasSelection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 3 / 4,
      ),
      itemCount: styles.length,
      itemBuilder: (context, i) {
        final s = styles[i];
        final key = s['key']!;
        final isSel = selected.contains(key);
        return _StyleCard(
          name: s['name']!,
          sub: s['sub']!,
          imgUrl: s['img']!,
          isSelected: isSel,
          isDimmed: hasSelection && !isSel,
          onTap: () => onToggle(key),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Style Card
//
// THE FIX — what was wrong in all previous versions:
//
//   _updateScaleAnim() was called on every didUpdateWidget().
//   Each call did:  TweenSequence([...]).animate(CurvedAnimation(parent: _ctrl))
//
//   CurvedAnimation(parent: _ctrl) registers a listener on _ctrl.
//   The OLD CurvedAnimation is never disposed → its listener stays attached.
//   After 2 taps: 2 listeners. After 3: 3. Flutter asserts on the stale
//   listener when the controller tries to notify all of them.
//
// THE CORRECT PATTERN:
//   Use animateTo() directly on the controller with an inline curve argument.
//   animateTo() creates NO persistent CurvedAnimation object — zero leaks.
//   Read controller.value in AnimatedBuilder and map it to scale manually.
// ─────────────────────────────────────────────────────────────

class _StyleCard extends StatefulWidget {
  final String name;
  final String sub;
  final String imgUrl;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _StyleCard({
    required this.name,
    required this.sub,
    required this.imgUrl,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  // controller.value is the raw animation value 0..1
  // We map it to a scale ourselves in AnimatedBuilder — no CurvedAnimation stored.
  late final AnimationController _ctrl;

  // Maps controller value → visual scale
  // 0.0 = 0.97  (press floor, never rests here)
  // 0.5 = 1.0   (deselected rest)
  // 0.8 = 1.018 (selected rest)
  // 1.0 = 1.028 (select overshoot peak)
  double _valueToScale(double v) {
    if (v <= 0.5) return 0.97 + v * 0.06;          // 0.97 → 1.0
    if (v <= 0.8) return 1.0 + (v - 0.5) * 0.06;   // 1.0  → 1.018
    return 1.018 + (v - 0.8) * 0.05;               // 1.018 → 1.028
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 268),
      value: widget.isSelected ? 0.8 : 0.5, // correct resting value on init
    );
  }

  Future<void> _runSelectBounce() async {
    // dip slightly, overshoot, settle at selected rest (0.8)
    if (!mounted) return;
    await _ctrl.animateTo(0.35,
        duration: const Duration(milliseconds: 60), curve: Curves.easeIn);
    if (!mounted) return;
    await _ctrl.animateTo(1.0,
        duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
    if (!mounted) return;
    await _ctrl.animateTo(0.8,
        duration: const Duration(milliseconds: 80), curve: Curves.easeInOut);
  }

  Future<void> _runDeselectBounce() async {
    // slight dip, return to deselected rest (0.5)
    if (!mounted) return;
    await _ctrl.animateTo(0.45,
        duration: const Duration(milliseconds: 60), curve: Curves.easeIn);
    if (!mounted) return;
    await _ctrl.animateTo(0.5,
        duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_StyleCard old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _runSelectBounce();
      } else {
        _runDeselectBounce();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedOpacity(
          opacity: widget.isDimmed ? 0.46 : 1.0,
          duration: const Duration(milliseconds: 220),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final scale =
              _pressed ? 0.97 : _valueToScale(_ctrl.value);
              return Transform.scale(scale: scale, child: child);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: const Cubic(0.34, 1.3, 0.64, 1.0),
              decoration: BoxDecoration(
                color: const Color(0xFF192131),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xBF6B91FF)
                      : const Color(0x1FFFFFFF),
                  width: 1.5,
                ),
                boxShadow: widget.isSelected
                    ? const [
                  BoxShadow(
                      color: Color(0x476B91FF),
                      blurRadius: 44,
                      offset: Offset(0, 10)),
                  BoxShadow(
                      color: Color(0x246B91FF),
                      blurRadius: 12,
                      offset: Offset(0, 2)),
                ]
                    : const [
                  BoxShadow(
                      color: Color(0x470A1432),
                      blurRadius: 18,
                      offset: Offset(0, 2)),
                  BoxShadow(
                      color: Color(0x240A1432),
                      blurRadius: 4,
                      offset: Offset(0, 1)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.5),
                child: Stack(fit: StackFit.expand, children: [
                  // Photo + hover zoom
                  AnimatedScale(
                    scale: _hovered ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 580),
                    curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                    child: Image.network(
                      widget.imgUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: const Color(0xFF192131)),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.36, 0.62, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0x8508111F),
                            Color(0xEB08111F),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glass sheen — always in tree, animated opacity
                  AnimatedOpacity(
                    opacity: widget.isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment(-0.6, -0.8),
                          end: Alignment(0.6, 0.8),
                          stops: [0.0, 0.46, 1.0],
                          colors: [
                            Color(0x1FFFFFFF),
                            Color(0x05FFFFFF),
                            Color(0x1A6B91FF),
                          ],
                        ),
                        border:
                        Border.all(color: const Color(0x29FFFFFF)),
                      ),
                    ),
                  ),
                  // Accent top bar — always in tree, animated opacity
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: AnimatedOpacity(
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        height: 2.5,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xCC8D7DFF),
                              Color(0xFF6B91FF),
                              Color(0xCC04D7C8),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.28, 0.50, 0.72, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Check icon
                  Positioned(
                    top: 10, right: 10,
                    child: AnimatedOpacity(
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedScale(
                        scale: widget.isSelected ? 1.0 : 0.38,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0x426B91FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0x4DFFFFFF)),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x666B91FF),
                                  blurRadius: 14,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(12, 12),
                              painter: _CheckmarkP(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Card label
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF5F7FF),
                                letterSpacing: 0.135,
                                height: 1.2,
                              )),
                          const SizedBox(height: 2),
                          Text(widget.sub,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xB8E6EBFF),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2625,
                              )),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckmarkP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .167, s.height * .5)
        ..lineTo(s.width * .417, s.height * .75)
        ..lineTo(s.width * .833, s.height * .25),
      Paint()
        ..color = const Color(0xFFF5F7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// CTA Section
//
// THE FIX:
//   Previous versions stored TweenSequence animations as fields and
//   called .animate(CurvedAnimation(parent: ctrl)) multiple times,
//   leaking listeners on every tap.
//
//   Now: controller value is a plain double 0..1.
//   We lerp scale from it directly in AnimatedBuilder.
//   animateTo() with an inline curve creates zero persistent objects.
// ─────────────────────────────────────────────────────────────

class _CtaSection extends StatefulWidget {
  final Set<String> selected;
  const _CtaSection({required this.selected});
  @override
  State<_CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<_CtaSection>
    with TickerProviderStateMixin {
  late final AnimationController _backCtrl;
  late final AnimationController _continueCtrl;

  bool _backBusy = false;
  bool _continueBusy = false;

  bool get _isValidSelection =>
      widget.selected.length >= 2 && widget.selected.length <= 3;

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    // value=0 → rest; value=1 → fully squeezed
    _backCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
        value: 0);
    _continueCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
        value: 0);
  }

  @override
  void dispose() {
    _backCtrl.dispose();
    _continueCtrl.dispose();
    super.dispose();
  }

  Future<void> _squeezeBack() async {
    if (_backBusy) return;
    _backBusy = true;
    // squeeze in
    await _backCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
    if (!mounted) { _backBusy = false; return; }
    // spring back
    await _backCtrl.animateTo(0.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.elasticOut);
    _backBusy = false;
  }

  Future<void> _squeezeContinue() async {
    if (_continueBusy) return;
    _continueBusy = true;
    await _continueCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
    if (!mounted) { _continueBusy = false; return; }
    await _continueCtrl.animateTo(0.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.elasticOut);
    _continueBusy = false;
  }

  void _onBackTap() {
    _squeezeBack();
    Future.delayed(const Duration(milliseconds: 180),
            () { if (mounted) Navigator.of(context).maybePop(); });
  }

  void _onContinueTap() {
    if (!_isValidSelection) {
      _showValidationError('Please select 2-3 styles to continue.');
      return;
    }
    _squeezeContinue();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        context.read<ProfileController>().updateStyles(widget.selected);
        Navigator.of(context).pushNamed(AppRoutes.onboarding3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // ── Back button ────────────────────────────────────
      GestureDetector(
        onTap: _onBackTap,
        child: AnimatedBuilder(
          animation: _backCtrl,
          builder: (_, child) {
            final v = _backCtrl.value;
            return Transform.translate(
              offset: Offset(-v * 3.0, 0),
              child: Transform.scale(
                scale: 1.0 - v * 0.09, // 1.0 → 0.91
                child: child,
              ),
            );
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0x1FFFFFFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x6608111F),
                    blurRadius: 26,
                    offset: Offset(0, 8)),
                BoxShadow(
                    color: Color(0x1AFFFFFF),
                    blurRadius: 0,
                    offset: Offset(0, 1)),
              ],
            ),
            child: Center(
              child: CustomPaint(
                  size: const Size(18, 18), painter: _BackArrowP()),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),

      // ── Continue button ────────────────────────────────
      Expanded(
        child: GestureDetector(
          onTap: _onContinueTap,
          child: AnimatedBuilder(
            animation: _continueCtrl,
            builder: (_, child) {
              return Transform.scale(
                scale: 1.0 - _continueCtrl.value * 0.028, // 1.0 → 0.972
                child: child,
              );
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B91FF), Color(0xFF8D7DFF)],
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x616B91FF),
                      blurRadius: 34,
                      offset: Offset(0, 10)),
                  BoxShadow(
                      color: Color(0x336B91FF),
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                  BoxShadow(
                      color: Color(0x29FFFFFF),
                      blurRadius: 0,
                      offset: Offset(0, 1)),
                ],
              ),
              child: Stack(children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: const LinearGradient(
                        begin: Alignment(-0.8, -1.0),
                        end: Alignment(0.2, 0.5),
                        colors: [Color(0x1FFFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10131B),
                            letterSpacing: 0.3,
                          )),
                      const SizedBox(width: 8),
                      CustomPaint(
                          size: const Size(16, 16), painter: _ArrowP()),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _BackArrowP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .611, s.height * .222)
        ..lineTo(s.width * .333, s.height * .5)
        ..lineTo(s.width * .611, s.height * .778),
      Paint()
        ..color = const Color(0xB8E6EBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ArrowP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xCC10131B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(Offset(s.width * .25, s.height * .5),
        Offset(s.width * .75, s.height * .5), p);
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .5625, s.height * .3125)
        ..lineTo(s.width * .75, s.height * .5)
        ..lineTo(s.width * .5625, s.height * .6875),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// Progress Row
// ─────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  const _ProgressRow();
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: const Color(0x806B91FF),
              borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Container(
        width: 24,
        height: 6,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6B91FF), Color(0xFF8D7DFF)]),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x666B91FF),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
      ),
      const SizedBox(width: 8),
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: const Color(0x386B91FF),
              borderRadius: BorderRadius.circular(3))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Home Indicator
// ─────────────────────────────────────────────────────────────

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0x2EF5F7FF),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}
