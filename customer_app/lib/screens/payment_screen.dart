import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
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
          backgroundColor: const Color(0xFFDC2626),
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
        backgroundColor: const Color(0xFF16A34A),
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
          backgroundColor: const Color(0xFFDC2626),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
            const SizedBox(height: 22),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(Icons.receipt_long,
                    size: 30, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Confirm Your Order',
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
            const SizedBox(height: 7),
            Text(
              'You are placing an order from $_merchantName\nfor \$${_formatPrice(_finalTotal)}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                  height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Delivering to: $_deliveryAddress',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF999999),
                  height: 1.4),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF444444),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Place Order',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w900)),
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
                    _buildPaymentCard(),
                    const SizedBox(height: 10),
                    _buildSecurityCard(),
                    const SizedBox(height: 10),
                    _buildPromoCard(),
                    const SizedBox(height: 10),
                    _buildTotalCard(),
                    const SizedBox(height: 10),
                    _buildPlaceOrderButton(),
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
                  color: Color(0xFFF2F2F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios,
                      size: 16, color: Color(0xFF444444)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Payment Method',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
          ],
        ),
      );

  Widget _buildPaymentCard() => _coCard(
        child: Column(
          children: [
            _coHead('Select Payment'),
            // PayPal row — disabled, Coming Soon
            Opacity(
              opacity: 0.4,
              child: IgnorePointer(
                child: _paymentRowContent(
                  index: 0,
                  icon: _paypalLogo(),
                  name: 'PayPal',
                  sub: 'Pay securely via PayPal',
                  iconBg: const Color(0xFFF0F4FF),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF888888),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: GoogleFonts.nunito(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            // COD row — active
            GestureDetector(
              onTap: () => setState(() => _selectedPayment = 1),
              child: _paymentRowContent(
                index: 1,
                icon: const Icon(Icons.payments,
                    size: 24, color: Color(0xFF16A34A)),
                name: 'Cash on Delivery',
                sub: 'Pay when your order arrives',
                iconBg: const Color(0xFFF0FDF4),
                isLast: true,
              ),
            ),
          ],
        ),
      );

  Widget _paymentRowContent({
    required int index,
    required Widget icon,
    required String name,
    required String sub,
    required Color iconBg,
    bool isLast = false,
    Widget? trailing,
  }) {
    final selected = _selectedPayment == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dark),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : const Color(0xFFDDDDDD),
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

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

  Widget _buildSecurityCard() => _coCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your payment is protected',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark),
              ),
              const SizedBox(height: 10),
              _securityRow(
                  icon: Icons.shield,
                  color: const Color(0xFF16A34A),
                  label: '256-bit SSL Encryption'),
              const SizedBox(height: 8),
              _securityRow(
                  icon: Icons.lock,
                  color: const Color(0xFF2563EB),
                  label: '100% Secure Payment'),
              const SizedBox(height: 8),
              _securityRow(
                  icon: Icons.verified_user,
                  color: const Color(0xFF003087),
                  label: 'ShipEast Buyer Protection'),
            ],
          ),
        ),
      );

  Widget _securityRow(
          {required IconData icon,
          required Color color,
          required String label}) =>
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF555555)),
          ),
        ],
      );

  Widget _buildPromoCard() => _coCard(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Promo Code',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.dark),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      enabled: !_promoApplied,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF555555)),
                      decoration: InputDecoration(
                        hintText: _promoApplied
                            ? 'Promo code applied!'
                            : 'Enter promo code...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: _promoApplied
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF888888)),
                        filled: true,
                        fillColor: _promoApplied
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: _promoApplied
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE8E8E8),
                              width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: _promoApplied
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE8E8E8),
                              width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        isDense: true,
                        suffixIcon: _promoApplied
                            ? const Icon(Icons.check_circle,
                                size: 18, color: Color(0xFF16A34A))
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  GestureDetector(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: _promoApplied
                            ? const Color(0xFF16A34A)
                            : AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildTotalCard() => _coCard(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Column(
            children: [
              if (_discount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Original Total',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF888888))),
                    Text(
                      '\$${_formatPrice(_total)}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF888888),
                          decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer,
                            size: 13, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text('Promo Discount',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(
                      '- \$${_formatPrice(_discount)}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF2F2F2)),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total to Pay',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.dark),
                  ),
                  Text(
                    '\$${_formatPrice(_finalTotal)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildPlaceOrderButton() => ElevatedButton(
        onPressed: _placingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: _placingOrder
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Place Order · \$${_formatPrice(_finalTotal)}',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ],
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

  Widget _coCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  Widget _coHead(String title) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark),
        ),
      );
}
