import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MerchantMenuScreen extends StatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  int _selectedTab = 0;
  final Map<int, int> _cart = {}; // itemIndex → quantity

  final List<Map<String, String>> _tabs = const [
    {'emoji': '🔥', 'label': 'Popular'},
    {'emoji': '🍗', 'label': 'Mains'},
    {'emoji': '🥤', 'label': 'Drinks'},
  ];

  final List<Map<String, dynamic>> _menuItems = const [
    {
      'name': 'Full Jerk Chicken',
      'desc': 'Smoky, slow-cooked with festival & rice',
      'price': 1200,
      'emoji': '🍗',
      'gradStart': Color(0xFFFEE2E2),
      'gradEnd': Color(0xFFFECACA),
    },
    {
      'name': 'Curry Goat Plate',
      'desc': 'Tender curry goat, white rice & peas',
      'price': 1400,
      'emoji': '🍛',
      'gradStart': Color(0xFFFEF9C3),
      'gradEnd': Color(0xFFFEF08A),
    },
    {
      'name': 'Sorrel Punch',
      'desc': 'Iced, sweet, with ginger kick',
      'price': 350,
      'emoji': '🥤',
      'gradStart': Color(0xFFDCFCE7),
      'gradEnd': Color(0xFFBBF7D0),
    },
  ];

  int get _cartCount =>
      _cart.values.fold(0, (sum, qty) => sum + qty);

  int get _cartTotal => _cart.entries.fold(0, (sum, e) {
        final price = _menuItems[e.key]['price'] as int;
        return sum + price * e.value;
      });

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _addToCart(int index) =>
      setState(() => _cart[index] = (_cart[index] ?? 0) + 1);

  void _goToCart() {
    final cartItems = _cart.entries
        .map((e) => {
              ..._menuItems[e.key],
              'quantity': e.value,
            })
        .toList();
    Navigator.pushNamed(context, '/cart', arguments: {'items': cartItems});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          // Hero banner
          _buildHero(),
          // Info bar
          _buildInfoBar(),
          // Scrollable menu + floating cart
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 11, 10, 4),
                        child: Text(
                          '🔥 MOST ORDERED',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.dark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ..._menuItems.asMap().entries.map(
                            (e) => _menuItemCard(e.key, e.value),
                          ),
                      // Bottom padding so last item isn't hidden by float cart
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                // Floating cart bar
                if (_cartCount > 0)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: _buildFloatCart(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      height: 155,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('←', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
            // Centred emoji
            const Center(
              child: Text('🍗', style: TextStyle(fontSize: 68)),
            ),
            // Heart button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🤍', style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── INFO BAR ──────────────────────────────────────────────────────────────
  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant name
          Text(
            'Island Jerk Palace',
            style: GoogleFonts.montserrat(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 5),
          // Rating / time / status row
          Row(
            children: [
              Text('⭐ 4.8',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF777777))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text('·',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFFDDDDDD))),
              ),
              Text('25–35 min',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF777777))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text('·',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFFDDDDDD))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDFCF2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Open Now',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Category tabs
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 7),
              itemBuilder: (context, i) {
                final active = _selectedTab == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFF0F2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: active
                          ? Border.all(color: AppTheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '${_tabs[i]['emoji']} ${_tabs[i]['label']}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: active
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: active
                            ? AppTheme.primary
                            : const Color(0xFF888888),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── MENU ITEM CARD ────────────────────────────────────────────────────────
  Widget _menuItemCard(int index, Map<String, dynamic> item) {
    final qty = _cart[index] ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(11),
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
          // Food image tile
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item['gradStart'] as Color,
                  item['gradEnd'] as Color,
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                item['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 11),
          // Name / desc / price / add
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF888888),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'J\$${_formatPrice(item['price'] as int)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    // Add / qty control
                    qty == 0
                        ? GestureDetector(
                            onTap: () => _addToCart(index),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Center(
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : _qtyControl(index, qty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyControl(int index, int qty) => Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (qty > 1) {
                _cart[index] = qty - 1;
              } else {
                _cart.remove(index);
              }
            }),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text('−',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF444444))),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _addToCart(index),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Center(
                child: Text('+',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      );

  // ── FLOATING CART BAR ─────────────────────────────────────────────────────
  Widget _buildFloatCart() => GestureDetector(
        onTap: _goToCart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$_cartCount ${_cartCount == 1 ? 'item' : 'items'}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'View Cart',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'J\$${_formatPrice(_cartTotal)} →',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
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
