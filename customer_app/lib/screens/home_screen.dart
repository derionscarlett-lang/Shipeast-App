import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  String _userName = 'Marcus Brown';
  String? _avatarPath;

  static const _keyName = 'shipeast_user_name';
  static const _keyAvatar = 'shipeast_avatar_path';

  final List<Map<String, dynamic>> _categories = const [
    {'icon': Icons.restaurant, 'label': 'Food'},
    {'icon': Icons.shopping_cart, 'label': 'Grocery'},
    {'icon': Icons.inventory_2, 'label': 'Packages'},
    {'icon': Icons.local_pharmacy, 'label': 'Pharmacy'},
  ];

  static const List<Map<String, dynamic>> _packageCategories = [
    {'emoji': '🍗', 'label': 'Food Items', 'color': Color(0xFFF97316)},
    {'emoji': '👕', 'label': 'Clothing', 'color': Color(0xFF8B5CF6)},
    {'emoji': '🥂', 'label': 'Glassware', 'color': Color(0xFF0891B2)},
    {'emoji': '📱', 'label': 'Electronics', 'color': Color(0xFF3B82F6)},
    {'emoji': '📄', 'label': 'Documents', 'color': Color(0xFF10B981)},
    {'emoji': '📦', 'label': 'Custom Package', 'color': Color(0xFF6B7280)},
  ];

  static const Map<int, List<Map<String, dynamic>>> _categoryMerchants = {
    0: [
      {
        'name': 'Island Jerk Palace',
        'emoji': '🍗',
        'rating': '4.8',
        'time': '25–35 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': '🔥 Popular',
        'gradStart': Color(0xFF7F1D1D),
        'gradEnd': Color(0xFF991B1B),
      },
      {
        'name': 'Kingston Eats',
        'emoji': '🍽️',
        'rating': '4.5',
        'time': '20–30 min',
        'delivery': 'J\$100 delivery',
        'open': true,
        'promo': null,
        'gradStart': Color(0xFFB45309),
        'gradEnd': Color(0xFFD97706),
      },
      {
        'name': "Mama's Kitchen",
        'emoji': '🥘',
        'rating': '4.7',
        'time': '30–45 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': '❤️ Local Fave',
        'gradStart': Color(0xFF92400E),
        'gradEnd': Color(0xFFB45309),
      },
      {
        'name': 'Rasta Pasta',
        'emoji': '🍝',
        'rating': '4.3',
        'time': '25–40 min',
        'delivery': 'J\$150 delivery',
        'open': false,
        'promo': null,
        'gradStart': Color(0xFF14532D),
        'gradEnd': Color(0xFF166534),
      },
      {
        'name': 'Seafood Shack',
        'emoji': '🦞',
        'rating': '4.9',
        'time': '35–50 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': '⭐ Top Rated',
        'gradStart': Color(0xFF1E3A5F),
        'gradEnd': Color(0xFF1D4ED8),
      },
    ],
    1: [
      {
        'name': 'FreshMart',
        'emoji': '🛒',
        'rating': '4.6',
        'time': '20–30 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': null,
        'gradStart': Color(0xFF064E3B),
        'gradEnd': Color(0xFF065F46),
      },
      {
        'name': 'SaveMore Supermarket',
        'emoji': '🏪',
        'rating': '4.4',
        'time': '30–45 min',
        'delivery': 'J\$150 delivery',
        'open': true,
        'promo': '💰 Best Value',
        'gradStart': Color(0xFF1F4E79),
        'gradEnd': Color(0xFF2563EB),
      },
      {
        'name': 'Green Valley Farms',
        'emoji': '🥬',
        'rating': '4.7',
        'time': '25–35 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': '🌿 Organic',
        'gradStart': Color(0xFF15803D),
        'gradEnd': Color(0xFF16A34A),
      },
      {
        'name': 'Daily Essentials',
        'emoji': '🧴',
        'rating': '4.2',
        'time': '15–25 min',
        'delivery': 'J\$100 delivery',
        'open': true,
        'promo': null,
        'gradStart': Color(0xFF7C3AED),
        'gradEnd': Color(0xFF6D28D9),
      },
      {
        'name': 'Farm Fresh',
        'emoji': '🥑',
        'rating': '4.5',
        'time': '20–30 min',
        'delivery': 'Free delivery',
        'open': false,
        'promo': null,
        'gradStart': Color(0xFF065F46),
        'gradEnd': Color(0xFF047857),
      },
    ],
    2: [],
    3: [
      {
        'name': 'PharmaCare Rx',
        'emoji': '💊',
        'rating': '4.8',
        'time': '20–30 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': '🏥 Certified',
        'gradStart': Color(0xFF1E40AF),
        'gradEnd': Color(0xFF2563EB),
      },
      {
        'name': 'MedPlus Pharmacy',
        'emoji': '🩺',
        'rating': '4.5',
        'time': '25–35 min',
        'delivery': 'J\$100 delivery',
        'open': true,
        'promo': null,
        'gradStart': Color(0xFF0E7490),
        'gradEnd': Color(0xFF0891B2),
      },
      {
        'name': 'HealthFirst',
        'emoji': '🌡️',
        'rating': '4.6',
        'time': '15–25 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': '⚡ Fast',
        'gradStart': Color(0xFF7C3AED),
        'gradEnd': Color(0xFF8B5CF6),
      },
      {
        'name': 'CityDrug',
        'emoji': '💉',
        'rating': '4.3',
        'time': '30–40 min',
        'delivery': 'J\$150 delivery',
        'open': false,
        'promo': null,
        'gradStart': Color(0xFF6B7280),
        'gradEnd': Color(0xFF4B5563),
      },
      {
        'name': 'Wellness Plus',
        'emoji': '🌿',
        'rating': '4.7',
        'time': '20–30 min',
        'delivery': 'Free delivery',
        'open': true,
        'promo': null,
        'gradStart': Color(0xFF14532D),
        'gradEnd': Color(0xFF15803D),
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString(_keyName) ?? 'Marcus Brown';
      _avatarPath = prefs.getString(_keyAvatar);
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
    Navigator.pushNamed(context, '/profile').then((_) => _loadProfile());
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

  void _showPackageForm(String category) {
    final pickupCtrl = TextEditingController();
    final deliveryCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool packingRequired = false;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Package Request',
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the details below to submit your package request.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _formLabel('Item Category'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFEBEBEB), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2,
                            size: 17, color: Color(0xFF888888)),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _formLabel('Pickup Location'),
                  const SizedBox(height: 6),
                  _formField(pickupCtrl, 'Enter pickup address',
                      Icons.my_location, TextInputType.streetAddress),
                  const SizedBox(height: 14),
                  _formLabel('Delivery Location'),
                  const SizedBox(height: 6),
                  _formField(deliveryCtrl, 'Enter delivery address',
                      Icons.location_on, TextInputType.streetAddress),
                  const SizedBox(height: 14),
                  _formLabel('Estimated Weight (kg)'),
                  const SizedBox(height: 6),
                  _formField(weightCtrl, 'e.g. 2.5', Icons.scale,
                      const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 14),
                  _formLabel('Packing Required'),
                  const SizedBox(height: 6),
                  StatefulBuilder(
                    builder: (ctx2, setToggle) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFEBEBEB), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory,
                              size: 17, color: Color(0xFF888888)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              packingRequired ? 'Yes' : 'No',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF333333)),
                            ),
                          ),
                          Switch(
                            value: packingRequired,
                            onChanged: (v) =>
                                setToggle(() => packingRequired = v),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _formLabel('Special Instructions'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: instructionsCtrl,
                    minLines: 2,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF333333)),
                    decoration: InputDecoration(
                      hintText: 'Any special handling instructions...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFFBBBBBB)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFEBEBEB), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFEBEBEB), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 12),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () {
                      if (pickupCtrl.text.trim().isEmpty ||
                          deliveryCtrl.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(ctx);
                      _showSnackbar(
                          'Package request submitted! We\'ll contact you shortly.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit Request',
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF666666),
        ),
      );

  Widget _formField(TextEditingController ctrl, String hint, IconData icon,
      TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style:
          GoogleFonts.inter(fontSize: 13, color: const Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBBBBB)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, size: 17, color: const Color(0xFF888888)),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        isDense: true,
      ),
    );
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
                  if (_selectedCategory == 2)
                    _buildPackagesGrid()
                  else
                    _buildMerchants(),
                  const SizedBox(height: 16),
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
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Color(0xB3FFFFFF)),
                            const SizedBox(width: 3),
                            Text(
                              'St. Thomas, Jamaica',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_greeting, $_firstName 👋',
                          style: GoogleFonts.montserrat(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToProfile,
                    child: Container(
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
                      child: ClipOval(
                        child: _avatarPath != null
                            ? Image.file(
                                File(_avatarPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Center(
                                  child: Icon(Icons.person,
                                      size: 20, color: Colors.white),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.person,
                                    size: 20, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          size: 18, color: Color(0xFFBDBDBD)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverseasBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/overseas-order'),
      child: Container(
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
            const Icon(Icons.flight, size: 28, color: Colors.white),
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
                    'Living overseas? Send groceries & gifts home',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

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
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categories[i]['icon'] as IconData,
                          size: 14,
                          color: active
                              ? AppTheme.primary
                              : const Color(0xFF555555),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _categories[i]['label'] as String,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: active
                                ? AppTheme.primary
                                : const Color(0xFF333333),
                          ),
                        ),
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Package Type',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose what you need shipped and fill in the details.',
            style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF888888)),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: _packageCategories.length,
            itemBuilder: (context, i) {
              final pkg = _packageCategories[i];
              final color = pkg['color'] as Color;
              return GestureDetector(
                onTap: () =>
                    _showPackageForm(pkg['label'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            pkg['emoji'] as String,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pkg['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMerchants() {
    final merchants =
        _categoryMerchants[_selectedCategory] ?? [];
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
              GestureDetector(
                onTap: () =>
                    _showSnackbar('All merchants coming soon!'),
                child: Text(
                  'See all',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...merchants.map(_merchantCard),
        ],
      ),
    );
  }

  Widget _merchantCard(Map<String, dynamic> m) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/merchant'),
      child: Container(
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
                  Center(
                    child: Text(
                      m['emoji'] as String,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: GestureDetector(
                      onTap: () =>
                          _showSnackbar('Added to favourites!'),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
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
                      _ratingChip(m['rating'] as String),
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
      ),
    );
  }

  Widget _ratingChip(String rating) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 11, color: Color(0xFFFACC15)),
          Text(
            ' $rating',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      );

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
            fontSize: 10, color: const Color(0xFFDDDDDD)),
      );

  Widget _statusBadge(bool open) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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

}
