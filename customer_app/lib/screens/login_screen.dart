import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../widgets/se_bottom_sheet.dart';
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

  /// Google sign-in via Firebase's own OAuth flow.
  ///
  /// Uses `signInWithPopup` on web and `signInWithProvider` on mobile, so no
  /// `google_sign_in` plugin (and its churny native config) is needed — Firebase
  /// handles the federated flow on every platform. Against the local Auth
  /// emulator this opens the emulator's built-in sign-in page, so it works in
  /// the preview too.
  ///
  /// Production note: Google must be enabled under Firebase Console →
  /// Authentication → Sign-in method, and the app's domain added to the
  /// authorized list. That is console config, not code.
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final provider = GoogleAuthProvider();
      final cred = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);
      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'no-user', message: 'Google sign-in returned no account.');
      }
      // A first-time Google account has no profile document. Seed one from the
      // Google profile so the rest of the app (name, avatar) has something to
      // read, exactly as email registration does.
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          if (user.photoURL != null) 'avatarUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await NotificationService.onSignedIn(user.uid);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Dismissing the popup is a choice, not a failure — stay silent on it.
      const cancels = {
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-canceled',
        'canceled',
        'user-canceled',
      };
      if (!cancels.contains(e.code) && mounted) {
        SeToast.error(context, e.message ?? 'Google sign-in failed.');
      }
    } catch (_) {
      if (mounted) SeToast.error(context, 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    showSeBottomSheet(
      context: context,
      builder: (_) =>
          _ForgotPasswordSheet(initialEmail: _emailController.text.trim()),
    );
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
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      // Persist the push token against THIS session (P4-03). Registering only
      // at startup would leave a device that signed in later unreachable.
      await NotificationService.onSignedIn(cred.user!.uid);
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
        child: Stack(
          children: [
            // Back button, pinned so the form group can centre on its own.
            Positioned(
              top: 4,
              left: SeSpacing.gutter - 8,
              child: _BackButton(onTap: () => Navigator.pop(context)),
            ),
            // Form group, vertically centred for balanced breathing room.
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
                      const _AuthHeader(
                        title: 'Welcome back',
                        subtitle: 'Sign in to continue with ShipEast',
                      ),
                      const SizedBox(height: 32),
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
                        hint: '••••••••',
                        icon: SeIcons.lock,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 22),
                          child: GestureDetector(
                            onTap: _handleForgotPassword,
                            child: Text('Forgot password?',
                                style: SeType.label
                                    .copyWith(color: SeColors.brandAction)),
                          ),
                        ),
                      ),
                      SeButton(
                        label: 'Sign In',
                        loading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: SeColors.ink200)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: SeType.bodyS
                                    .copyWith(color: SeColors.ink400)),
                          ),
                          const Expanded(child: Divider(color: SeColors.ink200)),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _GoogleButton(
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Don't have an account?  ",
                                style: SeType.body
                                    .copyWith(color: SeColors.ink500),
                              ),
                              TextSpan(
                                text: 'Sign Up',
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

/// A round, quiet back button — shared across the auth screens.
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: SeColors.surface50, shape: BoxShape.circle),
          child: const Icon(SeIcons.arrowLeft, size: 20, color: SeColors.ink900),
        ),
      );
}

/// Calm, centred brand mark + title used by both sign-in and sign-up, replacing
/// the old ember slab. A modest emblem gives brand presence without crowding the
/// form, keeping the screen clean and breathable.
class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SeColors.brand,
              borderRadius: SeRadius.all(SeRadius.lg),
              boxShadow: SeElevation.glow,
            ),
            child: const Icon(SeIcons.box, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(title, style: SeType.h1, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle,
              style: SeType.body.copyWith(color: SeColors.ink500),
              textAlign: TextAlign.center),
        ],
      );
}

/// Password-reset sheet. Sends a Firebase reset email and, on success, tells
/// the customer to check their inbox. Kept deliberately vague on failure: a
/// distinct "no such account" message would confirm which emails have accounts
/// to anyone who can open the app.
class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      SeToast.error(context, 'Enter your email address');
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Navigator.pop(context);
      SeToast.success(
          context, 'If that email has an account, a reset link is on its way.');
    } on FirebaseAuthException catch (e) {
      // invalid-email is a formatting problem worth surfacing; user-not-found is
      // swallowed above by the same success copy so we do not leak account
      // existence.
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        Navigator.pop(context);
        SeToast.success(context,
            'If that email has an account, a reset link is on its way.');
        return;
      }
      SeToast.error(context, e.message ?? 'Could not send reset email.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SeSpacing.gutter,
        right: SeSpacing.gutter,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SeSheetHandle(),
          const SizedBox(height: 12),
          Text('Reset your password', style: SeType.h2),
          const SizedBox(height: 8),
          Text(
            'Enter the email on your account and we will send you a link to set a new password.',
            style: SeType.body.copyWith(color: SeColors.ink500),
          ),
          const SizedBox(height: 20),
          SeTextField(
            controller: _controller,
            label: 'EMAIL ADDRESS',
            hint: 'your@email.com',
            icon: SeIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 20),
          SeButton(
            label: 'Send reset link',
            icon: SeIcons.envelope,
            loading: _sending,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SeColors.surfaceRaised,
            border: Border.all(color: SeColors.ink200, width: 1.5),
            borderRadius: SeRadius.pill,
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
      ),
    );
  }
}
