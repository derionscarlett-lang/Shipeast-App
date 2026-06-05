import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'services/driver_firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

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

Future<void> _initFCM() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Foreground messages are handled by the active screen
  });
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await DriverFirestoreService.saveFcmToken(uid);
  }
  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentUid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  });
}

Future<Widget> _resolveHome() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const LoginScreen();
  try {
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .get();
    if (doc.exists && doc.data()?['status'] == 'approved') {
      return const DriverShell();
    }
  } catch (_) {}
  return const PendingApprovalScreen();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await _initFCM();
  final home = await _resolveHome();
  runApp(ShipEastDriverApp(home: home));
}

class ShipEastDriverApp extends StatelessWidget {
  final Widget home;
  const ShipEastDriverApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipEast Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: home,
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
  final ValueNotifier<String> _driverNameNotifier =
      ValueNotifier<String>('Driver');

  @override
  void initState() {
    super.initState();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        _driverNameNotifier.value =
            doc.data()?['name'] as String? ?? 'Driver';
      }
    } catch (_) {}
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
