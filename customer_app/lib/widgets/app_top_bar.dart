import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Lightweight header used at the top of most screens: a circular back button,
/// a title (optionally with subtitle) and an optional trailing action.
///
/// Implements [PreferredSizeWidget] so it can be passed to `Scaffold.appBar`,
/// but it is a plain row so it also works inside a `Column` body. Navigation
/// stays with the caller via [onBack] (defaults to `Navigator.pop`).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.lightGray)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            if (showBack) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppTheme.lightGray,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF444444)),
        ),
      ),
    );
  }
}
