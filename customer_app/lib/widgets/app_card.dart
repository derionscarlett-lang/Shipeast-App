import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Surface container with the app's standard radius, padding, border and a
/// soft elevation shadow. Tappable when [onTap] is provided (adds press
/// feedback). Use for list rows, merchant tiles, info panels, etc.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double radius;
  final bool bordered;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTheme.spaceMd),
    this.margin,
    this.color,
    this.radius = AppTheme.radiusLg,
    this.bordered = false,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: AppTheme.border) : null,
        boxShadow: elevated ? AppTheme.shadowSm : null,
      ),
      child: child,
    );

    if (onTap == null) return container;
    return Pressable(onTap: onTap, child: container);
  }
}
