import 'package:cached_network_image/cached_network_image.dart';
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
  final Map<int, int> _cart = {};

  static const _tabs = [
    {'label': 'Popular', 'cat': 'all'},
    {'label': 'Mains', 'cat': 'mains'},
    {'label': 'Drinks', 'cat': 'drinks'},
  ];

  static const List<Map<String, dynamic>> _allItems = [
    {
      'name': 'Full Jerk Chicken',
      'desc': 'Smoky, slow-cooked with festival & rice',
      'price': 1200,
      'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76538591398?w=300',
      'cat': 'mains',
    },
    {
      'name': 'Curry Goat Plate',
      'desc': 'Tender curry goat, white rice & peas',
      'price': 1400,
      'imageUrl': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=300',
      'cat': 'mains',
    },
    {
      'name': 'Rice & Peas Plate',
      'desc': 'Jamaican staple — seasoned rice & kidney peas',
      'price': 800,
      'imageUrl': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=300',
      'cat': 'mains',
    },
    {
      'name': 'Sorrel Punch',
      'desc': 'Iced, sweet, with ginger kick',
      'price': 350,
      'imageUrl': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=300',
      'cat': 'drinks',
    },
  ];

  List<Map<String, dynamic>> get _visibleItems {
    final cat = _tabs[_selectedTab]['cat'];
    if (cat == 'all') return _allItems;
    return _allItems.where((item) => item['cat'] == cat).toList();
  }

  int get _cartCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  int get _cartTotal => _cart.entries.fold(0, (sum, e) {
        final price = _allItems[e.key]['price'] as int;
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
        .map((e) => {..._allItems[e.key], 'quantity': e.value})
        .toList();
    Navigator.pushNamed(context, '/cart', arguments: {'items': cartItems});
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

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
                SingleChildScrollView(
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
                              'MOST ORDERED',
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
                      ..._visibleItems.map((item) {
                        final index = _allItems.indexOf(item);
                        return _menuItemCard(index, item);
                      }),
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
                    child: Icon(Icons.arrow_back_ios, size: 16,
                        color: Color(0xFF333333)),
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
                child: const Center(
                  child: Icon(Icons.restaurant,
                      size: 44, color: Colors.white),
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
                    child: Icon(Icons.favorite_border, size: 16,
                        color: Color(0xFF888888)),
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
            'Island Jerk Palace',
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
              Text(' 4.8',
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
                      _tabs[i]['label']!,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight:
                            active ? FontWeight.w900 : FontWeight.w700,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 68,
              height: 68,
              child: CachedNetworkImage(
                imageUrl: item['imageUrl'] as String,
                fit: BoxFit.cover,
                placeholder: (_, _) => _ShimmerBox(
                    width: 68, height: 68, radius: 11),
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.restaurant,
                      size: 30, color: Color(0xFFBBBBBB)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
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
                                child: Text('+',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1)),
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
            child: Text('$qty',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark)),
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
      builder: (_, _) => Container(
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
