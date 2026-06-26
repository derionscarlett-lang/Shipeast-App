import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'app_badge.dart';

class AppBottomNavItem {
  final String label;
  final IconData icon;
  final int badgeCount;

  const AppBottomNavItem({
    required this.label,
    required this.icon,
    this.badgeCount = 0,
  });
}

/// Fixed bottom navigation bar (max 5 items, icon + label, active item tinted).
///
/// Purely presentational: it reports taps via [onTap] and the parent owns the
/// selected index and any routing/state. Respects the bottom safe area.
class AppBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = selectedIndex == i;
              final color = active ? AppTheme.primary : AppTheme.inactive;
              final showBadge = item.badgeCount > 0 && !active;
              return Expanded(
                child: Semantics(
                  selected: active,
                  button: true,
                  label: item.label,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(item.icon, size: 22, color: color),
                            if (showBadge)
                              Positioned(
                                top: -6,
                                right: -8,
                                child: CountBadge(
                                  count: item.badgeCount,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
