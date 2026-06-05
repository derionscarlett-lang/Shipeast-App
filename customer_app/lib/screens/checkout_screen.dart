import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'saved_addresses_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedAddress = 0;
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _addrSub;

  Map<String, dynamic> _orderArgs = {};
  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _subscribeAddresses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) _orderArgs = Map<String, dynamic>.from(args);
    }
  }

  void _subscribeAddresses() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _addresses = [];
        _loading = false;
      });
      return;
    }
    _addrSub = FirestoreService.addressStream(uid).listen((addrs) {
      if (mounted) {
        setState(() {
          _addresses = addrs;
          if (_selectedAddress >= _addresses.length) _selectedAddress = 0;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _addrSub?.cancel();
    super.dispose();
  }

  String get selectedAddressText {
    if (_addresses.isEmpty || _selectedAddress >= _addresses.length) return '';
    return _addresses[_selectedAddress]['text'] as String? ?? '';
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '$price';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
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
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary))
                  : SingleChildScrollView(
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
                    color: Color(0xFFF2F2F2), shape: BoxShape.circle),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios,
                      size: 16, color: Color(0xFF444444)),
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

  Widget _buildAddressCard() => _coCard(
        child: Column(
          children: [
            _coHead(
              'Delivery Address',
              actionLabel: '+ Manage',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen()),
                );
              },
            ),
            if (_addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.location_off,
                        size: 32, color: Color(0xFFDDDDDD)),
                    const SizedBox(height: 8),
                    Text(
                      'No addresses saved',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFFAAAAAA)),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedAddressesScreen()),
                        );
                      },
                      child: Text(
                        '+ Add New Address',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._addresses.asMap().entries.map((e) {
                final i = e.key;
                final addr = e.value;
                final selected = _selectedAddress == i;
                final isLast = i == _addresses.length - 1;
                final label = addr['label'] as String? ?? '';
                final iconData = label == 'Home'
                    ? Icons.home
                    : label == 'Work'
                        ? Icons.work
                        : Icons.location_on;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAddress = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFFF8F8)
                          : Colors.transparent,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: Color(0xFFF8F8F8))),
                    ),
                    child: Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(iconData,
                                      size: 12,
                                      color: selected
                                          ? AppTheme.primary
                                          : const Color(0xFF888888)),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: selected
                                          ? AppTheme.primary
                                          : const Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                addr['text'] as String? ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      );

  Widget _buildOrderSummaryCard() {
    final rawItems = _orderArgs['items'] as List? ?? [];
    final items =
        rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final deliveryFee = _orderArgs['deliveryFee'] as int? ?? 0;
    final serviceFee = _orderArgs['serviceFee'] as int? ?? 0;
    final total = _orderArgs['total'] as int? ?? 0;

    return _coCard(
      child: Column(
        children: [
          _coHead('Order Summary'),
          ...items.map((item) {
            final name = item['name'] as String? ?? '';
            final qty = item['quantity'] as int? ?? 1;
            final price = item['price'] as int? ?? 0;
            return _summaryLine(
                '$name × $qty', '\$${_formatPrice(price * qty)}');
          }),
          _summaryLine('Delivery fee',
              deliveryFee == 0 ? 'Free' : '\$${_formatPrice(deliveryFee)}'),
          _summaryLine('Service fee (10%)', '\$${_formatPrice(serviceFee)}'),
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
                      color: AppTheme.dark),
                ),
                Text(
                  '\$${_formatPrice(total)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF555555))),
            ),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF555555))),
          ],
        ),
      );

  Widget _buildChoosePaymentButton() => ElevatedButton(
        onPressed: () {
          if (_addresses.isEmpty) {
            _showError('Please add a delivery address first');
            return;
          }
          Navigator.pushNamed(context, '/payment', arguments: {
            ..._orderArgs,
            'deliveryAddress': selectedAddressText,
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: Text(
          'Choose Payment →',
          style:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
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

  Widget _coHead(String title,
          {String? actionLabel, VoidCallback? onAction}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
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
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary),
                ),
              ),
          ],
        ),
      );
}
