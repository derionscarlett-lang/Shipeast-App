import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../theme/se_brand.dart';
import '../widgets/se_text_field.dart';
import '../widgets/se_button.dart';
import '../widgets/se_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      SeToast.error(context, 'Please fill in all fields');
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
      if (mounted) {
        SeToast.error(context, e.message ?? 'Login failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeColors.surface0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              SeSpacing.gutter, 8, SeSpacing.gutter, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: SeColors.surface50, shape: BoxShape.circle),
                    child: const Icon(SeIcons.arrowLeft,
                        size: 20, color: SeColors.ink900),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SeWordmark(size: 30),
              const SizedBox(height: 18),
              Text('Welcome back', style: SeType.display),
              const SizedBox(height: 6),
              Text('Sign in to your ShipEast account',
                  style: SeType.body.copyWith(color: SeColors.ink500)),
              const SizedBox(height: 28),
              SeTextField(
                controller: _emailController,
                label: 'EMAIL ADDRESS',
                hint: 'your@email.com',
                icon: SeIcons.envelope,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              SeTextField(
                controller: _passwordController,
                label: 'PASSWORD',
                hint: '••••••••',
                icon: SeIcons.lock,
                obscure: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 22),
                  child: GestureDetector(
                    onTap: () =>
                        SeToast.info(context, 'Password reset coming soon!'),
                    child: Text('Forgot Password?',
                        style: SeType.label.copyWith(color: SeColors.red500)),
                  ),
                ),
              ),
              SeButton(
                label: 'Sign In',
                icon: SeIcons.arrowRight,
                loading: _isLoading,
                onPressed: _isLoading ? null : _handleLogin,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: SeColors.ink200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with',
                        style: SeType.bodyS.copyWith(color: SeColors.ink400)),
                  ),
                  const Expanded(child: Divider(color: SeColors.ink200)),
                ],
              ),
              const SizedBox(height: 20),
              _GoogleButton(
                onTap: () =>
                    SeToast.info(context, 'Google Sign-In coming soon!'),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Don't have an account?  ",
                        style: SeType.body.copyWith(color: SeColors.ink500),
                      ),
                      TextSpan(
                        text: 'Sign Up',
                        style: SeType.body.copyWith(
                            color: SeColors.red500, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SeColors.surface0,
          border: Border.all(color: SeColors.ink200, width: 1.5),
          borderRadius: SeRadius.all(SeRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(SeIcons.google, size: 22, color: Color(0xFF4285F4)),
            const SizedBox(width: 10),
            Text('Continue with Google',
                style: SeType.jakarta(15, FontWeight.w600,
                    color: SeColors.ink900)),
          ],
        ),
      ),
    );
  }
}
