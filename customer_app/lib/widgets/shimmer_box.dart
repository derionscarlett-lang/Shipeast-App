import 'package:flutter/material.dart';
import '../theme/se_colors.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No gradients: breathe a flat blush block's opacity (matches SeShimmer).
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = (_ctrl.value * 2 - 1).abs();
        return Opacity(
          opacity: 1 - 0.5 * t,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              color: SeColors.ink200,
            ),
          ),
        );
      },
    );
  }
}
