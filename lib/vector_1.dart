import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// COLORS & THEME
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF08111F);
  static const Color bg2 = Color(0xFF0F1A2D);
  static const Color panel = Color(0x14FFFFFF);
  static const Color panel2 = Color(0x1FFFFFFF);
  static const Color card = Color(0x14FFFFFF);
  static const Color cardBorder = Color(0x1FFFFFFF);
  static const Color text = Color(0xFFF5F7FF);
  static const Color muted = Color(0xB8E6EBFF);
  static const Color tileText = Color(0xFF10131B);
  static const Color accent = Color(0xFF6B91FF);
  static const Color accent2 = Color(0xFF8D7DFF);
  static const Color accent3 = Color(0xFF04D7C8);
  static const Color accent4 = Color(0xFFFF8EC7);
  static const Color accent5 = Color(0xFFFFD86E);
  static const Color phoneShell = Color(0xFF192131);
  static const Color phoneShell2 = Color(0xFF111723);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF2EFF8), Color(0xFFDDD4F0)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFECE8F5),
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent2,
      secondary: AppColors.accent,
      surface: Color(0xFFECE8F5),
    ),
  );
}

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WardrobeApp());
}

class WardrobeApp extends StatelessWidget {
  const WardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wardrobe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// ONBOARDING SCREEN
// ─────────────────────────────────────────────

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: const WardrobeIllustration(),
                  ),
                ),
              ),
              const PageIndicator(count: 3, current: 0),
              const SizedBox(height: 36),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'Your wardrobe,\nreimagined.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Digitize your style and unlock\nsmarter organization.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF888899),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OnboardingButton(
                      label: 'SKIP',
                      filled: false,
                      onTap: () {},
                    ),
                    OnboardingButton(
                      label: 'NEXT',
                      filled: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────

class PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const PageIndicator({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF2D2D2D) : Colors.transparent,
            border: isActive
                ? null
                : Border.all(color: const Color(0xFFAAAAAA), width: 1.5),
          ),
        );
      }),
    );
  }
}

class OnboardingButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const OnboardingButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF1A1A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: filled
              ? null
              : Border.all(color: const Color(0xFFBBBBBB), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: filled ? Colors.white : const Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WARDROBE ILLUSTRATION
// ─────────────────────────────────────────────

class WardrobeIllustration extends StatelessWidget {
  const WardrobeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 180,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D0E8),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: const Color(0xFFBFB5D5), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClothingItem(
                      color: const Color(0xFFE8A0B0),
                      width: 32,
                      height: 70,
                      shape: ClothingShape.dress,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ClothingItem(
                          color: const Color(0xFFB0BED8),
                          width: 50,
                          height: 55,
                          shape: ClothingShape.shirt,
                        ),
                        const SizedBox(height: 6),
                        _ClothingItem(
                          color: const Color(0xFF9090A8),
                          width: 50,
                          height: 55,
                          shape: ClothingShape.jacket,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _ClothingItem(
                        color: const Color(0xFFB8C8E0),
                        width: 28,
                        height: 80,
                        shape: ClothingShape.pants,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            bottom: 20,
            child: _PersonFigure(),
          ),
        ],
      ),
    );
  }
}

enum ClothingShape { dress, shirt, jacket, pants }

class _ClothingItem extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final ClothingShape shape;

  const _ClothingItem({
    required this.color,
    required this.width,
    required this.height,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _ClothingPainter(color: color, shape: shape),
    );
  }
}

class _ClothingPainter extends CustomPainter {
  final Color color;
  final ClothingShape shape;

  const _ClothingPainter({required this.color, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    switch (shape) {
      case ClothingShape.dress:
        path.moveTo(size.width * 0.2, 0);
        path.lineTo(size.width * 0.8, 0);
        path.lineTo(size.width * 0.9, size.height * 0.3);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.lineTo(size.width * 0.1, size.height * 0.3);
        path.close();
        break;
      case ClothingShape.shirt:
        path.moveTo(size.width * 0.1, 0);
        path.lineTo(size.width * 0.9, 0);
        path.lineTo(size.width, size.height * 0.2);
        path.lineTo(size.width * 0.85, size.height);
        path.lineTo(size.width * 0.15, size.height);
        path.lineTo(0, size.height * 0.2);
        path.close();
        break;
      case ClothingShape.jacket:
        path.moveTo(size.width * 0.05, 0);
        path.lineTo(size.width * 0.95, 0);
        path.lineTo(size.width, size.height * 0.15);
        path.lineTo(size.width * 0.9, size.height);
        path.lineTo(size.width * 0.1, size.height);
        path.lineTo(0, size.height * 0.15);
        path.close();
        break;
      case ClothingShape.pants:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width * 0.9, size.height * 0.5);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width * 0.55, size.height);
        path.lineTo(size.width * 0.5, size.height * 0.55);
        path.lineTo(size.width * 0.45, size.height);
        path.lineTo(0, size.height);
        path.lineTo(size.width * 0.1, size.height * 0.5);
        path.close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PersonFigure extends StatelessWidget {
  const _PersonFigure();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 150,
      child: CustomPaint(
        painter: _PersonPainter(),
      ),
    );
  }
}

class _PersonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = const Color(0xFFD4A899);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.1), 14, paint);

    paint.color = const Color(0xFFB8A8C8);
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.2, size.height * 0.22);
    bodyPath.lineTo(size.width * 0.8, size.height * 0.22);
    bodyPath.lineTo(size.width * 0.85, size.height * 0.6);
    bodyPath.lineTo(size.width * 0.15, size.height * 0.6);
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    paint.color = const Color(0xFFB8A8C8).withValues(alpha: 0.7);
    final skirtPath = Path();
    skirtPath.moveTo(size.width * 0.15, size.height * 0.55);
    skirtPath.lineTo(size.width * 0.85, size.height * 0.55);
    skirtPath.lineTo(size.width, size.height);
    skirtPath.lineTo(0, size.height);
    skirtPath.close();
    canvas.drawPath(skirtPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}