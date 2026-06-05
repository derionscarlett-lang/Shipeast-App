import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

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
      if (mounted) setState(() { _orders = orders; _loading = false; });
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
        return status == 'pending' || status == 'accepted' || status == 'in_transit';
      }
      if (label == 'Completed') return status == 'delivered';
      if (label == 'Cancelled') return status == 'cancelled';
      return false;
    }).toList();
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'pending': return 'Active';
      case 'accepted': return 'Active';
      case 'in_transit': return 'Active';
      case 'delivered': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Map<String, int> _statusColors(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
      case 'in_transit':
        return {'color': 0xFF16A34A, 'bg': 0xFFDCFCE7};
      case 'delivered':
        return {'color': 0xFF2563EB, 'bg': 0xFFEFF6FF};
      case 'cancelled':
        return {'color': 0xFFC8102E, 'bg': 0xFFFFF0F2};
      default:
        return {'color': 0xFF888888, 'bg': 0xFFF5F5F7};
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = (createdAt as Timestamp).toDate();
      const months = ['', 'January', 'February', 'March', 'April', 'May',
          'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final month = months[dt.month];
      final day = dt.day;
      final year = dt.year;
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
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
    if (t >= 1000) return '\$${t ~/ 1000},${(t % 1000).toString().padLeft(3, '0')}';
    return '\$$t';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          children: [
            if (Navigator.canPop(context)) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios,
                        size: 16, color: Color(0xFF444444)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              'Order History',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      );

  Widget _buildTabs() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: _tabs.asMap().entries.map((e) {
            final selected = _activeTab == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = e.key),
                child: Container(
                  margin: EdgeInsets.only(
                      right: e.key < _tabs.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF888888),
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2, size: 52, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(
              'No orders here yet',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Your ${_tabs[_activeTab].toLowerCase()} orders will appear here',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
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

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order-status',
          arguments: {'orderId': orderId}),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Center(
                    child: Icon(Icons.receipt_long,
                        size: 20, color: Color(0xFF888888)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchantName,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        shortId,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(colors['bg']!),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    displayStatus,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(colors['color']!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (itemsLabel.isNotEmpty)
              Text(
                itemsLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 7),
            Row(
              children: [
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                Text(
                  totalStr,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/order-status',
                    arguments: {'orderId': order['id'] as String? ?? ''},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Track',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
