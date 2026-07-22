/// Overseas ordering — gated, with interest capture (P5-02).
///
/// ## What was here before
///
/// A `WebView` pointed at `https://tally.so/r/shipeast`, falling back to
/// `https://form.jotform.com/shipeast`. Neither is a form this project owns.
/// The screen contained **zero** Firestore writes, so even in the best case —
/// a form that loaded — nothing reached the system. In the actual case, both
/// URLs fail, the customer sees "Connection Error", and a person who wanted to
/// send groceries home to family in Jamaica is told the internet is broken.
///
/// ## Why this is gated rather than built
///
/// Overseas shipping needs customs declarations, dimensional weight, prohibited
/// -item screening and a carrier integration. That is a project, not a screen,
/// and the plan scopes it out explicitly. Half-building it would produce the
/// same class of defect as the Packages form: a flow that accepts a commitment
/// the business cannot honour.
///
/// So the screen says what is true — this is not available yet — and does the
/// one useful thing it can: records who wants it, so the work can be prioritised
/// against real demand instead of a guess.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../widgets/se_app_bar.dart';
import '../widgets/se_button.dart';
import '../widgets/se_card.dart';
import '../widgets/se_text_field.dart';
import '../widgets/se_toast.dart';

/// The `feature` value recorded on waitlist entries from this screen.
const String kOverseasWaitlistFeature = 'overseas';

/// Accepts anything with a local part, an `@`, a dot-bearing domain and no
/// whitespace.
///
/// Deliberately permissive: the only thing an over-strict pattern achieves is
/// rejecting a real customer's real address. The address is verified by sending
/// to it, not by a regex.
bool isPlausibleEmail(String input) {
  final value = input.trim();
  if (value.isEmpty || value.length > 320) return false;
  if (value.contains(RegExp(r'\s'))) return false;
  return RegExp(r'^[^@]+@[^@]+\.[^@.]+$').hasMatch(value);
}

class OverseasOrderScreen extends StatefulWidget {
  const OverseasOrderScreen({super.key});

  @override
  State<OverseasOrderScreen> createState() => _OverseasOrderScreenState();
}

class _OverseasOrderScreenState extends State<OverseasOrderScreen> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  bool _joined = false;

  static const LinearGradient _oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E9488), Color(0xFF0B6E66)],
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    // Pre-fill from the signed-in account. Most people will want the address
    // they already gave us, and typing it again is friction with no purpose.
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) _emailCtrl.text = email;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final email = _emailCtrl.text.trim();
    if (!isPlausibleEmail(email)) {
      SeToast.error(context, 'Enter an email address we can reach you at');
      return;
    }
    setState(() => _submitting = true);
    try {
      await FirestoreService.joinWaitlist(
        feature: kOverseasWaitlistFeature,
        email: email,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _joined = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // Saying "we'll be in touch" after a failed write is the exact defect
      // this screen exists to remove. Fail out loud.
      SeToast.error(context, 'Could not save that. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeColors.surface50,
      body: Column(
        children: [
          const SeGradientHeader(
            title: 'Order for Family in Jamaica',
            subtitle: 'Diaspora overseas ordering',
            gradient: _oceanGradient,
            trailing: Icon(SeIcons.plane, size: 24, color: Colors.white),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SeSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _explainer(),
                  const SizedBox(height: 14),
                  if (_joined) _confirmation() else _signupCard(),
                  const SizedBox(height: 14),
                  _alternative(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explainer() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SeColors.oceanTint,
          borderRadius: SeRadius.all(SeRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(SeIcons.plane, size: 20, color: SeColors.ocean500),
                const SizedBox(width: 8),
                Text('Not available yet',
                    style: SeType.title.copyWith(color: SeColors.ocean500)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sending groceries, meals or gifts to family in Jamaica from '
              'overseas involves customs and international carriers. We are '
              'not ready to take those orders, and we would rather say so than '
              'take your money and hope.',
              style: SeType.bodyS.copyWith(color: const Color(0xFF0B6E66)),
            ),
          ],
        ),
      );

  Widget _signupCard() => SeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tell us you want it', style: SeType.h3),
            const SizedBox(height: 4),
            Text(
              'We will email you once, when overseas ordering opens. '
              'Nothing else.',
              style: SeType.bodyS.copyWith(color: SeColors.ink500),
            ),
            const SizedBox(height: 14),
            SeTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: SeIcons.envelope,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            SeButton(
              label: _submitting ? 'Saving…' : 'Notify Me',
              icon: SeIcons.check,
              onPressed: _submitting ? null : _join,
            ),
          ],
        ),
      );

  Widget _confirmation() => SeCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: SeColors.successTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(SeIcons.checkCircle,
                  size: 22, color: SeColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're on the list", style: SeType.title),
                  const SizedBox(height: 2),
                  Text(
                    'We saved ${_emailCtrl.text.trim()} and will email you when '
                    'overseas ordering opens.',
                    style: SeType.bodyS.copyWith(color: SeColors.ink500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _alternative() => SeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In the meantime', style: SeType.title),
            const SizedBox(height: 4),
            Text(
              'If someone in Jamaica can place the order, ShipEast delivers '
              'food, groceries and packages across St. Thomas today.',
              style: SeType.bodyS.copyWith(color: SeColors.ink500),
            ),
            const SizedBox(height: 12),
            SeButton(
              label: 'Browse Merchants',
              icon: SeIcons.arrowRight,
              variant: SeButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
}
