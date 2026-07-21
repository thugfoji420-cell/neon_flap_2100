import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/core/theme/theme_controller.dart';
import 'package:neon_flap1_game/firebase/auth_service.dart';
import 'package:neon_flap1_game/firebase/firebase_service.dart';
import 'package:neon_flap1_game/services/audio_service.dart';
import 'package:neon_flap1_game/services/offline_profile_service.dart';
import 'package:neon_flap1_game/services/settings_service.dart';
import 'package:neon_flap1_game/services/storage_service.dart';
import 'package:neon_flap1_game/settings/settings_screen.dart';

Future<void> _registerSettingsServices() async {
  await sl.reset();
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService(await SharedPreferences.getInstance());
  final settings = SettingsService(storage);
  await settings.load();
  final theme = ThemeController(storage);
  await theme.load();
  final offline = OfflineProfileService(storage);
  await offline.load();
  sl.registerSingleton<StorageService>(storage);
  sl.registerSingleton<SettingsService>(settings);
  sl.registerSingleton<ThemeController>(theme);
  sl.registerSingleton<AudioService>(AudioService());
  sl.registerSingleton<FirebaseService>(
    FirebaseService(null, null, AuthService.disabled(), offline),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets(
        'music selector stays usable on a small phone in $mode mode with large text',
        (tester) async {
      await _registerSettingsServices();
      addTearDown(sl.reset);
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('SPACE ADVENTURE'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('MENU MUSIC'), findsAtLeastNWidgets(2));
      expect(find.text('Revelation'), findsOneWidget);
      expect(find.text('PREVIEW'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });
  }
}
