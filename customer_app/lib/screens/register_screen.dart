import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../widgets/se_text_field.dart';
import '../widgets/se_button.dart';
import '../widgets/se_toast.dart';

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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || pass.isEmpty) {
      SeToast.error(context, 'Please fill in all fields');
      return;
    }
    if (pass.length < 6) {
      SeToast.error(context, 'Password must be at least 6 characters');
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
      await NotificationService.onSignedIn(cred.user!.uid);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        SeToast.error(
            context, e.message ?? 'Registration failed. Please try again.');
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
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: SeSpacing.gutter - 8,
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
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    SeSpacing.gutter, 64, SeSpacing.gutter, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 84),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Calm brand mark + title (matches sign-in), replacing the
                      // ember slab so the form has room to breathe.
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: SeColors.brand,
                              borderRadius: SeRadius.all(SeRadius.lg),
                              boxShadow: SeElevation.glow,
                            ),
                            child: const Icon(SeIcons.box,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 20),
                          Text('Create account',
                              style: SeType.h1, textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          Text('Join ShipEast in a few quick steps',
                              style:
                                  SeType.body.copyWith(color: SeColors.ink500),
                              textAlign: TextAlign.center),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SeTextField(
                        controller: _nameController,
                        label: 'FULL NAME',
                        hint: 'Your full name',
                        icon: SeIcons.user,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      SeTextField(
                        controller: _phoneController,
                        label: 'PHONE NUMBER',
                        hint: '+1 876 000 0000',
                        icon: SeIcons.phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      SeTextField(
                        controller: _emailController,
                        label: 'EMAIL ADDRESS',
                        hint: 'your@email.com',
                        icon: SeIcons.envelope,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      SeTextField(
                        controller: _passwordController,
                        label: 'PASSWORD',
                        hint: 'At least 6 characters',
                        icon: SeIcons.lock,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleRegister(),
                      ),
                      const SizedBox(height: 14),
                      // Slim trust line — reassurance without a heavy card.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(SeIcons.lock,
                              size: 14, color: SeColors.ink400),
                          const SizedBox(width: 6),
                          Text('Encrypted and never shared',
                              style: SeType.bodyS
                                  .copyWith(color: SeColors.ink400)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SeButton(
                        label: 'Create Account',
                        loading: _isLoading,
                        onPressed: _isLoading ? null : _handleRegister,
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account?  ',
                                style: SeType.body
                                    .copyWith(color: SeColors.ink500),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: SeType.body.copyWith(
                                    color: SeColors.brandAction,
                                    fontWeight: FontWeight.w700),
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
            ),
          ],
        ),
      ),
    );
  }
}
