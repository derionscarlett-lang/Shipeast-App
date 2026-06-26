import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
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
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = _orderArgs['total'] as int? ?? 0;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppTopBar(
              title: 'Checkout',
              subtitle: 'Confirm address & review order',
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary))
                  : ListView(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      children: [
                        _buildStepper().fadeSlideIn(),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildAddressCard().fadeSlideIn(index: 1),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildOrderSummaryCard().fadeSlideIn(index: 2),
                        const SizedBox(height: AppTheme.spaceMd),
                      ],
                    ),
            ),
            if (!_loading) _buildBottomBar(total),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() => Row(
        children: [
          _step('Cart', Icons.shopping_bag_rounded, done: true),
          _stepLine(active: true),
          _step('Address', Icons.location_on_rounded, active: true),
          _stepLine(active: false),
          _step('Payment', Icons.payments_rounded),
        ],
      );

  Widget _step(String label, IconData icon,
      {bool active = false, bool done = false}) {
    final on = active || done;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: on ? AppTheme.primary : AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
                color: on ? AppTheme.primary : AppTheme.border, width: 1.5),
          ),
          child: Icon(done ? Icons.check_rounded : icon,
              size: 17, color: on ? Colors.white : AppTheme.inactive),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: on ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _stepLine({required bool active}) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 18),
          color: active ? AppTheme.primary : AppTheme.border,
        ),
      );

  Widget _buildAddressCard() => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _coHead(
              'Delivery Address',
              Icons.location_on_rounded,
              actionLabel: 'Manage',
              actionIcon: Icons.tune_rounded,
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
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_off_rounded,
                          size: 26, color: AppTheme.inactive),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text(
                      'No addresses saved yet',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a delivery address to continue',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    AppButton(
                      label: 'Add New Address',
                      icon: Icons.add_location_alt_rounded,
                      variant: AppButtonVariant.secondary,
                      expand: false,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedAddressesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Column(
                  children: _addresses.asMap().entries.map((e) {
                    final i = e.key;
                    final addr = e.value;
                    final selected = _selectedAddress == i;
                    final label = addr['label'] as String? ?? '';
                    final iconData = label == 'Home'
                        ? Icons.home_rounded
                        : label == 'Work'
                            ? Icons.work_rounded
                            : Icons.location_on_rounded;
                    return Pressable(
                      onTap: () => setState(() => _selectedAddress = i),
                      child: AnimatedContainer(
                        duration: AppTheme.fast,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryLight
                              : AppTheme.background,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Icon(iconData,
                                  size: 18,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textMuted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label.isEmpty ? 'Address' : label,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: selected
                                          ? AppTheme.primary
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addr['text'] as String? ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _radio(selected),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );

  Widget _radio(bool selected) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.inputBorder,
            width: 2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      );

  Widget _buildOrderSummaryCard() {
    final rawItems = _orderArgs['items'] as List? ?? [];
    final items =
        rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final deliveryFee = _orderArgs['deliveryFee'] as int? ?? 0;
    final serviceFee = _orderArgs['serviceFee'] as int? ?? 0;
    final total = _orderArgs['total'] as int? ?? 0;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _coHead('Order Summary', Icons.receipt_long_rounded),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 12),
            child: Column(
              children: [
                ...items.map((item) {
                  final name = item['name'] as String? ?? '';
                  final qty = item['quantity'] as int? ?? 1;
                  final price = item['price'] as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(right: 9),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${qty}x',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                        Text(
                          '\$${_formatPrice(price * qty)}',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1),
                ),
                _summaryLine('Delivery fee',
                    deliveryFee == 0 ? 'Free' : '\$${_formatPrice(deliveryFee)}',
                    highlight: deliveryFee == 0),
                _summaryLine(
                    'Service fee (10%)', '\$${_formatPrice(serviceFee)}'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      '\$${_formatPrice(total)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textSecondary)),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color:
                        highlight ? AppTheme.success : AppTheme.textPrimary)),
          ],
        ),
      );

  Widget _buildBottomBar(int total) => Container(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 10, AppTheme.spaceMd, 10),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
          boxShadow: AppTheme.shadowMd,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted),
                  ),
                  Text(
                    '\$${_formatPrice(total)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: AppButton(
                  label: 'Choose Payment',
                  trailingArrow: true,
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
                ),
              ),
            ],
          ),
        ),
      );

  Widget _coHead(String title, IconData icon,
          {String? actionLabel, IconData? actionIcon, VoidCallback? onAction}) =>
      Container(
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary),
              ),
            ),
            if (actionLabel != null)
              Pressable(
                onTap: onAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actionIcon != null) ...[
                        Icon(actionIcon, size: 13, color: AppTheme.primary),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        actionLabel,
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
