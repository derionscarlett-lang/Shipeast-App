import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _sendingReset = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _sendPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    setState(() => _sendingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Password reset email sent to ${user.email}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Failed to send reset email. Try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {}
      await user.delete();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        final msg = e.code == 'requires-recent-login'
            ? 'Please sign out and sign back in, then try again.'
            : 'Failed to delete account. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDataCard(),
                    const SizedBox(height: 10),
                    _buildSecurityCard(),
                    const SizedBox(height: 10),
                    _buildDeleteCard(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2), shape: BoxShape.circle),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF444444)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Privacy & Security',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      );

  Widget _buildDataCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Data We Collect'),
            _dataItem(Icons.person_outline, 'Profile Information',
                'Name, phone number, email address'),
            _dataItem(Icons.location_on_outlined, 'Delivery Addresses',
                'Your saved delivery locations'),
            _dataItem(Icons.receipt_long_outlined, 'Order History',
                'Your past and current orders'),
            _dataItem(Icons.star_outline, 'Ratings & Reviews',
                'Ratings you give to drivers and merchants'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF888888)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We never sell your data. Information is used solely to provide and improve ShipEast services.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _dataItem(IconData icon, String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Center(child: Icon(icon, size: 17, color: const Color(0xFF666666))),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dark)),
                  Text(sub,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF888888))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSecurityCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Security'),
            Text(
              'Change your account password. A reset link will be sent to your registered email address.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendingReset ? null : _sendPasswordReset,
                icon: _sendingReset
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_reset, size: 18),
                label: Text('Send Password Reset Email',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDeleteCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Delete Account'),
            Text(
              'Permanently delete your ShipEast account and all associated data. This action cannot be undone.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleting ? null : _deleteAccount,
                icon: _deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.delete_forever, size: 18),
                label: Text('Delete My Account',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          t,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.dark,
          ),
        ),
      );
}
