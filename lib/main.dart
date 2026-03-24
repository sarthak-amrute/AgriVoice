import 'dart:math';
// ignore: unused_import
import 'package:agrivoice/app_translations.dart';
import 'package:agrivoice/main_dashboard_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageRoot(
      builder: (context, lang) => MaterialApp(
        title: 'Agri Voice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          fontFamily: 'SpaceGrotesk',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.45).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try to get language provider, fallback to English if not available
    String t(String key) {
      try {
        return LanguageProvider.of(context).t(key);
      } catch (_) {
        return AppTranslations.get(key, AppLanguage.english);
      }
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoSection(t),
                    const SizedBox(height: 96),
                    _buildLoadingSection(t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(String Function(String) t) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 60, spreadRadius: 20,
                  ),
                ],
              ),
            ),
            Container(
              width: 128, height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24, offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF2F7F34).withOpacity(0.2), width: 1),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomPaint(
                    painter: _PlantIconPainter(),
                    size: const Size(96, 96),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(t('app_name'),
            style: const TextStyle(
                color: Colors.white, fontSize: 36,
                fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(t('app_tagline'),
            style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLoadingSection(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Text(t('loading'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.5)),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity, height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(t('version'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PlantIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D5E1E)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF2D5E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawLine(
      Offset(cx, cy + size.height * 0.28),
      Offset(cx, cy - size.height * 0.10),
      strokePaint,
    );
    _drawLeaf(canvas, paint,
        base: Offset(cx, cy - size.height * 0.08),
        tip: Offset(cx, cy - size.height * 0.42),
        width: size.width * 0.22);
    _drawLeaf(canvas, paint,
        base: Offset(cx - size.width * 0.04, cy - size.height * 0.02),
        tip: Offset(cx - size.width * 0.32, cy - size.height * 0.30),
        width: size.width * 0.16);
    _drawLeaf(canvas, paint,
        base: Offset(cx + size.width * 0.04, cy - size.height * 0.02),
        tip: Offset(cx + size.width * 0.32, cy - size.height * 0.30),
        width: size.width * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.30),
          width: size.width * 0.55, height: size.height * 0.045,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawLeaf(Canvas canvas, Paint paint,
      {required Offset base, required Offset tip, required double width}) {
    final ax = tip.dx - base.dx;
    final ay = tip.dy - base.dy;
    final len = sqrt(ax * ax + ay * ay);
    if (len == 0) return;
    final perpX = (-ay / len) * width * 0.5;
    final perpY = (ax / len) * width * 0.5;
    final midX = (base.dx + tip.dx) / 2;
    final midY = (base.dy + tip.dy) / 2;
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(midX + perpX, midY + perpY, tip.dx, tip.dy)
      ..quadraticBezierTo(midX - perpX, midY - perpY, base.dx, base.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}