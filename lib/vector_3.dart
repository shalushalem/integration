import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────

class AppColors {
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
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.accent2,
    ),
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Stylist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const OnboardingScreen(),
    );
  }
}

// ─── Onboarding Screen ────────────────────────────────────────────────────────

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8E0F5),
              Color(0xFFD8D0F0),
              Color(0xFFCEC8EE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _FashionIllustrationCard(size: size),
                const SizedBox(height: 28),
                const _PageIndicator(total: 3, current: 2),
                const SizedBox(height: 32),
                const _HeadlineText(),
                const SizedBox(height: 12),
                const _SubtitleText(),
                const Spacer(flex: 3),
                const _GoogleButton(),
                const SizedBox(height: 12),
                const _AppleButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _FashionIllustrationCard extends StatelessWidget {
  final Size size;
  const _FashionIllustrationCard({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 0.55,
      height: size.width * 0.72,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEE8),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent2.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(
          'https://placeholder.com',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const _FallbackFashionIllustration(),
        ),
      ),
    );
  }
}

class _FallbackFashionIllustration extends StatelessWidget {
  const _FallbackFashionIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 80,
            color: AppColors.accent2.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Fashion Model',
            style: TextStyle(
              color: AppColors.accent2.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int total;
  final int current;

  const _PageIndicator({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF5A5A7A) : Colors.transparent,
            border: isActive
                ? null
                : Border.all(color: const Color(0xFF9090A8), width: 1.5),
          ),
        );
      }),
    );
  }
}

class _HeadlineText extends StatelessWidget {
  const _HeadlineText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Confidence,\nvisualized.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
        height: 1.2,
      ),
    );
  }
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Try on styles virtually before\nstepping out.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        color: Color(0xFF6B6B8A),
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final segments = [
      (0.0, 1.57, const Color(0xFF4285F4)),
      (1.57, 3.14, const Color(0xFF34A853)),
      (3.14, 4.71, const Color(0xFFFBBC05)),
      (4.71, 6.28, const Color(0xFFEA4335)),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          seg.$1,
          seg.$2 - seg.$1,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    canvas.drawCircle(center, radius * 0.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleButton extends StatelessWidget {
  const _AppleButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Continue with apple',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}