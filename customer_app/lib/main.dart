import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/merchant_menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/order_confirmed_screen.dart';
import 'screens/order_status_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/overseas_order_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rate_driver_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ShipEastApp());
}

class ShipEastApp extends StatelessWidget {
  const ShipEastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipEast',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/merchant': (_) => const MerchantMenuScreen(),
        '/cart': (_) => const CartScreen(),
        '/checkout': (_) => const CheckoutScreen(),
        '/payment': (_) => const PaymentScreen(),
        '/order-confirmed': (_) => const OrderConfirmedScreen(),
        '/order-status': (_) => const OrderStatusScreen(),
        '/order-history': (_) => const OrderHistoryScreen(),
        '/overseas-order': (_) => const OverseasOrderScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/rate-driver': (_) => const RateDriverScreen(),
      },
    );
  }
}
