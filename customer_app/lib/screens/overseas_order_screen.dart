import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/se_colors.dart';
import '../theme/se_icons.dart';
import '../theme/se_typography.dart';
import '../widgets/se_app_bar.dart';
import '../widgets/se_button.dart';
import '../widgets/se_empty_state.dart';

class OverseasOrderScreen extends StatefulWidget {
  const OverseasOrderScreen({super.key});

  @override
  State<OverseasOrderScreen> createState() => _OverseasOrderScreenState();
}

class _OverseasOrderScreenState extends State<OverseasOrderScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _usedFallback = false;

  static const _primaryUrl = 'https://tally.so/r/shipeast';
  static const _fallbackUrl = 'https://form.jotform.com/shipeast';

  static const LinearGradient _oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E9488), Color(0xFF0B6E66)],
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() {
          _isLoading = true;
          _hasError = false;
        }),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (_) {
          if (!_usedFallback) {
            setState(() {
              _usedFallback = true;
              _isLoading = true;
              _hasError = false;
            });
            _controller.loadRequest(Uri.parse(_fallbackUrl));
          } else {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(_primaryUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeColors.surface0,
      body: Column(
        children: [
          const SeGradientHeader(
            title: 'Order for Family in Jamaica',
            subtitle: 'Diaspora overseas ordering portal',
            gradient: _oceanGradient,
            trailing: Icon(SeIcons.plane, size: 24, color: Colors.white),
          ),
          _buildInfoBanner(),
          Expanded(
            child: Stack(
              children: [
                if (!_hasError)
                  WebViewWidget(controller: _controller)
                else
                  _buildErrorState(),
                if (_isLoading && !_hasError)
                  Container(
                    color: Colors.white.withValues(alpha: 0.7),
                    child: const Center(
                      child: CircularProgressIndicator(color: SeColors.ocean500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: SeColors.oceanTint,
          border: Border(bottom: BorderSide(color: Color(0xFFBFE7E2))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(SeIcons.plane, size: 20, color: SeColors.ocean500),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sending home from overseas?',
                      style: SeType.label.copyWith(color: SeColors.ocean500)),
                  const SizedBox(height: 2),
                  Text(
                    'For persons living overseas who want to send groceries, meals or gifts to family and friends in Jamaica.',
                    style: SeType.bodyS.copyWith(color: const Color(0xFF0B6E66)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SeEmptyState(
              icon: SeIcons.noConnection,
              title: 'Connection Error',
              message:
                  'Unable to load the overseas order form. Please check your internet connection and try again.',
              hue: SeColors.ocean500,
              tint: SeColors.oceanTint,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SeButton(
                label: 'Retry',
                icon: SeIcons.arrowRight,
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _usedFallback = false;
                  });
                  _controller.loadRequest(Uri.parse(_primaryUrl));
                },
              ),
            ),
          ],
        ),
      );
}
