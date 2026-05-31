import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _activeTab = 0;
  static const _tabs = ['All', 'Completed', 'Cancelled'];

  static const List<Map<String, dynamic>> _deliveries = [
    {
      'id': '#SE-2847',
      'merchant': 'Kingston Fresh Market',
      'customer': 'Sarah Williams',
      'route': '45 Constant Spring Rd → 12 Mona Rd',
      'amount': '\$8.50',
      'date': 'Today, 10:24 AM',
      'status': 'Completed',
      'duration': '18 min',
      'distance': '3.2 km',
    },
    {
      'id': '#SE-2831',
      'merchant': 'Island Jerk Palace',
      'customer': 'Marcus Brown',
      'route': '14 Knutsford Blvd → 22 Hope Rd',
      'amount': '\$12.00',
      'date': 'Today, 8:15 AM',
      'status': 'Completed',
      'duration': '22 min',
      'distance': '4.8 km',
    },
    {
      'id': '#SE-2819',
      'merchant': 'PharmaCare Rx',
      'customer': 'Diana Morgan',
      'route': '8 Barbican Rd → 45 Liguanea Ave',
      'amount': '\$9.50',
      'date': 'Yesterday, 3:40 PM',
      'status': 'Completed',
      'duration': '15 min',
      'distance': '2.9 km',
    },
    {
      'id': '#SE-2804',
      'merchant': 'FreshMart Grocery',
      'customer': 'Trevor Campbell',
      'route': 'Sovereign Centre → 7 Dunrobin Ave',
      'amount': '\$7.00',
      'date': 'Yesterday, 1:00 PM',
      'status': 'Cancelled',
      'duration': '—',
      'distance': '—',
    },
    {
      'id': '#SE-2791',
      'merchant': 'Mama\'s Kitchen',
      'customer': 'Angela Scott',
      'route': '3 Waterloo Rd → 91 Washington Blvd',
      'amount': '\$13.50',
      'date': 'May 30, 6:12 PM',
      'status': 'Completed',
      'duration': '25 min',
      'distance': '5.1 km',
    },
    {
      'id': '#SE-2778',
      'merchant': 'SaveMore Supermarket',
      'customer': 'Kevin James',
      'route': '123 Constant Spring → 4 Cherry Gdns',
      'amount': '\$11.00',
      'date': 'May 29, 11:30 AM',
      'status': 'Completed',
      'duration': '19 min',
      'distance': '3.8 km',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_activeTab == 0) return _deliveries;
    final label = _tabs[_activeTab];
    return _deliveries.where((d) => d['status'] == label).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          _buildSummaryStrip(),
          Expanded(child: _buildList()),
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
                    Text(
                      'Delivery History',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'All your past deliveries',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
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
                            selected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );

  Widget _buildSummaryStrip() {
    final completed =
        _deliveries.where((d) => d['status'] == 'Completed').length;
    final total = _deliveries.length;
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
          _summaryItem(
              '${(completed / total * 100).toStringAsFixed(0)}%',
              'Rate',
              const Color(0xFF1D4ED8)),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textMid,
              ),
            ),
          ],
        ),
      );

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        color: AppTheme.divider,
      );

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 52, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            Text(
              'No deliveries here yet',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
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

  Widget _buildCard(Map<String, dynamic> d) {
    final completed = d['status'] == 'Completed';
    return Container(
      padding: const EdgeInsets.all(14),
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
                  color: completed
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : const Color(0xFFF2F2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle
                      : Icons.cancel_outlined,
                  color: completed
                      ? AppTheme.primary
                      : AppTheme.textLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['merchant'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      d['id'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    d['amount'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: completed
                          ? AppTheme.primary
                          : AppTheme.textLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: completed
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      d['status'] as String,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: completed
                            ? AppTheme.success
                            : AppTheme.primary,
                      ),
                    ),
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
                child: Text(
                  d['route'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 12, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(
                d['date'] as String,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textLight),
              ),
              if (completed) ...[
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined,
                    size: 12, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  '${d['duration']}  ·  ${d['distance']}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textLight),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
