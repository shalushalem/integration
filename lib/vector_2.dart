import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Style App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const OnboardingScreen(),
    );
  }
}

// ─────────────────────────────────────────
// THEME
// ─────────────────────────────────────────

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

  static const LinearGradient lightBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0EDF8),
      Color(0xFFE2DCF4),
      Color(0xFFD0CAEC),
    ],
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    fontFamily: 'SF Pro Display',
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
        height: 1.2,
        letterSpacing: -0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF6B6B8A),
        height: 1.6,
      ),
    ),
  );
}

// ─────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.lightBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _IllustrationArea(size: size),
                const Spacer(flex: 1),
                const _PageIndicator(currentIndex: 1, total: 3),
                const SizedBox(height: 32),
                const _HeadlineText(),
                const SizedBox(height: 14),
                const _SubtitleText(),
                const Spacer(flex: 3),
                const _BottomActions(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────

class _IllustrationArea extends StatelessWidget {
  final Size size;
  const _IllustrationArea({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height * 0.32,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size.width * 0.55,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFCFC8E8).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          const _CharacterFigure(),
          Positioned(
            top: 10,
            right: size.width * 0.04,
            child: const _ClothingItem(
              icon: Icons.checkroom,
              color: Color(0xFFB5A8D0),
              size: 56,
            ),
          ),
          Positioned(
            top: 60,
            right: -size.width * 0.02,
            child: const _ClothingItem(
              icon: Icons.shopping_bag_outlined,
              color: Color(0xFFBDB5D5),
              size: 44,
            ),
          ),
          Positioned(
            bottom: 20,
            right: size.width * 0.01,
            child: const _ClothingItem(
              icon: Icons.dry_cleaning_outlined,
              color: Color(0xFFA89EC4),
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterFigure extends StatelessWidget {
  const _CharacterFigure();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFF2A1F3D),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Color(0xFFF5E6D3), size: 28),
        ),
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFB8AACF),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Container(
          width: 90,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFD4C8E8),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _ClothingItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _ClothingItem({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _PageIndicator({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF1A1A2E).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
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
    return Text(
      'Style, intelligently\ncurated.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Complete looks from your own\nwardrobe — perfectly matched\nto the moment.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SkipButton()),
        SizedBox(width: 12),
        Expanded(child: _NextButton()),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: const Text(
        'SKIP',
        style: TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: AppColors.text,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: const Text(
        'NEXT',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}