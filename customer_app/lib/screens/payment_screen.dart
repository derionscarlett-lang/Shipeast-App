import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPayment = 0; // 0 = PayPal, 1 = COD
  final _promoController = TextEditingController();
  bool _promoApplied = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
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
                    _buildPaymentCard(),
                    const SizedBox(height: 10),
                    _buildSecurityCard(),
                    const SizedBox(height: 10),
                    _buildPromoCard(),
                    const SizedBox(height: 10),
                    _buildTotalCard(),
                    const SizedBox(height: 10),
                    _buildPlaceOrderButton(),
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
                  child: Icon(Icons.arrow_back_ios, size: 16,
                      color: Color(0xFF444444)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Payment Method',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      );

  Widget _buildPaymentCard() => _coCard(
        child: Column(
          children: [
            _coHead('Select Payment'),
            _paymentRow(
              index: 0,
              icon: _paypalLogo(),
              name: 'PayPal',
              sub: 'Pay securely via PayPal',
              iconBg: const Color(0xFFF0F4FF),
            ),
            _paymentRow(
              index: 1,
              icon: const Icon(Icons.payments,
                  size: 24, color: Color(0xFF16A34A)),
              name: 'Cash on Delivery',
              sub: 'Pay when your order arrives',
              iconBg: const Color(0xFFF0FDF4),
              isLast: true,
            ),
          ],
        ),
      );

  Widget _paymentRow({
    required int index,
    required Widget icon,
    required String name,
    required String sub,
    required Color iconBg,
    bool isLast = false,
  }) {
    final selected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFFDDDDDD),
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
          ],
        ),
      ),
    );
  }

  Widget _paypalLogo() => RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Pay',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF003087),
              ),
            ),
            TextSpan(
              text: 'Pal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF009CDE),
              ),
            ),
          ],
        ),
      );

  Widget _buildSecurityCard() => _coCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your payment is protected',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 10),
              _securityRow(
                icon: Icons.shield,
                color: const Color(0xFF16A34A),
                label: '256-bit SSL Encryption',
              ),
              const SizedBox(height: 8),
              _securityRow(
                icon: Icons.lock,
                color: const Color(0xFF2563EB),
                label: '100% Secure Payment',
              ),
              const SizedBox(height: 8),
              _securityRow(
                icon: Icons.verified_user,
                color: const Color(0xFF003087),
                label: 'PayPal Buyer Protection',
              ),
            ],
          ),
        ),
      );

  Widget _securityRow(
          {required IconData icon,
          required Color color,
          required String label}) =>
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF555555),
            ),
          ),
        ],
      );

  Widget _buildPromoCard() => _coCard(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Promo Code',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF555555)),
                      decoration: InputDecoration(
                        hintText: 'Enter promo code...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF888888)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  GestureDetector(
                    onTap: () {
                      if (_promoController.text.trim().isNotEmpty) {
                        setState(() => _promoApplied = true);
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Promo code applied!',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700)),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: _promoApplied
                            ? const Color(0xFF16A34A)
                            : AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _promoApplied ? 'Applied' : 'Apply',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
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

  Widget _buildTotalCard() => _coCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total to Pay',
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
      );

  Widget _buildPlaceOrderButton() => ElevatedButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-confirmed',
          (route) => route.settings.name == '/home',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 14),
            const SizedBox(width: 6),
            Text(
              'Place Order · J\$1,925',
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );

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

  Widget _coHead(String title) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.dark),
        ),
      );
}
