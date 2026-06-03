import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<String> driverNameNotifier;
  const ProfileScreen({super.key, required this.driverNameNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Driver';
  String _phone = '';
  String _email = '';
  String _vehicle = 'Motorcycle';
  String _licence = '';
  String? _imagePath;

  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _licenceCtrl;
  String _editVehicle = 'Motorcycle';

  static const _vehicleTypes = ['Motorcycle', 'Car', 'Van', 'Truck'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _licenceCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _licenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] as String? ?? 'Driver';
          _phone = data['phone'] as String? ?? '';
          _email = data['email'] as String? ?? '';
          _vehicle = data['vehicleType'] as String? ?? 'Motorcycle';
          _licence = data['licencePlate'] as String? ?? '';
        });
      }
    } catch (_) {}
    // Image path stored locally only
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _imagePath = prefs.getString('driver_avatar'));
    }
  }

  void _startEditing() {
    _nameCtrl.text = _name;
    _phoneCtrl.text = _phone;
    _emailCtrl.text = _email;
    _licenceCtrl.text = _licence;
    _editVehicle = _vehicle;
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'vehicleType': _editVehicle,
          'licencePlate': _licenceCtrl.text.trim(),
        });
      } catch (_) {}
    }
    setState(() {
      _name = _nameCtrl.text.trim();
      _phone = _phoneCtrl.text.trim();
      _email = _emailCtrl.text.trim();
      _vehicle = _editVehicle;
      _licence = _licenceCtrl.text.trim();
      _isEditing = false;
      _isSaving = false;
    });
    widget.driverNameNotifier.value = _name;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile saved!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_avatar', picked.path);
      setState(() => _imagePath = picked.path);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title: Text('Take Photo', style: AppTheme.body()),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.primary),
              title: Text('Choose from Gallery', style: AppTheme.body()),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          feature,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.construction, color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This feature is coming soon. Stay tuned for updates!',
                style: AppTheme.body(color: AppTheme.textMid),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.local_shipping, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'About ShipEast',
              style:
                  GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ShipEast Driver App',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: AppTheme.body(color: AppTheme.textMid)),
            const SizedBox(height: 12),
            Text(
              'Connecting drivers with customers across Jamaica. Fast, reliable, and seamless deliveries.',
              style: AppTheme.body(color: AppTheme.textMid),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2025 ShipEast. All rights reserved.',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Are you sure you want to sign out?',
            style: AppTheme.body(color: AppTheme.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900, color: AppTheme.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _signOut();
            },
            child: Text('Sign Out',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900, color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: Column(
        children: [
          _buildRedHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  if (_isEditing) _buildEditForm() else _buildViewMode(),
                  const SizedBox(height: 12),
                  _buildRatingCard(),
                  const SizedBox(height: 12),
                  _buildSettingsCard(),
                  const SizedBox(height: 12),
                  _buildSignOutTile(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedHeader() => Container(
        color: AppTheme.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      'Driver Profile',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (!_isEditing)
                      GestureDetector(
                        onTap: _startEditing,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit,
                              size: 17, color: Colors.white),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _isEditing = false),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close,
                              size: 17, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Avatar
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2.5),
                        ),
                        child: ClipOval(
                          child: _imagePath != null
                              ? Image.file(File(_imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.person,
                                          size: 38, color: Colors.white))
                              : const Icon(Icons.person,
                                  size: 38, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.camera_alt,
                                size: 13, color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _name,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ShipEast Driver · Kingston, JA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildViewMode() {
    return Column(
      children: [
        // Stats row
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('247', 'Trips'),
              Container(width: 1, height: 36, color: AppTheme.divider),
              _statItem('98%', 'Completion'),
              Container(width: 1, height: 36, color: AppTheme.divider),
              _statItemWithStar('4.9', 'Rating'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Info card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            children: [
              _infoRow(Icons.phone, 'Phone', _phone),
              const Divider(
                  height: 1,
                  color: AppTheme.divider,
                  indent: 16,
                  endIndent: 16),
              _infoRow(Icons.email_outlined, 'Email', _email),
              const Divider(
                  height: 1,
                  color: AppTheme.divider,
                  indent: 16,
                  endIndent: 16),
              _infoRow(Icons.two_wheeler, 'Vehicle', _vehicle),
              const Divider(
                  height: 1,
                  color: AppTheme.divider,
                  indent: 16,
                  endIndent: 16),
              _infoRow(Icons.credit_card_outlined, 'Licence Plate', _licence),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textMid),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textLight)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '—' : value,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textDark)),
              ],
            ),
          ],
        ),
      );

  Widget _statItem(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
      );

  Widget _statItemWithStar(String value, String label) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                const SizedBox(width: 2),
                Text(value,
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark)),
              ],
            ),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
      );

  Widget _buildEditForm() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile',
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),
            _editField(_nameCtrl, 'Full Name', Icons.person_outline,
                TextInputType.name),
            const SizedBox(height: 12),
            _editField(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                TextInputType.phone),
            const SizedBox(height: 12),
            _editField(_emailCtrl, 'Email', Icons.email_outlined,
                TextInputType.emailAddress),
            const SizedBox(height: 12),
            // Vehicle selector
            Text('Vehicle Type',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMid)),
            const SizedBox(height: 8),
            Row(
              children: _vehicleTypes.map((v) {
                final selected = _editVehicle == v;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _editVehicle = v),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: v != _vehicleTypes.last ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.surfaceGrey,
                        borderRadius: BorderRadius.circular(8),
                        border: selected
                            ? null
                            : Border.all(
                                color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          v,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : AppTheme.textMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _editField(_licenceCtrl, 'Licence Plate',
                Icons.credit_card_outlined, TextInputType.text),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Save Changes', style: AppTheme.buttonLG()),
              ),
            ),
          ],
        ),
      );

  Widget _editField(TextEditingController ctrl, String label, IconData icon,
      TextInputType type) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: AppTheme.body(),
      decoration: AppTheme.inputDecoration(label, icon),
    );
  }

  Widget _buildRatingCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating Breakdown',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _buildRatingRow(5, 0.82, '82%'),
            _buildRatingRow(4, 0.65, '65%'),
            _buildRatingRow(3, 0.08, '8%'),
            _buildRatingRow(2, 0.03, '3%'),
            _buildRatingRow(1, 0.02, '2%'),
          ],
        ),
      );

  Widget _buildRatingRow(int stars, double value, String pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            child: Text('$stars',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textDark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.surfaceGrey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(pct,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textMid),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
          children: [
            _settingsTile(Icons.notifications_outlined, 'Notifications',
                () => _showComingSoon('Notifications')),
            const Divider(
                height: 1,
                color: AppTheme.divider,
                indent: 16,
                endIndent: 16),
            _settingsTile(Icons.lock_outline, 'Privacy & Security',
                () => _showComingSoon('Privacy & Security')),
            const Divider(
                height: 1,
                color: AppTheme.divider,
                indent: 16,
                endIndent: 16),
            _settingsTile(Icons.help_outline, 'Help & Support',
                () => _showComingSoon('Help & Support')),
            const Divider(
                height: 1,
                color: AppTheme.divider,
                indent: 16,
                endIndent: 16),
            _settingsTile(Icons.info_outline, 'About ShipEast', _showAbout),
          ],
        ),
      );

  Widget _settingsTile(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: AppTheme.textMid, size: 22),
        title: Text(title,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppTheme.textLight),
        onTap: onTap,
      );

  Widget _buildSignOutTile() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppTheme.primary),
          title: Text('Sign Out',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary)),
          onTap: _showSignOutDialog,
        ),
      );
}
