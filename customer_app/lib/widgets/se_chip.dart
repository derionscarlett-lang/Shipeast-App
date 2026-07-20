import 'package:flutter/material.dart';
import '../theme/se_colors.dart';
import '../theme/se_spacing.dart';
import '../theme/se_typography.dart';

/// Small pill chip — used for filters, tags and info bits (SEDS §1.4).
class SeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color fg;
  final Color bg;
  final bool selected;
  final VoidCallback? onTap;

  const SeChip({
    super.key,
    required this.label,
    this.icon,
    this.fg = SeColors.ink700,
    this.bg = SeColors.surface0,
    this.selected = false,
    this.onTap,
  });

  /// A soft status/semantic pill (e.g. Open / Closed / Delivered).
  factory SeChip.status({
    required String label,
    required Color color,
    required Color tint,
  }) =>
      SeChip(label: label, fg: color, bg: tint);

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SeRadius.pill,
        border: selected
            ? Border.all(color: SeColors.red500, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: SeType.label.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}

/// Category tile — 56dp duotone glyph on a soft tinted circle (SEDS §1.5).
class SeCategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color hue;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  const SeCategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.hue,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? hue : tint,
              shape: BoxShape.circle,
              boxShadow: selected
                  ? SeElevation.glowColor(hue, opacity: 0.28)
                  : SeElevation.e0,
            ),
            child: Icon(icon, size: 26, color: selected ? Colors.white : hue),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: SeType.label.copyWith(
              color: selected ? SeColors.ink900 : SeColors.ink500,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
