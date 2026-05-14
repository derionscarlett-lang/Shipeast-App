import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  static const _steps = [
    {
      'icon': '✅',
      'name': 'Order Confirmed',
      'sub': 'Island Jerk Palace accepted',
      'time': '9:41 AM',
      'state': 'done',
    },
    {
      'icon': '✅',
      'name': 'Order Picked Up',
      'sub': 'Driver collected your order',
      'time': '9:58 AM',
      'state': 'done',
    },
    {
      'icon': '🛵',
      'name': 'On the Way',
      'sub': 'Driver heading to you now',
      'time': 'Live',
      'state': 'now',
    },
    {
      'icon': '🏠',
      'name': 'Delivered',
      'sub': 'Waiting...',
      'time': '',
      'state': 'wait',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulseScale = Tween<double>(begin: 0.7, end: 2.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildMapArea(),
          _buildStatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ..._steps.map(_buildStepRow),
                  const SizedBox(height: 8),
                  _buildDriverCard(),
                  const SizedBox(height: 12),
                  _buildRateButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MAP AREA ──────────────────────────────────────────────────────────────
  Widget _buildMapArea() {
    return SizedBox(
      height: 155,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Green gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B4332), Color(0xFF14532D)],
              ),
            ),
          ),
          // Grid painter
          CustomPaint(painter: _MapGridPainter()),
          // Destination pin
          const Center(
            child: Text('📍', style: TextStyle(fontSize: 28)),
          ),
          // Driver pulse + dot
          Positioned(
            bottom: 40,
            left: 64,
            child: SizedBox(
              width: 26,
              height: 26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseScale.value,
                      child: Opacity(
                        opacity: _pulseOpacity.value,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

  // ── STATUS BAR ────────────────────────────────────────────────────────────
  Widget _buildStatusBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #SE-20268814',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'On the Way 🛵',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F2),
                border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '~15 min',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );

  // ── STEP ROW ──────────────────────────────────────────────────────────────
  Widget _buildStepRow(Map<String, String> step) {
    final state = step['state']!;
    final isDone = state == 'done';
    final isNow = state == 'now';
    final isWait = state == 'wait';

    Color dotBg;
    if (isDone) {
      dotBg = const Color(0xFFEDFCF2);
    } else if (isNow) {
      dotBg = AppTheme.primary;
    } else {
      dotBg = const Color(0xFFF2F2F2);
    }

    return Opacity(
      opacity: isWait ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dotBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step['icon']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: isNow ? Colors.white : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['name']!,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isWait
                          ? const Color(0xFFCCCCCC)
                          : AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    step['sub']!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (step['time']!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      step['time']!,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DRIVER CARD ───────────────────────────────────────────────────────────
  Widget _buildDriverCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Text('👨', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rohan Williams',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '⭐ 4.9  ·  Toyota Corolla  ·  PK-2048',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDFCF2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: Text('📞', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildRateButton() => ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/rate-driver'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: Text(
          'Rate Your Experience →',
          style:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      );
}

// ── MAP GRID PAINTER ────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fine);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fine);
    }
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 84) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (double y = 0; y < size.height; y += 84) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
