import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/widgets.dart';

class MerchantMenuScreen extends StatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  // Merchant info from route args
  String _merchantId = '';
  String _merchantName = 'Merchant';
  String _merchantImageUrl = '';
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

  int _selectedTab = 0;
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
        _merchantImageUrl = args['imageUrl'] as String? ?? '';
        _merchantRating = args['rating'] as String? ?? '4.5';
        _merchantDeliveryTime = args['deliveryTime'] as String? ?? '25–35 min';
        _merchantDeliveryFee = args['deliveryFee'] as String? ?? 'Free delivery';
        _merchantDeliveryFeeAmount = args['deliveryFeeAmount'] as int? ?? 0;
        _merchantIsOpen = args['isOpen'] as bool? ?? true;
        _merchantCategory = args['category'] as String? ?? 'Food';
      }
      _subscribeMenuItems();

      final cart = Provider.of<CartProvider>(context, listen: false);
      if (cart.cartCount > 0 &&
          cart.merchantId.isNotEmpty &&
          cart.merchantId != _merchantId &&
          _merchantId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              title: Text('Start new order?',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
              content: Text(
                'Your cart has items from ${cart.merchantName}. Clear cart to order from $_merchantName?',
                style: GoogleFonts.inter(fontSize: 13, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Keep Cart',
                      style: GoogleFonts.nunito(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () {
                    cart.clearCart();
                    cart.setMerchant(
                        _merchantId, _merchantName, _merchantDeliveryFeeAmount);
                    Navigator.pop(context);
                  },
                  child: Text('Clear & Start New',
                      style: GoogleFonts.nunito(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          );
        });
      } else {
        cart.setMerchant(_merchantId, _merchantName, _merchantDeliveryFeeAmount);
      }
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
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<String> get _categoryTabs {
    final seen = <String>{};
    final cats = <String>[];
    for (final item in _menuItems) {
      final c = item['category'] as String? ?? '';
      if (c.isNotEmpty && seen.add(c)) cats.add(c);
    }
    return cats;
  }

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

  void _addToCart(Map<String, dynamic> item) {
    final cart = context.read<CartProvider>();
    final itemId = item['id'] as String? ?? '';
    if (itemId.isEmpty) return;
    cart.addItem(CartItem(
      id: itemId,
      name: item['name'] as String? ?? '',
      description: item['description'] as String? ?? '',
      price: (item['price'] as num?)?.toInt() ?? 0,
      imageUrl: item['imageUrl'] as String? ?? '',
      quantity: 1,
    ));
  }

  void _removeFromCart(String itemId) {
    context.read<CartProvider>().removeItem(itemId);
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

  static const _categoryGradients = <String, List<Color>>{
    'Food': [Color(0xFF7F1D1D), Color(0xFF991B1B)],
    'Grocery': [Color(0xFF064E3B), Color(0xFF065F46)],
    'Pharmacy': [Color(0xFF1E40AF), Color(0xFF2563EB)],
  };

  List<Color> get _heroGradient =>
      _categoryGradients[_merchantCategory] ??
      const [Color(0xFF374151), Color(0xFF1F2937)];

  IconData get _categoryIcon {
    switch (_merchantCategory) {
      case 'Grocery':
        return Icons.shopping_basket_rounded;
      case 'Pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'Packages':
        return Icons.inventory_2_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: cart.cartCount > 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              elevation: 4,
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      color: Colors.white, size: 22),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: CountBadge(
                      count: cart.cartCount,
                      color: Colors.white,
                      textColor: AppTheme.primary,
                      borderColor: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ).popIn()
          : null,
      body: Column(
        children: [
          _buildHero(),
          _buildInfoBar(),
          Expanded(
            child: _loading
                ? _buildShimmerList()
                : _menuItems.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AppTheme.spaceMd, 16, AppTheme.spaceMd, 6),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 16,
                                      color: AppTheme.warning),
                                  const SizedBox(width: 5),
                                  Text(
                                    _selectedTab == 0
                                        ? 'MOST ORDERED'
                                        : _tabLabels[_selectedTab]
                                            .toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.dark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._visibleItems
                                .asMap()
                                .entries
                                .map((e) =>
                                    _menuItemCard(e.value, cart)
                                        .fadeSlideIn(index: e.key)),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _merchantImageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _merchantImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => _heroGradientBox(),
                  errorWidget: (ctx, url, err) => _heroGradientBox(),
                )
              : _heroGradientBox(),
          // Scrim for control legibility.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          _heroContent(),
        ],
      ),
    );
  }

  Widget _heroGradientBox() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _heroGradient,
          ),
        ),
        child: _merchantImageUrl.isEmpty
            ? Center(
                child: Icon(_categoryIcon,
                    size: 64, color: Colors.white.withValues(alpha: 0.9)),
              )
            : null,
      );

  Widget _heroContent() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.shadowSm,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 15, color: AppTheme.textPrimary),
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: () => _showSnackbar('Added to favourites!'),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.shadowSm,
                ),
                child: const Icon(Icons.favorite_border_rounded,
                    size: 18, color: AppTheme.primary),
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
      transform: Matrix4.translationValues(0, -20, 0),
      margin: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 0, AppTheme.spaceMd, -20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _merchantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: _merchantIsOpen ? 'Open Now' : 'Closed',
                color: _merchantIsOpen ? AppTheme.success : AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip(Icons.star_rounded, _merchantRating,
                  iconColor: AppTheme.gold),
              const SizedBox(width: 8),
              _infoChip(Icons.access_time_rounded, _merchantDeliveryTime),
              const SizedBox(width: 8),
              Flexible(
                child: _infoChip(
                    Icons.pedal_bike_rounded, _merchantDeliveryFee),
              ),
            ],
          ),
          if (tabs.length > 1) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: tabs.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _selectedTab == i;
                  return Pressable(
                    onTap: () => setState(() => _selectedTab = i),
                    child: AnimatedContainer(
                      duration: AppTheme.fast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary : AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      child: Text(
                        tabs[i],
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w900 : FontWeight.w700,
                          color:
                              active ? Colors.white : AppTheme.textSecondary,
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

  Widget _infoChip(IconData icon, String label, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? AppTheme.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItemCard(Map<String, dynamic> item, CartProvider cart) {
    final itemId = item['id'] as String? ?? '';
    final qty = cart.items[itemId]?.quantity ?? 0;
    final price = (item['price'] as num?)?.toInt() ?? 0;
    final imageUrl = item['imageUrl'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 0, AppTheme.spaceMd, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              width: 74,
              height: 74,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => const ShimmerBox(
                          width: 74, height: 74, radius: AppTheme.radiusMd),
                      errorWidget: (ctx, url, err) => _itemFallback(),
                    )
                  : _itemFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['description'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_formatPrice(price)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    qty == 0
                        ? Pressable(
                            onTap: () => _addToCart(item),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 20),
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

  Widget _itemFallback() => Container(
        color: AppTheme.primaryLight,
        child: Icon(_categoryIcon, size: 32, color: AppTheme.primary),
      );

  Widget _qtyControl(String itemId, int qty) => Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Pressable(
              onTap: () => _removeFromCart(itemId),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                child: const Icon(Icons.remove_rounded,
                    size: 18, color: AppTheme.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('$qty',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark)),
            ),
            Pressable(
              onTap: () => _addToCart(_menuItems
                  .firstWhere((m) => m['id'] == itemId, orElse: () => {})),
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.add_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 16, AppTheme.spaceMd, 90),
      itemCount: 4,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 98,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 74, height: 74, radius: AppTheme.radiusMd),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 140, height: 13, radius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 10, radius: 5),
                  SizedBox(height: 12),
                  ShimmerBox(width: 60, height: 14, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu_rounded,
                    size: 40, color: AppTheme.primary),
              ).popIn(),
              const SizedBox(height: 16),
              Text(
                'No menu items yet',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark),
              ),
              const SizedBox(height: 5),
              Text(
                'This merchant is still setting up — check back soon.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMuted),
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
