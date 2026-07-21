import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neon_flap1_game/screens/main_menu_screen.dart';

void main() {
  testWidgets('logout confirmation has finite dialog actions on small screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: MainMenuScreen()),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('LOGOUT'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Log out?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
