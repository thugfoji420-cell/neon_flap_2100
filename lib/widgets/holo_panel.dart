import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';

/// A translucent holographic panel with a glowing neon border. Used to frame
/// content on the menus and dialogs.
class HoloPanel extends StatelessWidget {
  const HoloPanel({
    super.key,
    required this.child,
    this.color = NeonPalette.cyan,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(NeonLayout.panelRadius);
    final colors = NeonTheme.colors(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  colors.panel,
                  Color.lerp(colors.panel, color, 0.10)!,
                  colors.field,
                ]
              : [
                  colors.highlight.withOpacity(0.10),
                  color.withOpacity(0.08),
                  colors.shadow.withOpacity(0.34),
                ],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: Border.all(
          color: isLight ? color.withOpacity(0.72) : color.withOpacity(0.46),
          width: 1.2,
        ),
        boxShadow: [
          if (!isLight)
            BoxShadow(
              color: colors.highlight.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(-1, -1),
            ),
          BoxShadow(
            color: colors.shadow.withOpacity(isLight ? 0.24 : 0.34),
            blurRadius: isLight ? 9 : 12,
            offset: const Offset(3, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLight
                        ? [
                            color.withOpacity(0.12),
                            Colors.transparent,
                            colors.shadow.withOpacity(0.10),
                          ]
                        : [
                            colors.highlight.withOpacity(0.10),
                            Colors.transparent,
                            colors.shadow.withOpacity(0.22),
                          ],
                    stops: const [0.0, 0.52, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Light surfaces use crisp metallic layers instead of an expensive blur.
    // The dark glass treatment remains unchanged for the established night UI.
    return ClipRRect(
      borderRadius: radius,
      child: isLight
          ? panel
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: panel,
            ),
    );
  }
}
