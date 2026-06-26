import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps any child with a subtle press-scale + opacity feedback.
///
/// Gives tappable surfaces (buttons, cards, tiles) a consistent ~150ms
/// tactile response without shifting surrounding layout. When [onTap] is
/// null the child renders inert (no feedback, no hit handling).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.borderRadius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: AppTheme.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
