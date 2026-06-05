import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/driver_firestore_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _selectedPeriod = 0;
  static const _periods = ['Today', 'This Week', 'This Month'];

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '\$${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$price';
  }

  DateTime _periodStart(int period) {
    final now = DateTime.now();
    if (period == 0) {
      return DateTime(now.year, now.month, now.day);
    } else if (period == 1) {
      final weekday = now.weekday; // 1=Mon
      return DateTime(now.year, now.month, now.day - (weekday - 1));
    } else {
      return DateTime(now.year, now.month, 1);
    }
  }

  List<Map<String, dynamic>> _filterByPeriod(
      List<Map<String, dynamic>> orders, int period) {
    final start = _periodStart(period);
    return orders.where((o) {
      if (o['status'] != 'delivered') return false;
      final ts = o['deliveredAt'] as Timestamp?;
      if (ts == null) return false;
      return ts.toDate().isAfter(start);
    }).toList();
  }

  List<double> _computeBars(
      List<Map<String, dynamic>> periodOrders, int period) {
    if (period == 0) {
      // Today: 8 two-hour blocks from 6am to 10pm
      final bars = List<double>.filled(8, 0);
      for (final o in periodOrders) {
        final ts = (o['deliveredAt'] as Timestamp?)?.toDate();
        if (ts == null) continue;
        final idx = ((ts.hour - 6) / 2).floor().clamp(0, 7);
        bars[idx] += ((o['total'] as num?)?.toDouble() ?? 0) / 10;
      }
      return bars;
    } else if (period == 1) {
      // This Week: 7 bars (Mon-Sun)
      final bars = List<double>.filled(7, 0);
      for (final o in periodOrders) {
        final ts = (o['deliveredAt'] as Timestamp?)?.toDate();
        if (ts == null) continue;
        final idx = (ts.weekday - 1).clamp(0, 6);
        bars[idx] += ((o['total'] as num?)?.toDouble() ?? 0) / 10;
      }
      return bars;
    } else {
      // This Month: 4 weekly bars
      final bars = List<double>.filled(4, 0);
      for (final o in periodOrders) {
        final ts = (o['deliveredAt'] as Timestamp?)?.toDate();
        if (ts == null) continue;
        final idx = ((ts.day - 1) ~/ 7).clamp(0, 3);
        bars[idx] += ((o['total'] as num?)?.toDouble() ?? 0) / 10;
      }
      return bars;
    }
  }

  List<String> _barLabels(int period) {
    if (period == 0) {
      return ['6a', '8a', '10a', '12p', '2p', '4p', '6p', '8p'];
    } else if (period == 1) {
      return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    } else {
      return ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
    }
  }

  String _barChartLabel(int period) {
    if (period == 0) return 'Hourly Breakdown';
    if (period == 1) return 'Daily Breakdown';
    return 'Weekly Breakdown';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: Column(
        children: [
          _buildHeader(),
          _buildPeriodTabs(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DriverFirestoreService.driverOrderHistoryStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2));
                }
                final allOrders = snapshot.data ?? [];
                final periodOrders =
                    _filterByPeriod(allOrders, _selectedPeriod);
                final totalEarnings = periodOrders.fold<int>(
                    0,
                    (acc, o) =>
                        acc + ((o['total'] as num?)?.toInt() ?? 0) ~/ 10);
                final deliveriesCount = periodOrders.length;
                final bars = _computeBars(periodOrders, _selectedPeriod);
                final labels = _barLabels(_selectedPeriod);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryCards(
                            _formatPrice(totalEarnings),
                            '$deliveriesCount'),
                        const SizedBox(height: 12),
                        _buildBarChart(bars, labels,
                            _barChartLabel(_selectedPeriod)),
                        const SizedBox(height: 12),
                        _buildRecentTrips(periodOrders),
                        const SizedBox(height: 12),
                        _buildPayoutCard(_formatPrice(totalEarnings)),
                        const SizedBox(height: 16),
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
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earnings',
                        style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('Track your income & trips',
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

  Widget _buildPeriodTabs() => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: List.generate(_periods.length, (i) {
            final isSelected = _selectedPeriod == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = i),
                child: Container(
                  margin:
                      EdgeInsets.only(right: i < _periods.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(_periods[i],
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textDark)),
                  ),
                ),
              ),
            );
          }),
        ),
      );

  Widget _buildSummaryCards(String total, String deliveries) => Row(
        children: [
          Expanded(
            child: _summaryCard(
              label: 'Total Earned',
              value: total,
              icon: Icons.trending_up,
              iconColor: AppTheme.success,
              sub: _periods[_selectedPeriod],
              valueColor: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              label: 'Deliveries',
              value: deliveries,
              icon: Icons.local_shipping,
              iconColor: const Color(0xFF1D4ED8),
              sub: 'Completed',
              valueColor: AppTheme.textDark,
            ),
          ),
        ],
      );

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String sub,
    required Color valueColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textMid)),
                Icon(icon, color: iconColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: valueColor)),
            Text(sub,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMid)),
          ],
        ),
      );

  Widget _buildBarChart(
      List<double> bars, List<String> labels, String chartLabel) =>
      Container(
        padding: const EdgeInsets.all(16),
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
            Text(chartLabel,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: CustomPaint(
                painter: _BarChartPainter(
                  data: bars,
                  labels: labels,
                  selectedIndex: bars.isEmpty
                      ? 0
                      : bars
                          .asMap()
                          .entries
                          .reduce((a, b) => a.value >= b.value ? a : b)
                          .key,
                ),
                size: const Size(double.infinity, 140),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  bars.every((b) => b == 0)
                      ? 'No data for this period'
                      : 'Highest earning period highlighted',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMid),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildRecentTrips(List<Map<String, dynamic>> orders) {
    final trips = orders.take(5).toList();
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Trips',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark)),
                Text('${orders.length} total',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary)),
              ],
            ),
          ),
          if (trips.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text('No trips this period.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textMid)),
            )
          else
            ...List.generate(trips.length, (i) {
              final o = trips[i];
              final shortId = () {
                final id = o['id'] as String? ?? '';
                return id.length > 8
                    ? '#${id.substring(0, 8).toUpperCase()}'
                    : '#$id';
              }();
              final merchant =
                  o['merchantName'] as String? ?? 'Merchant';
              final commission = ((o['total'] as num?)?.toInt() ?? 0) ~/ 10;
              final addr = o['deliveryAddress'] as String? ?? '—';
              return Column(
                children: [
                  if (i > 0)
                    const Divider(
                        height: 1,
                        color: AppTheme.divider,
                        indent: 16,
                        endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.two_wheeler,
                              color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(merchant,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textDark)),
                              const SizedBox(height: 2),
                              Text(addr,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textMid),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatPrice(commission),
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary)),
                            const SizedBox(height: 2),
                            Text(shortId,
                                style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(String total) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC8102E), Color(0xFFB00D28)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Payout',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 2),
                  Text('Every Friday',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ],
              ),
            ),
            Text(total,
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      );
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final int selectedIndex;

  const _BarChartPainter({
    required this.data,
    required this.labels,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    // Show placeholder bars when there's no data
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;
    final effectiveData = maxVal == 0
        ? data.map((_) => 0.3).toList()
        : data;

    final barWidth = (size.width - 40) / (data.length * 2 - 1);
    final chartHeight = size.height - 30;
    const labelHeight = 20.0;
    final chartAreaHeight = chartHeight - labelHeight;

    final bgPaint = Paint()..color = const Color(0xFFEBEBEB);
    final redPaint = Paint()..color = AppTheme.primary;
    const textStyle = TextStyle(
      color: AppTheme.textMid,
      fontSize: 10,
      fontFamily: 'Inter',
    );

    if (maxVal > 0) {
      final maxLabelPainter = TextPainter(
        text: TextSpan(
          text: '\$${maxVal.toStringAsFixed(0)}',
          style: const TextStyle(
              color: AppTheme.textLight, fontSize: 9, fontFamily: 'Inter'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      maxLabelPainter.paint(canvas, const Offset(0, 0));
    }

    for (int i = 0; i < effectiveData.length; i++) {
      final x = 30.0 + i * (barWidth * 2);
      final barHeight =
          (effectiveData[i] / effectiveMax) * (chartAreaHeight - 20);
      final top = chartAreaHeight - barHeight;
      final rect = Rect.fromLTWH(x, top, barWidth, barHeight);
      final isSelected = i == selectedIndex && maxVal > 0;

      if (isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          redPaint,
        );
      } else {
        final bgRect = Rect.fromLTWH(x, 20, barWidth, chartAreaHeight - 20);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          bgPaint,
        );
        if (maxVal > 0) {
          final redRect = Rect.fromLTWH(x, top, barWidth, 4);
          canvas.drawRRect(
            RRect.fromRectAndRadius(redRect, const Radius.circular(4)),
            redPaint,
          );
        }
      }

      if (i < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(text: labels[i], style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(
          canvas,
          Offset(
            x + barWidth / 2 - labelPainter.width / 2,
            chartAreaHeight + 6,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.data != data || old.selectedIndex != selectedIndex;
}
