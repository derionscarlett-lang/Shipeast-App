import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OverseasOrderScreen extends StatefulWidget {
  const OverseasOrderScreen({super.key});

  @override
  State<OverseasOrderScreen> createState() => _OverseasOrderScreenState();
}

class _OverseasOrderScreenState extends State<OverseasOrderScreen> {
  final _senderNameCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _recipientAddressCtrl = TextEditingController();
  final _packageDescCtrl = TextEditingController();
  String _selectedCountry = 'United States';

  static const _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'China',
    'Japan',
    'Germany',
    'France',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _recipientAddressCtrl.dispose();
    _packageDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoBox(),
                  const SizedBox(height: 10),
                  _buildFormCard(),
                  const SizedBox(height: 10),
                  _buildContinueButton(context),
                  const SizedBox(height: 16),
                ],
              ),
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
                  child: Icon(Icons.arrow_back_ios, size: 16,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overseas Order',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ship from abroad to Jamaica',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.flight, size: 26, color: Colors.white),
          ],
        ),
      );

  Widget _buildInfoBox() => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCE8),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shop from international stores, ship to our overseas warehouse, and we deliver straight to your door in Jamaica. Duties & taxes may apply.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF92400E),
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

  Widget _buildFormCard() => Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHead('Sender Details', iconData: Icons.inventory_2),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 4, 13, 13),
              child: Column(
                children: [
                  _formField(
                    controller: _senderNameCtrl,
                    label: 'Your Full Name',
                    hint: 'e.g. Marcus Brown',
                    icon: Icons.person,
                  ),
                ],
              ),
            ),
            _divider(),
            _sectionHead('Recipient Details', iconData: Icons.home),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 4, 13, 13),
              child: Column(
                children: [
                  _formField(
                    controller: _recipientNameCtrl,
                    label: 'Recipient Full Name',
                    hint: 'e.g. Asha Williams',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 10),
                  _formField(
                    controller: _recipientPhoneCtrl,
                    label: 'Recipient Phone',
                    hint: '+1 876 000 0000',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _formField(
                    controller: _recipientAddressCtrl,
                    label: 'Delivery Address (Jamaica)',
                    hint: 'e.g. 14 Yallahs Main Road, St. Thomas',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            _divider(),
            _sectionHead('📬  Package Details'),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 4, 13, 13),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shipping From',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFEBEBEB), width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountry,
                            isExpanded: true,
                            icon: const Text('▾',
                                style: TextStyle(
                                    color: Color(0xFFAAAAAA), fontSize: 13)),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF333333)),
                            onChanged: (v) =>
                                setState(() => _selectedCountry = v!),
                            items: _countries
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _formField(
                    controller: _packageDescCtrl,
                    label: 'What are you sending?',
                    hint: 'e.g. Clothes, Electronics, Shoes, etc.',
                    icon: '🛍️',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sectionHead(String title, {IconData? iconData}) => Padding(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 0),
        child: Row(
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 13, color: const Color(0xFF888888)),
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF888888),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );

  Widget _divider() => const Divider(color: Color(0xFFF2F2F2), height: 1);

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required dynamic icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    Widget prefixWidget;
    if (icon is IconData) {
      prefixWidget = Icon(icon, size: 16, color: const Color(0xFF888888));
    } else {
      prefixWidget = Text(icon as String, style: const TextStyle(fontSize: 16));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style:
              GoogleFonts.inter(fontSize: 13, color: const Color(0xFF333333)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFFBBBBBB)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 11, right: 8),
              child: prefixWidget,
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
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) => ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Overseas order request submitted!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 0,
        ),
        child: Text(
          'Continue →',
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      );
}
