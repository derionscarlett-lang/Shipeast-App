import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

/// Primary CTA button used across the app.
///
/// Handles loading state (spinner + disabled), an optional leading icon and a
/// subtle press-scale for tactile feedback. Pure presentation — callers keep
/// owning the [onPressed] logic.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool trailingArrow;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingArrow = false,
  });

  bool get _isOutlined =>
      variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost;

  Color get _bg {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppTheme.primary;
      case AppButtonVariant.secondary:
        return AppTheme.primaryLight;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _fg {
    switch (variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _fg),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  trailingArrow ? '$label  →' : label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: _fg, fontSize: 14),
                ),
              ),
            ],
          );

    return Pressable(
      onTap: disabled ? null : onPressed,
      child: Opacity(
        opacity: disabled && !loading ? 0.5 : 1,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: _isOutlined && variant == AppButtonVariant.outline
                ? Border.all(color: AppTheme.primary, width: 1.5)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
