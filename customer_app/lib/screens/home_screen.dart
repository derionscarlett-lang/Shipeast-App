import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  int _selectedNav = 0;

  final List<Map<String, String>> _categories = const [
    {'emoji': '🍔', 'label': 'Food'},
    {'emoji': '🛒', 'label': 'Grocery'},
    {'emoji': '📦', 'label': 'Packages'},
    {'emoji': '💊', 'label': 'Pharmacy'},
  ];

  final List<Map<String, dynamic>> _merchants = const [
    {
      'name': 'Island Jerk Palace',
      'emoji': '🍗',
      'rating': '4.8',
      'time': '25–35 min',
      'delivery': 'J\$0 delivery',
      'open': true,
      'promo': '🔥 Popular',
      'gradStart': Color(0xFF7F1D1D),
      'gradEnd': Color(0xFF991B1B),
    },
    {
      'name': 'FreshMart Grocery',
      'emoji': '🛒',
      'rating': '4.6',
      'time': '20–30 min',
      'delivery': 'J\$0 delivery',
      'open': true,
      'promo': null,
      'gradStart': Color(0xFF064E3B),
      'gradEnd': Color(0xFF065F46),
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOverseasBanner(),
                  _buildCategories(),
                  _buildMerchants(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── RED HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppTheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 St. Thomas, Jamaica',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Good morning, Marcus 👋',
                          style: GoogleFonts.montserrat(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              // Search bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 9),
                    Text(
                      'Search food, merchants, items...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── OVERSEAS BANNER ─────────────────────────────────────────────────────────
  Widget _buildOverseasBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/overseas-order'),
      child: _overseasBannerInner(),
    );
  }

  Widget _overseasBannerInner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('✈️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order for Family in Jamaica',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Diaspora? Send groceries & gifts home',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '›',
            style: GoogleFonts.inter(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORIES ──────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = _selectedCategory == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFF0F2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: active
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_categories[i]['emoji']} ${_categories[i]['label']}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: active
                            ? AppTheme.primary
                            : const Color(0xFF333333),
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

  // ── MERCHANT CARDS ──────────────────────────────────────────────────────────
  Widget _buildMerchants() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Near You',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark,
                ),
              ),
              Text(
                'See all',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ..._merchants.map(_merchantCard),
        ],
      ),
    );
  }

  Widget _merchantCard(Map<String, dynamic> m) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/merchant'),
      child: _merchantCardInner(m),
    );
  }

  Widget _merchantCardInner(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Gradient banner
          SizedBox(
            height: 115,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        m['gradStart'] as Color,
                        m['gradEnd'] as Color,
                      ],
                    ),
                  ),
                ),
                // Promo badge
                if (m['promo'] != null)
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        m['promo'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Centered emoji
                Center(
                  child: Text(
                    m['emoji'] as String,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
                // Favourite heart
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
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
          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['name'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip('⭐ ${m['rating']}'),
                    _dot(),
                    _chip(m['time'] as String),
                    _dot(),
                    _chip(m['delivery'] as String),
                    _statusBadge(m['open'] as bool),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF777777),
        ),
      );

  Widget _dot() => Text(
        '·',
        style: GoogleFonts.inter(
          fontSize: 10,
          color: const Color(0xFFDDDDDD),
        ),
      );

  Widget _statusBadge(bool open) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: open
              ? const Color(0xFFEDFCF2)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          open ? 'Open' : 'Closed',
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: open
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
        ),
      );

  // ── BOTTOM NAV ──────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': '🏠', 'label': 'Home'},
      {'icon': '🔍', 'label': 'Search'},
      {'icon': '📦', 'label': 'Orders'},
      {'icon': '👤', 'label': 'Profile'},
    ];
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = _selectedNav == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedNav = i);
                if (i == 2) Navigator.pushNamed(context, '/order-history');
                if (i == 3) Navigator.pushNamed(context, '/profile');
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    items[i]['icon']!,
                    style: const TextStyle(fontSize: 20, height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i]['label']!,
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppTheme.primary
                          : const Color(0xFFC0C0C0),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
