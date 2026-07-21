import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../driver_constants.dart';
import '../models/order_status.dart';
import '../services/driver_firestore_service.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_motion.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';
import '../widgets/se_bottom_sheet.dart';
import '../widgets/se_card.dart';
import '../widgets/se_empty_state.dart';
import '../widgets/se_online_toggle.dart';
import '../widgets/se_stat_tile.dart';
import '../widgets/se_toast.dart';
import 'new_order_screen.dart';
import 'pickup_confirmation_screen.dart';
import 'delivery_confirmation_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onTabSwitch;
  final ValueNotifier<String> driverNameNotifier;
  const DashboardScreen(
      {super.key, required this.onTabSwitch, required this.driverNameNotifier});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool isOnline = false;
  bool _togglingPresence = false;
  int _todayEarnings = 0;
  int _todayDeliveries = 0;
  Map<String, dynamic>? _activeOrder;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<List<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSub;
  StreamSubscription<List<Map<String, dynamic>>>? _historySub;
  StreamSubscription<List<Map<String, dynamic>>>? _activeOrderSub;

  final Set<String> _seenOrderIds = {};
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
    _subscribeToDriverData();
    _subscribeToOrderHistory();
    _subscribeToActiveOrder();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ordersSub?.cancel();
    _driverSub?.cancel();
    _historySub?.cancel();
    _activeOrderSub?.cancel();
    super.dispose();
  }

  DriverPresence get _presence => _activeOrder != null
      ? DriverPresence.delivering
      : isOnline
          ? DriverPresence.online
          : DriverPresence.offline;

  void _subscribeToDriverData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _driverSub = DriverFirestoreService.driverStream(uid).listen(
      (snap) {
        if (!mounted) return;
        final data = snap.data();
        if (data == null) return;
        final newOnline = data['isOnline'] as bool? ?? false;
        final wasOnline = isOnline;
        setState(() => isOnline = newOnline);
        if (newOnline && !wasOnline) {
          if (_activeOrder == null) _startListening();
        } else if (!newOnline && wasOnline) {
          _ordersSub?.cancel();
          _ordersSub = null;
          _seenOrderIds.clear();
        }
      },
      // Audit §7.4: streams had no error handler, so a rules failure looked
      // identical to "no data".
      onError: (_) {
        if (mounted) SeToast.error(context, 'Lost connection to your profile.');
      },
    );
  }

  void _subscribeToActiveOrder() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _activeOrderSub = DriverFirestoreService.activeOrderStream(uid).listen(
      (orders) {
        if (!mounted) return;
        final hadActive = _activeOrder != null;
        final newActive = orders.isNotEmpty ? orders.first : null;
        setState(() => _activeOrder = newActive);

        if (newActive != null) {
          _ordersSub?.cancel();
          _ordersSub = null;
        } else if (hadActive && isOnline) {
          _seenOrderIds.clear();
          _startListening();
        }
      },
      onError: (_) {
        if (mounted) SeToast.error(context, 'Could not load your active order.');
      },
    );
  }

  void _subscribeToOrderHistory() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _historySub = DriverFirestoreService.driverOrderHistoryStream(uid).listen(
      (orders) {
        if (!mounted) return;
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final deliveredToday = orders.where((o) {
          if (o['status'] != OrderStatus.delivered) return false;
          final ts = (o['deliveredAt'] as Timestamp?)?.toDate();
          return ts != null && ts.isAfter(todayStart);
        }).toList();

        // Audit §7.2: `drivers/{uid}.todayEarnings` is incremented on delivery
        // but never reset at midnight, so it drifts away from the Earnings tab
        // forever. Deriving the figure from today's delivered orders keeps the
        // two screens in agreement and needs no scheduled reset.
        final earned = deliveredToday.fold<double>(
          0,
          (acc, o) => acc + DriverPay.commissionOn((o['total'] as num?) ?? 0),
        );

        setState(() {
          _todayDeliveries = deliveredToday.length;
          _todayEarnings = earned.round();
        });
      },
      onError: (_) {
        if (mounted) SeToast.error(context, 'Could not load today\'s trips.');
      },
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _setOnline(bool next) async {
    setState(() {
      isOnline = next;
      _togglingPresence = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null) {
        await DriverFirestoreService.setDriverOnline(uid, next);
      }
      if (next) {
        if (_activeOrder == null) _startListening();
      } else {
        _ordersSub?.cancel();
        _ordersSub = null;
        _seenOrderIds.clear();
      }
    } catch (_) {
      // Roll the control back so it never claims a state the backend rejected.
      if (mounted) {
        setState(() => isOnline = !next);
        SeToast.error(context, 'Could not update your status. Try again.');
      }
    } finally {
      if (mounted) setState(() => _togglingPresence = false);
    }
  }

  void _startListening() {
    _ordersSub?.cancel();
    _ordersSub = DriverFirestoreService.pendingOrdersStream().listen(
      (orders) async {
        if (!mounted || !isOnline || _navigating || _activeOrder != null) {
          return;
        }
        for (final order in orders) {
          final id = order['id'] as String? ?? '';
          if (id.isEmpty || _seenOrderIds.contains(id)) continue;
          _seenOrderIds.add(id);
          _navigating = true;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewOrderScreen(order: order)),
          );
          _navigating = false;
          break;
        }
      },
      onError: (_) {
        if (mounted) {
          SeToast.error(context, 'Order feed interrupted. Retrying…');
        }
      },
    );
  }

  /// Drives the active-order card's single tap target.
  ///
  /// Three states, not two. `picked_up` used to jump straight to delivery
  /// confirmation, so `in_transit` was never written and the customer's
  /// "On the Way" step was unreachable — their tracker went from "Picked Up"
  /// to "Delivered" with no signal the driver had set off.
  Future<void> _continueActiveOrder() async {
    final order = _activeOrder;
    if (order == null) return;
    final status = order['status'] as String? ?? '';
    final orderId = order['id'] as String? ?? '';

    if (status == OrderStatus.confirmed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PickupConfirmationScreen(orderId: orderId, order: order),
        ),
      );
      return;
    }

    if (status == OrderStatus.pickedUp) {
      // Start the leg to the customer. The card re-renders from the stream as
      // "Confirm Delivery" once the write lands.
      try {
        await DriverFirestoreService.startTransit(orderId);
        if (mounted) SeToast.success(context, 'Delivery started.');
      } catch (_) {
        if (mounted) {
          SeToast.error(context, 'Could not start the delivery. Try again.');
        }
      }
      return;
    }

    if (status == OrderStatus.inTransit) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeliveryConfirmationScreen(orderId: orderId, order: order),
        ),
      );
    }
  }

  /// Replaces the old `showDialog` coming-soon alert with a SEDS sheet.
  void _showHelpSheet() {
    showSeBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SeSheetHandle(),
            SeEmptyState(
              icon: SeIcons.chat,
              title: 'Support is on the way',
              message:
                  'In-app support chat is still being built. For anything urgent right now, reach the ShipEast dispatch desk on the number in your driver pack.',
              ctaLabel: 'Got it',
              onCta: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeColors.surface50,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  SeSpacing.gutter, SeSpacing.x5, SeSpacing.gutter, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero presence control ─────────────────────────────
                  SeOnlineToggle(
                    presence: _presence,
                    busy: _togglingPresence,
                    onChanged: _setOnline,
                  ),
                  const SizedBox(height: SeSpacing.x5),

                  // ── Today's stats ─────────────────────────────────────
                  Text('TODAY', style: SeType.eyebrow),
                  const SizedBox(height: SeSpacing.x3),
                  Row(
                    children: [
                      Expanded(
                        child: SeStatTile(
                          icon: SeIcons.wallet,
                          label: 'Earned today',
                          value: _todayEarnings,
                          prefix: Money.symbol,
                        ),
                      ),
                      const SizedBox(width: SeSpacing.x3),
                      Expanded(
                        child: SeStatTile(
                          icon: SeIcons.bike,
                          label: 'Deliveries',
                          value: _todayDeliveries,
                          hue: SeColors.ocean500,
                          tint: SeColors.oceanTint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SeSpacing.x6),

                  Text('CURRENT JOB', style: SeType.eyebrow),
                  const SizedBox(height: SeSpacing.x3),
                  AnimatedSwitcher(
                    duration: SeMotion.reduced(context)
                        ? Duration.zero
                        : SeMotion.base,
                    child: _activeOrder != null
                        ? _activeOrderCard(_activeOrder!)
                        : isOnline
                            ? _readyCard()
                            : _offlineCard(),
                  ),
                  const SizedBox(height: SeSpacing.x6),

                  Text('QUICK ACTIONS', style: SeType.eyebrow),
                  const SizedBox(height: SeSpacing.x3),
                  _quickAction(SeIcons.wallet, 'View Earnings',
                      'Trips, commission and payouts', SeColors.red500,
                      SeColors.red50, () => widget.onTabSwitch(2)),
                  const SizedBox(height: SeSpacing.x3),
                  _quickAction(SeIcons.history, 'Delivery History',
                      'Every job you have run', SeColors.success,
                      SeColors.successTint, () => widget.onTabSwitch(1)),
                  const SizedBox(height: SeSpacing.x3),
                  _quickAction(SeIcons.user, 'My Profile',
                      'Vehicle, licence and rating', SeColors.ocean500,
                      SeColors.oceanTint, () => widget.onTabSwitch(3)),
                  const SizedBox(height: SeSpacing.x3),
                  _quickAction(SeIcons.chat, 'Help & Support',
                      'Reach the dispatch desk', SeColors.gold500,
                      SeColors.goldTint, _showHelpSheet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Container(
        decoration: const BoxDecoration(gradient: SeColors.emberGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(SeSpacing.gutter, SeSpacing.x3,
                SeSpacing.gutter, SeSpacing.x5),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(SeIcons.userFill,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: SeSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: SeType.bodyS.copyWith(
                            color: Colors.white.withValues(alpha: 0.80)),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: widget.driverNameNotifier,
                        builder: (_, name, _) => Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SeType.h2.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _offlineCard() => SeCard(
        key: const ValueKey('offline'),
        padding: const EdgeInsets.all(SeSpacing.x5),
        color: SeColors.warningTint,
        shadow: SeElevation.e0,
        border: Border.all(
            color: SeColors.warning.withValues(alpha: 0.35), width: 1.5),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SeColors.warning.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(SeIcons.warning,
                  color: SeColors.warning, size: 22),
            ),
            const SizedBox(width: SeSpacing.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are offline', style: SeType.title),
                  const SizedBox(height: 2),
                  Text(
                    'Flip the switch above to start receiving orders.',
                    style: SeType.bodyS.copyWith(color: SeColors.ink500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _readyCard() => SeCard(
        key: const ValueKey('ready'),
        padding: const EdgeInsets.all(SeSpacing.x5),
        shadow: SeElevation.e1,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: SeColors.successTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(SeIcons.checkCircle,
                      color: SeColors.success, size: 22),
                ),
                const SizedBox(width: SeSpacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready for orders', style: SeType.title),
                      const SizedBox(height: 2),
                      Text(
                        'You are visible to dispatch right now.',
                        style: SeType.bodyS.copyWith(color: SeColors.ink500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SeSpacing.x4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: SeColors.success.withValues(
                        alpha: SeMotion.reduced(context)
                            ? 1.0
                            : _pulseAnimation.value,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: SeSpacing.x2),
                Text(
                  'Waiting for new orders…',
                  style: SeType.bodyS.copyWith(color: SeColors.success),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _activeOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final merchantName = order['merchantName'] as String? ?? 'Merchant';
    final customerName = order['customerName'] as String? ?? 'Customer';
    final deliveryAddress = order['deliveryAddress'] as String? ?? '—';
    final isPickup = status == OrderStatus.confirmed;
    final isReadyToDepart = status == OrderStatus.pickedUp;
    final orderId = order['id'] as String? ?? '';
    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    return SeCard(
      key: const ValueKey('active'),
      onTap: _continueActiveOrder,
      padding: const EdgeInsets.all(SeSpacing.x5),
      shadow: SeElevation.e2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: SeColors.red50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    isPickup
                        ? SeIcons.storefront
                        : isReadyToDepart
                            ? SeIcons.box
                            : SeIcons.bike,
                    color: SeColors.red700,
                    size: 20),
              ),
              const SizedBox(width: SeSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE DELIVERY', style: SeType.eyebrow),
                    Text(
                      isPickup
                          ? 'Head to merchant'
                          : isReadyToDepart
                              ? 'Start delivery'
                              : 'On the way',
                      style: SeType.h3,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: SeSpacing.x2, vertical: SeSpacing.x1),
                decoration: BoxDecoration(
                  color: SeColors.surface50,
                  borderRadius: SeRadius.all(SeRadius.xs),
                ),
                child: Text('#$shortId',
                    style: SeType.tabular(SeType.label)
                        .copyWith(color: SeColors.ink500)),
              ),
            ],
          ),
          const SizedBox(height: SeSpacing.x4),

          // ── Route line: pickup → dropoff ──────────────────────────────
          _RouteLine(
            pickupLabel: merchantName,
            dropoffLabel: '$customerName · $deliveryAddress',
            atPickup: isPickup,
          ),
          const SizedBox(height: SeSpacing.x4),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: SeSpacing.x3),
            decoration: BoxDecoration(
              gradient: SeColors.emberGradient,
              borderRadius: SeRadius.all(SeRadius.sm),
              boxShadow: SeElevation.glow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPickup ? SeIcons.navigation : SeIcons.checkCircle,
                    color: Colors.white, size: 18),
                const SizedBox(width: SeSpacing.x2),
                Text(
                  isPickup ? 'Go to pickup' : 'Confirm delivery',
                  style: SeType.jakarta(15, FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String title, String subtitle, Color hue,
          Color tint, VoidCallback onTap) =>
      SeCard(
        onTap: onTap,
        padding: const EdgeInsets.all(SeSpacing.x4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, color: hue, size: 21),
            ),
            const SizedBox(width: SeSpacing.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SeType.title),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: SeType.bodyS.copyWith(color: SeColors.ink500)),
                ],
              ),
            ),
            const Icon(SeIcons.caretRight, size: 20, color: SeColors.ink300),
          ],
        ),
      );
}

/// Pickup → dropoff route with a connecting rail, so the job reads as a
/// journey rather than two unrelated address lines.
class _RouteLine extends StatelessWidget {
  final String pickupLabel;
  final String dropoffLabel;
  final bool atPickup;

  const _RouteLine({
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.atPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SeSpacing.x4),
      decoration: BoxDecoration(
        color: SeColors.surface50,
        borderRadius: SeRadius.all(SeRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: atPickup ? SeColors.red500 : SeColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 3),
                color: SeColors.ink200,
              ),
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: atPickup ? SeColors.ink300 : SeColors.red500,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: SeSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PICKUP', style: SeType.eyebrow),
                Text(pickupLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SeType.body.copyWith(
                        color: SeColors.ink900, fontWeight: FontWeight.w500)),
                const SizedBox(height: SeSpacing.x2),
                Text('DROP-OFF', style: SeType.eyebrow),
                Text(dropoffLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SeType.body.copyWith(
                        color: SeColors.ink900, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
