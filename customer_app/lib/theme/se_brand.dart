import 'package:flutter/material.dart';
import 'se_colors.dart';
import 'se_typography.dart';

/// Brand constants (SEDS §1.1). Single source for the app version string.
class SeBrand {
  SeBrand._();

  /// Keep in lockstep with pubspec `version:` (before the `+build`).
  static const String version = '1.2.0';
  static const String tagline = 'Couriers & Bearer Services · Jamaica';

  /// Tracked-out strap for the launch screen. Short enough to hold one line on
  /// a 320dp phone at the wide letter-spacing the lockup needs.
  static const String strapline = 'COURIERS & DELIVERY · JAMAICA';
}

/// ShipEast wordmark — `Ship` + `East` in one face, two tones.
///
/// On light ground the accent is the identity red; on the brand shell it is
/// [SeColors.shellMark], the pink that reads as a highlight against deep red
/// instead of vanishing into it. Tracking tightens as the mark grows, which is
/// what keeps it looking drawn rather than typed at display sizes.
class SeWordmark extends StatelessWidget {
  final double size;

  /// When true, renders for the brand shell (warm white + pink accent).
  final bool onDark;

  const SeWordmark({super.key, this.size = 26, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final shipColor = onDark ? SeColors.shellInk : SeColors.ink900;
    final eastColor = onDark ? SeColors.shellMark : SeColors.red500;
    return Text.rich(
      TextSpan(
        style: SeType.jakarta(size, FontWeight.w800)
            .copyWith(letterSpacing: -size * 0.032, height: 1.1),
        children: [
          TextSpan(text: 'Ship', style: TextStyle(color: shipColor)),
          TextSpan(text: 'East', style: TextStyle(color: eastColor)),
        ],
      ),
    );
  }
}
