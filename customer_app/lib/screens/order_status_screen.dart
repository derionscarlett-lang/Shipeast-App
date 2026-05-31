import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  int _currentStep = 0;
  bool _demoRunning = false;
  Timer? _demoTimer;

  static const _stepDefs = [
    {
      'name': 'Order Confirmed',
      'sub': 'Island Jerk Palace accepted',
      'time': '9:41 AM',
      'icon': Icons.check_circle,
      'emoji': null,
    },
    {
      'name': 'Order Picked Up',
      'sub': 'Driver collected your order',
      'time': '9:58 AM',
      'icon': Icons.check_circle,
      'emoji': null,
    },
    {
      'name': 'On the Way',
      'sub': 'Driver heading to you now',
      'time': 'Live',
      'icon': Icons.delivery_dining,
      'emoji': null,
    },
    {
      'name': 'Delivered',
      'sub': 'Order delivered successfully!',
      'time': '10:24 AM',
      'icon': Icons.home,
      'emoji': null,
    },
  ];

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
        return '';
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
  void dispose() {
    _pulseCtrl.dispose();
    _demoTimer?.cancel();
    super.dispose();
  }

  void _toggleDemo() {
    if (_demoRunning) {
      _demoTimer?.cancel();
      setState(() => _demoRunning = false);
    } else {
      if (_currentStep >= 3) {
        setState(() => _currentStep = 0);
      }
      setState(() => _demoRunning = true);
      _demoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_currentStep < 3) {
            _currentStep++;
          } else {
            timer.cancel();
            _demoRunning = false;
          }
        });
      });
    }
  }

  String _stepState(int stepIndex) {
    if (stepIndex < _currentStep) return 'done';
    if (stepIndex == _currentStep) return 'now';
    return 'wait';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildMapArea(),
          _buildStatusBar(),
          _buildDemoStrip(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...List.generate(_stepDefs.length, _buildStepRow),
                  const SizedBox(height: 8),
                  _buildDriverCard(),
                  const SizedBox(height: 12),
                  if (_currentStep == 3) _buildRateButton(),
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
                              color:
                                  AppTheme.primary.withValues(alpha: 0.25),
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
                        border: Border.all(color: Colors.white, width: 2.5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Delivered!',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
                  'Order #SE-20268814',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFAAAAAA),
                  ),
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

  Widget _buildDemoStrip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: _demoRunning
              ? const Color(0xFFFFF0F2)
              : const Color(0xFFF8F8F8),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFF2F2F2))),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _demoRunning
                    ? AppTheme.primary
                    : const Color(0xFFBBBBBB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _demoRunning
                    ? 'Demo running — watch the order progress live...'
                    : 'Demo Mode: Tap ▶ to watch the full order flow',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _demoRunning
                      ? AppTheme.primary
                      : const Color(0xFF888888),
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleDemo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _demoRunning
                      ? AppTheme.primary
                      : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _demoRunning ? '⏹ Stop' : '▶ Start',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildStepRow(int stepIndex) {
    final step = _stepDefs[stepIndex];
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

    final iconData = step['icon'] as IconData?;
    final emoji = step['emoji'] as String?;

    Widget stepIcon;
    if (iconData != null) {
      stepIcon = Icon(
        iconData,
        size: 16,
        color: isDone
            ? const Color(0xFF16A34A)
            : isNow
                ? Colors.white
                : const Color(0xFFAAAAAA),
      );
    } else {
      stepIcon = Text(emoji ?? '', style: const TextStyle(fontSize: 16));
    }

    final timeStr = step['time'] as String;
    final showTime = (isDone || isNow) && timeStr.isNotEmpty;

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
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3),
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
              decoration: BoxDecoration(
                color: dotBg,
                shape: BoxShape.circle,
              ),
              child: Center(child: stepIcon),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['name'] as String,
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
                        ? step['sub'] as String
                        : 'Waiting...',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showTime) ...[
                    const SizedBox(height: 1),
                    Text(
                      timeStr,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() => Container(
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
                child: Icon(Icons.person, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rohan Williams',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 10, color: Color(0xFFFACC15)),
                      Text(
                        ' 4.9  ·  Toyota Corolla  ·  PK-2048',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Calling Rohan Williams...',
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

  Widget _buildRateButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/rate-driver'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
            elevation: 0,
          ),
          child: Text(
            'Rate Your Experience →',
            style:
                GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
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
            const Icon(Icons.info_outline, size: 16, color: Color(0xFFAAAAAA)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'We\'ll notify you when your order is delivered.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFAAAAAA),
                  fontWeight: FontWeight.w500,
                ),
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
