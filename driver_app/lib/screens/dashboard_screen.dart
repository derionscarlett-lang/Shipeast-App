import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import 'new_order_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onTabSwitch;
  const DashboardScreen({super.key, required this.onTabSwitch});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool isOnline = false;
  bool _hasActiveOrder = false;
  String _driverName = 'Driver';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverName = prefs.getString('driver_name') ?? 'Driver';
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Help & Support',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.construction, color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Help & Support is coming soon. Stay tuned for updates!',
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
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleOnline() {
    setState(() {
      isOnline = !isOnline;
      if (!isOnline) _hasActiveOrder = false;
    });
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 68,
        height: 32,
        decoration: BoxDecoration(
          color: isOnline
              ? AppTheme.success.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: isOnline ? 36 : 2,
              top: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(left: isOnline ? 0 : 20),
                child: Text(
                  isOnline ? 'ON' : 'OFF',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color iconBgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBgColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE65100), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are currently offline.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toggle the switch above to start receiving orders.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF795548),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleOnline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Go Online',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.circle,
                    color: AppTheme.success, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for Orders',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "You're online — ready to receive delivery requests",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: _pulseAnimation.value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for new orders...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewOrderScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Simulate New Order',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppTheme.primary, width: 4),
        ),
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
          Row(
            children: [
              const Icon(Icons.local_shipping,
                  color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Active Order #SE-2847',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kingston Fresh Market → 12 Mona Road',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMid),
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
          // Red header
          Container(
            color: AppTheme.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$_greeting!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildOnlineToggle(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB00D28),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildStatItem('J\$3,750', "Today's Earnings"),
                          Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.3)),
                          _buildStatItem('6', 'Deliveries'),
                          Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.3)),
                          _buildStatItem('4h 32m', 'Online Time'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status section
                  Row(
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isOnline
                                ? AppTheme.success
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!isOnline) _buildOfflineBanner(),
                  if (isOnline && _hasActiveOrder) _buildActiveOrderCard(),
                  if (isOnline && !_hasActiveOrder) _buildReadyCard(),

                  const SizedBox(height: 16),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildQuickActionCard(
                    'View Earnings',
                    Icons.account_balance_wallet,
                    AppTheme.primary,
                    () => widget.onTabSwitch(2),
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionCard(
                    'Delivery History',
                    Icons.history,
                    AppTheme.success,
                    () => widget.onTabSwitch(1),
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionCard(
                    'My Profile',
                    Icons.person,
                    const Color(0xFF1D4ED8),
                    () => widget.onTabSwitch(3),
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionCard(
                    'Help & Support',
                    Icons.headset_mic,
                    const Color(0xFF7C3AED),
                    _showHelpDialog,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
