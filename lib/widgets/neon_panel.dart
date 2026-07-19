import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';

/// A neon-styled dialog/reusable panel container. Wraps [child] in a rounded
/// panel with the theme's panel background, a glowing border, and a subtle
/// neon drop shadow. Used uniformly across every dialog in the app.
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    super.key,
    required this.child,
    this.borderColor,
    this.shadowColor,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth,
    this.gap = 0,
    this.shadowOpacity = 0.25,
  });

  final Widget child;
  final Color? borderColor;
  final Color? shadowColor;
  final EdgeInsets padding;
  final double? maxWidth;
  final double gap;

  /// Shadow opacity override (default 0.25). The daily reward dialog uses 0.20
  /// for a softer yellow glow.
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final themeColors = NeonTheme.colors(context);
    final scheme = Theme.of(context).colorScheme;
    final effectiveBorder = borderColor ?? scheme.primary;
    final effectiveShadow = shadowColor ?? scheme.primary;

    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: themeColors.panel,
        border: Border.all(color: effectiveBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: effectiveShadow.withOpacity(shadowOpacity),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );

    if (maxWidth case final mw?) {
      panel = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: panel,
      );
    }

    if (gap > 0) {
      panel = Padding(
        padding: EdgeInsets.all(gap),
        child: panel,
      );
    }

    return panel;
  }
}
