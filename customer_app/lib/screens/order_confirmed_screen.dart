import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

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
  String _deliveryAddress = '';
  String _paymentMethod = 'Cash on Delivery';
  List<Map<String, dynamic>> _items = const [];
  int _subtotal = 0;
  int _deliveryFee = 0;
  int _serviceFee = 0;
  int _total = 0;
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
        _deliveryAddress = args['deliveryAddress'] as String? ?? '';
        _paymentMethod = args['paymentMethod'] as String? ?? 'Cash on Delivery';
        _subtotal = args['subtotal'] as int? ?? 0;
        _deliveryFee = args['deliveryFee'] as int? ?? 0;
        _serviceFee = args['serviceFee'] as int? ?? 0;
        _total = args['total'] as int? ?? 0;
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
      backgroundColor: AppTheme.background,
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
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg, AppTheme.spaceLg, AppTheme.spaceLg, AppTheme.spaceLg),
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
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.32),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.check_rounded,
                                size: 50, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Order Confirmed!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your order has been sent to ${_merchantName.isNotEmpty ? _merchantName : 'the merchant'}. We\'ll keep you posted at every step.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    // Order ID + ETA row
                    Row(
                      children: [
                        Expanded(child: _orderIdCard()),
                        const SizedBox(width: 10),
                        Expanded(child: _etaCard()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Delivery address
                    _addressCard(),
                    const SizedBox(height: 10),
                    // Receipt card
                    _buildReceiptCard(),
                    const SizedBox(height: AppTheme.spaceLg),
                    // Track button
                    AppButton(
                      label: 'Track My Order',
                      icon: Icons.location_searching_rounded,
                      trailingArrow: true,
                      onPressed: () => Navigator.pushNamed(
                          context, '/order-status',
                          arguments: {'orderId': _orderId}),
                    ),
                    const SizedBox(height: 10),
                    // Back to home
                    AppButton(
                      label: 'Back to Home',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
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

  Widget _orderIdCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag_rounded,
                    size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 3),
                Text(
                  'ORDER ID',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _orderId.isNotEmpty
                  ? '#${_orderId.substring(0, _orderId.length.clamp(0, 8)).toUpperCase()}'
                  : '#SE-ORDER',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );

  Widget _etaCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 12, color: AppTheme.primary),
                const SizedBox(width: 3),
                Text(
                  'ARRIVES IN',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '30 – 40 min',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      );

  Widget _addressCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.location_on_rounded,
                  size: 19, color: AppTheme.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _deliveryAddress.isNotEmpty
                        ? _deliveryAddress
                        : 'No address provided',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildReceiptCard() => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.divider)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      size: 17, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Order Receipt',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ..._items.map((item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppTheme.divider)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(right: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item['qty']}x',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item['name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '\$${_fmt(item['price'] as int)}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )),
            _receiptRow('Subtotal', '\$${_fmt(_subtotal)}'),
            _receiptRow('Delivery fee',
                _deliveryFee == 0 ? 'Free' : '\$${_fmt(_deliveryFee)}',
                highlight: _deliveryFee == 0),
            _receiptRow('Service fee', '\$${_fmt(_serviceFee)}'),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: const BoxDecoration(color: AppTheme.primaryLight),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '\$${_fmt(_total)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 7),
                  Text(
                    'Paid via $_paymentMethod',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _receiptRow(String label, String value, {bool highlight = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400)),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color:
                        highlight ? AppTheme.success : AppTheme.textPrimary,
                    fontWeight: FontWeight.w800)),
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
