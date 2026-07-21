import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/store/achievements_dialog.dart';
import 'package:neon_flap1_game/store/daily_reward_dialog.dart';
import 'package:neon_flap1_game/store/leaderboard_dialog.dart';

void main() {
  testWidgets('Leaderboard dialog builds without throwing',
      (WidgetTester tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => showLeaderboardDialog(context),
          child: const Text('Open'),
        );
      }),
    ));
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LEADERBOARD'), findsOneWidget);
  });

  testWidgets('Achievements dialog builds without throwing',
      (WidgetTester tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => showAchievementsDialog(context),
          child: const Text('Open'),
        );
      }),
    ));
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
  });

  testWidgets('Daily reward dialog builds without throwing',
      (WidgetTester tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => showDailyRewardDialog(context),
          child: const Text('Open'),
        );
      }),
    ));
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DAILY REWARDS'), findsOneWidget);
  });
}
