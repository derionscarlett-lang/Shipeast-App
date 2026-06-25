import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Small numeric count bubble (cart count, unread alerts). Renders nothing
/// when [count] is 0. Caps display at `9+`.
class CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final double size;

  const CountBadge({
    super.key,
    required this.count,
    this.color = AppTheme.primary,
    this.textColor = Colors.white,
    this.borderColor,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.5),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
          color: textColor,
          height: 1,
        ),
      ),
    );
  }
}

/// Coloured pill used for statuses, tags and labels (e.g. order state).
/// Pass [filled] for a solid background, otherwise a soft tinted variant.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppTheme.primary,
    this.filled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
