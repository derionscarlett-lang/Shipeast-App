import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../services/firestore_service.dart';
import '../widgets/se_card.dart';
import '../widgets/se_button.dart';
import '../widgets/se_toast.dart';
import '../widgets/se_bottom_sheet.dart';

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
        SeToast.error(context, 'Invalid or expired promo code');
        return;
      }
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
      SeToast.success(context, 'Promo applied! You saved \$${_formatPrice(discount)}');
    } catch (_) {
      if (mounted) {
        setState(() => _validatingPromo = false);
        SeToast.error(context, 'Error validating promo code');
      }
    }
  }

  Future<bool> _showOrderConfirmation() async {
    final res = await showSeBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: SeSpacing.gutter,
          right: SeSpacing.gutter,
          top: 4,
          bottom: MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SeSheetHandle(),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: SeColors.sunsetGradient,
                  borderRadius: SeRadius.all(SeRadius.lg),
                  boxShadow: SeElevation.glow,
                ),
                child: const Icon(SeIcons.orders, size: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text('Confirm Your Order',
                style: SeType.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'You are placing an order from $_merchantName for \$${_formatPrice(_finalTotal)}.',
              textAlign: TextAlign.center,
              style: SeType.body.copyWith(color: SeColors.ink500),
            ),
            if (_deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Delivering to: $_deliveryAddress',
                  textAlign: TextAlign.center,
                  style: SeType.bodyS.copyWith(color: SeColors.ink400)),
            ],
            const SizedBox(height: 22),
            SeButton(
              label: 'Place Order',
              icon: SeIcons.check,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 10),
            SeButton(
              label: 'Cancel',
              variant: SeButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx, false),
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
      backgroundColor: SeColors.surface50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SeSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPaymentCard(),
                    const SizedBox(height: 14),
                    _buildSecurityCard(),
                    const SizedBox(height: 14),
                    _buildPromoCard(),
                    const SizedBox(height: 14),
                    _buildTotalCard(),
                    const SizedBox(height: 20),
                    _buildPlaceOrderButton(),
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
        padding: const EdgeInsets.fromLTRB(12, 12, SeSpacing.gutter, 12),
        decoration: const BoxDecoration(
          color: SeColors.surface0,
          border: Border(bottom: BorderSide(color: SeColors.ink100)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: SeColors.surface50, shape: BoxShape.circle),
                child: const Icon(SeIcons.arrowLeft,
                    size: 20, color: SeColors.ink900),
              ),
            ),
            const SizedBox(width: 12),
            Text('Payment Method', style: SeType.h2),
          ],
        ),
      );

  Widget _buildPaymentCard() => SeCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _coHead('Select Payment'),
            Opacity(
              opacity: 0.45,
              child: IgnorePointer(
                child: _paymentRow(
                  index: 0,
                  icon: _paypalLogo(),
                  name: 'PayPal',
                  sub: 'Pay securely via PayPal',
                  iconBg: const Color(0xFFF0F4FF),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: SeColors.ink400,
                        borderRadius: SeRadius.all(SeRadius.xs)),
                    child: Text('Soon',
                        style: SeType.inter(9, FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedPayment = 1),
              behavior: HitTestBehavior.opaque,
              child: _paymentRow(
                index: 1,
                icon: const Icon(SeIcons.cash,
                    size: 24, color: SeColors.success),
                name: 'Cash on Delivery',
                sub: 'Pay when your order arrives',
                iconBg: SeColors.successTint,
                isLast: true,
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
    bool isLast = false,
    Widget? trailing,
  }) {
    final selected = _selectedPayment == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? SeColors.red50 : Colors.transparent,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: SeColors.ink100)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: SeRadius.all(SeRadius.sm)),
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: SeType.title),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(sub,
                    style: SeType.bodyS.copyWith(color: SeColors.ink500)),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? SeColors.red500 : SeColors.ink300,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          color: SeColors.red500, shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _paypalLogo() => RichText(
        text: TextSpan(
          style: SeType.jakarta(15, FontWeight.w800),
          children: const [
            TextSpan(text: 'Pay', style: TextStyle(color: Color(0xFF003087))),
            TextSpan(text: 'Pal', style: TextStyle(color: Color(0xFF009CDE))),
          ],
        ),
      );

  Widget _buildSecurityCard() => SeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your payment is protected', style: SeType.title),
            const SizedBox(height: 12),
            _securityRow(SeIcons.shield, SeColors.success,
                '256-bit SSL Encryption'),
            const SizedBox(height: 10),
            _securityRow(SeIcons.lock, SeColors.ocean500,
                '100% Secure Payment'),
            const SizedBox(height: 10),
            _securityRow(SeIcons.checkCircle, SeColors.red500,
                'ShipEast Buyer Protection'),
          ],
        ),
      );

  Widget _securityRow(IconData icon, Color color, String label) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: SeType.body.copyWith(color: SeColors.ink500)),
        ],
      );

  Widget _buildPromoCard() => SeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(SeIcons.tag, size: 16, color: SeColors.gold500),
                const SizedBox(width: 8),
                Text('Promo Code', style: SeType.title),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _promoApplied
                          ? SeColors.successTint
                          : SeColors.surface50,
                      borderRadius: SeRadius.inputRadius,
                      border: Border.all(
                          color: _promoApplied
                              ? SeColors.success
                              : SeColors.ink200,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            enabled: !_promoApplied,
                            textCapitalization:
                                TextCapitalization.characters,
                            style:
                                SeType.body.copyWith(color: SeColors.ink900),
                            cursorColor: SeColors.red500,
                            decoration: InputDecoration(
                              hintText: _promoApplied
                                  ? 'Promo applied!'
                                  : 'Enter promo code...',
                              hintStyle: SeType.body.copyWith(
                                  color: _promoApplied
                                      ? SeColors.success
                                      : SeColors.ink400),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        if (_promoApplied)
                          const Icon(SeIcons.checkCircle,
                              size: 20, color: SeColors.success),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _promoApplied
                      ? () => setState(() {
                            _promoApplied = false;
                            _discount = 0;
                            _promoController.clear();
                          })
                      : _validatingPromo
                          ? null
                          : _applyPromo,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: _promoApplied ? null : SeColors.emberGradient,
                      color: _promoApplied ? SeColors.ink100 : null,
                      borderRadius: SeRadius.all(SeRadius.sm),
                    ),
                    child: _validatingPromo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.2))
                        : Text(_promoApplied ? 'Remove' : 'Apply',
                            style: SeType.jakarta(14, FontWeight.w700,
                                color: _promoApplied
                                    ? SeColors.ink700
                                    : Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildTotalCard() => SeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_discount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Original Total',
                      style: SeType.body.copyWith(color: SeColors.ink400)),
                  Text('\$${_formatPrice(_total)}',
                      style: SeType.tabular(SeType.body).copyWith(
                          color: SeColors.ink400,
                          decoration: TextDecoration.lineThrough)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(SeIcons.tag,
                          size: 14, color: SeColors.success),
                      const SizedBox(width: 5),
                      Text('Promo Discount',
                          style:
                              SeType.body.copyWith(color: SeColors.success)),
                    ],
                  ),
                  Text('- \$${_formatPrice(_discount)}',
                      style: SeType.tabular(SeType.body)
                          .copyWith(color: SeColors.success)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: SeColors.ink100),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total to Pay', style: SeType.h3),
                Text('\$${_formatPrice(_finalTotal)}',
                    style: SeType.tabular(SeType.h3)
                        .copyWith(color: SeColors.red600)),
              ],
            ),
          ],
        ),
      );

  Widget _buildPlaceOrderButton() => SeButton(
        label: 'Place Order · \$${_formatPrice(_finalTotal)}',
        icon: SeIcons.lock,
        loading: _placingOrder,
        onPressed: _placingOrder ? null : _placeOrder,
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
          'paymentMethod': paymentMethod,
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _placingOrder = false);
        SeToast.error(context, 'Could not place order. Please try again.');
      }
    }
  }

  Widget _coHead(String title) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: SeColors.ink100)),
        ),
        child: Text(title, style: SeType.title),
      );
}
