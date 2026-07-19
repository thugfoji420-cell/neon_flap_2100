import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';

/// Animated coin balance badge. Uses [TweenAnimationBuilder] for a smooth
/// count-up / count-down transition whenever [coins] changes.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonPalette.yellow.withOpacity(0.7)),
        color: NeonPalette.yellow.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 12, color: NeonPalette.yellow),
          const SizedBox(width: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: coins, end: coins),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value',
              style: NeonTextStyle.label.copyWith(
                color: NeonPalette.yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
