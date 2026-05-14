import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RateDriverScreen extends StatefulWidget {
  const RateDriverScreen({super.key});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _driverRating = 0;
  int _merchantRating = 0;
  final Set<int> _selectedTags = {};
  final _commentCtrl = TextEditingController();

  static const _tags = [
    '🚀 Fast delivery',
    '😊 Friendly',
    '🔥 Food was hot',
    '💼 Professional',
    '📦 Careful handling',
    '✅ On time',
  ];

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
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDriverRatingCard(),
                    const SizedBox(height: 10),
                    _buildTagsCard(),
                    const SizedBox(height: 10),
                    _buildMerchantRatingCard(),
                    const SizedBox(height: 10),
                    _buildCommentCard(),
                    const SizedBox(height: 10),
                    _buildSubmitButton(context),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
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
              'Rate Your Experience',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
      );

  Widget _buildDriverRatingCard() => Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            // Driver avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Text('👨', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Rohan Williams',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your delivery driver',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your delivery?',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _driverRating;
                return GestureDetector(
                  onTap: () => setState(() => _driverRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      '★',
                      style: TextStyle(
                        fontSize: 36,
                        color: filled
                            ? const Color(0xFFFACC15)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_driverRating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _ratingLabel(_driverRating),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildTagsCard() => Container(
        padding: const EdgeInsets.all(13),
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
            Text(
              'What did you love?',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _tags.asMap().entries.map((e) {
                final selected = _selectedTags.contains(e.key);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedTags.remove(e.key);
                    } else {
                      _selectedTags.add(e.key);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : const Color(0xFFE5E5E5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF555555),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _buildMerchantRatingCard() => Container(
        padding: const EdgeInsets.all(13),
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
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🍗', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Island Jerk Palace',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rate the restaurant',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _merchantRating;
                return GestureDetector(
                  onTap: () => setState(() => _merchantRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Text(
                      '★',
                      style: TextStyle(
                        fontSize: 22,
                        color: filled
                            ? const Color(0xFFFACC15)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _buildCommentCard() => Container(
        padding: const EdgeInsets.all(13),
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
            Text(
              '💬  Leave a comment',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF555555)),
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFBBBBBB)),
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
                contentPadding: const EdgeInsets.all(12),
                isDense: true,
              ),
            ),
          ],
        ),
      );

  Widget _buildSubmitButton(BuildContext context) => ElevatedButton(
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
              context, '/home', (route) => false);
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
          'Submit Rating →',
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      );

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent! 🎉';
      default:
        return '';
    }
  }
}
