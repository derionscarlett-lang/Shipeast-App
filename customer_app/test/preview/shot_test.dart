import 'package:flutter_test/flutter_test.dart';
import 'package:shipeast_customer/screens/coming_soon_screen.dart';
import 'package:shipeast_customer/screens/help_support_screen.dart';
import 'package:shipeast_customer/screens/order_confirmed_screen.dart';
import 'package:shipeast_customer/screens/order_status_screen.dart';
import 'package:shipeast_customer/screens/payment_screen.dart';
import 'package:shipeast_customer/screens/privacy_security_screen.dart';
import 'package:shipeast_customer/screens/rate_driver_screen.dart';
import 'package:shipeast_customer/screens/welcome_screen.dart';

import 'harness.dart';
import 'previews.dart';

/// Order args, shaped exactly as checkout hands them on.
const _order = {
  'merchantId': 'm1',
  'merchantName': 'Island Grill Morant Bay',
  'items': [
    {'name': 'Curry Goat with Rice & Peas', 'quantity': 2, 'price': 1450},
    {'name': 'Festival (2 pcs)', 'quantity': 1, 'price': 300},
    {'name': 'Ting', 'quantity': 3, 'price': 250},
  ],
  'subtotal': 3850,
  'deliveryFee': 350,
  'serviceFee': 385,
  'discount': 0,
  'total': 4585,
  'deliveryAddress': '14 Yallahs Main Road, St. Thomas',
  'paymentMethod': 'Cash on Delivery',
  'orderId': 'se4821bf90c1',
};

void main() {
  // Screens that touch no Firebase before their first frame: photographed for
  // real, not mirrored.
  testWidgets('welcome', (t) async => shoot(t, const WelcomeScreen(), 'welcome'));
  testWidgets('payment',
      (t) async => shoot(t, const PaymentScreen(), 'payment', args: _order));
  testWidgets(
      'confirmed',
      (t) async => shoot(t, const OrderConfirmedScreen(), 'confirmed',
          args: _order));
  testWidgets(
      'track', (t) async => shoot(t, const OrderStatusScreen(), 'track'));
  testWidgets('rate', (t) async => shoot(t, const RateDriverScreen(), 'rate'));
  testWidgets('help', (t) async => shoot(t, const HelpSupportScreen(), 'help'));
  testWidgets('privacy',
      (t) async => shoot(t, const PrivacySecurityScreen(), 'privacy'));
  testWidgets('coming-soon',
      (t) async => shoot(t, const ComingSoonScreen(title: 'Wallet'), 'coming-soon'));

  // Screens that reach for Firebase in initState: mirrored (see previews.dart).
  testWidgets('home', (t) async => shoot(t, homePreview(), 'home'));
  testWidgets('home-small',
      (t) async => shoot(t, homePreview(), 'home-small', size: small));
  testWidgets('search', (t) async => shoot(t, searchPreview(), 'search'));
  testWidgets('alerts', (t) async => shoot(t, alertsPreview(), 'alerts'));
  testWidgets('orders', (t) async => shoot(t, ordersPreview(), 'orders'));
  testWidgets('profile', (t) async => shoot(t, profilePreview(), 'profile'));
  testWidgets('menu', (t) async => shoot(t, menuPreview(), 'menu'));
  testWidgets('cart', (t) async => shoot(t, cartPreview(), 'cart'));
  testWidgets('checkout', (t) async => shoot(t, checkoutPreview(), 'checkout'));
  testWidgets('overseas', (t) async => shoot(t, overseasPreview(), 'overseas'));
  testWidgets('overseas-small',
      (t) async => shoot(t, overseasPreview(), 'overseas-small', size: small));
}
