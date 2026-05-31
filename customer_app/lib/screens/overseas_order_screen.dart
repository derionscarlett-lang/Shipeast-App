import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primary),
                          SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 14,
          left: 16,
          right: 16,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.primary,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order for Family in Jamaica',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Diaspora overseas ordering portal',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.flight, size: 24, color: Colors.white),
          ],
        ),
      );

  Widget _buildInfoBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0F2),
          border: Border(bottom: BorderSide(color: Color(0xFFFECDD3))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.public, size: 20, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sending home from overseas?',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'For persons living overseas who want to send groceries, meals or gifts to family and friends in Jamaica.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF9E0B23),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.wifi_off,
                      size: 38, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Connection Error',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load the overseas order form. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                      _usedFallback = false;
                    });
                    _controller.loadRequest(Uri.parse(_primaryUrl));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF888888),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
