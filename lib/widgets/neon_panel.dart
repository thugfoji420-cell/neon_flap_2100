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
    final isLight = scheme.brightness == Brightness.light;
    final effectiveBorder = borderColor ?? scheme.primary;
    final effectiveShadow = shadowColor ?? scheme.primary;

    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isLight ? null : themeColors.panel,
        gradient: isLight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColors.panel,
                  Color.lerp(themeColors.panel, themeColors.field, 0.46)!,
                ],
              )
            : null,
        border: Border.all(
          color: effectiveBorder.withOpacity(isLight ? 0.72 : 0.5),
          width: isLight ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLight ? themeColors.shadow : effectiveShadow)
                .withOpacity(isLight ? shadowOpacity * 0.72 : shadowOpacity),
            blurRadius: isLight ? 14 : 28,
            spreadRadius: isLight ? 0 : 2,
            offset: isLight ? const Offset(0, 5) : Offset.zero,
          ),
          if (isLight)
            BoxShadow(
              color: themeColors.panelBorder.withOpacity(0.18),
              blurRadius: 2,
              offset: const Offset(-1, -1),
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

/// A compact, dark futuristic HUD shell used for live player information.
///
/// This intentionally stays dark in light mode so dynamic account data keeps
/// strong contrast without making the rest of the light interface dark.
class ProfileHudPanel extends StatelessWidget {
  const ProfileHudPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = NeonTheme.colors(context);
    final radius = BorderRadius.circular(NeonLayout.panelRadius);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.hudSurfaceRaised, colors.hudSurface],
        ),
        border: Border.all(color: colors.hudBorder.withValues(alpha: 0.88)),
        boxShadow: [
          BoxShadow(
            color: colors.hudShadow.withValues(alpha: 0.46),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: colors.hudHighlight.withValues(alpha: 0.10),
            blurRadius: 3,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Premium futuristic HUD sub-panel with a crisp metallic border and inner
/// highlight. Used inside the main-menu profile card for Player, Gold and
/// High Score readouts.
class HudSection extends StatelessWidget {
  const HudSection({
    super.key,
    required this.label,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  final String label;
  final Widget child;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = NeonTheme.colors(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.hudSurfaceRaised, colors.hudSurface],
        ),
        border: Border.all(
          color: colors.hudBorder.withValues(alpha: 0.72),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final sectionIcon?) ...[
                  Icon(sectionIcon, size: 12, color: colors.hudMuted),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: NeonTextStyle.label.copyWith(
                    fontSize: 8,
                    letterSpacing: 1.15,
                    color: colors.hudMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

/// Equal-size, accessible profile statistic card for Gold and High Score.
class ProfileStatBox extends StatelessWidget {
  const ProfileStatBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.height,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;
  final double height;

  /// Formats presentation values without changing the persisted coin/score.
  static String compactNumber(int value) {
    String compact(double number, String suffix) {
      final text = number.toStringAsFixed(1);
      return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}$suffix';
    }

    if (value >= 1000000) return compact(value / 1000000, 'M');
    if (value >= 1000) return compact(value / 1000, 'K');
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '$value',
      child: Tooltip(
        message: '$label: $value',
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: HudSection(
            label: label,
            icon: icon,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    compactNumber(value),
                    maxLines: 1,
                    style: NeonTextStyle.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      shadows: [
                        Shadow(
                            color: accent.withValues(alpha: 0.32),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
