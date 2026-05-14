import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> _items;
  final _instructionsController = TextEditingController();
  bool _initialized = false;

  static const int _deliveryFee = 100;
  static const int _serviceFee = 275;

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
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
      if (args != null && args['items'] != null) {
        _items = (args['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        // Fallback demo state matching the design
        _items = [
          {
            'name': 'Full Jerk Chicken',
            'emoji': '🍗',
            'price': 1200,
            'quantity': 1,
          },
          {
            'name': 'Sorrel Punch',
            'emoji': '🥤',
            'price': 350,
            'quantity': 1,
          },
        ];
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  int get _subtotal => _items.fold(
      0,
      (sum, item) =>
          sum + (item['price'] as int) * (item['quantity'] as int));

  int get _total => _subtotal + _deliveryFee + _serviceFee;

  int get _totalItems =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  void _increment(int index) =>
      setState(() => _items[index]['quantity'] = (_items[index]['quantity'] as int) + 1);

  void _decrement(int index) {
    final qty = _items[index]['quantity'] as int;
    if (qty > 1) {
      setState(() => _items[index]['quantity'] = qty - 1);
    } else {
      setState(() => _items.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back row with cart count badge
            _buildHeader(),
            // Scrollable cart content
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Merchant label
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 3, bottom: 7),
                            child: Text(
                              '📍 Island Jerk Palace',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF999999),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          // Item cards
                          ..._items.asMap().entries.map(
                                (e) => _itemCard(e.key, e.value),
                              ),
                          // Special instructions
                          _buildInstructionsCard(),
                          // Order summary
                          _buildSummaryCard(),
                          const SizedBox(height: 2),
                          // Checkout button
                          _buildCheckoutButton(),
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

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                  child: Text('←', style: TextStyle(fontSize: 16)),
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
            if (_totalItems > 0)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$_totalItems',
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

  // ── ITEM CARD ─────────────────────────────────────────────────────────────
  Widget _itemCard(int index, Map<String, dynamic> item) => Container(
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
            Text(item['emoji'] as String,
                style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'J\$${_formatPrice(item['price'] as int)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Qty controls
            Row(
              children: [
                _qtyBtn(
                  icon: '−',
                  bgColor: const Color(0xFFF2F2F2),
                  textColor: const Color(0xFF444444),
                  onTap: () => _decrement(index),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item['quantity']}',
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
                  onTap: () => _increment(index),
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
            child: Text(
              icon,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      );

  // ── SPECIAL INSTRUCTIONS ──────────────────────────────────────────────────
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
              '✏️  SPECIAL INSTRUCTIONS',
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

  // ── ORDER SUMMARY ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() => Container(
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
            _summaryRow('Subtotal', _formatPrice(_subtotal)),
            _summaryRow('Delivery fee', _formatPrice(_deliveryFee)),
            _summaryRow('Service fee', _formatPrice(_serviceFee)),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 0),
              padding: const EdgeInsets.only(top: 9),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF2F2F2)),
                ),
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
                    'J\$${_formatPrice(_total)}',
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
            Text('J\$$value',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  // ── CHECKOUT BUTTON ───────────────────────────────────────────────────────
  Widget _buildCheckoutButton() => GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proceeding to checkout…',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(13),
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
                'J\$${_formatPrice(_total)} →',
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

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 56)),
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
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      );

  String _formatPrice(int price) {
    if (price >= 1000) {
      final thousands = price ~/ 1000;
      final hundreds = price % 1000;
      return '$thousands,${hundreds.toString().padLeft(3, '0')}';
    }
    return '$price';
  }
}
