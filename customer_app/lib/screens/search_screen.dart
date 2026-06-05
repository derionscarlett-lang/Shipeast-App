import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/shimmer_box.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _allMerchants = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirestoreService.allMerchantsStream().listen((merchants) {
      if (mounted) setState(() => _allMerchants = merchants);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return const [];
    final q = _query.toLowerCase();
    return _allMerchants
        .where((m) =>
            (m['name'] as String? ?? '').toLowerCase().contains(q) ||
            (m['category'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  static int _parseDeliveryFee(String s) {
    if (s.toLowerCase().contains('free')) return 0;
    final match = RegExp(r'\d+').firstMatch(s);
    return match != null ? int.tryParse(match.group(0)!) ?? 100 : 100;
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
                      autofocus: false,
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

  Widget _buildResults(List<Map<String, dynamic>> results) =>
      ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: results.length,
        itemBuilder: (context, i) {
          final m = results[i];
          final imageUrl = m['imageUrl'] as String? ?? '';
          final isOpen = m['isOpen'] as bool? ?? true;
          final rating = m['rating'];
          final ratingStr = rating is double
              ? rating.toStringAsFixed(1)
              : rating?.toString() ?? '4.5';
          final deliveryFee = m['deliveryFee'] as String? ?? 'Free delivery';
          final deliveryTime = m['deliveryTime'] as String? ?? '25–35 min';
          final category = m['category'] as String? ?? '';

          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/merchant',
                arguments: {
                  'id': m['id'] ?? '',
                  'name': m['name'] ?? '',
                  'emoji': m['emoji'] as String? ?? '🍽️',
                  'imageUrl': imageUrl,
                  'category': category,
                  'rating': ratingStr,
                  'deliveryTime': deliveryTime,
                  'deliveryFee': deliveryFee,
                  'deliveryFeeAmount': _parseDeliveryFee(deliveryFee),
                  'isOpen': isOpen,
                }),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => const ShimmerBox(
                                  width: 56, height: 56, radius: 11),
                              errorWidget: (ctx, url, err) => _iconFallback(category),
                            )
                          : _iconFallback(category),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name'] as String? ?? '',
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
                                category,
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
                              ' $ratingStr  ·  $deliveryTime',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(0xFFEDFCF2)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOpen ? 'Open' : 'Closed',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isOpen
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              deliveryFee,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF888888)),
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

  Widget _iconFallback(String category) => Container(
        color: const Color(0xFFF5F5F7),
        child: Center(
          child: Icon(
            _categoryIcon(category),
            size: 26,
            color: const Color(0xFF888888),
          ),
        ),
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
