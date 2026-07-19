import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/vibration_service.dart';

/// A holographic neon button used across all menus. Plays the button sound and
/// a subtle haptic, and squashes slightly on press for tactile feedback.
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
  });

  final String label;
  final VoidCallback? onPressed;

  /// Uses the active Material primary colour when no brand accent is supplied.
  final Color? color;
  final double? width;
  final double height;
  final double fontSize;
  final bool enabled;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1;
  late final AnimationController _pulse;

  T? _readService<T extends Object>() {
    try {
      return sl<T>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _pressDown() => setState(() => _scale = 0.94);
  void _pressUp() => setState(() => _scale = 1);

  void _activate() {
    if (!widget.enabled) return;
    _readService<AudioService>()?.playSfx(Sfx.buttonClick);
    _readService<VibrationService>()?.selection();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final scheme = Theme.of(context).colorScheme;
    final themeColors = Theme.of(context).extension<NeonThemeColors>() ??
        NeonThemeColors(
          background: scheme.surface,
          panel: scheme.surfaceContainerHigh,
          field: scheme.surfaceContainerHighest,
          disabled: scheme.onSurfaceVariant,
        );
    final buttonColor = widget.color ?? scheme.primary;
    return Semantics(
      button: true,
      enabled: active,
      label: widget.label,
      child: GestureDetector(
      onTapDown: (_) => _pressDown(),
      onTapUp: (_) => _pressUp(),
      onTapCancel: () => _pressUp(),
      onTap: _activate,
      child: AnimatedScale(
        scale: active ? _scale : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final glow = active ? 14 + _pulse.value * 10 : 4.0;
            return Container(
              constraints: BoxConstraints(
                minHeight: widget.height,
                minWidth: widget.width ?? double.infinity,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: active
                      ? [
                          buttonColor.withOpacity(0.22),
                          buttonColor.withOpacity(0.05),
                        ]
                      : [
                          themeColors.disabled.withOpacity(0.12),
                          themeColors.disabled.withOpacity(0.05),
                        ],
                ),
                border: Border.all(
                  color: active ? buttonColor : themeColors.disabled,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? buttonColor.withOpacity(0.6)
                        : Colors.transparent,
                    blurRadius: glow,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: NeonTextStyle.body.copyWith(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: active ? scheme.onSurface : themeColors.disabled,
                letterSpacing: 2,
                shadows: active
                    ? [Shadow(color: buttonColor, blurRadius: 12)]
                    : null,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
