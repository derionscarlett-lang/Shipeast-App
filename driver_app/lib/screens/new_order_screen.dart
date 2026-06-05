import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/driver_firestore_service.dart';
import 'pickup_confirmation_screen.dart';

class NewOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const NewOrderScreen({super.key, required this.order});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen>
    with TickerProviderStateMixin {
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _expired = false;
  bool _accepting = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  String get _orderId => widget.order['id'] as String? ?? '';
  String get _merchantName => widget.order['merchantName'] as String? ?? 'Merchant';
  String get _customerName => widget.order['customerName'] as String? ?? 'Customer';
  String get _deliveryAddress => widget.order['deliveryAddress'] as String? ?? '—';
  String get _merchantAddress =>
      widget.order['merchantAddress'] as String? ??
      widget.order['address'] as String? ??
      '—';
  int get _total => (widget.order['total'] as num?)?.toInt() ?? 0;
  String get _paymentMethod => widget.order['paymentMethod'] as String? ?? 'COD';
  List _getItems() => widget.order['items'] as List? ?? [];

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '\$${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$price';
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _expired = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _orderId.isEmpty) return;
    setState(() => _accepting = true);
    try {
      await DriverFirestoreService.acceptOrder(_orderId, uid);
      _timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PickupConfirmationScreen(
              orderId: _orderId,
              order: widget.order,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _accepting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to accept order. Try again.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_expired) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('New Order Request',
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: AppTheme.primary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.timer_off, color: AppTheme.primary, size: 40),
                ),
                const SizedBox(height: 20),
                Text('Order Expired',
                    style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Text('The order request has timed out.',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textMid),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: Text('Go Back', style: AppTheme.buttonLG()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final timerColor = _remainingSeconds <= 10
        ? Colors.orange
        : _remainingSeconds <= 20
            ? Colors.amber
            : AppTheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('New Order Request',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppTheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIncomingBanner(),
            const SizedBox(height: 14),
            _buildTimerCard(timerColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.attach_money, AppTheme.success,
                    _formatPrice(_total ~/ 10), 'Earnings',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.inventory_2, AppTheme.primary,
                    '${_getItems().length} item${_getItems().length == 1 ? '' : 's'}', 'Items',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.payments, const Color(0xFF1D4ED8),
                    _paymentMethod, 'Payment',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOrderDetailsCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _accepting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side:
                            const BorderSide(color: AppTheme.primary, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text('Reject',
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _accepting ? null : _acceptOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: _accepting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 6),
                                Text('Accept', style: AppTheme.buttonLG()),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingBanner() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _pulseScale.value,
            child: Opacity(
              opacity: _pulseOpacity.value,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC8102E), Color(0xFFB00D28)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.inventory_2, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Delivery Request!',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Respond before the timer runs out',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(Color timerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text('Accept before time expires',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark)),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / 60.0,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_remainingSeconds',
                        style: GoogleFonts.montserrat(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: timerColor,
                            height: 1.0)),
                    const SizedBox(height: 2),
                    Text('sec',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMid)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _remainingSeconds <= 10
                ? 'Expiring soon!'
                : 'Order will auto-expire if not accepted',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight:
                  _remainingSeconds <= 10 ? FontWeight.w700 : FontWeight.w400,
              color: _remainingSeconds <= 10 ? Colors.orange : AppTheme.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppTheme.textMid)),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    final items = _getItems();
    final itemsSummary = items.isNotEmpty
        ? items
            .map((i) {
              final name = (i is Map) ? (i['name'] as String? ?? '') : '$i';
              final qty = (i is Map) ? (i['quantity'] as int? ?? 1) : 1;
              return qty > 1 ? '$name ×$qty' : name;
            })
            .where((s) => s.isNotEmpty)
            .join(', ')
        : 'No items listed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${_orderId.length > 8 ? _orderId.substring(0, 8).toUpperCase() : _orderId.toUpperCase()}',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('PENDING',
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary)),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.divider),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle_outlined,
                      color: AppTheme.primary, size: 20),
                  Container(
                      width: 2,
                      height: 40,
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      margin: const EdgeInsets.symmetric(vertical: 2)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PICKUP',
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textLight,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(_merchantName,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textDark)),
                    if (_merchantAddress != '—')
                      Text(_merchantAddress,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppTheme.textMid)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DELIVERY TO',
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textLight,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(_customerName,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textDark)),
                    Text(_deliveryAddress,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textMid)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.divider),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_2,
                    color: AppTheme.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${items.length} item${items.length == 1 ? '' : 's'}',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark)),
                    Text(itemsSummary,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textMid),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.divider),
          Row(
            children: [
              const Icon(Icons.payments, color: AppTheme.textMid, size: 18),
              const SizedBox(width: 8),
              Text('$_paymentMethod – ${_formatPrice(_total)}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}
