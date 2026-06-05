import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/firestore_service.dart';
import 'providers/cart_provider.dart';
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
import 'screens/saved_addresses_screen.dart';
import 'screens/search_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'theme/app_theme.dart';

Future<void> _initFirebase() async {
  for (int attempt = 1; attempt <= 5; attempt++) {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      return;
    } catch (e) {
      if (attempt == 5) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ShipEastApp());
}

class ShipEastApp extends StatelessWidget {
  const ShipEastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'ShipEast',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const MainShell(),
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
          '/saved-addresses': (_) => const SavedAddressesScreen(),
          '/search': (_) => const SearchScreen(),
          '/help-support': (_) => const HelpSupportScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/privacy-security': (_) => const PrivacySecurityScreen(),
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  StreamSubscription<int>? _unreadSub;

  static const List<Map<String, dynamic>> _navItems = [
    {'label': 'Home', 'icon': Icons.home},
    {'label': 'Search', 'icon': Icons.search},
    {'label': 'Orders', 'icon': Icons.receipt_long},
    {'label': 'Alerts', 'icon': Icons.notifications},
    {'label': 'Profile', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    _subscribeUnread();
  }

  void _subscribeUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _unreadSub = FirestoreService.unreadNotificationsCountStream(uid).listen((count) {
      if (mounted) setState(() => _unreadNotifications = count);
    });
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  Widget? _buildCartFab(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (ctx, cart, _) {
        if (cart.cartCount == 0) return const SizedBox.shrink();
        return FloatingActionButton(
          backgroundColor: AppTheme.primary,
          elevation: 4,
          onPressed: () => Navigator.pushNamed(ctx, '/cart'),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                  ),
                  child: Text(
                    cart.cartCount > 9 ? '9+' : '${cart.cartCount}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          SearchScreen(),
          OrderHistoryScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _buildCartFab(context),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final active = _selectedIndex == i;
                final isAlerts = _navItems[i]['label'] == 'Alerts';
                final showBadge = isAlerts && _unreadNotifications > 0 && !active;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _navItems[i]['icon'] as IconData,
                              size: 22,
                              color: active
                                  ? AppTheme.primary
                                  : const Color(0xFFC0C0C0),
                            ),
                            if (showBadge)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 14, minHeight: 14),
                                  child: Text(
                                    _unreadNotifications > 9
                                        ? '9+'
                                        : '$_unreadNotifications',
                                    style: const TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[i]['label'] as String,
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? AppTheme.primary
                                : const Color(0xFFC0C0C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
