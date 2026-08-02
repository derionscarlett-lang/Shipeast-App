import 'package:flutter_test/flutter_test.dart';
import 'package:shipeast_driver/screens/delivery_confirmation_screen.dart';
import 'package:shipeast_driver/screens/login_screen.dart';
import 'package:shipeast_driver/screens/new_order_screen.dart';
import 'package:shipeast_driver/screens/pickup_confirmation_screen.dart';
import 'package:shipeast_driver/screens/register_screen.dart';

import 'harness.dart';
import 'previews.dart';

/// A job, shaped exactly as Firestore hands one to these screens.
const _order = {
  'id': 'se4821bf90c1',
  'type': 'food',
  'status': 'confirmed',
  'merchantName': 'Island Grill Morant Bay',
  'merchantAddr': '3 Queen Street, Morant Bay',
  'merchantPhone': '8767341200',
  'customerName': 'Kemar Brown',
  'customerPhone': '8764459812',
  'deliveryAddress': '14 Yallahs Main Road, St. Thomas',
  'items': [
    {'name': 'Curry Goat with Rice & Peas', 'quantity': 2, 'price': 1450},
    {'name': 'Festival (2 pcs)', 'quantity': 1, 'price': 300},
    {'name': 'Ting', 'quantity': 3, 'price': 250},
  ],
  'subtotal': 3850,
  'deliveryFee': 350,
  'total': 4585,
  'paymentMethod': 'Cash on Delivery',
};

void main() {
  // ── Photographed for real ─────────────────────────────────────────────────
  // These four reach Firebase only from a BUTTON, so they render truthfully.
  // Sign-in is where the app OPENS, so it is shot at the root: no back button,
  // and the brand lockup in its place.
  testWidgets('login',
      (t) async => shoot(t, const LoginScreen(), 'login', root: true));
  testWidgets('register',
      (t) async => shoot(t, const RegisterScreen(), 'register'));
  testWidgets(
      'new-order',
      (t) async => shoot(
          t,
          const NewOrderScreen(order: _order, pickupDistanceMeters: 2400),
          'new-order'));
  testWidgets(
      'pickup',
      (t) async => shoot(
          t,
          const PickupConfirmationScreen(
              orderId: 'se4821bf90c1', order: _order),
          'pickup'));
  testWidgets(
      'delivery',
      (t) async => shoot(
          t,
          const DeliveryConfirmationScreen(
              orderId: 'se4821bf90c1', order: _order),
          'delivery'));

  // ── Mirrored ──────────────────────────────────────────────────────────────
  // These five read Firestore in `initState`/`build`, so they cannot be pumped.
  // `previews.dart` rebuilds each one from the same widgets against fixed data.
  testWidgets('dashboard', (t) async => shoot(t, dashboardPreview(), 'dashboard'));
  testWidgets('dashboard-offline',
      (t) async => shoot(t, dashboardOfflinePreview(), 'dashboard-offline'));
  testWidgets('history', (t) async => shoot(t, historyPreview(), 'history'));
  testWidgets('history-empty',
      (t) async => shoot(t, historyEmptyPreview(), 'history-empty'));
  testWidgets('earnings', (t) async => shoot(t, earningsPreview(), 'earnings'));
  testWidgets('profile', (t) async => shoot(t, profilePreview(), 'profile'));
  testWidgets('pending-approval',
      (t) async => shoot(t, pendingApprovalPreview(), 'pending-approval'));
  testWidgets('delivery-done',
      (t) async => shoot(t, deliveryDonePreview(), 'delivery-done'));

  // The small phone is the floor we support; the dashboard is the screen most
  // likely to overflow on it.
  testWidgets(
      'dashboard-small',
      (t) async =>
          shoot(t, dashboardPreview(), 'dashboard-small', size: small));
}
