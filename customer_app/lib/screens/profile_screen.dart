import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'coming_soon_screen.dart';
import 'help_support_screen.dart';
import 'saved_addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _navIndex = 3;

  String _name = 'Marcus Brown';
  String _phone = '+1 876 432 1987';
  String _email = 'marcus@email.com';
  String? _imagePath;

  static const _keyName = 'shipeast_user_name';
  static const _keyPhone = 'shipeast_user_phone';
  static const _keyEmail = 'shipeast_user_email';
  static const _keyAvatar = 'shipeast_avatar_path';

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString(_keyName) ?? 'Marcus Brown';
      _phone = prefs.getString(_keyPhone) ?? '+1 876 432 1987';
      _email = prefs.getString(_keyEmail) ?? 'marcus@email.com';
      _imagePath = prefs.getString(_keyAvatar);
    });
  }

  Future<void> _saveProfile(
      String name, String phone, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyEmail, email);
    setState(() {
      _name = name;
      _phone = phone;
      _email = email;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAvatar, picked.path);
      setState(() => _imagePath = picked.path);
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
            _editField(
                nameCtrl, 'Full Name', Icons.person, TextInputType.name),
            const SizedBox(height: 12),
            _editField(phoneCtrl, 'Phone Number', Icons.phone,
                TextInputType.phone),
            const SizedBox(height: 12),
            _editField(emailCtrl, 'Email Address', Icons.email,
                TextInputType.emailAddress),
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
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700)),
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
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF333333)),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child:
                  Icon(icon, size: 17, color: const Color(0xFF888888)),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFFEBEBEB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFFEBEBEB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 13, vertical: 13),
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
          _buildBottomNav(context),
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
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: ClipOval(
                      child: _imagePath != null
                          ? Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) => const Center(
                                child: Icon(Icons.person,
                                    size: 26, color: Colors.white),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.person,
                                  size: 26, color: Colors.white),
                            ),
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
                        child: Icon(Icons.camera_alt,
                            size: 12, color: AppTheme.primary),
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
                    _name,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
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
                  child:
                      Icon(Icons.edit, size: 17, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

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
        child: Row(
          children: [
            _statItem('24', 'Orders'),
            _statDivider(),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '4.9',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.star,
                          size: 14, color: Color(0xFFFACC15)),
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
            _statItem('3', 'Saved'),
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

  Widget _statDivider() => Container(
        width: 1,
        height: 32,
        color: const Color(0xFFF2F2F2),
      );

  Widget _buildMenuCard(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.location_on,
        'label': 'Saved Addresses',
        'sub': 'Manage your delivery locations',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SavedAddressesScreen()),
            ),
      },
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'sub': 'Push alerts & order updates',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ComingSoonScreen(
                      title: 'Notifications')),
            ),
      },
      {
        'icon': Icons.credit_card,
        'label': 'Payment Methods',
        'sub': 'Cards, PayPal & Cash',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ComingSoonScreen(
                      title: 'Payment Methods')),
            ),
      },
      {
        'icon': Icons.lock,
        'label': 'Privacy & Security',
        'sub': 'Password, data & permissions',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ComingSoonScreen(
                      title: 'Privacy & Security')),
            ),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Help & Support',
        'sub': 'FAQs, WhatsApp & Email',
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HelpSupportScreen()),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom:
                            BorderSide(color: Color(0xFFF8F8F8))),
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
        onTap: () => Navigator.pushNamedAndRemoveUntil(
            context, '/welcome', (route) => false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F2),
            border: Border.all(
                color: const Color(0xFFFECDD3), width: 1.5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout,
                    size: 16, color: AppTheme.primary),
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

  Widget _buildBottomNav(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4,
          top: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, 0, Icons.home, 'Home', '/home'),
            _navItem(context, 1, Icons.inventory_2, 'Orders',
                '/order-history'),
            _navItem(context, 3, Icons.person, 'Profile', null),
          ],
        ),
      );

  Widget _navItem(BuildContext context, int index, IconData iconData,
      String label, String? route) {
    final active = _navIndex == index;
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 22,
            color: active ? AppTheme.primary : const Color(0xFFAAAAAA),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? AppTheme.primary : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}
