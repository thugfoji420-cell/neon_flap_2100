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
    seedColor: NeonPalette.cyan,
    brightness: Brightness.light,
  ).copyWith(
    // Daytime remains intentionally metallic, but is now several steps below
    // white so panels, controls, and neon accents retain a clear hierarchy.
    primary: const Color(0xFF005F6D),
    onPrimary: const Color(0xFFF1FCFD),
    primaryContainer: const Color(0xFF77D3DC),
    onPrimaryContainer: const Color(0xFF002F38),
    secondary: const Color(0xFF692D86),
    onSecondary: const Color(0xFFFFF1FC),
    secondaryContainer: const Color(0xFFDDBEE8),
    onSecondaryContainer: const Color(0xFF2E003C),
    tertiary: const Color(0xFF3B4D9D),
    onTertiary: const Color(0xFFF4F4FF),
    tertiaryContainer: const Color(0xFFCBD5FA),
    onTertiaryContainer: const Color(0xFF111A57),
    surface: const Color(0xFFA9BCC6),
    surfaceContainerLowest: const Color(0xFFC4D1D7),
    surfaceContainerLow: const Color(0xFFB8C7CF),
    surfaceContainer: const Color(0xFFADC0CA),
    surfaceContainerHigh: const Color(0xFFC2D0D6),
    surfaceContainerHighest: const Color(0xFFD0DCE1),
    onSurface: const Color(0xFF0B2634),
    onSurfaceVariant: const Color(0xFF2B4A57),
    outline: const Color(0xFF416B7B),
    outlineVariant: const Color(0xFF718F9D),
    inverseSurface: const Color(0xFF0D2734),
    onInverseSurface: const Color(0xFFE5F1F4),
    inversePrimary: const Color(0xFF66DFEB),
    error: const Color(0xFFA72A2A),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outline, width: 1.2),
          ),
        ),
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
    required this.highlight,
    required this.shadow,
    required this.panelBorder,
    required this.hudSurface,
    required this.hudSurfaceRaised,
    required this.hudText,
    required this.hudMuted,
    required this.hudBorder,
    required this.hudHighlight,
    required this.hudShadow,
    required this.gold,
    required this.success,
    required this.warning,
  });

  final Color background;
  final Color panel;
  final Color field;
  final Color disabled;
  final Color highlight;
  final Color shadow;
  final Color panelBorder;
  final Color hudSurface;
  final Color hudSurfaceRaised;
  final Color hudText;
  final Color hudMuted;
  final Color hudBorder;
  final Color hudHighlight;
  final Color hudShadow;
  final Color gold;
  final Color success;
  final Color warning;

  factory NeonThemeColors.fromScheme(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return NeonThemeColors(
      background: isLight ? const Color(0xFF91A9B6) : scheme.surface,
      panel: isLight ? const Color(0xFFC2D0D6) : scheme.surfaceContainerHigh,
      field: isLight ? const Color(0xFFADC0CA) : scheme.surfaceContainerHighest,
      disabled: isLight ? const Color(0xFF4C6875) : scheme.onSurfaceVariant,
      highlight: isLight ? const Color(0xFFD9E6EA) : NeonPalette.white,
      shadow: isLight ? const Color(0xFF243D4A) : NeonPalette.backgroundDeep,
      panelBorder: isLight ? const Color(0xFF547989) : scheme.outline,
      // HUDs intentionally remain dark in both modes: they create a stable,
      // high-contrast anchor for live gameplay and player-profile information.
      hudSurface: const Color(0xFF081722),
      hudSurfaceRaised:
          isLight ? const Color(0xFF102936) : const Color(0xFF0C1E2B),
      hudText: const Color(0xFFE9F8FC),
      hudMuted: const Color(0xFFA9CBD5),
      hudBorder: isLight ? const Color(0xFF4AB1C1) : const Color(0xFF1E7B8D),
      hudHighlight: isLight ? const Color(0xFF91EAF5) : const Color(0xFF4BE7F5),
      hudShadow: const Color(0xFF02080D),
      gold: isLight ? const Color(0xFF8A5700) : NeonPalette.yellow,
      success: isLight ? const Color(0xFF187331) : NeonPalette.green,
      warning: isLight ? const Color(0xFF875400) : NeonPalette.yellow,
    );
  }

  @override
  NeonThemeColors copyWith({
    Color? background,
    Color? panel,
    Color? field,
    Color? disabled,
    Color? highlight,
    Color? shadow,
    Color? panelBorder,
    Color? hudSurface,
    Color? hudSurfaceRaised,
    Color? hudText,
    Color? hudMuted,
    Color? hudBorder,
    Color? hudHighlight,
    Color? hudShadow,
    Color? gold,
    Color? success,
    Color? warning,
  }) =>
      NeonThemeColors(
        background: background ?? this.background,
        panel: panel ?? this.panel,
        field: field ?? this.field,
        disabled: disabled ?? this.disabled,
        highlight: highlight ?? this.highlight,
        shadow: shadow ?? this.shadow,
        panelBorder: panelBorder ?? this.panelBorder,
        hudSurface: hudSurface ?? this.hudSurface,
        hudSurfaceRaised: hudSurfaceRaised ?? this.hudSurfaceRaised,
        hudText: hudText ?? this.hudText,
        hudMuted: hudMuted ?? this.hudMuted,
        hudBorder: hudBorder ?? this.hudBorder,
        hudHighlight: hudHighlight ?? this.hudHighlight,
        hudShadow: hudShadow ?? this.hudShadow,
        gold: gold ?? this.gold,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  NeonThemeColors lerp(NeonThemeColors? other, double t) {
    if (other is! NeonThemeColors) return this;
    return NeonThemeColors(
      background: Color.lerp(background, other.background, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      field: Color.lerp(field, other.field, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      hudSurface: Color.lerp(hudSurface, other.hudSurface, t)!,
      hudSurfaceRaised:
          Color.lerp(hudSurfaceRaised, other.hudSurfaceRaised, t)!,
      hudText: Color.lerp(hudText, other.hudText, t)!,
      hudMuted: Color.lerp(hudMuted, other.hudMuted, t)!,
      hudBorder: Color.lerp(hudBorder, other.hudBorder, t)!,
      hudHighlight: Color.lerp(hudHighlight, other.hudHighlight, t)!,
      hudShadow: Color.lerp(hudShadow, other.hudShadow, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// Convenient access to semantic custom surfaces from a build context.
class NeonTheme {
  const NeonTheme._();

  static NeonThemeColors colors(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<NeonThemeColors>() ??
        NeonThemeColors.fromScheme(theme.colorScheme);
  }
}

/// Shared responsive measurements for menu and dialog UI.
///
/// Keeping these values together prevents each screen from inventing slightly
/// different paddings and breakpoints. Game-world coordinates intentionally do
/// not use this class.
class NeonLayout {
  const NeonLayout._();

  static const double compactWidth = 360;
  static const double tabletWidth = 600;
  static const double maxContentWidth = 560;
  static const double minimumTapTarget = 48;
  static const double buttonRadius = 16;
  static const double panelRadius = 20;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletWidth;

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < compactWidth ? 16.0 : 24.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 16);
  }

  static double sectionGap(BuildContext context) =>
      isCompact(context) ? 12 : 18;

  static double titleSize(BuildContext context) => isCompact(context) ? 34 : 42;
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
