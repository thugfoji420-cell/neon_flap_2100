import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/services/audio_service.dart';
import 'package:neon_flap_2100/services/vibration_service.dart';

/// A holographic neon button used across all menus. Plays the button sound and
/// a subtle haptic, and squashes slightly on press for tactile feedback.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = NeonPalette.cyan,
    this.width,
    this.height = 56,
    this.fontSize = 20,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
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
    sl<AudioService>().playSfx(Sfx.buttonClick);
    sl<VibrationService>().selection();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    return GestureDetector(
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
              width: widget.width,
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: active
                      ? [
                          widget.color.withOpacity(0.22),
                          widget.color.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.04),
                          Colors.white.withOpacity(0.02),
                        ],
                ),
                border: Border.all(
                  color: active ? widget.color : Colors.white24,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? widget.color.withOpacity(0.6)
                        : Colors.transparent,
                    blurRadius: glow,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Text(
            widget.label,
            style: NeonTextStyle.body.copyWith(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w700,
              color: active ? NeonPalette.white : Colors.white54,
              letterSpacing: 2,
              shadows: active
                  ? [Shadow(color: widget.color, blurRadius: 12)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
