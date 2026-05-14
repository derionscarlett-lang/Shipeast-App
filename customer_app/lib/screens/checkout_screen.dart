import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedAddress = 0;

  final List<Map<String, String>> _addresses = const [
    {
      'icon': '🏠',
      'label': 'Home',
      'text': '14 Yallahs Main Road, St. Thomas',
    },
    {
      'icon': '💼',
      'label': 'Work',
      'text': '45 King Street, Kingston',
    },
  ];

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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAddressCard(),
                    const SizedBox(height: 10),
                    _buildOrderSummaryCard(),
                    const SizedBox(height: 10),
                    _buildChoosePaymentButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
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
              'Checkout',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      );

  // ── DELIVERY ADDRESS CARD ─────────────────────────────────────────────────
  Widget _buildAddressCard() => _coCard(
        child: Column(
          children: [
            _coHead('Delivery Address', actionLabel: '+ Add New'),
            ..._addresses.asMap().entries.map((e) {
              final i = e.key;
              final addr = e.value;
              final selected = _selectedAddress == i;
              final isLast = i == _addresses.length - 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedAddress = i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom:
                                BorderSide(color: Color(0xFFF8F8F8))),
                  ),
                  child: Row(
                    children: [
                      // Radio button
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : const Color(0xFFDDDDDD),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 11),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${addr['icon']} ${addr['label']}',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: selected
                                  ? AppTheme.primary
                                  : const Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addr['text']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );

  // ── ORDER SUMMARY CARD ────────────────────────────────────────────────────
  Widget _buildOrderSummaryCard() => _coCard(
        child: Column(
          children: [
            _coHead('Order Summary'),
            _summaryLine('Full Jerk Chicken × 1', 'J\$1,200'),
            _summaryLine('Sorrel Punch × 1', 'J\$350'),
            _summaryLine('Delivery + Service', 'J\$375'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  Text(
                    'J\$1,925',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _summaryLine(String label, String value) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF555555))),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF555555))),
          ],
        ),
      );

  // ── CHOOSE PAYMENT BUTTON ─────────────────────────────────────────────────
  Widget _buildChoosePaymentButton() => ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/payment'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: Text(
          'Choose Payment →',
          style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w900),
        ),
      );

  // ── SHARED HELPERS ────────────────────────────────────────────────────────
  Widget _coCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  Widget _coHead(String title, {String? actionLabel}) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark),
            ),
            if (actionLabel != null)
              Text(
                actionLabel,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary),
              ),
          ],
        ),
      );
}
