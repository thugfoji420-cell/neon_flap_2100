import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:neon_flap1_game/firebase_options.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/app.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';
import 'package:neon_flap1_game/store/leaderboard_dialog.dart';
import 'package:neon_flap1_game/store/achievements_dialog.dart';
import 'package:neon_flap1_game/store/daily_reward_dialog.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> boot(WidgetTester tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await setupServiceLocator();
    await tester.pumpWidget(const NeonFlapApp(home: MainMenuScreen()));
    await tester.pump(const Duration(seconds: 1));
    return tester.element(find.byType(MainMenuScreen));
  }

  testWidgets('leaderboard dialog opens without layout error', (tester) async {
    final ctx = await boot(tester);
    await showLeaderboardDialog(ctx);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    expect(find.text('LEADERBOARD'), findsWidgets);
    debugPrint('REPRO_LEADERBOARD_OK');
  });

  testWidgets('achievements dialog opens without layout error', (tester) async {
    final ctx = await boot(tester);
    await showAchievementsDialog(ctx);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('ACHIEVEMENTS'), findsWidgets);
    debugPrint('REPRO_ACHIEVEMENTS_OK');
  });

  testWidgets('daily reward dialog opens without layout error', (tester) async {
    final ctx = await boot(tester);
    await showDailyRewardDialog(ctx);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('DAILY REWARDS'), findsWidgets);
    debugPrint('REPRO_DAILY_OK');
  });
}
