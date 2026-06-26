import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/widgets.dart';

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

  // Presentational only: quick-tap suggestions shown on the empty state.
  static const _suggestions = ['Food', 'Grocery', 'Pharmacy', 'Packages'];

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
      backgroundColor: AppTheme.background,
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
            Positioned(
              top: -46,
              right: -36,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 24,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (Navigator.canPop(context)) ...[
                          Pressable(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          'Search',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: false,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search merchants, food, items…',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.hint),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 20, color: AppTheme.primary),
                          suffixIcon: _query.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _ctrl.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: AppTheme.hint),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, AppTheme.spaceLg, AppTheme.spaceMd, AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse by category',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .map((s) => Pressable(
                        onTap: () {
                          _ctrl.text = s;
                          setState(() => _query = s);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXl),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_categoryIcon(s),
                                  size: 16, color: AppTheme.primary),
                              const SizedBox(width: 7),
                              Text(s,
                                  style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search_rounded,
                        size: 46, color: AppTheme.primary),
                  ).popIn(),
                  const SizedBox(height: 18),
                  Text(
                    'Find what you need',
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.dark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search across food, grocery, pharmacy & more.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildNoResults() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded,
                    size: 46, color: AppTheme.primary),
              ).popIn(),
              const SizedBox(height: 18),
              Text(
                'No results for "$_query"',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark),
              ),
              const SizedBox(height: 6),
              Text(
                'Try a different name or category.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );

  Widget _buildResults(List<Map<String, dynamic>> results) =>
      ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceLg),
        itemCount: results.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${results.length} ${results.length == 1 ? 'result' : 'results'} found',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary),
              ),
            );
          }
          final m = results[i - 1];
          final imageUrl = m['imageUrl'] as String? ?? '';
          final isOpen = m['isOpen'] as bool? ?? true;
          final rating = m['rating'];
          final ratingStr = rating is double
              ? rating.toStringAsFixed(1)
              : rating?.toString() ?? '4.5';
          final deliveryFee = m['deliveryFee'] as String? ?? 'Free delivery';
          final deliveryTime = m['deliveryTime'] as String? ?? '25–35 min';
          final category = m['category'] as String? ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
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
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => const ShimmerBox(
                                  width: 62, height: 62, radius: AppTheme.radiusMd),
                              errorWidget: (ctx, url, err) =>
                                  _iconFallback(category),
                            )
                          : _iconFallback(category),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m['name'] as String? ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.dark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppTheme.gold),
                            const SizedBox(width: 2),
                            Text(
                              ratingStr,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXl),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                deliveryTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadge(
                              label: isOpen ? 'Open' : 'Closed',
                              color:
                                  isOpen ? AppTheme.success : AppTheme.error,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                deliveryFee,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.inactive),
                ],
              ),
            ).fadeSlideIn(index: i),
          );
        },
      );

  Widget _iconFallback(String category) => Container(
        color: AppTheme.primaryLight,
        child: Center(
          child: Icon(
            _categoryIcon(category),
            size: 28,
            color: AppTheme.primary,
          ),
        ),
      );

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Grocery':
        return Icons.shopping_basket_rounded;
      case 'Pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'Packages':
        return Icons.inventory_2_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}
