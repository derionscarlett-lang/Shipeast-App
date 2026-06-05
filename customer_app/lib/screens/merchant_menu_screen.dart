import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class MerchantMenuScreen extends StatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  // Merchant info from route args
  String _merchantId = '';
  String _merchantName = 'Merchant';
  String _merchantEmoji = '🍽️';
  String _merchantRating = '4.5';
  String _merchantDeliveryTime = '25–35 min';
  String _merchantDeliveryFee = 'Free delivery';
  int _merchantDeliveryFeeAmount = 0;
  bool _merchantIsOpen = true;
  String _merchantCategory = 'Food';

  // Menu items from Firestore
  List<Map<String, dynamic>> _menuItems = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  // Selected tab: 0 = Popular (all), then per-category tabs
  int _selectedTab = 0;

  // Cart: itemId -> quantity
  final Map<String, int> _cart = {};

  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
        _merchantId = args['id'] as String? ?? '';
        _merchantName = args['name'] as String? ?? 'Merchant';
        _merchantEmoji = args['emoji'] as String? ?? '🍽️';
        _merchantRating = args['rating'] as String? ?? '4.5';
        _merchantDeliveryTime = args['deliveryTime'] as String? ?? '25–35 min';
        _merchantDeliveryFee = args['deliveryFee'] as String? ?? 'Free delivery';
        _merchantDeliveryFeeAmount = args['deliveryFeeAmount'] as int? ?? 0;
        _merchantIsOpen = args['isOpen'] as bool? ?? true;
        _merchantCategory = args['category'] as String? ?? 'Food';
      }
      _subscribeMenuItems();
    }
  }

  void _subscribeMenuItems() {
    if (_merchantId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    _sub = FirestoreService.menuItemsStream(_merchantId).listen((items) {
      if (mounted) {
        setState(() {
          _menuItems = items;
          _loading = false;
        });
      }
    }, onError: (_) {
      if (mounted) { setState(() => _loading = false); }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Unique category tabs derived from loaded items
  List<String> get _categoryTabs {
    final seen = <String>{};
    final cats = <String>[];
    for (final item in _menuItems) {
      final c = item['category'] as String? ?? '';
      if (c.isNotEmpty && seen.add(c)) cats.add(c);
    }
    return cats;
  }

  // Tab labels: "Popular" first, then each category capitalized
  List<String> get _tabLabels {
    return ['Popular', ..._categoryTabs.map(_capitalize)];
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<Map<String, dynamic>> get _visibleItems {
    if (_selectedTab == 0) return _menuItems;
    final cat = _categoryTabs[_selectedTab - 1];
    return _menuItems.where((i) => i['category'] == cat).toList();
  }

  int get _cartCount =>
      _cart.values.fold(0, (sum, qty) => sum + qty);

  int get _cartTotal {
    int total = 0;
    for (final entry in _cart.entries) {
      final item = _menuItems.firstWhere(
        (m) => m['id'] == entry.key,
        orElse: () => {},
      );
      if (item.isEmpty) continue;
      total += ((item['price'] as num?)?.toInt() ?? 0) * entry.value;
    }
    return total;
  }

  void _addToCart(String itemId) =>
      setState(() => _cart[itemId] = (_cart[itemId] ?? 0) + 1);

  void _removeFromCart(String itemId) {
    final qty = _cart[itemId] ?? 0;
    setState(() {
      if (qty > 1) {
        _cart[itemId] = qty - 1;
      } else {
        _cart.remove(itemId);
      }
    });
  }

  void _goToCart() {
    final cartItems = _cart.entries.map((e) {
      final item = _menuItems.firstWhere(
        (m) => m['id'] == e.key,
        orElse: () => {},
      );
      if (item.isEmpty) return null;
      return <String, dynamic>{
        'id': e.key,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'quantity': e.value,
      };
    }).whereType<Map<String, dynamic>>().toList();

    Navigator.pushNamed(context, '/cart', arguments: {
      'items': cartItems,
      'merchantId': _merchantId,
      'merchantName': _merchantName,
      'deliveryFeeAmount': _merchantDeliveryFeeAmount,
    });
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── Gradient for hero banner based on category ───────────────────────────

  static const _categoryGradients = <String, List<Color>>{
    'Food': [Color(0xFF7F1D1D), Color(0xFF991B1B)],
    'Grocery': [Color(0xFF064E3B), Color(0xFF065F46)],
    'Pharmacy': [Color(0xFF1E40AF), Color(0xFF2563EB)],
  };

  List<Color> get _heroGradient =>
      _categoryGradients[_merchantCategory] ??
      const [Color(0xFF374151), Color(0xFF1F2937)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildHero(),
          _buildInfoBar(),
          Expanded(
            child: Stack(
              children: [
                _loading
                    ? _buildShimmerList()
                    : _menuItems.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 11, 10, 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_fire_department,
                                          size: 14, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedTab == 0
                                            ? 'MOST ORDERED'
                                            : _tabLabels[_selectedTab].toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.dark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ..._visibleItems.map(_menuItemCard),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
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

  Widget _buildHero() {
    return Container(
      height: 155,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _heroGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
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
                    child: Icon(Icons.arrow_back_ios,
                        size: 16, color: Color(0xFF333333)),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(_merchantEmoji,
                      style: const TextStyle(fontSize: 42)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => _showSnackbar('Added to favourites!'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite_border,
                        size: 16, color: Color(0xFF888888)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    final tabs = _tabLabels;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _merchantName,
            style: GoogleFonts.montserrat(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.star, size: 11, color: Color(0xFFFACC15)),
              Text(' $_merchantRating',
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
              Text(_merchantDeliveryTime,
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
              Text(_merchantDeliveryFee,
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
                  color: _merchantIsOpen
                      ? const Color(0xFFEDFCF2)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _merchantIsOpen ? 'Open Now' : 'Closed',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _merchantIsOpen
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          if (tabs.length > 1) ...[
            const SizedBox(height: 9),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, i) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
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
                        tabs[i],
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
        ],
      ),
    );
  }

  Widget _menuItemCard(Map<String, dynamic> item) {
    final itemId = item['id'] as String? ?? '';
    final qty = _cart[itemId] ?? 0;
    final price = (item['price'] as num?)?.toInt() ?? 0;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 68,
              height: 68,
              color: const Color(0xFFF0F0F0),
              child: const Icon(Icons.restaurant,
                  size: 30, color: Color(0xFFBBBBBB)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['description'] as String? ?? '',
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
                      'J\$${_formatPrice(price)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    qty == 0
                        ? GestureDetector(
                            onTap: () => _addToCart(itemId),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Center(
                                child: Text('+',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1)),
                              ),
                            ),
                          )
                        : _qtyControl(itemId, qty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyControl(String itemId, int qty) => Row(
        children: [
          GestureDetector(
            onTap: () => _removeFromCart(itemId),
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
            child: Text('$qty',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark)),
          ),
          GestureDetector(
            onTap: () => _addToCart(itemId),
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

  Widget _buildFloatCart() => GestureDetector(
        onTap: _goToCart,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                    color: Colors.white),
              ),
              Text(
                'J\$${_formatPrice(_cartTotal)} →',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      );

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 80),
      itemCount: 4,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            const SizedBox(width: 11),
            _ShimmerBox(width: 68, height: 68, radius: 11),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 140, height: 13, radius: 6),
                  const SizedBox(height: 7),
                  _ShimmerBox(width: 100, height: 10, radius: 5),
                  const SizedBox(height: 10),
                  _ShimmerBox(width: 60, height: 13, radius: 6),
                ],
              ),
            ),
            const SizedBox(width: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu,
                size: 52, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(
              'No menu items yet',
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
            const SizedBox(height: 5),
            Text(
              'Check back soon',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF888888)),
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

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox(
      {required this.width, required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFDDDDDD),
              Color(0xFFEEEEEE),
            ],
          ),
        ),
      ),
    );
  }
}
