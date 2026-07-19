/// Material 3 theme definitions and shared visual tokens for Neon Flap 2100.
library;

import 'package:flutter/material.dart';

/// Brand colours used by the game world and as accents throughout the UI.
///
/// These intentionally remain stable across theme modes so game characters and
/// rewards keep their established identities. App surfaces and text should use
/// [NeonTheme.colors] or [ColorScheme] instead of these raw background values.
class NeonPalette {
  const NeonPalette._();

  static const Color backgroundDeep = Color(0xFF05010F);
  static const Color backgroundDark = Color(0xFF0A0420);
  static const Color surface = Color(0xFF120A2E);

  static const Color cyan = Color(0xFF00F0FF);
  static const Color magenta = Color(0xFFFF2BD6);
  static const Color purple = Color(0xFF9D4DFF);
  static const Color green = Color(0xFF39FF14);
  static const Color yellow = Color(0xFFFFD000);
  static const Color red = Color(0xFFFF3860);
  static const Color white = Color(0xFFEAFCFF);

  /// Glowing stroke colour per visual layer in the Flame game.
  static const List<Color> pipeCycle = [cyan, magenta, purple, green];
}

/// Central Material 3 configuration for both app appearances.
class AppTheme {
  const AppTheme._();

  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF006A73),
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF006A73),
    onPrimary: Colors.white,
    secondary: const Color(0xFF8A2E7F),
    tertiary: const Color(0xFF5B4DB3),
    error: const Color(0xFFBA1A1A),
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: NeonPalette.cyan,
    brightness: Brightness.dark,
  ).copyWith(
    primary: NeonPalette.cyan,
    onPrimary: const Color(0xFF00363B),
    secondary: const Color(0xFFFFABEE),
    tertiary: const Color(0xFFC9B8FF),
    surface: NeonPalette.backgroundDeep,
    onSurface: NeonPalette.white,
    error: const Color(0xFFFFB4AB),
  );

  /// The light Material 3 theme supplied to [MaterialApp.theme].
  static final ThemeData lightTheme = _buildTheme(lightScheme);

  /// The dark Material 3 theme supplied to [MaterialApp.darkTheme].
  static final ThemeData darkTheme = _buildTheme(darkScheme);

  static ThemeData _buildTheme(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = base.textTheme.apply(
      fontFamily: NeonTextStyle.fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final outline = scheme.outline.withValues(alpha: 0.72);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: outline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [NeonThemeColors.fromScheme(scheme)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.primary),
        helperStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.22),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Theme-specific surfaces used by the custom neon widgets.
///
/// Keeping these semantic values in a [ThemeExtension] makes custom UI follow
/// the active Material colour scheme without scattering light/dark checks.
@immutable
class NeonThemeColors extends ThemeExtension<NeonThemeColors> {
  const NeonThemeColors({
    required this.background,
    required this.panel,
    required this.field,
    required this.disabled,
  });

  final Color background;
  final Color panel;
  final Color field;
  final Color disabled;

  factory NeonThemeColors.fromScheme(ColorScheme scheme) => NeonThemeColors(
        background: scheme.surface,
        panel: scheme.surfaceContainerHigh,
        field: scheme.surfaceContainerHighest,
        disabled: scheme.onSurfaceVariant,
      );

  @override
  NeonThemeColors copyWith({
    Color? background,
    Color? panel,
    Color? field,
    Color? disabled,
  }) =>
      NeonThemeColors(
        background: background ?? this.background,
        panel: panel ?? this.panel,
        field: field ?? this.field,
        disabled: disabled ?? this.disabled,
      );

  @override
  NeonThemeColors lerp(NeonThemeColors? other, double t) {
    if (other is! NeonThemeColors) return this;
    return NeonThemeColors(
      background: Color.lerp(background, other.background, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      field: Color.lerp(field, other.field, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}

/// Convenient access to semantic custom surfaces from a build context.
class NeonTheme {
  const NeonTheme._();

  static NeonThemeColors colors(BuildContext context) =>
      Theme.of(context).extension<NeonThemeColors>()!;
}

/// Pre-configured neon typography. The colour is deliberately omitted so text
/// inherits the active Material 3 [ColorScheme] in both light and dark modes.
class NeonTextStyle {
  const NeonTextStyle._();

  static const String fontFamily = 'Orbitron';

  static const title = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: 3,
    shadows: [
      Shadow(color: NeonPalette.cyan, blurRadius: 18),
      Shadow(color: NeonPalette.magenta, blurRadius: 30),
    ],
  );

  static const heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    shadows: [Shadow(color: NeonPalette.cyan, blurRadius: 12)],
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );
}
