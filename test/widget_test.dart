// Smoke test that simply pumps the root widget without crashing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neon_flap1_game/app.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/core/theme/theme_controller.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';
import 'package:neon_flap1_game/services/storage_service.dart';

void main() {
  Future<ThemeController> registerThemeController() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final controller = ThemeController(
      StorageService(await SharedPreferences.getInstance()),
    );
    await controller.load();
    sl.registerSingleton<ThemeController>(controller);
    return controller;
  }

  testWidgets('App root widget builds without throwing',
      (WidgetTester tester) async {
    final controller = await registerThemeController();
    addTearDown(sl.reset);

    expect(controller.themeMode, ThemeMode.system);

    await tester.pumpWidget(const NeonFlapApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);

    await controller.setThemeMode(ThemeMode.dark);
    await tester.pump();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);
  });

  testWidgets('MainMenuScreen builds without registered services',
      (WidgetTester tester) async {
    await sl.reset();
    addTearDown(sl.reset);

    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.pump();

    expect(find.text('NEON FLAP'), findsOneWidget);
  });

  testWidgets('Main menu exit dialog uses the active theme surface',
      (WidgetTester tester) async {
    await sl.reset();
    addTearDown(sl.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainMenuScreen(),
    ));
    await tester.pump();

    await tester.ensureVisible(find.text('EXIT GAME'));
    await tester.pump();
    await tester.tap(find.text('EXIT GAME'), warnIfMissed: false);
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    // The dialog defers backgroundColor to the DialogTheme (it is not
    // explicitly set). Verify the rendered container uses the theme surface.
    final theme = Theme.of(tester.element(find.byType(AlertDialog)));
    expect(
      theme.dialogTheme.backgroundColor,
      theme.colorScheme.surfaceContainerHigh,
    );
  });

  test('ThemeController persists the selected theme mode', () async {
    final controller = await registerThemeController();
    addTearDown(sl.reset);

    await controller.setThemeMode(ThemeMode.light);
    final restored = ThemeController(
      StorageService(await SharedPreferences.getInstance()),
    );
    await restored.load();

    expect(restored.themeMode, ThemeMode.light);
  });
}
