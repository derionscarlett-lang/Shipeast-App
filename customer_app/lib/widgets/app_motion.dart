import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Reusable motion presets built on `flutter_animate` so entrance animations
/// stay consistent (duration, easing, distance) across screens.
///
/// Usage:
/// ```dart
/// MyCard().fadeSlideIn();              // single element
/// MyTile().fadeSlideIn(index: i);      // staggered list item
/// ```
extension AppMotion on Widget {
  /// Fade + upward slide entrance. Pass [index] to stagger list/grid items.
  Widget fadeSlideIn({int index = 0, double dy = 12, Duration? delay}) {
    final stagger = delay ?? Duration(milliseconds: 40 * index);
    return animate()
        .fadeIn(duration: AppTheme.normal, delay: stagger)
        .slideY(
          begin: dy / 100,
          end: 0,
          duration: AppTheme.normal,
          delay: stagger,
          curve: Curves.easeOutCubic,
        );
  }

  /// Soft scale-in entrance for emphasis (badges, confirmations, icons).
  Widget popIn({Duration? delay}) {
    return animate().scale(
      begin: const Offset(0.92, 0.92),
      end: const Offset(1, 1),
      duration: AppTheme.normal,
      delay: delay ?? Duration.zero,
      curve: Curves.easeOutBack,
    );
  }
}
