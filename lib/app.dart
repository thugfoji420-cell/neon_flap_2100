import 'package:flutter/material.dart';

import 'package:neon_flap_2100/core/theme/app_theme.dart';
import 'package:neon_flap_2100/routing/app_routes.dart';
import 'package:neon_flap_2100/screens/main_menu_screen.dart';
import 'package:neon_flap_2100/screens/splash_screen.dart';
import 'package:neon_flap_2100/settings/settings_screen.dart';
import 'package:neon_flap_2100/store/character_store_screen.dart';
import 'package:neon_flap_2100/store/coin_shop_screen.dart';

/// Root application widget. Configures the cyberpunk theme and declarative
/// named routes for every screen.
class NeonFlapApp extends StatelessWidget {
  const NeonFlapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Flap 2100',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: NeonPalette.backgroundDeep,
        colorScheme: ColorScheme.dark(
          primary: NeonPalette.cyan,
          secondary: NeonPalette.magenta,
          surface: NeonPalette.backgroundDeep,
        ),
        textTheme: const TextTheme(
          bodyMedium: NeonTextStyle.body,
          titleLarge: NeonTextStyle.heading,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.mainMenu: (_) => const MainMenuScreen(),
        AppRoutes.characterStore: (_) => const CharacterStoreScreen(),
        AppRoutes.coinShop: (_) => const CoinShopScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
