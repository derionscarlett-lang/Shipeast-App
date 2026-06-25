import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar(
              title: 'My Cart',
              subtitle: items.isEmpty
                  ? 'Nothing here yet'
                  : '${cart.cartCount} ${cart.cartCount == 1 ? 'item' : 'items'} ready to go',
              trailing: items.isEmpty
                  ? null
                  : CountBadge(count: cart.cartCount, size: 22),
            ),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 8),
                      children: [
                        if (cart.merchantName.isNotEmpty)
                          _merchantPill(cart.merchantName).fadeSlideIn(),
                        ...List.generate(items.length, (i) {
                          return _itemCard(items[i], cart)
                              .fadeSlideIn(index: i + 1);
                        }),
                        const SizedBox(height: AppTheme.spaceXs),
                        _buildAddMoreButton().fadeSlideIn(index: items.length + 1),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildInstructionsCard()
                            .fadeSlideIn(index: items.length + 2),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildSummaryCard(subtotal, deliveryFee, serviceFee, total)
                            .fadeSlideIn(index: items.length + 3),
                        const SizedBox(height: AppTheme.spaceMd),
                      ],
                    ),
            ),
            if (items.isNotEmpty) _buildCheckoutBar(cart, subtotal, deliveryFee, serviceFee, total),
          ],
        ),
      ),
    );
  }

  Widget _merchantPill(String name) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceSm, left: 2),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 15, color: AppTheme.primary),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _itemCard(CartItem item, CartProvider cart) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => const ShimmerBox(
                              width: 58, height: 58, radius: AppTheme.radiusMd),
                          errorWidget: (ctx, url, err) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_formatPrice(item.price)} each',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${_formatPrice(item.price * item.quantity)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _qtyStepper(item, cart),
            ],
          ),
        ),
      );

  Widget _imageFallback() => Container(
        color: AppTheme.lightGray,
        child: const Icon(Icons.restaurant_rounded,
            size: 24, color: AppTheme.inactive),
      );

  Widget _qtyStepper(CartItem item, CartProvider cart) => Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qtyBtn(
              icon: Icons.add_rounded,
              filled: true,
              onTap: () => cart.incrementItem(item.id),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                '${item.quantity}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1,
                ),
              ),
            ),
            _qtyBtn(
              icon: item.quantity > 1
                  ? Icons.remove_rounded
                  : Icons.delete_outline_rounded,
              filled: false,
              onTap: () => cart.removeItem(item.id),
            ),
          ],
        ),
      );

  Widget _qtyBtn({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) =>
      Pressable(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: filled ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: filled ? null : Border.all(color: AppTheme.border),
          ),
          child: Icon(icon,
              size: 17,
              color: filled ? Colors.white : AppTheme.textSecondary),
        ),
      );

  Widget _buildAddMoreButton() => AppButton(
        label: 'Add More Items',
        icon: Icons.add_rounded,
        variant: AppButtonVariant.outline,
        onPressed: () => Navigator.pop(context),
      );

  Widget _buildInstructionsCard() => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Special Instructions',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Extra spicy, no onions, leave at the door…',
                isDense: true,
              ),
            ),
          ],
        ),
      );

  Widget _buildSummaryCard(
          int subtotal, int deliveryFee, int serviceFee, int total) =>
      AppCard(
        child: Column(
          children: [
            _summaryRow('Subtotal', '\$${_formatPrice(subtotal)}'),
            _summaryRow(
              'Delivery fee',
              deliveryFee == 0 ? 'Free' : '\$${_formatPrice(deliveryFee)}',
              highlight: deliveryFee == 0,
            ),
            _summaryRow('Service fee', '\$${_formatPrice(serviceFee)}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '\$${_formatPrice(total)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: highlight ? AppTheme.success : AppTheme.textPrimary,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _buildCheckoutBar(CartProvider cart, int subtotal, int deliveryFee,
          int serviceFee, int total) =>
      Container(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 10, AppTheme.spaceMd, 10),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
          boxShadow: AppTheme.shadowMd,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted),
                  ),
                  Text(
                    '\$${_formatPrice(total)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: AppButton(
                  label: 'Checkout',
                  trailingArrow: true,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/checkout', arguments: {
                    'merchantId': cart.merchantId,
                    'merchantName': cart.merchantName,
                    'items': cart.toOrderItems(),
                    'subtotal': subtotal,
                    'deliveryFee': deliveryFee,
                    'serviceFee': serviceFee,
                    'total': total,
                  }),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 50, color: AppTheme.primary),
              ).popIn(),
              const SizedBox(height: AppTheme.spaceLg),
              Text(
                'Your cart is empty',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                'Browse merchants and add your\nfavourite items to get started.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textMuted),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              AppButton(
                label: 'Browse Merchants',
                expand: false,
                icon: Icons.storefront_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ).fadeSlideIn(),
        ),
      );
}
