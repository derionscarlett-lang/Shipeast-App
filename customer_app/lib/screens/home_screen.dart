import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  String _userName = '';
  String? _avatarUrl;

  StreamSubscription<Map<String, dynamic>?>? _nameSub;

  // Firestore merchants by category index
  final Map<int, List<Map<String, dynamic>>> _firestoreMerchants = {};
  final Map<int, bool> _merchantsLoaded = {};
  final Map<int, StreamSubscription<List<Map<String, dynamic>>>> _subs = {};

  static const _categoryLabels = ['Food', 'Grocery', 'Packages', 'Pharmacy'];

  final List<Map<String, dynamic>> _categories = const [
    {'icon': Icons.restaurant_rounded, 'label': 'Food'},
    {'icon': Icons.shopping_basket_rounded, 'label': 'Grocery'},
    {'icon': Icons.inventory_2_rounded, 'label': 'Packages'},
    {'icon': Icons.local_pharmacy_rounded, 'label': 'Pharmacy'},
  ];

  static const List<Map<String, dynamic>> _packageCategories = [
    {'icon': Icons.lunch_dining_rounded, 'label': 'Food Items', 'color': Color(0xFFF97316)},
    {'icon': Icons.checkroom_rounded, 'label': 'Clothing', 'color': Color(0xFF8B5CF6)},
    {'icon': Icons.wine_bar_rounded, 'label': 'Glassware', 'color': Color(0xFF0891B2)},
    {'icon': Icons.devices_rounded, 'label': 'Electronics', 'color': Color(0xFF3B82F6)},
    {'icon': Icons.description_rounded, 'label': 'Documents', 'color': Color(0xFF10B981)},
    {'icon': Icons.inventory_2_rounded, 'label': 'Custom Package', 'color': Color(0xFF6B7280)},
  ];

  // Category gradient palettes
  static const _catGrads = <int, List<List<Color>>>{
    0: [
      [Color(0xFF7F1D1D), Color(0xFF991B1B)],
      [Color(0xFFB45309), Color(0xFFD97706)],
      [Color(0xFF92400E), Color(0xFFB45309)],
      [Color(0xFF14532D), Color(0xFF166534)],
      [Color(0xFF1E3A5F), Color(0xFF1D4ED8)],
    ],
    1: [
      [Color(0xFF064E3B), Color(0xFF065F46)],
      [Color(0xFF1F4E79), Color(0xFF2563EB)],
      [Color(0xFF15803D), Color(0xFF16A34A)],
      [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      [Color(0xFF065F46), Color(0xFF047857)],
    ],
    3: [
      [Color(0xFF1E40AF), Color(0xFF2563EB)],
      [Color(0xFF0E7490), Color(0xFF0891B2)],
      [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      [Color(0xFF6B7280), Color(0xFF4B5563)],
      [Color(0xFF14532D), Color(0xFF15803D)],
    ],
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadUserName();
    FirestoreService.seedMerchantsIfEmpty();
    _subscribeMerchants(0);
    _subscribeMerchants(1);
    _subscribeMerchants(3);
  }

  @override
  void dispose() {
    _nameSub?.cancel();
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  void _subscribeMerchants(int catIndex) {
    final label = _categoryLabels[catIndex];
    _subs[catIndex] =
        FirestoreService.merchantsByCategory(label).listen((merchants) {
      if (mounted) {
        setState(() {
          _firestoreMerchants[catIndex] = merchants;
          _merchantsLoaded[catIndex] = true;
        });
      }
    });
  }

  void _loadUserName() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _nameSub = FirestoreService.watchUserProfile(uid).listen((data) {
      if (!mounted) return;
      setState(() {
        final name = data?['name'] as String?;
        if (name != null && name.isNotEmpty) {
          _userName = name;
        }
        _avatarUrl = data?['avatarUrl'] as String?;
      });
    });
  }

  String get _firstName {
    final parts = _userName.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : _userName;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _goToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  Widget _avatarInitials() {
    final initials = _userName.isNotEmpty
        ? _userName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '';
    return Center(
      child: initials.isNotEmpty
          ? Text(initials,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white))
          : const Icon(Icons.person, size: 20, color: Colors.white),
    );
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

  // Returns null when still loading, empty list when loaded but no merchants
  List<Map<String, dynamic>>? _merchantsFor(int catIndex) {
    if (_merchantsLoaded[catIndex] != true) return null;
    return _firestoreMerchants[catIndex] ?? [];
  }

  List<Color> _gradientFor(int catIndex, int itemIndex) {
    final palette = _catGrads[catIndex] ?? _catGrads[0]!;
    return palette[itemIndex % palette.length];
  }

  IconData _merchantIcon(int catIndex) {
    switch (catIndex) {
      case 0:
        return Icons.restaurant_rounded;
      case 1:
        return Icons.shopping_basket_rounded;
      case 3:
        return Icons.local_pharmacy_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  static int _parseDeliveryFee(String s) {
    if (s.toLowerCase().contains('free')) return 0;
    final match = RegExp(r'\d+').firstMatch(s);
    return match != null ? int.tryParse(match.group(0)!) ?? 100 : 100;
  }

  void _showPackageForm(String category) {
    final pickupCtrl = TextEditingController();
    final deliveryCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool packingRequired = false;
          return Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spaceLg,
              right: AppTheme.spaceLg,
              top: AppTheme.spaceMd,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spaceLg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(
                    'New package request',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell us what to move and where — we handle the rest.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  _formLabel('ITEM CATEGORY'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_rounded, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Text(category,
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppTextField(
                    controller: pickupCtrl,
                    label: 'Pickup location',
                    hint: 'Enter pickup address',
                    prefixIcon: Icons.my_location_rounded,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppTextField(
                    controller: deliveryCtrl,
                    label: 'Delivery location',
                    hint: 'Enter delivery address',
                    prefixIcon: Icons.location_on_rounded,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppTextField(
                    controller: weightCtrl,
                    label: 'Estimated weight (kg)',
                    hint: 'e.g. 2.5',
                    prefixIcon: Icons.scale_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  _formLabel('PACKING REQUIRED'),
                  const SizedBox(height: 6),
                  StatefulBuilder(
                    builder: (ctx2, setToggle) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_rounded, size: 18, color: AppTheme.hint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                packingRequired
                                    ? 'Yes, please pack it'
                                    : 'No packing needed',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppTheme.textPrimary)),
                          ),
                          Switch(
                            value: packingRequired,
                            onChanged: (v) => setToggle(() => packingRequired = v),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppTextField(
                    controller: instructionsCtrl,
                    label: 'Special instructions',
                    hint: 'Any special handling instructions...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  AppButton(
                    label: 'Submit Request',
                    trailingArrow: true,
                    onPressed: () {
                      if (pickupCtrl.text.trim().isEmpty || deliveryCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      _showSnackbar("Package request submitted! We'll contact you shortly.");
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4),
      );

  Widget _sectionTitle(String title, {Widget? trailing}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark)),
          ?trailing,
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverseasBanner(),
                  _buildCategories(),
                  if (_selectedCategory == 2)
                    _buildPackagesGrid()
                  else
                    _buildMerchants(),
                  const SizedBox(height: AppTheme.spaceLg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          // Decorative ring echoing the auth hero.
          Positioned(
            top: -46,
            right: -36,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 26,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Color(0xCCFFFFFF)),
                                const SizedBox(width: 4),
                                Text(
                                  'St. Thomas, Jamaica',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 15,
                                    color: Colors.white.withValues(alpha: 0.8)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _userName.isEmpty
                                  ? _greeting
                                  : '$_greeting, $_firstName',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pressable(
                        onTap: _goToProfile,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.5),
                          ),
                          child: ClipOval(
                            child: _avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _avatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) => _avatarInitials(),
                                    errorWidget: (ctx, url, err) =>
                                        _avatarInitials(),
                                  )
                                : _avatarInitials(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Pressable(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              size: 20, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Search food, merchants, items…',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.hint,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverseasBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceSm),
      child: Pressable(
        onTap: () => Navigator.pushNamed(context, '/overseas-order'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.flight_takeoff_rounded,
                    size: 26, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order for family in Jamaica',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('Living overseas? Send groceries & gifts home',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.9)),
            ],
          ),
        ),
      ).fadeSlideIn(),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 8, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Categories'),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = _selectedCategory == i;
                return Pressable(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: AnimatedContainer(
                    duration: AppTheme.fast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(
                          color: active ? AppTheme.primary : AppTheme.border,
                          width: 1.5),
                      boxShadow: active ? AppTheme.shadowSm : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_categories[i]['icon'] as IconData,
                            size: 16,
                            color: active
                                ? Colors.white
                                : AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(_categories[i]['label'] as String,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: active
                                    ? Colors.white
                                    : AppTheme.textPrimary)),
                      ],
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

  Widget _buildPackagesGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 20, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Select package type'),
          const SizedBox(height: 4),
          Text('Choose what you need shipped and fill in the details.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemCount: _packageCategories.length,
            itemBuilder: (context, i) {
              final pkg = _packageCategories[i];
              final color = pkg['color'] as Color;
              return AppCard(
                onTap: () => _showPackageForm(pkg['label'] as String),
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(pkg['icon'] as IconData,
                          size: 26, color: color),
                    ),
                    const SizedBox(height: 10),
                    Text(pkg['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.dark)),
                  ],
                ),
              ).fadeSlideIn(index: i);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMerchants() {
    final merchants = _merchantsFor(_selectedCategory);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd, 20, AppTheme.spaceMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Popular near you',
            trailing: Pressable(
              onTap: () => _showSnackbar('All merchants coming soon!'),
              child: Text('See all',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary)),
            ),
          ),
          const SizedBox(height: 14),
          if (merchants == null)
            // Loading shimmer
            ...List.generate(3, (_) => _shimmerMerchantCard())
          else if (merchants.isEmpty)
            _buildMerchantsEmpty()
          else
            ...merchants
                .asMap()
                .entries
                .map((e) => _merchantCard(e.key, e.value).fadeSlideIn(index: e.key)),
        ],
      ),
    );
  }

  Widget _shimmerMerchantCard() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: double.infinity, height: 130, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 160, height: 14, radius: 5),
                  SizedBox(height: 8),
                  ShimmerBox(width: 220, height: 10, radius: 4),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildMerchantsEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 34, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No merchants available',
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
            const SizedBox(height: 4),
            Text(
              'New partners are joining soon — check back shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      );

  Widget _merchantCard(int index, Map<String, dynamic> m) {
    final grads = _gradientFor(_selectedCategory, index);
    final rating = m['rating'];
    final ratingStr = rating is double
        ? rating.toStringAsFixed(1)
        : rating?.toString() ?? '4.5';
    final isOpen = m['isOpen'] as bool? ?? true;
    final promo = m['promo'] as String?;
    final imageUrl = m['imageUrl'] as String? ?? '';

    return Pressable(
      onTap: () {
        Navigator.pushNamed(context, '/merchant', arguments: {
          'id': m['id'] ?? '',
          'name': m['name'] ?? '',
          'emoji': m['emoji'] as String? ?? '🍽️',
          'imageUrl': m['imageUrl'] as String? ?? '',
          'category': _categoryLabels[_selectedCategory],
          'rating': ratingStr,
          'deliveryTime': m['deliveryTime'] ?? '25–35 min',
          'deliveryFee': m['deliveryFee'] ?? 'Free delivery',
          'deliveryFeeAmount': _parseDeliveryFee(m['deliveryFee'] as String? ?? ''),
          'isOpen': isOpen,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background: image or gradient fallback
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => const ShimmerBox(
                            width: double.infinity,
                            height: 130,
                            radius: 0,
                          ),
                          errorWidget: (ctx, url, err) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: grads,
                              ),
                            ),
                            child: Center(
                              child: Icon(_merchantIcon(_selectedCategory),
                                  size: 46,
                                  color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: grads,
                            ),
                          ),
                          child: Center(
                            child: Icon(_merchantIcon(_selectedCategory),
                                size: 46,
                                color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ),
                  // Scrim so text/badges remain readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  if (promo != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: StatusBadge(label: promo, filled: true),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Pressable(
                      onTap: () => _showSnackbar('Added to favourites!'),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.shadowSm),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 18, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(m['name'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.dark)),
                      ),
                      const SizedBox(width: 8),
                      _ratingChip(ratingStr),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(m['deliveryTime'] as String? ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary)),
                      _dot(),
                      const Icon(Icons.pedal_bike_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(m['deliveryFee'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: isOpen ? 'Open' : 'Closed',
                        color: isOpen ? AppTheme.success : AppTheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingChip(String rating) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 13, color: AppTheme.gold),
            const SizedBox(width: 2),
            Text(rating,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark)),
          ],
        ),
      );

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Text('·',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.border)),
      );
}
