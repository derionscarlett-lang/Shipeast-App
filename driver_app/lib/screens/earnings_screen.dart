import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int selectedPeriod = 0;

  final List<String> _periods = ['This Week', 'Last Week', 'This Month'];

  final List<Map<String, String>> _recentTrips = [
    {
      'order': '#SE-2847',
      'route': 'Kingston · 15 min',
      'amount': '\$8.50',
    },
    {
      'order': '#SE-2831',
      'route': 'New Kingston · 22 min',
      'amount': '\$12.00',
    },
    {
      'order': '#SE-2819',
      'route': 'Half Way Tree · 18 min',
      'amount': '\$9.50',
    },
    {
      'order': '#SE-2804',
      'route': 'Liguanea · 10 min',
      'amount': '\$7.00',
    },
    {
      'order': '#SE-2791',
      'route': 'Barbican · 25 min',
      'amount': '\$13.50',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Earnings',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Period tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(_periods.length, (i) {
                  final isSelected = selectedPeriod == i;
                  return GestureDetector(
                    onTap: () => setState(() => selectedPeriod = i),
                    child: Container(
                      margin: EdgeInsets.only(right: i < _periods.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _periods[i],
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary cards row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Earned',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textMid,
                                    ),
                                  ),
                                  const Icon(Icons.trending_up,
                                      color: AppTheme.success, size: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$284.50',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(
                                _periods[selectedPeriod],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Deliveries',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textMid,
                                    ),
                                  ),
                                  const Icon(Icons.local_shipping,
                                      color: Color(0xFF1D4ED8), size: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '23',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Completed',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bar chart card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Breakdown',
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
                              data: const [32.0, 45.0, 28.0, 52.0, 38.0, 47.0, 42.5],
                              labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                              selectedIndex: 3,
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
                              'Avg \$40.64/day',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textMid,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Recent trips card
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                        ...List.generate(_recentTrips.length, (i) {
                          final trip = _recentTrips[i];
                          return Column(
                            children: [
                              if (i > 0)
                                const Divider(
                                    height: 1, color: AppTheme.divider,
                                    indent: 16, endIndent: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.local_shipping,
                                          color: AppTheme.primary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              fontSize: 11,
                                              color: AppTheme.textMid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                  ),

                  // Payout info card
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                                  color: Colors.white.withOpacity(0.7),
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
                          '\$284.50',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final textStyle = TextStyle(
      color: AppTheme.textMid,
      fontSize: 10,
      fontFamily: 'Inter',
    );

    // Max value label
    final maxLabelPainter = TextPainter(
      text: TextSpan(
        text: '\$${maxVal.toStringAsFixed(0)}',
        style: TextStyle(
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
        // Background bar (full height, light grey)
        final bgRect = Rect.fromLTWH(x, 20, barWidth, chartAreaHeight - 20);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
          bgPaint,
        );
        // Red top portion
        final redRect = Rect.fromLTWH(x, top, barWidth, 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(redRect, const Radius.circular(4)),
          redPaint,
        );
      }

      // Label
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
