import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OrderConfirmedScreen extends StatefulWidget {
  const OrderConfirmedScreen({super.key});

  @override
  State<OrderConfirmedScreen> createState() => _OrderConfirmedScreenState();
}

class _OrderConfirmedScreenState extends State<OrderConfirmedScreen>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _confettiAnim;

  late List<_Particle> _particles;

  String _orderId = '';
  String _merchantName = '';
  List<Map<String, dynamic>> _items = const [
    {'name': 'Full Jerk Chicken', 'qty': 1, 'price': 1200},
    {'name': 'Sorrel Punch', 'qty': 1, 'price': 350},
  ];
  int _subtotal = 1550;
  int _deliveryFee = 250;
  int _serviceFee = 125;
  int _total = 1925;
  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _confettiAnim = CurvedAnimation(
        parent: _confettiCtrl, curve: Curves.easeOut);

    _particles = List.generate(40, (_) => _Particle());

    _animCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiCtrl.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _orderId = args['orderId'] as String? ?? '';
        _merchantName = args['merchantName'] as String? ?? '';
        _subtotal = args['subtotal'] as int? ?? 1550;
        _deliveryFee = args['deliveryFee'] as int? ?? 250;
        _serviceFee = args['serviceFee'] as int? ?? 125;
        _total = args['total'] as int? ?? 1925;
        final rawItems = args['items'] as List?;
        if (rawItems != null && rawItems.isNotEmpty) {
          _items = rawItems
              .map((e) => Map<String, dynamic>.from(e as Map))
              .map((e) => {
                    'name': e['name'] ?? '',
                    'qty': e['quantity'] ?? 1,
                    'price': e['price'] ?? 0,
                  })
              .toList();
        }
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  String _fmt(int price) {
    if (price >= 1000) {
      return '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '$price';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiAnim,
            builder: (_, _) => CustomPaint(
              painter: _ConfettiPainter(_confettiAnim.value, _particles),
              size: Size.infinite,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success icon
                    Center(
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.32),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.check_circle,
                                size: 44, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Order Placed!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.dark,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Your order is confirmed & sent to ${_merchantName.isNotEmpty ? _merchantName : 'the merchant'}. We\'ll notify you at every step.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Order ID
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ORDER ID',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFAAAAAA),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _orderId.isNotEmpty
                                ? '#${_orderId.substring(0, _orderId.length.clamp(0, 8)).toUpperCase()}'
                                : '#SE-ORDER',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ETA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        border: Border.all(
                            color: const Color(0xFFFECDD3), width: 1.5),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer,
                              size: 28, color: AppTheme.primary),
                          const SizedBox(width: 11),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESTIMATED ARRIVAL',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFAAAAAA),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '30 – 40 mins',
                                style: GoogleFonts.montserrat(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delivery address
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: AppTheme.dark),
                              const SizedBox(width: 4),
                              Text(
                                'Delivering to',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.dark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '14 Yallahs Main Road, St. Thomas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF555555),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Receipt card
                    _buildReceiptCard(),
                    const SizedBox(height: 18),
                    // Track button
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/order-status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Track My Order →',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 9),
                    // Back to home
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F2),
                        foregroundColor: const Color(0xFF333333),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      size: 16, color: Color(0xFF666666)),
                  const SizedBox(width: 7),
                  Text(
                    'Order Receipt',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                ],
              ),
            ),
            ..._items.map((item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFF2F2F2))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} × ${item['qty']}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF444444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'J\$${_fmt(item['price'] as int)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF444444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
            _receiptRow('Subtotal', 'J\$${_fmt(_subtotal)}', false),
            _receiptRow('Delivery fee', _deliveryFee == 0 ? 'Free' : 'J\$${_fmt(_deliveryFee)}', false),
            _receiptRow('Service fee', 'J\$${_fmt(_serviceFee)}', false),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  Text(
                    'J\$${_fmt(_total)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.payments,
                      size: 14, color: Color(0xFF777777)),
                  const SizedBox(width: 7),
                  Text(
                    'Paid via Cash on Delivery',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF777777),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _receiptRow(String label, String value, bool isBold) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                    fontWeight:
                        isBold ? FontWeight.w700 : FontWeight.w400)),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                    fontWeight:
                        isBold ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      );
}

class _Particle {
  final double x;
  final double speedY;
  final double speedX;
  final double size;
  final Color color;
  final double startY;

  _Particle()
      : x = math.Random().nextDouble(),
        speedY = 0.3 + math.Random().nextDouble() * 0.7,
        speedX = (math.Random().nextDouble() - 0.5) * 0.3,
        size = 4 + math.Random().nextDouble() * 8,
        color = [
          const Color(0xFFC8102E),
          const Color(0xFFFACC15),
          const Color(0xFF2563EB),
          const Color(0xFF16A34A),
          const Color(0xFFFF6B6B),
          const Color(0xFFFFD93D),
        ][math.Random().nextInt(6)],
        startY = -0.1 - math.Random().nextDouble() * 0.3;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final currentY = p.startY + p.speedY * progress;
      if (currentY < 0 || currentY > 1.1) continue;
      final currentX = p.x + p.speedX * progress;
      final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      final rect = Rect.fromCenter(
        center: Offset(currentX * size.width, currentY * size.height),
        width: p.size,
        height: p.size * 0.6,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(progress * math.pi * 4 * p.speedX);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
