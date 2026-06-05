import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../services/driver_firestore_service.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const DeliveryConfirmationScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  State<DeliveryConfirmationScreen> createState() =>
      _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState
    extends State<DeliveryConfirmationScreen> {
  File? _photo;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  String get _customerName =>
      widget.order['customerName'] as String? ?? 'Customer';
  String get _deliveryAddress =>
      widget.order['deliveryAddress'] as String? ?? '—';
  int get _total => (widget.order['total'] as num?)?.toInt() ?? 0;
  String get _paymentMethod =>
      widget.order['paymentMethod'] as String? ?? 'COD';

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '\$${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$price';
  }

  bool get _isCod =>
      _paymentMethod.toLowerCase().contains('cod') ||
      _paymentMethod.toLowerCase().contains('cash');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1080);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Photo',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title:
                  Text('Take Photo', style: GoogleFonts.inter(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.primary),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.inter(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('Remove Photo',
                    style:
                        GoogleFonts.inter(fontSize: 14, color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDelivered() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      String? photoUrl;
      if (_photo != null) {
        try {
          photoUrl = await DriverFirestoreService.uploadDeliveryPhoto(
              widget.orderId, _photo!);
        } catch (_) {
          // Photo upload failed — still mark as delivered
        }
      }
      await DriverFirestoreService.confirmDelivery(
        widget.orderId,
        uid,
        _total,
        photoUrl,
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to confirm delivery. Try again.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 40),
            ),
            const SizedBox(height: 18),
            Text('Delivery Complete!',
                style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(
              'Order delivered to $_customerName.\nGreat job!',
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppTheme.textMid),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Earned ${_formatPrice(_total ~/ 10)} this trip',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            if (_isCod) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments,
                        color: AppTheme.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collect ${_formatPrice(_total)} from customer',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name == '/dashboard' ||
                          route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text('Back to Dashboard',
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Delivery Confirmation',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: AppTheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC8102E), Color(0xFFB00D28)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Almost There!',
                            style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Confirm delivery to complete the order',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Details',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  _detailRow(Icons.person, 'Customer', _customerName),
                  const SizedBox(height: 8),
                  _detailRow(Icons.location_on, 'Address', _deliveryAddress),
                  const SizedBox(height: 8),
                  _detailRow(Icons.payments, 'Payment',
                      '$_paymentMethod – ${_formatPrice(_total)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Photo (Optional)',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text('Take a photo as proof of delivery',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textMid)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E5E5), width: 1.5),
                      ),
                      child: _photo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_photo!,
                                  fit: BoxFit.cover,
                                  width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt,
                                    size: 36, color: Color(0xFFCCCCCC)),
                                const SizedBox(height: 8),
                                Text('Tap to add photo',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppTheme.textMid)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Note (Optional)',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'Any notes about the delivery...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textLight),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F7),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E5E5))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E5E5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.primary)),
                      contentPadding: const EdgeInsets.all(12),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _markAsDelivered,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Mark as Delivered',
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMid),
          const SizedBox(width: 8),
          SizedBox(
              width: 72,
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMid))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
          ),
        ],
      );
}
