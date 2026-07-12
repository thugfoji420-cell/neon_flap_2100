import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/theme/app_theme.dart';

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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
