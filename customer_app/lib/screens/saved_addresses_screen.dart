import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    if (_uid.isNotEmpty) {
      _sub = FirestoreService.addressStream(_uid).listen((addrs) {
        if (mounted) setState(() { _addresses = addrs; _loading = false; });
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    if (_uid.isEmpty) return;
    final isEdit = existing != null;
    final labelCtrl = TextEditingController(
        text: isEdit ? existing['label'] as String? ?? '' : '');
    final addressCtrl = TextEditingController(
        text: isEdit ? existing['text'] as String? ?? '' : '');
    const quickLabels = ['Home', 'Work', 'Mom', 'Dad', 'School', 'Other'];
    String selectedQuick = isEdit &&
            quickLabels.contains(existing['label'])
        ? existing['label'] as String
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? 'Edit Address' : 'Add New Address',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark),
                ),
                const SizedBox(height: 14),
                Text('Label',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF888888))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickLabels.map((ql) {
                    final sel = selectedQuick == ql;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => selectedQuick = ql);
                        labelCtrl.text = ql;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary
                              : const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? AppTheme.primary
                                : const Color(0xFFE5E5E5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(ql,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF555555),
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: labelCtrl,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF333333)),
                  decoration: _inputDeco('Or type a custom label...'),
                ),
                const SizedBox(height: 10),
                Text('Address',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF888888))),
                const SizedBox(height: 6),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF333333)),
                  decoration:
                      _inputDeco('e.g. 14 Yallahs Main Road, St. Thomas'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final label = labelCtrl.text.trim();
                      final text = addressCtrl.text.trim();
                      if (label.isEmpty || text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please fill in both fields',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700)),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                        return;
                      }
                      Navigator.pop(ctx);
                      if (isEdit) {
                        await FirestoreService.updateAddress(
                            _uid,
                            existing['id'] as String,
                            label,
                            text);
                      } else {
                        await FirestoreService.addAddress(_uid, label, text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Address',
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBBBBB)),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        isDense: true,
      );

  Future<void> _deleteAddress(Map<String, dynamic> addr) async {
    if (_uid.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Address',
            style: GoogleFonts.montserrat(
                fontSize: 15, fontWeight: FontWeight.w900)),
        content: Text('Remove "${addr['label']}"?',
            style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreService.deleteAddress(_uid, addr['id'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
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
                    color: Color(0xFFF2F2F2), shape: BoxShape.circle),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios,
                      size: 16, color: Color(0xFF444444)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Saved Addresses',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark),
              ),
            ),
            GestureDetector(
              onTap: () => _showAddEditDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+ Add',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off,
                size: 52, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 14),
            Text('No saved addresses',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dark)),
            const SizedBox(height: 6),
            Text('Tap + Add to save a delivery address',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF888888))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add_location_alt, size: 16),
              label: Text('Add New Address',
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _addresses.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _buildAddressCard(_addresses[i]),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    final label = addr['label'] as String? ?? '';
    final text = addr['text'] as String? ?? '';
    final iconData = label == 'Home'
        ? Icons.home
        : label == 'Work'
            ? Icons.work
            : Icons.location_on;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child:
                  Icon(iconData, size: 20, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.dark)),
                const SizedBox(height: 3),
                Text(text,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF666666))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showAddEditDialog(existing: addr),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child:
                    Icon(Icons.edit, size: 15, color: Color(0xFF666666)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteAddress(addr),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(Icons.delete_outline,
                    size: 15, color: Color(0xFFDC2626)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
