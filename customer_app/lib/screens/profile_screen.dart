import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _navIndex = 3; // Profile tab

  static const _menuItems = [
    {'icon': '📍', 'label': 'Saved Addresses', 'sub': 'Manage your delivery locations'},
    {'icon': '🔔', 'label': 'Notifications', 'sub': 'Push alerts & order updates'},
    {'icon': '💳', 'label': 'Payment Methods', 'sub': 'Cards, PayPal & Cash'},
    {'icon': '🔒', 'label': 'Privacy & Security', 'sub': 'Password, data & permissions'},
    {'icon': '❓', 'label': 'Help & Support', 'sub': 'FAQs, chat with us'},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
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
            // Avatar
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            // Name & phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marcus Brown',
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '+1 876 432 1987',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Edit button
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('✏️', style: TextStyle(fontSize: 16)),
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
            _statItem('4.9 ⭐', 'Rating'),
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

  Widget _buildMenuCard(BuildContext context) => Container(
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
          children: _menuItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isLast = i == _menuItems.length - 1;
            return GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
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
                        child: Text(
                          item['icon']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label']!,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item['sub']!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFAAAAAA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('›',
                        style: TextStyle(
                            fontSize: 18, color: Color(0xFFCCCCCC))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildSignOutButton(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pushNamedAndRemoveUntil(
            context, '/welcome', (route) => false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F2),
            border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              '🚪  Sign Out',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
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
            _navItem(context, 0, '🏠', 'Home', '/home'),
            _navItem(context, 1, '📦', 'Orders', '/order-history'),
            _navItem(context, 3, '👤', 'Profile', null),
          ],
        ),
      );

  Widget _navItem(BuildContext context, int index, String emoji, String label,
      String? route) {
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
          Text(emoji,
              style: TextStyle(
                  fontSize: 22,
                  color: active ? AppTheme.primary : const Color(0xFFAAAAAA))),
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
