import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/driver_firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _activeTab = 0;
  static const _tabs = ['All', 'Completed', 'Cancelled'];

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '\$${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$price';
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);
    final timeStr =
        '${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '${dt.hour >= 12 ? 'PM' : 'AM'}';
    if (day == today) return 'Today, $timeStr';
    if (day == yesterday) return 'Yesterday, $timeStr';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, $timeStr';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'In Progress';
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    if (_activeTab == 0) return all;
    if (_activeTab == 1) {
      return all.where((o) => o['status'] == 'delivered').toList();
    }
    return all.where((o) => o['status'] == 'cancelled').toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DriverFirestoreService.driverOrderHistoryStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2));
                }
                final all = snapshot.data ?? [];
                final displayOrders = _filtered(all);
                final completed =
                    all.where((o) => o['status'] == 'delivered').length;
                final total = all.length;

                return Column(
                  children: [
                    _buildSummaryStrip(total, completed),
                    Expanded(child: _buildList(displayOrders)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        color: AppTheme.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery History',
                        style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('All your past deliveries',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTabs() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = _activeTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: Container(
                  margin:
                      EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.surfaceGrey,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[i],
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color:
                              selected ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );

  Widget _buildSummaryStrip(int total, int completed) {
    final rate = total > 0
        ? (completed / total * 100).toStringAsFixed(0)
        : '0';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryItem('$total', 'Total Trips', AppTheme.primary),
          _vDivider(),
          _summaryItem('$completed', 'Completed', AppTheme.success),
          _vDivider(),
          _summaryItem('$rate%', 'Rate', const Color(0xFF1D4ED8)),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
      );

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: AppTheme.divider);

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 52, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text('No deliveries here yet',
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final isCompleted = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final label = _statusLabel(status);
    final merchant = order['merchantName'] as String? ?? 'Merchant';
    final shortId = () {
      final id = order['id'] as String? ?? '';
      return id.length > 8 ? '#${id.substring(0, 8).toUpperCase()}' : '#$id';
    }();
    final pickupAddr = order['merchantAddress'] as String? ??
        order['address'] as String? ??
        '—';
    final deliverAddr = order['deliveryAddress'] as String? ?? '—';
    final route = '$pickupAddr → $deliverAddr';
    final total = (order['total'] as num?)?.toInt() ?? 0;
    final dateTs = order['deliveredAt'] ??
        order['createdAt'] ??
        order['acceptedAt'];
    final dateStr = _formatDate(dateTs);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                  color: isCompleted
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : const Color(0xFFF2F2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isCancelled
                          ? Icons.cancel_outlined
                          : Icons.local_shipping,
                  color: isCompleted ? AppTheme.primary : AppTheme.textLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchant,
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark)),
                    Text(shortId,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatPrice(total),
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isCompleted
                              ? AppTheme.primary
                              : AppTheme.textLight)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isCompleted
                                ? AppTheme.success
                                : isCancelled
                                    ? AppTheme.primary
                                    : const Color(0xFF1D4ED8))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 12, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(route,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textMid),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 12, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(dateStr,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}
