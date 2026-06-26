import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );
    _progressCtrl.forward();
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final user = FirebaseAuth.instance.currentUser;
        Navigator.pushReplacementNamed(
          context,
          user != null ? '/home' : '/welcome',
        );
      }
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            // ── Soft decorative shapes ───────────────────────────────
            Positioned(
              top: -60,
              right: -60,
              child: _ring(220, 30),
            ),
            Positioned(
              bottom: -90,
              left: -70,
              child: _circle(240, Colors.white.withValues(alpha: 0.05)),
            ),
            Positioned(
              top: 90,
              left: -40,
              child: _circle(120, Colors.white.withValues(alpha: 0.04)),
            ),

            // ── Brand lockup ─────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 232,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 34,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ).popIn(),
                  const SizedBox(height: AppTheme.spaceLg),
                  Text(
                    'FAST · RELIABLE · YOURS',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.92),
                      letterSpacing: 2.4,
                    ),
                  ).fadeSlideIn(delay: AppTheme.normal),
                ],
              ),
            ),

            // ── Loading + version ────────────────────────────────────
            Positioned(
              bottom: 38,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 150,
                        height: 4,
                        child: AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (_, _) => LinearProgressIndicator(
                            value: _progressAnim.value,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.16),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preparing your deliveries…',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'v1.0.2',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ).fadeSlideIn(delay: AppTheme.slow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _ring(double size, double stroke) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: stroke,
          ),
        ),
      );
}
