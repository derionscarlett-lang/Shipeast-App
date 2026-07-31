import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/se_brand.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../widgets/se_button.dart';

/// First screen a signed-out customer sees.
///
/// 2026 rebuild. The old layout was a 320px hero with a floating parcel
/// illustration stacked over a block of copy and two identical full-width
/// buttons — three competing focal points and a stack of button mass at the
/// bottom. This is one composition instead: the brand shell carries the
/// promise, a blush sheet carries the actions, and there is exactly ONE
/// button on the page. Signing in is a text link, because a second filled
/// pill of equal weight only asks the customer to choose between two things
/// that look the same.
///
/// The red-over-sheet shape continues straight into [SeAuthScaffold], so
/// welcome → sign up → sign in reads as one surface being pulled up rather
/// than three unrelated screens.
///
/// The copy sits at the TOP of the shell and the courier mark anchors the
/// bottom-right corner, which leaves the lower-left of the shell deliberately
/// empty — the rider needs room to read as a subject rather than as a texture,
/// and a block of type stacked directly above it would close that room off.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => Navigator.pushNamed(context, '/privacy-security');
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => Navigator.pushNamed(context, '/privacy-security');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The headline is the one thing allowed to be loud, so it is also the one
    // thing that has to survive a 320dp phone without wrapping into four lines.
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360 ? 27.0 : 31.0;

    return Scaffold(
      backgroundColor: SeColors.shell,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned(top: -110, right: -90, child: _disc(240, 0.06)),
                Positioned(bottom: -70, right: -50, child: _disc(230, 0.05)),
                SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, shell) {
                      // The rider owns a fixed band at the foot of the shell so
                      // the copy above can never push it off — it takes 42% of
                      // the shell, but never so much that the copy is left
                      // under ~250dp. The copy gets a scroll view for the case
                      // where even that is not enough (320dp phone, large
                      // system text size): a short scroll is a better failure
                      // than a yellow overflow stripe.
                      final markBand = math.min(
                        _CourierMark.maxWidth * _CourierMark.ratio,
                        math.min(
                          shell.maxHeight * 0.42,
                          math.max(96.0, shell.maxHeight - 250),
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  SeSpacing.gutter,
                                  16,
                                  SeSpacing.gutter,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SeWordmark(size: 22, onDark: true),
                                    const SizedBox(height: 28),
                                    Text.rich(
                                      TextSpan(
                                        style: SeType.display.copyWith(
                                          fontSize: titleSize,
                                          height: 1.12,
                                          letterSpacing: -0.9,
                                          color: SeColors.shellInk,
                                        ),
                                        children: const [
                                          TextSpan(text: 'Delivery,\n'),
                                          TextSpan(
                                            text: 'done right.',
                                            style: TextStyle(
                                              color: SeColors.shellMark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 290,
                                      ),
                                      child: Text(
                                        'Restaurants, groceries and pharmacy '
                                        'runs across St. Thomas & Kingston — '
                                        'at your door.',
                                        style: SeType.bodyS.copyWith(
                                          color: SeColors.shellInk.withValues(
                                            alpha: 0.78,
                                          ),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _Pill(
                                          icon: SeIcons.food,
                                          label: 'Restaurants',
                                        ),
                                        _Pill(
                                          icon: SeIcons.grocery,
                                          label: 'Groceries',
                                        ),
                                        _Pill(
                                          icon: SeIcons.pharmacy,
                                          label: 'Pharmacy',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: markBand,
                            width: double.infinity,
                            child: const _CourierMark(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _ActionSheet(termsTap: _termsTap, privacyTap: _privacyTap),
        ],
      ),
    );
  }

  Widget _disc(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );
}

/// The courier from the ShipEast logo, riding out of the bottom-right corner.
///
/// Lifted straight from `assets/logo.png` rather than drawn fresh, so the
/// welcome screen is carrying the actual mark the business already uses. It
/// bleeds past the right gutter on purpose — a mascot pinned neatly inside the
/// margin reads as a sticker, one that runs off the edge reads as moving.
///
/// The blurred copy underneath is the only shadow on this screen; it is what
/// stops the silhouette from looking like a flat sticker laid on the red.
class _CourierMark extends StatelessWidget {
  static const String _asset = 'assets/brand/rider.png';

  /// Height ÷ width of the exported PNG (900 × 832).
  static const double ratio = 832 / 900;

  /// A ceiling, so a tablet gets a mark rather than a billboard.
  static const double maxWidth = 270;

  const _CourierMark();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      // Bounded by the band it was handed, then by a share of the width.
      final markWidth = math.min(
        maxWidth,
        math.min(c.maxWidth * 0.68, c.maxHeight / ratio),
      );
      // Below this it is an illegible smudge; a clean empty corner is
      // better than a tiny one.
      if (markWidth < 92) return const SizedBox.shrink();

      return Align(
        alignment: Alignment.bottomRight,
        // Bleeds past the right gutter, and lifts just clear of the sheet so
        // the ground shadow has somewhere to land.
        child: Transform.translate(
          offset: const Offset(16, -6),
          child: SizedBox(
            width: markWidth,
            height: markWidth * ratio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: const Offset(2, 12),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                    child: Image.asset(
                      _asset,
                      fit: BoxFit.contain,
                      color: const Color.fromRGBO(58, 4, 18, 0.55),
                    ),
                  ),
                ),
                Image.asset(
                  _asset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  color: SeColors.shellInk,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// What ShipEast actually carries, said in three words rather than a paragraph.
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: SeRadius.pill,
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: SeColors.shellMark),
        const SizedBox(width: 6),
        Text(label, style: SeType.label.copyWith(color: SeColors.shellInk)),
      ],
    ),
  );
}

/// The blush sheet: one primary action, one text link, one line of small print.
class _ActionSheet extends StatelessWidget {
  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;

  const _ActionSheet({required this.termsTap, required this.privacyTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: SeColors.surface0,
      borderRadius: BorderRadius.vertical(top: Radius.circular(SeRadius.xl)),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(70, 8, 24, 0.22),
          blurRadius: 28,
          offset: Offset(0, -8),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SeSpacing.gutter,
          32,
          SeSpacing.gutter,
          20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SeButton(
              label: 'Create an account',
              onPressed: () => Navigator.pushNamed(context, '/register'),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Already have an account?  ',
                        style: SeType.body.copyWith(color: SeColors.ink500),
                      ),
                      TextSpan(
                        text: 'Sign in',
                        style: SeType.body.copyWith(
                          color: SeColors.brandAction,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: SeType.bodyS.copyWith(color: SeColors.ink400),
                children: [
                  const TextSpan(text: 'By continuing you agree to our '),
                  TextSpan(
                    text: 'Terms',
                    style: const TextStyle(
                      color: SeColors.brandAction,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: termsTap,
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy',
                    style: const TextStyle(
                      color: SeColors.brandAction,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: privacyTap,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
