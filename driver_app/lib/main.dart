import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

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
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
