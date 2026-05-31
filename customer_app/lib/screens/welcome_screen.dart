import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red hero section
          SizedBox(
            height: 268,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 268,
                  color: AppTheme.primary,
                ),
                // Decorative ring top-right
                Positioned(
                  top: -35,
                  right: -35,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 28,
                      ),
                    ),
                  ),
                ),
                // Delivery illustration — centered
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.15),
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: _DeliveryIllustration(),
                    ),
                  ),
                ),
                // White curved strip at bottom
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(38),
                        topRight: Radius.circular(38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // White content section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Delivery,\n',
                          style: GoogleFonts.montserrat(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.dark,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'Done Right.',
                          style: GoogleFonts.montserrat(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order from local restaurants, groceries & merchants in St. Thomas & Kingston — delivered straight to your door.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF777777),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Get Started →',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightGray,
                      foregroundColor: const Color(0xFF333333),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'I Already Have an Account',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'By continuing you agree to our ',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFC0C0C0),
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Terms',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: ' & ',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFC0C0C0),
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
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

class _DeliveryIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Speed lines
          CustomPaint(
            size: const Size(200, 140),
            painter: _SpeedLinesPainter(),
          ),
          // Shadow ellipse at bottom
          Positioned(
            bottom: 8,
            left: 30,
            right: 30,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Motorcycle body
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(180, 80),
              painter: _MotorcyclePainter(),
            ),
          ),
          // Delivery box on back
          Positioned(
            bottom: 56,
            left: 22,
            child: Container(
              width: 38,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.inventory_2, size: 18, color: AppTheme.primary),
              ),
            ),
          ),
          // Rider helmet
          Positioned(
            bottom: 72,
            right: 32,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person, size: 18, color: AppTheme.primary),
              ),
            ),
          ),
          // Location pin above
          Positioned(
            top: 0,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on,
                      size: 14, color: AppTheme.primary),
                ),
                Container(
                  width: 2,
                  height: 8,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final shortPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Long speed lines
    for (int i = 0; i < 3; i++) {
      final y = size.height * 0.55 + i * 14.0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * 0.35, y),
        paint,
      );
    }
    // Short speed lines
    for (int i = 0; i < 2; i++) {
      final y = size.height * 0.50 + i * 18.0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * 0.22, y),
        shortPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MotorcyclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final wheelPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Body
    final bodyPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.35)
      ..lineTo(size.width * 0.75, size.height * 0.35)
      ..lineTo(size.width * 0.82, size.height * 0.65)
      ..lineTo(size.width * 0.18, size.height * 0.65)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Accent stripe
    final accentPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.35)
      ..lineTo(size.width * 0.70, size.height * 0.55)
      ..lineTo(size.width * 0.30, size.height * 0.55)
      ..close();
    canvas.drawPath(accentPath, accentPaint);

    // Front wheel
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.75),
      size.height * 0.22,
      wheelPaint,
    );
    // Rear wheel
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.75),
      size.height * 0.22,
      wheelPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

