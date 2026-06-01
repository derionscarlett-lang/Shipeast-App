import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _selectedPeriod = 0;

  static const _periods = ['Today', 'This Week', 'This Month'];

  static const List<Map<String, dynamic>> _periodData = [
    {
      'total': '\$3,750',
      'deliveries': '6',
      'avg': '\$625',
      'hours': '4h 32m',
      'bars': [25.0, 40.0, 35.0, 45.0, 38.0, 50.0, 62.5],
      'labels': ['10', '11', '12', '1', '2', '3', '4'],
      'barLabel': 'Hourly Breakdown',
      'avgLabel': 'Avg \$625/hr',
    },
    {
      'total': '\$22,400',
      'deliveries': '38',
      'avg': '\$3,200',
      'hours': '31h 14m',
      'bars': [32.0, 45.0, 28.0, 52.0, 38.0, 47.0, 42.5],
      'labels': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      'barLabel': 'Daily Breakdown',
      'avgLabel': 'Avg \$3,200/day',
    },
    {
      'total': '\$89,500',
      'deliveries': '152',
      'avg': '\$22,375',
      'hours': '118h 40m',
      'bars': [55.0, 72.0, 63.0, 80.0],
      'labels': ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'],
      'barLabel': 'Weekly Breakdown',
      'avgLabel': 'Avg \$22,375/week',
    },
  ];

  static const List<List<Map<String, String>>> _periodTrips = [
    [
      {'order': '#SE-2847', 'route': 'Kingston · 18 min', 'amount': '\$850'},
      {'order': '#SE-2831', 'route': 'New Kingston · 22 min', 'amount': '\$1,000'},
      {'order': '#SE-2819', 'route': 'Half Way Tree · 15 min', 'amount': '\$750'},
    ],
    [
      {'order': '#SE-2847', 'route': 'Kingston · 18 min', 'amount': '\$850'},
      {'order': '#SE-2831', 'route': 'New Kingston · 22 min', 'amount': '\$1,000'},
      {'order': '#SE-2819', 'route': 'Half Way Tree · 15 min', 'amount': '\$750'},
      {'order': '#SE-2804', 'route': 'Liguanea · 10 min', 'amount': '\$620'},
      {'order': '#SE-2791', 'route': 'Barbican · 25 min', 'amount': '\$1,100'},
    ],
    [
      {'order': '#SE-2847', 'route': 'Kingston · 18 min', 'amount': '\$850'},
      {'order': '#SE-2831', 'route': 'New Kingston · 22 min', 'amount': '\$1,000'},
      {'order': '#SE-2819', 'route': 'Half Way Tree · 15 min', 'amount': '\$750'},
      {'order': '#SE-2804', 'route': 'Liguanea · 10 min', 'amount': '\$620'},
      {'order': '#SE-2791', 'route': 'Barbican · 25 min', 'amount': '\$1,100'},
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final data = _periodData[_selectedPeriod];
    final trips = _periodTrips[_selectedPeriod];

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: Column(
        children: [
          _buildHeader(),
          _buildPeriodTabs(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCards(data),
                    const SizedBox(height: 12),
                    _buildBarChart(data),
                    const SizedBox(height: 12),
                    _buildRecentTrips(trips),
                    const SizedBox(height: 12),
                    _buildPayoutCard(data),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
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
                    Text(
                      'Earnings',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Track your income & trips',
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
                  margin: EdgeInsets.only(right: i < _periods.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      _periods[i],
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );

  Widget _buildSummaryCards(Map<String, dynamic> data) => Row(
        children: [
          Expanded(
            child: _summaryCard(
              label: 'Total Earned',
              value: data['total'] as String,
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
              value: data['deliveries'] as String,
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
              offset: const Offset(0, 2),
            ),
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
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            Text(sub,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMid)),
          ],
        ),
      );

  Widget _buildBarChart(Map<String, dynamic> data) => Container(
        padding: const EdgeInsets.all(16),
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
            Text(
              data['barLabel'] as String,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: CustomPaint(
                painter: _BarChartPainter(
                  data: List<double>.from(data['bars'] as List),
                  labels: List<String>.from(data['labels'] as List),
                  selectedIndex:
                      (data['bars'] as List).length == 4 ? 3 : 3,
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
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  data['avgLabel'] as String,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMid),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildRecentTrips(List<Map<String, String>> trips) => Container(
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Trips',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    'View All',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(trips.length, (i) {
              final trip = trips[i];
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
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.two_wheeler,
                              color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ${trip['order']}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip['route']!,
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppTheme.textMid),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              trip['amount']!,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Completed',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
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

  Widget _buildPayoutCard(Map<String, dynamic> data) => Container(
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
                  Text(
                    'Next Payout',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Friday, June 6',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              data['total'] as String,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
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
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final barWidth = (size.width - 40) / (data.length * 2 - 1);
    final chartHeight = size.height - 30;
    final labelHeight = 20.0;
    final chartAreaHeight = chartHeight - labelHeight;

    final bgPaint = Paint()..color = const Color(0xFFEBEBEB);
    final redPaint = Paint()..color = AppTheme.primary;
    const textStyle = TextStyle(
      color: AppTheme.textMid,
      fontSize: 10,
      fontFamily: 'Inter',
    );

    final maxLabelPainter = TextPainter(
      text: TextSpan(
        text: '\$${maxVal.toStringAsFixed(0)}',
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 9,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabelPainter.paint(canvas, const Offset(0, 0));

    for (int i = 0; i < data.length; i++) {
      final x = 30.0 + i * (barWidth * 2);
      final barHeight = (data[i] / maxVal) * (chartAreaHeight - 20);
      final top = chartAreaHeight - barHeight;
      final rect = Rect.fromLTWH(x, top, barWidth, barHeight);
      final isSelected = i == selectedIndex;

      if (isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          redPaint,
        );
      } else {
        final bgRect =
            Rect.fromLTWH(x, 20, barWidth, chartAreaHeight - 20);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          bgPaint,
        );
        final redRect = Rect.fromLTWH(x, top, barWidth, 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(redRect, const Radius.circular(4)),
          redPaint,
        );
      }

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

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
}
