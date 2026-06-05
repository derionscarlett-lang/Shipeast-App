import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/driver_firestore_service.dart';
import 'delivery_confirmation_screen.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const PickupConfirmationScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;
  bool _confirming = false;

  String get _merchantName =>
      widget.order['merchantName'] as String? ?? 'Merchant';
  String get _customerName =>
      widget.order['customerName'] as String? ?? 'Customer';
  String get _deliveryAddress =>
      widget.order['deliveryAddress'] as String? ?? '—';
  int get _total => (widget.order['total'] as num?)?.toInt() ?? 0;
  String get _paymentMethod =>
      widget.order['paymentMethod'] as String? ?? 'COD';
  List _getItems() => widget.order['items'] as List? ?? [];

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '\$${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$price';
  }

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _dotAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_dotController);
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _confirmPickup() async {
    setState(() => _confirming = true);
    try {
      await DriverFirestoreService.confirmPickup(widget.orderId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryConfirmationScreen(
              orderId: widget.orderId,
              order: widget.order,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _confirming = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to confirm pickup. Try again.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pickup Confirmation',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppTheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _dotAnimation,
                    builder: (_, child) => Opacity(
                      opacity: _dotAnimation.value,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                            color: AppTheme.success, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Accepted',
                            style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.success)),
                        const SizedBox(height: 2),
                        Text('Head to the merchant to pick up the order',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppTheme.textMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Merchant card
            _infoCard(
              icon: Icons.store,
              iconColor: AppTheme.primary,
              title: 'Pickup From',
              rows: [
                _infoRow('Merchant', _merchantName),
              ],
            ),
            const SizedBox(height: 10),

            // Customer & delivery card
            _infoCard(
              icon: Icons.location_on,
              iconColor: AppTheme.success,
              title: 'Deliver To',
              rows: [
                _infoRow('Customer', _customerName),
                _infoRow('Address', _deliveryAddress),
              ],
            ),
            const SizedBox(height: 10),

            // Items card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.inventory_2,
                            color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Order Items',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...items.map((item) {
                    final name =
                        (item is Map) ? (item['name'] as String? ?? '—') : '$item';
                    final qty =
                        (item is Map) ? (item['quantity'] as int? ?? 1) : 1;
                    final price =
                        (item is Map) ? (item['price'] as num?)?.toInt() : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: AppTheme.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('$name ×$qty',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppTheme.textDark)),
                          ),
                          if (price != null)
                            Text(_formatPrice(price * qty),
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMid)),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: AppTheme.divider, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total ($_paymentMethod)',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.textMid)),
                      Text(_formatPrice(_total),
                          style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _confirming ? null : _confirmPickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _confirming
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Confirm Pickup',
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> rows,
  }) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark)),
              ],
            ),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMid)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ),
          ],
        ),
      );
}
