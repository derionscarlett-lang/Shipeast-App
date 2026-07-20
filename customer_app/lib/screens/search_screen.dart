import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../services/firestore_service.dart';
import '../widgets/se_card.dart';
import '../widgets/se_chip.dart';
import '../widgets/se_skeleton.dart';
import '../widgets/se_empty_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
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
    _focus.dispose();
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
      backgroundColor: SeColors.surface50,
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
        decoration: const BoxDecoration(gradient: SeColors.emberGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, SeSpacing.gutter, 16),
            child: Row(
              children: [
                if (Navigator.canPop(context)) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(SeIcons.arrowLeft,
                          size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: SeRadius.all(SeRadius.md),
                      boxShadow: SeElevation.e2,
                    ),
                    child: Row(
                      children: [
                        const Icon(SeIcons.search,
                            size: 20, color: SeColors.ink400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            style: SeType.body.copyWith(color: SeColors.ink900),
                            cursorColor: SeColors.red500,
                            decoration: InputDecoration(
                              hintText: 'Search merchants, food, items...',
                              hintStyle:
                                  SeType.body.copyWith(color: SeColors.ink400),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(SeIcons.close,
                                size: 18, color: SeColors.ink400),
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

  Widget _buildEmptyState() => Center(
        child: SeEmptyState(
          icon: SeIcons.search,
          title: 'Search merchants',
          message: 'Food, grocery, pharmacy & more',
        ),
      );

  Widget _buildNoResults() => Center(
        child: SeEmptyState(
          icon: SeIcons.noConnection,
          title: 'No results for "$_query"',
          message: 'Try a different search term',
          hue: SeColors.ink500,
          tint: SeColors.surface50,
        ),
      );

  Widget _buildResults(List<Map<String, dynamic>> results) =>
      ListView.separated(
        padding: const EdgeInsets.all(SeSpacing.gutter),
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

          return SeCard(
            onTap: () => Navigator.pushNamed(context, '/merchant', arguments: {
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
                  borderRadius: SeRadius.all(SeRadius.sm),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => const SeShimmer(
                                child: SeSkeleton(
                                    width: 60, height: 60, radius: 12)),
                            errorWidget: (ctx, url, err) =>
                                _iconFallback(category),
                          )
                        : _iconFallback(category),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['name'] as String? ?? '',
                          style: SeType.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (category.isNotEmpty)
                            SeChip.status(
                              label: category,
                              color: SeColors.red700,
                              tint: SeColors.red50,
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(SeIcons.star,
                                  size: 13, color: SeColors.gold500),
                              const SizedBox(width: 3),
                              Text('$ratingStr · $deliveryTime',
                                  style: SeType.bodyS
                                      .copyWith(color: SeColors.ink500)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(SeIcons.caretRight,
                    size: 18, color: SeColors.ink300),
              ],
            ),
          );
        },
      );

  Widget _iconFallback(String category) => Container(
        color: SeColors.surface50,
        child: Icon(_categoryIcon(category),
            size: 26, color: SeColors.ink400),
      );

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return SeIcons.food;
      case 'Grocery':
        return SeIcons.grocery;
      case 'Pharmacy':
        return SeIcons.pharmacy;
      default:
        return SeIcons.storefront;
    }
  }
}
