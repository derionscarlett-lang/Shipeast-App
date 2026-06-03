import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'pending_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licencePlateController = TextEditingController();
  final _licenceNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedVehicle = 'Motorcycle';

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'label': 'Motorcycle', 'icon': Icons.motorcycle},
    {'label': 'Car', 'icon': Icons.directions_car},
    {'label': 'Van', 'icon': Icons.airport_shuttle},
    {'label': 'Truck', 'icon': Icons.local_shipping},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licencePlateController.dispose();
    _licenceNumberController.dispose();
    super.dispose();
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  Future<void> _createAccount() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final uid = credential.user!.uid;
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'vehicleType': _selectedVehicle,
        'licencePlate': _licencePlateController.text.trim(),
        'licenceNumber': _licenceNumberController.text.trim(),
        'status': 'pending',
        'isOnline': false,
        'rating': 5.0,
        'totalTrips': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_authErrorMessage(e.code)),
        backgroundColor: AppTheme.primary,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration failed: $e'),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Driver Registration',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join the ShipEast delivery network',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Full Name
              TextFormField(
                controller: _nameController,
                style: AppTheme.body(),
                decoration:
                    AppTheme.inputDecoration('Full Name', Icons.person_outline),
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTheme.body(),
                decoration: AppTheme.inputDecoration(
                    'Phone Number', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.body(),
                decoration:
                    AppTheme.inputDecoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 12),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTheme.body(),
                decoration:
                    AppTheme.inputDecoration('Password', Icons.lock_outline)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: AppTheme.body(),
                decoration: AppTheme.inputDecoration(
                        'Confirm Password', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textLight,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Vehicle Information section
              Text(
                'Vehicle Information',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Vehicle type chips
              Row(
                children: _vehicleTypes.map((vehicle) {
                  final isSelected = _selectedVehicle == vehicle['label'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedVehicle = vehicle['label']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: const Color(0xFFE0E0E0), width: 1),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              vehicle['icon'] as IconData,
                              color:
                                  isSelected ? Colors.white : AppTheme.textMid,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vehicle['label'] as String,
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMid,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Licence Plate
              TextFormField(
                controller: _licencePlateController,
                style: AppTheme.body(),
                decoration: AppTheme.inputDecoration(
                        'Licence Plate', Icons.credit_card_outlined)
                    .copyWith(hintText: 'ABC 1234'),
              ),
              const SizedBox(height: 12),

              // Licence Number
              TextFormField(
                controller: _licenceNumberController,
                style: AppTheme.body(),
                decoration: AppTheme.inputDecoration(
                        'Licence Number', Icons.badge_outlined)
                    .copyWith(hintText: 'DL-XXXXXXXX'),
              ),
              const SizedBox(height: 24),

              // Create Account button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: AppTheme.buttonLG(),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Sign In link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMid,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
