import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const List<Map<String, String>> _allMerchants = [
    {'name': 'Island Jerk Palace', 'category': 'Food', 'emoji': '🍗', 'rating': '4.8', 'time': '25–35 min'},
    {'name': 'Kingston Eats', 'category': 'Food', 'emoji': '🍽️', 'rating': '4.5', 'time': '20–30 min'},
    {'name': "Mama's Kitchen", 'category': 'Food', 'emoji': '🥘', 'rating': '4.7', 'time': '30–45 min'},
    {'name': 'Rasta Pasta', 'category': 'Food', 'emoji': '🍝', 'rating': '4.3', 'time': '25–40 min'},
    {'name': 'Seafood Shack', 'category': 'Food', 'emoji': '🦞', 'rating': '4.9', 'time': '35–50 min'},
    {'name': 'FreshMart', 'category': 'Grocery', 'emoji': '🛒', 'rating': '4.6', 'time': '20–30 min'},
    {'name': 'SaveMore Supermarket', 'category': 'Grocery', 'emoji': '🏪', 'rating': '4.4', 'time': '30–45 min'},
    {'name': 'Green Valley Farms', 'category': 'Grocery', 'emoji': '🥬', 'rating': '4.7', 'time': '25–35 min'},
    {'name': 'Daily Essentials', 'category': 'Grocery', 'emoji': '🧴', 'rating': '4.2', 'time': '15–25 min'},
    {'name': 'Farm Fresh', 'category': 'Grocery', 'emoji': '🥑', 'rating': '4.5', 'time': '20–30 min'},
    {'name': 'PharmaCare Rx', 'category': 'Pharmacy', 'emoji': '💊', 'rating': '4.8', 'time': '20–30 min'},
    {'name': 'MedPlus Pharmacy', 'category': 'Pharmacy', 'emoji': '🩺', 'rating': '4.5', 'time': '25–35 min'},
    {'name': 'HealthFirst', 'category': 'Pharmacy', 'emoji': '🌡️', 'rating': '4.6', 'time': '15–25 min'},
    {'name': 'CityDrug', 'category': 'Pharmacy', 'emoji': '💉', 'rating': '4.3', 'time': '30–40 min'},
    {'name': 'Wellness Plus', 'category': 'Pharmacy', 'emoji': '🌿', 'rating': '4.7', 'time': '20–30 min'},
  ];

  List<Map<String, String>> get _filtered {
    if (_query.trim().isEmpty) return const [];
    final q = _query.toLowerCase();
    return _allMerchants
        .where((m) =>
            m['name']!.toLowerCase().contains(q) ||
            m['category']!.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _query.trim().isEmpty
                ? _buildEmptyState()
                : results.isEmpty
                    ? _buildNoResults()
                    : _buildResults(results),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
        color: AppTheme.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
            child: Row(
              children: [
                if (Navigator.canPop(context)) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF333333)),
                      decoration: InputDecoration(
                        hintText: 'Search merchants, food, items...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFFBDBDBD)),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Color(0xFFBDBDBD)),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _ctrl.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(Icons.close,
                                    size: 16, color: Color(0xFFBDBDBD)),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 70, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 18),
            Text(
              'Search merchants',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFBBBBBB)),
            ),
            const SizedBox(height: 6),
            Text(
              'Food, grocery, pharmacy & more',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFFCCCCCC)),
            ),
          ],
        ),
      );

  Widget _buildNoResults() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 70, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 18),
            Text(
              'No results for "$_query"',
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFBBBBBB)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFFCCCCCC)),
            ),
          ],
        ),
      );

  Widget _buildResults(List<Map<String, String>> results) =>
      ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: results.length,
        itemBuilder: (context, i) {
          final m = results[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/merchant'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Icon(
                        _categoryIcon(m['category']!),
                        size: 24,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name']!,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m['category']!,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star,
                                size: 11, color: Color(0xFFFACC15)),
                            Text(
                              ' ${m['rating']}  ·  ${m['time']}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          );
        },
      );

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Grocery':
        return Icons.shopping_basket;
      case 'Pharmacy':
        return Icons.local_pharmacy;
      default:
        return Icons.store;
    }
  }
}
