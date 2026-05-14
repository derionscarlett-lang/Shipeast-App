import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back row
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
                        child: Text('←', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Create Account',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('FULL NAME'),
                    const SizedBox(height: 5),
                    _textField(
                      controller: _nameController,
                      hint: 'Marcus Thompson',
                      isActive: true,
                    ),
                    const SizedBox(height: 12),
                    _label('PHONE NUMBER'),
                    const SizedBox(height: 5),
                    _textField(
                      controller: _phoneController,
                      hint: '+1 876 000 0000',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _label('EMAIL ADDRESS'),
                    const SizedBox(height: 5),
                    _textField(
                      controller: _emailController,
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _label('PASSWORD'),
                    const SizedBox(height: 5),
                    _passwordField(),
                    const SizedBox(height: 14),
                    // Security note
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        border: Border.all(
                            color: const Color(0xFFFECDD3), width: 1.5),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Your info is encrypted and never shared',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9B1C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Create Account button
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Create My Account →',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    // Sign In link
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF888888),
                              ),
                            ),
                            TextSpan(
                              text: 'Sign In',
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF666666),
          letterSpacing: 0.4,
        ),
      );

  Widget _textField({
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

  Widget _passwordField() => TextField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.dark),
        decoration: InputDecoration(
          hintText: 'Create a password',
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
