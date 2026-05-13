import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red hero section — 268px
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
                // Scooter emoji — centered, shifted up to account for white curve
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.2),
                    child: Text(
                      '🛵',
                      style: TextStyle(
                        fontSize: 86,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
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
                  // Heading
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
                  // Subtitle
                  Text(
                    'Order from local restaurants, groceries & merchants in St. Thomas & Kingston — delivered straight to your door.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF777777),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Get Started button
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
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
                  // Already have account button
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
                  // Terms text
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
