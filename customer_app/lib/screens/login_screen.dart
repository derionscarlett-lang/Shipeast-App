import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: color ?? AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showSnackbar('Please fill in all fields', color: AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showSnackbar(
        e.message ?? 'Login failed. Please try again.',
        color: AppTheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AuthHero(
            title: 'Welcome back',
            subtitle: 'Sign in to continue ordering with ShipEast',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'your@email.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    active: true,
                  ).fadeSlideIn(index: 1),
                  const SizedBox(height: AppTheme.spaceMd),
                  _PasswordField(
                    controller: _passwordController,
                    visible: _passwordVisible,
                    onToggle: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ).fadeSlideIn(index: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 18),
                      child: GestureDetector(
                        onTap: () =>
                            _showSnackbar('Password reset coming soon!'),
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppButton(
                    label: 'Sign In',
                    trailingArrow: true,
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ).fadeSlideIn(index: 3),
                  const SizedBox(height: AppTheme.spaceLg),
                  const _OrDivider(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _GoogleButton(
                    onTap: () => _showSnackbar('Google Sign-In coming soon!'),
                  ).fadeSlideIn(index: 4),
                  const SizedBox(height: AppTheme.spaceLg),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "New to ShipEast?  ",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: 'Create an account',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).fadeSlideIn(index: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared red brand hero with a curved white sheet edge, used by the auth
/// screens. Presentation only — the back button defers to `Navigator.pop`.
class _AuthHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHero({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pressable(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 15, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ).fadeSlideIn(),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ).fadeSlideIn(delay: AppTheme.fast),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -1,
            left: 0,
            right: 0,
            child: Container(
              height: 26,
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Password input styled to match [AppTextField] but with externally-owned
/// visibility state so the parent keeps control of the toggle.
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PASSWORD',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: !visible,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.dark),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 18, color: AppTheme.hint),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppTheme.hint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.divider, thickness: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(painter: _GoogleGPainter()),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline vector Google "G" mark drawn from four brand-coloured arcs plus the
/// blue crossbar — no raster asset or text glyph.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  double _rad(double deg) => deg * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - stroke) / 2,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, _rad(24), _rad(66), false, p..color = _green);
    canvas.drawArc(rect, _rad(90), _rad(78), false, p..color = _yellow);
    canvas.drawArc(rect, _rad(168), _rad(90), false, p..color = _red);
    canvas.drawArc(rect, _rad(258), _rad(78), false, p..color = _blue);

    // Blue crossbar from the centre to the right edge.
    final cy = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, cy - stroke / 2, size.width * 0.5, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
