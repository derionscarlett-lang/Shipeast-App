import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _activeTab = 0;
  static const _tabs = ['All', 'Active', 'Completed', 'Cancelled'];

  static const _orders = [
    {
      'merchant': 'Island Jerk Palace',
      'emoji': '🍗',
      'status': 'Active',
      'statusColor': 0xFF16A34A,
      'statusBg': 0xFFDCFCE7,
      'items': 'Full Jerk Chicken, Sorrel Punch',
      'total': 'J\$1,925',
      'date': 'Today, 9:41 AM',
      'orderId': '#SE-20268814',
    },
    {
      'merchant': 'Kingston Burger Co.',
      'emoji': '🍔',
      'status': 'Completed',
      'statusColor': 0xFF2563EB,
      'statusBg': 0xFFEFF6FF,
      'items': 'Smash Burger, Loaded Fries, Coke',
      'total': 'J\$2,450',
      'date': 'Yesterday, 2:15 PM',
      'orderId': '#SE-20268799',
    },
    {
      'merchant': 'Spice Island Cuisine',
      'emoji': '🍛',
      'status': 'Completed',
      'statusColor': 0xFF2563EB,
      'statusBg': 0xFFEFF6FF,
      'items': 'Curry Goat, Rice & Peas, Ting',
      'total': 'J\$1,780',
      'date': 'May 12, 6:30 PM',
      'orderId': '#SE-20268751',
    },
    {
      'merchant': 'FreshMart Grocery',
      'emoji': '🛒',
      'status': 'Cancelled',
      'statusColor': 0xFFC8102E,
      'statusBg': 0xFFFFF0F2,
      'items': 'Bananas, Bread, Milk, Eggs',
      'total': 'J\$890',
      'date': 'May 10, 11:00 AM',
      'orderId': '#SE-20268722',
    },
    {
      'merchant': 'Tropical Pharmacy',
      'emoji': '💊',
      'status': 'Completed',
      'statusColor': 0xFF2563EB,
      'statusBg': 0xFFEFF6FF,
      'items': 'Panadol, Vitamin C, Bandages',
      'total': 'J\$1,120',
      'date': 'May 8, 3:45 PM',
      'orderId': '#SE-20268688',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_activeTab == 0) return List<Map<String, dynamic>>.from(_orders);
    final label = _tabs[_activeTab];
    return _orders
        .where((o) => o['status'] == label)
        .map((o) => Map<String, dynamic>.from(o))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
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
                  child: Text('←', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                  margin: EdgeInsets.only(right: e.key < _tabs.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : const Color(0xFF888888),
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
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📦', style: TextStyle(fontSize: 52)),
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

  Widget _buildOrderCard(Map<String, dynamic> order) => Container(
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
            // Top row: merchant + status badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      order['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['merchant'] as String,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        order['orderId'] as String,
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
                    color: Color(order['statusBg'] as int),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    order['status'] as String,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(order['statusColor'] as int),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Items
            Text(
              order['items'] as String,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            // Bottom row: date + total + reorder
            Row(
              children: [
                Text(
                  order['date'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  order['total'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/merchant'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reorder',
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
      );
}
