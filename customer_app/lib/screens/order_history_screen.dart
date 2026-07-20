import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../services/firestore_service.dart';
import '../widgets/se_card.dart';
import '../widgets/se_chip.dart';
import '../widgets/se_skeleton.dart';
import '../widgets/se_empty_state.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _activeTab = 0;
  static const _tabs = ['All', 'Active', 'Completed', 'Cancelled'];

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _subscribe();
  }

  void _subscribe() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _sub = FirestoreService.orderHistoryStream(uid).listen((orders) {
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_activeTab == 0) return _orders;
    final label = _tabs[_activeTab];
    return _orders.where((o) {
      final status = o['status'] as String? ?? '';
      if (label == 'Active') {
        return status == 'pending' ||
            status == 'accepted' ||
            status == 'in_transit';
      }
      if (label == 'Completed') return status == 'delivered';
      if (label == 'Cancelled') return status == 'cancelled';
      return false;
    }).toList();
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
      case 'in_transit':
        return 'Active';
      case 'delivered':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  ({Color color, Color tint}) _statusColors(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
      case 'in_transit':
        return (color: SeColors.success, tint: SeColors.successTint);
      case 'delivered':
        return (color: SeColors.ocean500, tint: SeColors.oceanTint);
      case 'cancelled':
        return (color: SeColors.danger, tint: SeColors.dangerTint);
      default:
        return (color: SeColors.ink500, tint: SeColors.surface50);
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = (createdAt as Timestamp).toDate();
      const months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
        'August', 'September', 'October', 'November', 'December'
      ];
      final month = months[dt.month];
      final day = dt.day;
      final year = dt.year;
      final hour12 =
          dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$month $day, $year at $hour12:$minute $ampm';
    } catch (_) {
      return '';
    }
  }

  String _itemsLabel(List<dynamic> items) {
    if (items.isEmpty) return '';
    return items
        .take(3)
        .map((i) => i['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  String _formatTotal(dynamic total) {
    final t = (total as num?)?.toInt() ?? 0;
    if (t >= 1000) {
      return '\$${t ~/ 1000},${(t % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$t';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeColors.surface50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(SeSpacing.gutter, 14, SeSpacing.gutter, 14),
        decoration: const BoxDecoration(color: SeColors.surface0),
        child: Row(
          children: [
            if (Navigator.canPop(context)) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: SeColors.surface50, shape: BoxShape.circle),
                  child: const Icon(SeIcons.arrowLeft,
                      size: 20, color: SeColors.ink900),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text('Order History', style: SeType.h1),
          ],
        ),
      );

  Widget _buildTabs() => Container(
        color: SeColors.surface0,
        padding: const EdgeInsets.fromLTRB(SeSpacing.gutter, 0, SeSpacing.gutter, 14),
        child: Row(
          children: _tabs.asMap().entries.map((e) {
            final selected = _activeTab == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin:
                      EdgeInsets.only(right: e.key < _tabs.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected ? SeColors.emberGradient : null,
                    color: selected ? null : SeColors.surface50,
                    borderRadius: SeRadius.pill,
                    boxShadow:
                        selected ? SeElevation.glow : SeElevation.e0,
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: SeType.label.copyWith(
                        color: selected ? Colors.white : SeColors.ink500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildList() {
    if (_loading) {
      return SeShimmer(
        child: ListView.separated(
          padding: const EdgeInsets.all(SeSpacing.gutter),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: SeRadius.all(SeRadius.md),
            ),
            child: Row(
              children: const [
                SeSkeleton(width: 42, height: 42, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SeSkeleton(width: 130, height: 13, radius: 5),
                      SizedBox(height: 8),
                      SeSkeleton(width: 90, height: 10, radius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: SeEmptyState(
          icon: SeIcons.orders,
          title: 'No orders here yet',
          message:
              'Your ${_tabs[_activeTab].toLowerCase()} orders will appear here.',
          ctaLabel: _activeTab == 0 ? 'Start an order' : null,
          onCta: _activeTab == 0
              ? () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (r) => false)
              : null,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(SeSpacing.gutter),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildOrderCard(items[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final displayStatus = _displayStatus(status);
    final colors = _statusColors(status);
    final merchantName = order['merchantName'] as String? ?? 'Merchant';
    final orderId = order['id'] as String? ?? '';
    final rawItems = order['items'] as List? ?? [];
    final itemsLabel = _itemsLabel(rawItems);
    final dateStr = _formatDate(order['createdAt']);
    final totalStr = _formatTotal(order['total']);
    final shortId = orderId.length > 8
        ? '#${orderId.substring(0, 8).toUpperCase()}'
        : '#${orderId.toUpperCase()}';

    return SeCard(
      onTap: () => Navigator.pushNamed(context, '/order-status',
          arguments: {'orderId': orderId}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SeColors.red50,
                  borderRadius: SeRadius.all(SeRadius.sm),
                ),
                child: const Icon(SeIcons.orders,
                    size: 21, color: SeColors.red500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchantName,
                        style: SeType.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Text(shortId,
                        style: SeType.tabular(SeType.label)
                            .copyWith(color: SeColors.ink400)),
                  ],
                ),
              ),
              SeChip.status(
                label: displayStatus,
                color: colors.color,
                tint: colors.tint,
              ),
            ],
          ),
          if (itemsLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(itemsLabel,
                style: SeType.bodyS.copyWith(color: SeColors.ink500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: SeColors.ink100),
          const SizedBox(height: 12),
          Row(
            children: [
              if (dateStr.isNotEmpty)
                Expanded(
                  child: Text(dateStr,
                      style: SeType.label.copyWith(color: SeColors.ink400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(width: 8),
              Text(totalStr,
                  style: SeType.tabular(SeType.title)
                      .copyWith(color: SeColors.ink900)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/order-status',
                    arguments: {'orderId': orderId}),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: SeColors.emberGradient,
                    borderRadius: SeRadius.pill,
                  ),
                  child: Text('Track',
                      style: SeType.label.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
