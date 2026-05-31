import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: color ?? AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _handleLogin() {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();
    if (phone.isEmpty || pass.isEmpty) {
      _showSnackbar('Please fill in all fields',
          color: const Color(0xFFDC2626));
      return;
    }
    if (pass.length < 4) {
      _showSnackbar('Invalid phone/email or password',
          color: const Color(0xFFDC2626));
      return;
    }
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios, size: 16,
                            color: Color(0xFF444444)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Welcome back',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in to your ShipEast account',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF888888)),
                    ),
                    const SizedBox(height: 22),
                    _buildLabel('PHONE OR EMAIL'),
                    const SizedBox(height: 5),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'your@email.com or phone',
                      isActive: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('PASSWORD'),
                    const SizedBox(height: 5),
                    _buildPasswordField(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 18),
                        child: GestureDetector(
                          onTap: () =>
                              _showSnackbar('Password reset coming soon!'),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign In →',
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          const Expanded(
                              child: Divider(
                                  color: Color(0xFFEEEEEE), thickness: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'or continue with',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFBBBBBB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(
                                  color: Color(0xFFEEEEEE), thickness: 1)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _showSnackbar('Google Sign-In coming soon!'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          border: Border.all(
                              color: const Color(0xFFE8E8E8), width: 1.5),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('G',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4))),
                            const SizedBox(width: 9),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF888888),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: 'Sign Up',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF666666),
          letterSpacing: 0.4,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isActive = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final activeBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
    );
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: const Color(0xFF999999)),
        filled: true,
        fillColor: isActive ? const Color(0xFFFFF8F9) : AppTheme.inputBg,
        border: isActive ? activeBorder : normalBorder,
        enabledBorder: isActive ? activeBorder : normalBorder,
        focusedBorder: activeBorder,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildPasswordField() => TextField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.dark),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle:
              GoogleFonts.inter(fontSize: 13, color: const Color(0xFF999999)),
          filled: true,
          fillColor: AppTheme.inputBg,
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
            icon: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: const Color(0xFF999999),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}
