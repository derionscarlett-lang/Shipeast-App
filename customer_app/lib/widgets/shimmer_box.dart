import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFDDDDDD),
              Color(0xFFEEEEEE),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width shimmer line for skeleton text rows.
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, this.width = double.infinity, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: width, height: height, radius: 6);
  }
}

/// A card-shaped skeleton placeholder matching [AppCard] dimensions — drop in
/// while list/detail content loads instead of a blocking spinner.
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 84});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 54, height: 54, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLine(width: 140, height: 13),
                SizedBox(height: 8),
                ShimmerLine(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical stack of [ShimmerCard]s for list loading states.
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ShimmerList({super.key, this.count = 5, this.itemHeight = 84});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: itemHeight),
        ),
      ),
    );
  }
}
