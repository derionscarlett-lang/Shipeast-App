import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../widgets/se_card.dart';
import '../widgets/se_button.dart';
import '../widgets/se_toast.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

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
        return 'Done';
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
    SeIcons.checkCircle,
    SeIcons.box,
    SeIcons.bike,
    SeIcons.home,
  ];

  String _stepSub(int index) {
    final merchantName = _order?['merchantName'] as String? ?? 'Merchant';
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
    final delivered = _currentStep == 3;
    return Scaffold(
      backgroundColor: SeColors.surface50,
      body: Column(
        children: [
          _buildHero(delivered),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SeSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepper(),
                  const SizedBox(height: 16),
                  _buildDriverCard(),
                  const SizedBox(height: 12),
                  if (delivered && _order?['rated'] != true)
                    SeButton(
                      label: 'Rate Your Experience',
                      icon: SeIcons.star,
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
                    ),
                  if (!delivered) _buildTrackingNote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Honest live-tracking status hero (SEDS) — deliberately NOT a fake street
  // map. Shows the real order status, a route progress bar, and a pulsing
  // "current" node. A real map lands with the maps integration (see audit).
  Widget _buildHero(bool delivered) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            delivered ? _successGradient : SeColors.emberGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, SeSpacing.gutter, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(SeIcons.arrowLeft,
                          size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _orderId.isNotEmpty
                          ? 'Order #${_orderId.substring(0, _orderId.length.clamp(0, 8)).toUpperCase()}'
                          : 'Your Order',
                      style: SeType.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: SeRadius.pill,
                    ),
                    child: Text(_etaLabel,
                        style: SeType.tabular(SeType.label)
                            .copyWith(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(_statusLabel, style: SeType.h1.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                delivered
                    ? 'Thanks for ordering with ShipEast.'
                    : 'Live status · updates automatically',
                style: SeType.bodyS.copyWith(
                    color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              _routeBar(delivered),
            ],
          ),
        ),
      ),
    );
  }

  static const LinearGradient _successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF0B7A38)],
  );

  Widget _routeBar(bool delivered) {
    final progress = (_currentStep / 3).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        return SizedBox(
          height: 24,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress == 0 ? 0.02 : progress,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Moving node
              Positioned(
                left: (width - 20) * progress,
                child: _pulseNode(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pulseNode() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_currentStep < 3)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) => Transform.scale(
                scale: 0.7 + _pulseCtrl.value * 1.3,
                child: Opacity(
                  opacity: (1 - _pulseCtrl.value).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: SeElevation.e1,
            ),
            child: Icon(
              _currentStep >= 3 ? SeIcons.check : SeIcons.bike,
              size: 8,
              color: SeColors.red500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return SeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(4, (i) => _stepRow(i, isLast: i == 3)),
      ),
    );
  }

  Widget _stepRow(int stepIndex, {required bool isLast}) {
    final state = _stepState(stepIndex);
    final isDone = state == 'done';
    final isNow = state == 'now';
    final isWait = state == 'wait';

    final Color dotBg = isDone
        ? SeColors.successTint
        : isNow
            ? SeColors.red500
            : SeColors.surface50;
    final Color iconColor = isDone
        ? SeColors.success
        : isNow
            ? Colors.white
            : SeColors.ink300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: dotBg,
                  shape: BoxShape.circle,
                  boxShadow:
                      isNow ? SeElevation.glow : SeElevation.e0,
                ),
                child: Icon(_stepIcons[stepIndex], size: 18, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? SeColors.success : SeColors.ink200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: isLast ? 8 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepNames[stepIndex],
                    style: SeType.title.copyWith(
                        color: isWait ? SeColors.ink400 : SeColors.ink900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone || isNow ? _stepSub(stepIndex) : 'Waiting...',
                    style: SeType.bodyS.copyWith(color: SeColors.ink400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callDriver(String name) async {
    final phone = (_driver?['phone'] as String?)?.trim() ?? '';
    if (phone.isEmpty) {
      if (mounted) SeToast.info(context, 'Driver contact not available yet');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      SeToast.error(context, 'Could not start the call');
    }
  }

  Widget _buildDriverCard() {
    final driverId = _order?['driverId'] as String?;
    final hasDriver = driverId != null && driverId.isNotEmpty;

    if (!hasDriver) {
      return SeCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: SeColors.surface50,
                borderRadius: SeRadius.all(SeRadius.sm),
              ),
              child: const Icon(SeIcons.user, size: 22, color: SeColors.ink300),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Finding your driver...', style: SeType.title),
                  const SizedBox(height: 2),
                  Text('A driver will be assigned shortly',
                      style: SeType.bodyS.copyWith(color: SeColors.ink400)),
                ],
              ),
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

    return SeCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: SeColors.emberGradient,
              borderRadius: SeRadius.all(SeRadius.sm),
            ),
            child: const Icon(SeIcons.user, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName, style: SeType.title),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(SeIcons.star, size: 12, color: SeColors.gold500),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '$avgRating${vehicleInfo.isNotEmpty ? '  ·  $vehicleInfo' : ''}',
                        style: SeType.bodyS.copyWith(color: SeColors.ink500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _callDriver(driverName),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SeColors.successTint,
                borderRadius: SeRadius.all(SeRadius.sm),
              ),
              child: const Icon(SeIcons.phone, size: 18, color: SeColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingNote() => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SeColors.oceanTint,
          borderRadius: SeRadius.all(SeRadius.md),
        ),
        child: Row(
          children: [
            const Icon(SeIcons.info, size: 18, color: SeColors.ocean500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "We'll notify you when your order is delivered.",
                style: SeType.bodyS.copyWith(color: SeColors.ocean500),
              ),
            ),
          ],
        ),
      );
}
