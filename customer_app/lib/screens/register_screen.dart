import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
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
    _nameController.dispose();
    _phoneController.dispose();
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

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnackbar('Please fill in all fields', color: AppTheme.error);
      return;
    }
    if (pass.length < 6) {
      _showSnackbar('Password must be at least 6 characters',
          color: AppTheme.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? 'Registration failed. Please try again.',
          color: AppTheme.error);
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
            title: 'Create account',
            subtitle: 'Join ShipEast and get your first order moving',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hint: 'Your full name',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    active: true,
                  ).fadeSlideIn(index: 1),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    hint: '+1 876 000 0000',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ).fadeSlideIn(index: 2),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'your@email.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ).fadeSlideIn(index: 3),
                  const SizedBox(height: AppTheme.spaceMd),
                  _PasswordField(
                    controller: _passwordController,
                    visible: _passwordVisible,
                    onToggle: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ).fadeSlideIn(index: 4),
                  const SizedBox(height: AppTheme.spaceMd),
                  const _SecurityNote().fadeSlideIn(index: 5),
                  const SizedBox(height: AppTheme.spaceLg),
                  AppButton(
                    label: 'Create my account',
                    trailingArrow: true,
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _handleRegister,
                  ).fadeSlideIn(index: 6),
                  const SizedBox(height: AppTheme.spaceMd),
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account?  ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: 'Sign In',
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
                  ).fadeSlideIn(index: 7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reassurance chip shown above the submit button.
class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 16, color: AppTheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your details are encrypted and never shared.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared red brand hero with a curved white sheet edge. Presentation only —
/// the back button defers to `Navigator.pop`.
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
            hintText: 'At least 6 characters',
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
