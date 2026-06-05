import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_box.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      final thousands = price ~/ 1000;
      final hundreds = price % 1000;
      return '$thousands,${hundreds.toString().padLeft(3, '0')}';
    }
    return '$price';
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.itemList;
    final subtotal = cart.cartTotal;
    final deliveryFee = cart.deliveryFeeAmount;
    final serviceFee = (subtotal * 0.1).round();
    final total = subtotal + deliveryFee + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(cart.cartCount),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (cart.merchantName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 3, bottom: 7),
                              child: Row(
                                children: [
                                  const Icon(Icons.store, size: 12,
                                      color: Color(0xFF999999)),
                                  Text(
                                    ' ${cart.merchantName}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF999999),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...items.map((item) => _itemCard(item, cart)),
                          const SizedBox(height: 4),
                          _buildAddMoreButton(),
                          const SizedBox(height: 8),
                          _buildInstructionsCard(),
                          _buildSummaryCard(subtotal, deliveryFee, serviceFee, total),
                          const SizedBox(height: 8),
                          _buildCheckoutButton(cart, subtotal, deliveryFee, serviceFee, total),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalItems) => Container(
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
              'My Cart',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(width: 8),
            if (totalItems > 0)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$totalItems',
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
      );

  Widget _itemCard(CartItem item, CartProvider cart) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 52,
                height: 52,
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) =>
                            const ShimmerBox(width: 52, height: 52, radius: 9),
                        errorWidget: (ctx, url, err) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.restaurant,
                              size: 24, color: Color(0xFFBBBBBB)),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.restaurant,
                            size: 24, color: Color(0xFFBBBBBB)),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${_formatPrice(item.price)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _qtyBtn(
                  icon: '−',
                  bgColor: const Color(0xFFF2F2F2),
                  textColor: const Color(0xFF444444),
                  onTap: () => cart.removeItem(item.id),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                ),
                _qtyBtn(
                  icon: '+',
                  bgColor: AppTheme.primary,
                  textColor: Colors.white,
                  onTap: () => cart.incrementItem(item.id),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _qtyBtn({
    required String icon,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(icon,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1)),
          ),
        ),
      );

  Widget _buildAddMoreButton() => OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
        ),
        icon: const Icon(Icons.add_shopping_cart, size: 16),
        label: Text(
          'Add More Items',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      );

  Widget _buildInstructionsCard() => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPECIAL INSTRUCTIONS',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF999999),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF666666)),
              decoration: InputDecoration(
                hintText: 'e.g. Extra spicy, no onions...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFBBBBBB)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );

  Widget _buildSummaryCard(int subtotal, int deliveryFee, int serviceFee, int total) =>
      Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _summaryRow('Subtotal', _formatPrice(subtotal)),
            _summaryRow('Delivery fee',
                deliveryFee == 0 ? 'Free' : _formatPrice(deliveryFee)),
            _summaryRow('Service fee', _formatPrice(serviceFee)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.only(top: 9),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF2F2F2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  Text(
                    '\$${_formatPrice(total)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500)),
            Text(value.startsWith('\$') || value == 'Free'
                    ? value
                    : '\$$value',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildCheckoutButton(
          CartProvider cart, int subtotal, int deliveryFee, int serviceFee, int total) =>
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/checkout', arguments: {
          'merchantId': cart.merchantId,
          'merchantName': cart.merchantName,
          'items': cart.toOrderItems(),
          'subtotal': subtotal,
          'deliveryFee': deliveryFee,
          'serviceFee': serviceFee,
          'total': total,
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proceed to Checkout',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                '\$${_formatPrice(total)} →',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 56, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 14),
            Text(
              'Your cart is empty',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add items from a merchant to get started',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Browse Merchants',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary),
              ),
            ),
          ],
        ),
      );
}
