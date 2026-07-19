import 'package:flutter/material.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/core/theme/theme_controller.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/routing/app_routes.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';
import 'package:neon_flap1_game/screens/splash_screen.dart';
import 'package:neon_flap1_game/settings/settings_screen.dart';
import 'package:neon_flap1_game/store/character_store_screen.dart';
import 'package:neon_flap1_game/store/coin_shop_screen.dart';

/// `MyApp` is the public entry-point name used by [main]. It is an alias of
/// [NeonFlapApp] so the root widget can be referenced consistently.
typedef MyApp = NeonFlapApp;

/// Root application widget. Configures the cyberpunk theme and declarative
/// named routes for every screen.
class NeonFlapApp extends StatelessWidget {
  const NeonFlapApp({super.key, this.home});

  /// Optional root override used by widget tests; production starts at Splash.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
    return AnimatedBuilder(
      animation: themeController,
      builder: (_, __) => MaterialApp(
        title: 'Neon Flap 2100',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 300),
        themeAnimationCurve: Curves.easeInOut,
        home: home,
        initialRoute: home == null ? AppRoutes.splash : null,
        routes: {
          if (home == null) AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.mainMenu: (_) => const MainMenuScreen(),
          AppRoutes.characterStore: (_) => const CharacterStoreScreen(),
          AppRoutes.coinShop: (_) => const CoinShopScreen(),
          AppRoutes.settings: (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
