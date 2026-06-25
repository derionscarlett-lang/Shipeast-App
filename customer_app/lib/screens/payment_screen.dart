import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../services/firestore_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPayment = 1; // 0 = PayPal (disabled), 1 = COD
  final _promoController = TextEditingController();
  bool _promoApplied = false;
  bool _validatingPromo = false;
  bool _placingOrder = false;
  int _discount = 0;

  // Order context from checkout
  String _merchantId = '';
  String _merchantName = '';
  List<Map<String, dynamic>> _items = [];
  int _subtotal = 0;
  int _deliveryFee = 0;
  int _serviceFee = 0;
  int _total = 0;
  String _deliveryAddress = '';
  bool _argsLoaded = false;

  int get _finalTotal =>
      _total > 0 ? (_total - _discount).clamp(0, _total) : 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _merchantId = args['merchantId'] as String? ?? '';
        _merchantName = args['merchantName'] as String? ?? '';
        _items = (args['items'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        _subtotal = args['subtotal'] as int? ?? 0;
        _deliveryFee = args['deliveryFee'] as int? ?? 0;
        _serviceFee = args['serviceFee'] as int? ?? 0;
        _total = args['total'] as int? ?? 0;
        _deliveryAddress = args['deliveryAddress'] as String? ?? '';
      }
    }
  }

  String _formatPrice(int p) {
    if (p >= 1000) {
      return '${p ~/ 1000},${(p % 1000).toString().padLeft(3, '0')}';
    }
    return '$p';
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingPromo = true);
    try {
      final data = await FirestoreService.validatePromoCode(code);
      if (!mounted) return;
      if (data == null) {
        setState(() {
          _discount = 0;
          _promoApplied = false;
          _validatingPromo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invalid or expired promo code',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
        return;
      }
      // Calculate discount
      final discountType = data['discountType'] as String? ?? 'percentage';
      final discountVal = (data['discount'] as num?)?.toInt() ?? 0;
      int discount = 0;
      if (discountType == 'percentage') {
        discount = (_total * discountVal / 100).round();
      } else {
        discount = discountVal;
      }
      discount = discount.clamp(0, _total > 0 ? _total : 0);
      setState(() {
        _discount = discount;
        _promoApplied = true;
        _validatingPromo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Promo applied! You saved \$${_formatPrice(discount)}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    } catch (_) {
      if (mounted) {
        setState(() => _validatingPromo = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error validating promo code',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<bool> _showOrderConfirmation() async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.receipt_long_rounded,
                    size: 30, color: AppTheme.primary),
              ),
            ).popIn(),
            const SizedBox(height: 16),
            Text(
              'Confirm Your Order',
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 7),
            Text(
              'You\'re ordering from $_merchantName for \$${_formatPrice(_finalTotal)}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _deliveryAddress,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Place Order',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppTopBar(
              title: 'Payment',
              subtitle: 'Choose how you\'d like to pay',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                children: [
                  _buildStepper().fadeSlideIn(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildPaymentCard().fadeSlideIn(index: 1),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildSecurityCard().fadeSlideIn(index: 2),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildPromoCard().fadeSlideIn(index: 3),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildTotalCard().fadeSlideIn(index: 4),
                  const SizedBox(height: AppTheme.spaceMd),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() => Row(
        children: [
          _step('Cart', Icons.shopping_bag_rounded, done: true),
          _stepLine(),
          _step('Address', Icons.location_on_rounded, done: true),
          _stepLine(),
          _step('Payment', Icons.payments_rounded, active: true),
        ],
      );

  Widget _step(String label, IconData icon,
      {bool active = false, bool done = false}) {
    final on = active || done;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: on ? AppTheme.primary : AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
                color: on ? AppTheme.primary : AppTheme.border, width: 1.5),
          ),
          child: Icon(done ? Icons.check_rounded : icon,
              size: 17, color: on ? Colors.white : AppTheme.inactive),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: on ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _stepLine() => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 18),
          color: AppTheme.primary,
        ),
      );

  Widget _buildPaymentCard() => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _coHead('Select Payment', Icons.account_balance_wallet_rounded),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  // PayPal row — disabled, Coming Soon
                  Opacity(
                    opacity: 0.55,
                    child: IgnorePointer(
                      child: _paymentRow(
                        index: 0,
                        icon: _paypalLogo(),
                        name: 'PayPal',
                        sub: 'Pay securely via PayPal',
                        iconBg: const Color(0xFFF0F4FF),
                        trailing: const StatusBadge(
                          label: 'Coming Soon',
                          color: AppTheme.textMuted,
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // COD row — active
                  Pressable(
                    onTap: () => setState(() => _selectedPayment = 1),
                    child: _paymentRow(
                      index: 1,
                      icon: const Icon(Icons.payments_rounded,
                          size: 24, color: AppTheme.success),
                      name: 'Cash on Delivery',
                      sub: 'Pay when your order arrives',
                      iconBg: const Color(0xFFF0FDF4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _paymentRow({
    required int index,
    required Widget icon,
    required String name,
    required String sub,
    required Color iconBg,
    Widget? trailing,
  }) {
    final selected = _selectedPayment == index;
    return AnimatedContainer(
      duration: AppTheme.fast,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryLight : AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _radio(selected),
        ],
      ),
    );
  }

  Widget _radio(bool selected) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.inputBorder,
            width: 2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      );

  Widget _paypalLogo() => RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Pay',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF003087)),
            ),
            TextSpan(
              text: 'Pal',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF009CDE)),
            ),
          ],
        ),
      );

  Widget _buildSecurityCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: const Color(0xFFD1FAE0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    size: 18, color: AppTheme.success),
                const SizedBox(width: 7),
                Text(
                  'Your payment is protected',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _securityRow(Icons.shield_rounded, '256-bit SSL encryption'),
            const SizedBox(height: 9),
            _securityRow(Icons.lock_rounded, '100% secure payment'),
            const SizedBox(height: 9),
            _securityRow(
                Icons.handshake_rounded, 'ShipEast buyer protection'),
          ],
        ),
      );

  Widget _securityRow(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.success),
          const SizedBox(width: 9),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary),
          ),
        ],
      );

  Widget _buildPromoCard() => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_rounded,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 7),
                Text(
                  'Promo Code',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    enabled: !_promoApplied,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: _promoApplied
                          ? 'Promo code applied'
                          : 'Enter promo code',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: _promoApplied
                              ? AppTheme.success
                              : AppTheme.hint),
                      filled: true,
                      fillColor: _promoApplied
                          ? const Color(0xFFF0FDF4)
                          : AppTheme.inputBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(
                            color: _promoApplied
                                ? const Color(0xFF86EFAC)
                                : AppTheme.border,
                            width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 12),
                      isDense: true,
                      prefixIcon: Icon(
                        _promoApplied
                            ? Icons.check_circle_rounded
                            : Icons.confirmation_number_outlined,
                        size: 18,
                        color:
                            _promoApplied ? AppTheme.success : AppTheme.hint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: _promoApplied
                      ? () {
                          setState(() {
                            _promoApplied = false;
                            _discount = 0;
                            _promoController.clear();
                          });
                        }
                      : _validatingPromo
                          ? null
                          : _applyPromo,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _promoApplied
                          ? AppTheme.surface
                          : AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: _promoApplied
                          ? Border.all(color: AppTheme.border)
                          : null,
                    ),
                    child: _validatingPromo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _promoApplied ? 'Remove' : 'Apply',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _promoApplied
                                    ? AppTheme.textSecondary
                                    : Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildTotalCard() => AppCard(
        child: Column(
          children: [
            if (_discount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Original total',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textMuted)),
                  Text(
                    '\$${_formatPrice(_total)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        decoration: TextDecoration.lineThrough),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 14, color: AppTheme.success),
                      const SizedBox(width: 5),
                      Text('Promo discount',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(
                    '− \$${_formatPrice(_discount)}',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total to pay',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  '\$${_formatPrice(_finalTotal)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 10, AppTheme.spaceMd, 10),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
          boxShadow: AppTheme.shadowMd,
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            label: 'Place Order · \$${_formatPrice(_finalTotal)}',
            icon: Icons.lock_rounded,
            loading: _placingOrder,
            onPressed: _placingOrder ? null : _placeOrder,
          ),
        ),
      );

  Future<void> _placeOrder() async {
    if (_placingOrder) return;

    final confirmed = await _showOrderConfirmation();
    if (!confirmed) return;

    setState(() => _placingOrder = true);
    try {
      final paymentMethod =
          _selectedPayment == 0 ? 'PayPal' : 'Cash on Delivery';
      String orderId;
      if (_merchantId.isNotEmpty && _items.isNotEmpty) {
        orderId = await FirestoreService.placeOrder(
          merchantId: _merchantId,
          merchantName: _merchantName,
          items: _items,
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          serviceFee: _serviceFee,
          total: _finalTotal,
          paymentMethod: paymentMethod,
          deliveryAddress: _deliveryAddress,
        );
      } else {
        orderId = '';
      }
      if (!mounted) return;
      Provider.of<CartProvider>(context, listen: false).clearCart();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/order-confirmed',
        (route) => route.settings.name == '/home',
        arguments: {
          'orderId': orderId,
          'merchantName': _merchantName,
          'items': _items,
          'subtotal': _subtotal,
          'deliveryFee': _deliveryFee,
          'serviceFee': _serviceFee,
          'total': _finalTotal,
          'deliveryAddress': _deliveryAddress,
          'paymentMethod': _selectedPayment == 0 ? 'PayPal' : 'Cash on Delivery',
        },
      );
    } catch (_) {
      if (mounted) setState(() => _placingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not place order. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _coHead(String title, IconData icon) => Container(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
      );
}
