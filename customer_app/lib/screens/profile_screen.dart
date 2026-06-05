import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'saved_addresses_screen.dart';
import 'coming_soon_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  String _email = '';
  String? _avatarUrl;

  int _orderCount = 0;
  double _avgRating = 0;
  int _savedCount = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _email = user.email ?? '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] as String? ?? '';
          _phone = data['phone'] as String? ?? '';
          _email = data['email'] as String? ?? user.email ?? '';
          _avatarUrl = data['avatarUrl'] as String?;
        });
      }
    } catch (_) {}

    try {
      final stats = await FirestoreService.getUserStats(user.uid);
      if (mounted) {
        setState(() {
          _orderCount = stats['orderCount'] as int? ?? 0;
          _avgRating = (stats['avgRating'] as num?)?.toDouble() ?? 0;
          _savedCount = stats['savedCount'] as int? ?? 0;
          _statsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  Future<void> _saveProfile(String name, String phone, String email) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _name = name;
      _phone = phone;
      _email = email;
    });
  }

  Future<void> _pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      final url = await FirestoreService.uploadAvatar(user.uid, File(picked.path));
      if (mounted) setState(() => _avatarUrl = url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload photo',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final emailCtrl = TextEditingController(text: _email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Profile',
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
            const SizedBox(height: 18),
            _editField(nameCtrl, 'Full Name', Icons.person, TextInputType.name),
            const SizedBox(height: 12),
            _editField(phoneCtrl, 'Phone Number', Icons.phone, TextInputType.phone),
            const SizedBox(height: 12),
            _editField(emailCtrl, 'Email Address', Icons.email, TextInputType.emailAddress),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty) return;
                _saveProfile(name, phone, email);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Profile saved!',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                elevation: 0,
              ),
              child: Text('Save Changes',
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label,
      IconData icon, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF333333)),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 17, color: const Color(0xFF888888)),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            isDense: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildRedHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 10),
                  _buildMenuCard(context),
                  const SizedBox(height: 10),
                  _buildSignOutButton(context),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedHeader(BuildContext context) => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: 22,
          left: 16,
          right: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => _initialsWidget(26),
                              errorWidget: (ctx, url, err) => _initialsWidget(26),
                            )
                          : _initialsWidget(26),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, size: 12, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name.isNotEmpty ? _name : 'ShipEast User',
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (_phone.isNotEmpty)
                    Text(
                      _phone,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (_email.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      _email,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: _showEditDialog,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.edit, size: 17, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _initialsWidget(double size) {
    final initials = _name.isNotEmpty
        ? _name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '';
    return Center(
      child: initials.isNotEmpty
          ? Text(initials,
              style: TextStyle(
                  fontSize: size * 0.62,
                  fontWeight: FontWeight.w900,
                  color: Colors.white))
          : Icon(Icons.person, size: size, color: Colors.white),
    );
  }

  Widget _buildStatsCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: !_statsLoaded
            ? const SizedBox(
                height: 50,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2),
                  ),
                ),
              )
            : Row(
                children: [
                  _statItem('$_orderCount', 'Orders'),
                  _statDivider(),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _avgRating > 0
                                  ? _avgRating.toStringAsFixed(1)
                                  : '—',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.dark,
                              ),
                            ),
                            if (_avgRating > 0) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.star,
                                  size: 14, color: Color(0xFFFACC15)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rating',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statDivider(),
                  _statItem('$_savedCount', 'Saved'),
                ],
              ),
      );

  Widget _statItem(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _statDivider() => Container(width: 1, height: 32, color: const Color(0xFFF2F2F2));

  Widget _buildMenuCard(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.location_on,
        'label': 'Saved Addresses',
        'sub': 'Manage your delivery locations',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
            ),
      },
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'sub': 'Push alerts & order updates',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
      },
      {
        'icon': Icons.credit_card,
        'label': 'Payment Methods',
        'sub': 'Cards, PayPal & Cash',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const ComingSoonScreen(title: 'Payment Methods')),
            ),
      },
      {
        'icon': Icons.lock,
        'label': 'Privacy & Security',
        'sub': 'Password, data & permissions',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
            ),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Help & Support',
        'sub': 'FAQs, WhatsApp & Email',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
      },
    ];

    return Container(
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
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == menuItems.length - 1;
          return GestureDetector(
            onTap: item['action'] as VoidCallback,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF8F8F8))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        item['icon'] as IconData,
                        size: 19,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.dark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item['sub'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) => GestureDetector(
        onTap: _handleSignOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F2),
            border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 16, color: AppTheme.primary),
                const SizedBox(width: 7),
                Text(
                  'Sign Out',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
