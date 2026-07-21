import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/vibration_service.dart';

/// A holographic embossed button used across all menus. Plays the button sound
/// and a subtle haptic. The surface is inset/glass-like instead of a raised
/// stacked block, so every screen shares the same professional molded style.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.width,
    this.height = 48,
    this.fontSize = 16,
    this.enabled = true,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Uses the active Material primary colour when no brand accent is supplied.
  final Color? color;
  final double? width;
  final double height;
  final double fontSize;
  final bool enabled;
  final IconData? icon;
  final bool isLoading;
  final String? loadingLabel;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  T? _readService<T extends Object>() {
    try {
      return sl<T>();
    } catch (_) {
      return null;
    }
  }

  void _pressDown() => setState(() => _pressed = true);
  void _pressUp() => setState(() => _pressed = false);

  void _activate() {
    if (!widget.enabled || widget.isLoading || widget.onPressed == null) {
      return;
    }
    _readService<AudioService>()?.playSfx(Sfx.buttonClick);
    _readService<VibrationService>()?.selection();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.enabled && !widget.isLoading && widget.onPressed != null;
    final active =
        widget.enabled && (widget.onPressed != null || widget.isLoading);
    final scheme = Theme.of(context).colorScheme;
    final themeColors = NeonTheme.colors(context);
    final isLight = scheme.brightness == Brightness.light;
    final buttonColor = widget.color ?? scheme.primary;
    final foreground =
        ThemeData.estimateBrightnessForColor(buttonColor) == Brightness.dark
            ? NeonPalette.white
            : NeonPalette.backgroundDeep;
    final height = widget.height < NeonLayout.minimumTapTarget
        ? NeonLayout.minimumTapTarget
        : widget.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fill bounded columns while keeping intrinsic width in Rows and dialog
        // headers, whose horizontal constraints are intentionally unbounded.
        final requestedWidth = widget.width;
        final maxWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : null;
        final estimatedContentWidth =
            widget.label.length * widget.fontSize * 0.72 +
                28 +
                (widget.icon == null ? 0 : widget.fontSize + 16);
        final intrinsicWidth =
            estimatedContentWidth.clamp(80.0, 280.0).toDouble();
        final resolvedWidth = requestedWidth != null && requestedWidth.isFinite
            ? maxWidth == null
                ? requestedWidth
                : requestedWidth.clamp(0.0, maxWidth)
            : maxWidth ?? intrinsicWidth;
        return Semantics(
          button: true,
          enabled: interactive,
          label: widget.label,
          child: GestureDetector(
            onTapDown: interactive ? (_) => _pressDown() : null,
            onTapUp: interactive ? (_) => _pressUp() : null,
            onTapCancel: interactive ? _pressUp : null,
            onTap: interactive ? _activate : null,
            child: AnimatedScale(
              scale: active && _pressed ? 0.985 : 1.0,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: resolvedWidth,
                height: height,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      NeonLayout.buttonRadius,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: active
                          ? isLight
                              ? [
                                  Color.lerp(
                                    buttonColor,
                                    themeColors.highlight,
                                    0.08,
                                  )!,
                                  buttonColor,
                                  Color.lerp(
                                    buttonColor,
                                    themeColors.shadow,
                                    _pressed ? 0.30 : 0.20,
                                  )!,
                                ]
                              : [
                                  Color.lerp(
                                    buttonColor,
                                    themeColors.highlight,
                                    0.18,
                                  )!
                                      .withValues(
                                          alpha: _pressed ? 0.46 : 0.62),
                                  buttonColor.withValues(
                                      alpha: _pressed ? 0.48 : 0.58),
                                  Color.lerp(
                                    buttonColor,
                                    themeColors.shadow,
                                    0.48,
                                  )!
                                      .withValues(
                                          alpha: _pressed ? 0.72 : 0.58),
                                ]
                          : [
                              themeColors.disabled.withValues(alpha: 0.22),
                              themeColors.disabled.withValues(alpha: 0.12),
                            ],
                    ),
                    border: Border.all(
                      color: active
                          ? isLight
                              ? Color.lerp(
                                  buttonColor,
                                  themeColors.shadow,
                                  0.42,
                                )!
                                  .withValues(
                                  alpha: _pressed ? 0.94 : 0.82,
                                )
                              : buttonColor.withValues(
                                  alpha: _pressed ? 0.88 : 0.7,
                                )
                          : themeColors.disabled.withValues(alpha: 0.38),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? (isLight ? themeColors.shadow : buttonColor)
                                .withValues(
                                alpha: _pressed
                                    ? (isLight ? 0.12 : 0.08)
                                    : (isLight ? 0.26 : 0.22),
                              )
                            : Colors.transparent,
                        blurRadius: _pressed ? 4 : 10,
                        spreadRadius: _pressed ? 0 : 0.5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      NeonLayout.buttonRadius - 1,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (isLight
                                        ? themeColors.highlight
                                        : themeColors.highlight)
                                    .withValues(
                                  alpha: active && !_pressed
                                      ? (isLight ? 0.12 : 0.22)
                                      : 0.08,
                                ),
                                Colors.transparent,
                                themeColors.shadow.withValues(
                                  alpha: active && _pressed
                                      ? (isLight ? 0.28 : 0.38)
                                      : (isLight ? 0.14 : 0.22),
                                ),
                              ],
                              stops: const [0.0, 0.48, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 1,
                          top: 1,
                          right: 1,
                          height: 1.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: themeColors.highlight.withValues(
                                alpha: active && !_pressed
                                    ? (isLight ? 0.22 : 0.38)
                                    : 0.12,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 1,
                          bottom: 1,
                          left: 1,
                          height: _pressed ? 4 : 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: themeColors.shadow.withValues(
                                alpha: active ? (isLight ? 0.34 : 0.44) : 0.18,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: widget.isLoading
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: active
                                                ? foreground
                                                : themeColors.disabled,
                                          ),
                                        ),
                                        if (widget.loadingLabel
                                            case final label?) ...[
                                          const SizedBox(width: 10),
                                          Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            softWrap: false,
                                            style: NeonTextStyle.body.copyWith(
                                              fontSize: widget.fontSize,
                                              fontWeight: FontWeight.w800,
                                              color: active
                                                  ? foreground
                                                  : themeColors.disabled,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.icon case final icon?) ...[
                                          Icon(
                                            icon,
                                            size: widget.fontSize + 3,
                                            color: active
                                                ? foreground
                                                : themeColors.disabled,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          widget.label,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          style: NeonTextStyle.body.copyWith(
                                            fontSize: widget.fontSize,
                                            fontWeight: FontWeight.w800,
                                            color: active
                                                ? foreground
                                                : themeColors.disabled,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NeonBackButton extends StatelessWidget {
  const NeonBackButton({
    super.key,
    this.label = 'BACK',
    this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return NeonButton(
      label: label,
      icon: Icons.arrow_back_rounded,
      color: color ?? Theme.of(context).colorScheme.primary,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
