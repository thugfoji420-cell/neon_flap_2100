import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';
import 'package:neon_flap1_game/store/leaderboard_dialog.dart';

void main() {
  testWidgets('main menu remains reachable on a short phone display',
      (tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainMenuScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -240));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaderboard exposes Easy, Normal, Hard without cloud services',
      (tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showLeaderboardDialog(context),
          child: const Text('OPEN'),
        ),
      ),
    ));
    await tester.tap(find.text('OPEN'));
    await tester.pump();

    expect(find.text('EASY'), findsOneWidget);
    expect(find.text('NORMAL'), findsOneWidget);
    expect(find.text('HARD'), findsOneWidget);
    expect(find.text('OFFLINE PERSONAL BEST'), findsOneWidget);
  });
}
