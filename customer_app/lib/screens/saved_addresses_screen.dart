import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  static const prefsKey = 'shipeast_addresses';

  static Future<List<Map<String, String>>> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null) return _defaultAddresses();
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  static List<Map<String, String>> _defaultAddresses() => [
        {'label': 'Home', 'text': '14 Yallahs Main Road, St. Thomas'},
        {'label': 'Work', 'text': '45 King Street, Kingston'},
      ];

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, String>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SavedAddressesScreen.prefsKey);
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw);
      setState(() {
        _addresses =
            decoded.map((e) => Map<String, String>.from(e as Map)).toList();
        _loading = false;
      });
    } else {
      _addresses = SavedAddressesScreen._defaultAddresses();
      await _saveAddresses();
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SavedAddressesScreen.prefsKey, jsonEncode(_addresses));
  }

  void _showAddEditDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final labelCtrl = TextEditingController(
        text: isEdit ? _addresses[editIndex]['label'] : '');
    final addressCtrl = TextEditingController(
        text: isEdit ? _addresses[editIndex]['text'] : '');

    const quickLabels = ['Home', 'Work', 'Mom', 'Dad', 'School', 'Other'];
    String selectedQuick =
        isEdit && quickLabels.contains(_addresses[editIndex]['label'])
            ? _addresses[editIndex]['label']!
            : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              const SizedBox(height: 16),
              Text(
                'Label',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickLabels.map((lbl) {
                  final selected = selectedQuick == lbl;
                  return GestureDetector(
                    onTap: () {
                      setBS(() {
                        selectedQuick = lbl;
                        labelCtrl.text = lbl;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFF0F2)
                            : const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        lbl,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? AppTheme.primary
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: labelCtrl,
                onChanged: (v) => setBS(() => selectedQuick = ''),
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                    'Custom label (e.g. Mom, Gym, Hotel)', Icons.label_outline),
              ),
              const SizedBox(height: 12),
              Text(
                'Full Address',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF333333)),
                decoration: _inputDecoration(
                    'e.g. 14 Yallahs Main Road, St. Thomas',
                    Icons.location_on),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  final label = labelCtrl.text.trim().isEmpty
                      ? (selectedQuick.isEmpty ? 'Home' : selectedQuick)
                      : labelCtrl.text.trim();
                  final addr = addressCtrl.text.trim();
                  if (addr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please enter an address',
                          style:
                              GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                    return;
                  }
                  setState(() {
                    if (isEdit) {
                      _addresses[editIndex] = {'label': label, 'text': addr};
                    } else {
                      _addresses.add({'label': label, 'text': addr});
                    }
                  });
                  _saveAddresses();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Address',
                  style:
                      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFFBBBBBB)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, size: 16, color: const Color(0xFF888888)),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        isDense: true,
      );

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Address',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w900)),
        content: Text(
            'Remove "${_addresses[index]['label']}" from your saved addresses?',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _addresses.removeAt(index));
              _saveAddresses();
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: GoogleFonts.nunito(
                    color: AppTheme.primary, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _addresses.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _addresses.length,
                        itemBuilder: (ctx, i) => _buildAddressCard(i),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Address',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)],
          ),
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
                  child: Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Addresses',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                Text(
                  'Manage your delivery locations',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 56, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 14),
            Text('No saved addresses',
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFCCCCCC))),
            const SizedBox(height: 6),
            Text('Tap + Add Address below to get started',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFBBBBBB))),
          ],
        ),
      );

  Widget _buildAddressCard(int i) {
    final addr = _addresses[i];
    final label = addr['label'] ?? '';
    final text = addr['text'] ?? '';
    final iconData = label == 'Home'
        ? Icons.home
        : label == 'Work'
            ? Icons.work
            : Icons.location_on;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Icon(iconData, size: 20, color: AppTheme.primary)),
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
                        fontSize: 11,
                        color: const Color(0xFF777777),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showAddEditDialog(editIndex: i),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Icon(Icons.edit, size: 16, color: Color(0xFF888888))),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteAddress(i),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Icon(Icons.delete_outline,
                      size: 16, color: AppTheme.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
