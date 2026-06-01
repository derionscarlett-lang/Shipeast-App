import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('driver_logged_in') ?? false;
  runApp(ShipEastDriverApp(initialRoute: isLoggedIn ? '/dashboard' : '/login'));
}

class ShipEastDriverApp extends StatelessWidget {
  final String initialRoute;
  const ShipEastDriverApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipEast Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DriverShell(),
      },
    );
  }
}

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _selectedIndex = 0;
  final ValueNotifier<String> _driverNameNotifier = ValueNotifier<String>('Driver');

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _driverNameNotifier.value = prefs.getString('driver_name') ?? 'Driver';
    });
  }

  @override
  void dispose() {
    _driverNameNotifier.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _navItems = [
    {'label': 'Home', 'icon': Icons.home},
    {'label': 'History', 'icon': Icons.history},
    {'label': 'Earnings', 'icon': Icons.account_balance_wallet},
    {'label': 'Profile', 'icon': Icons.person},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            onTabSwitch: (i) => setState(() => _selectedIndex = i),
            driverNameNotifier: _driverNameNotifier,
          ),
          const HistoryScreen(),
          const EarningsScreen(),
          ProfileScreen(driverNameNotifier: _driverNameNotifier),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final active = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _navItems[i]['icon'] as IconData,
                          size: 22,
                          color: active
                              ? AppTheme.primary
                              : const Color(0xFFC0C0C0),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[i]['label'] as String,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
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
