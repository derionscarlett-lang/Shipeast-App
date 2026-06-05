import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  String _orderId = '';
  bool _argsLoaded = false;
  StreamSubscription<Map<String, dynamic>?>? _orderSub;
  StreamSubscription<Map<String, dynamic>?>? _driverSub;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _driver;
  String? _watchedDriverId;

  int get _currentStep {
    final status = _order?['status'] as String? ?? 'pending';
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'in_transit':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  String get _statusLabel {
    switch (_currentStep) {
      case 0:
        return 'Order Confirmed';
      case 1:
        return 'Order Picked Up';
      case 2:
        return 'On the Way';
      case 3:
        return 'Delivered!';
      default:
        return 'Loading...';
    }
  }

  String get _etaLabel {
    switch (_currentStep) {
      case 0:
        return '~40 min';
      case 1:
        return '~25 min';
      case 2:
        return '~15 min';
      case 3:
        return 'Done!';
      default:
        return '';
    }
  }

  static const _stepNames = [
    'Order Confirmed',
    'Order Picked Up',
    'On the Way',
    'Delivered',
  ];

  static const _stepIcons = [
    Icons.check_circle,
    Icons.check_circle,
    Icons.delivery_dining,
    Icons.home,
  ];

  String _stepSub(int index) {
    final merchantName =
        _order?['merchantName'] as String? ?? 'Merchant';
    switch (index) {
      case 0:
        return '$merchantName accepted your order';
      case 1:
        return 'Driver collected your order';
      case 2:
        return 'Driver is heading to you now';
      case 3:
        return 'Order delivered successfully!';
      default:
        return '';
    }
  }

  String _stepState(int stepIndex) {
    if (stepIndex < _currentStep) return 'done';
    if (stepIndex == _currentStep) return 'now';
    return 'wait';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulseScale = Tween<double>(begin: 0.7, end: 2.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _orderId = args['orderId'] as String? ?? '';
      }
      if (_orderId.isNotEmpty) {
        _orderSub = FirestoreService.watchOrder(_orderId).listen((order) {
          if (!mounted) return;
          setState(() => _order = order);
          final driverId = order?['driverId'] as String?;
          if (driverId != null &&
              driverId.isNotEmpty &&
              driverId != _watchedDriverId) {
            _driverSub?.cancel();
            _watchedDriverId = driverId;
            _driverSub =
                FirestoreService.watchDriver(driverId).listen((driver) {
              if (mounted) setState(() => _driver = driver);
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _orderSub?.cancel();
    _driverSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildMapArea(),
          _buildStatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...List.generate(4, _buildStepRow),
                  const SizedBox(height: 8),
                  _buildDriverCard(),
                  const SizedBox(height: 12),
                  if (_currentStep == 3 &&
                      _order?['rated'] != true)
                    _buildRateButton(),
                  if (_currentStep < 3) _buildTrackingNote(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return SizedBox(
      height: 155,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B4332), Color(0xFF14532D)],
              ),
            ),
          ),
          CustomPaint(painter: _MapGridPainter()),
          const Center(
            child: Icon(Icons.location_on, size: 28, color: Colors.red),
          ),
          if (_currentStep < 3)
            Positioned(
              bottom: 40,
              left: 64,
              child: SizedBox(
                width: 26,
                height: 26,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseScale.value,
                        child: Opacity(
                          opacity: _pulseOpacity.value,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentStep == 3)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Delivered!',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
            ),
          // Back button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_ios,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orderId.isNotEmpty
                      ? 'Order #${_orderId.substring(0, _orderId.length.clamp(0, 8)).toUpperCase()}'
                      : 'Your Order',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFAAAAAA)),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _currentStep == 3
                        ? const Color(0xFF16A34A)
                        : AppTheme.dark,
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: _currentStep == 3
                    ? const Color(0xFFEDFCF2)
                    : const Color(0xFFFFF0F2),
                border: Border.all(
                    color: _currentStep == 3
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFECDD3),
                    width: 1.5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                _etaLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _currentStep == 3
                      ? const Color(0xFF16A34A)
                      : AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildStepRow(int stepIndex) {
    final state = _stepState(stepIndex);
    final isDone = state == 'done';
    final isNow = state == 'now';
    final isWait = state == 'wait';

    Color dotBg;
    if (isDone) {
      dotBg = const Color(0xFFEDFCF2);
    } else if (isNow) {
      dotBg = AppTheme.primary;
    } else {
      dotBg = const Color(0xFFF2F2F2);
    }

    final iconData = _stepIcons[stepIndex];
    final stepIcon = Icon(
      iconData,
      size: 16,
      color: isDone
          ? const Color(0xFF16A34A)
          : isNow
              ? Colors.white
              : const Color(0xFFAAAAAA),
    );

    return AnimatedOpacity(
      opacity: isWait ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: isNow
              ? Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: dotBg, shape: BoxShape.circle),
              child: Center(child: stepIcon),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepNames[stepIndex],
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isWait
                          ? const Color(0xFFCCCCCC)
                          : AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isDone || isNow
                        ? _stepSub(stepIndex)
                        : 'Waiting...',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
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

  Widget _buildDriverCard() {
    final driverId = _order?['driverId'] as String?;
    final hasDriver = driverId != null && driverId.isNotEmpty;

    if (!hasDriver) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Icon(Icons.person_search,
                    size: 22, color: Color(0xFFBBBBBB)),
              ),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finding your driver...',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark),
                ),
                const SizedBox(height: 2),
                Text(
                  'A driver will be assigned shortly',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final driverName = _driver?['name'] as String? ?? 'Your Driver';
    final avgRating =
        (_driver?['averageRating'] as num?)?.toStringAsFixed(1) ?? '5.0';
    final vehicleMake = _driver?['vehicleMake'] as String? ?? '';
    final vehicleModel = _driver?['vehicleModel'] as String? ?? '';
    final licensePlate = _driver?['licensePlate'] as String? ?? '';
    final vehicleInfo = [
      if (vehicleMake.isNotEmpty || vehicleModel.isNotEmpty)
        '$vehicleMake $vehicleModel'.trim(),
      if (licensePlate.isNotEmpty) licensePlate,
    ].join('  ·  ');

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Center(
              child:
                  Icon(Icons.person, size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 10, color: Color(0xFFFACC15)),
                    Text(
                      ' $avgRating${vehicleInfo.isNotEmpty ? '  ·  $vehicleInfo' : ''}',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Calling $driverName...',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700)),
                backgroundColor: const Color(0xFF16A34A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEDFCF2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(
                child: Icon(Icons.phone,
                    size: 18, color: Color(0xFF16A34A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            '/rate-driver',
            arguments: {
              'orderId': _orderId,
              'driverId': _order?['driverId'] ?? '',
              'merchantId': _order?['merchantId'] ?? '',
              'merchantName': _order?['merchantName'] ?? '',
            },
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
            elevation: 0,
          ),
          child: Text(
            'Rate Your Experience →',
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      );

  Widget _buildTrackingNote() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: Color(0xFFAAAAAA)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "We'll notify you when your order is delivered.",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fine);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fine);
    }
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 84) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (double y = 0; y < size.height; y += 84) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
