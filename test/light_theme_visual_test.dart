import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/widgets/holo_panel.dart';
import 'package:neon_flap1_game/widgets/neon_button.dart';
import 'package:neon_flap1_game/widgets/neon_panel.dart';

void main() {
  test('light theme uses a restrained steel palette with visible boundaries',
      () {
    final scheme = AppTheme.lightScheme;
    final colors = NeonThemeColors.fromScheme(scheme);

    expect(scheme.surface, isNot(const Color(0xFFFFFFFF)));
    expect(colors.background, isNot(const Color(0xFFFFFFFF)));
    expect(colors.panel, isNot(const Color(0xFFFFFFFF)));
    expect(colors.field, isNot(const Color(0xFFFFFFFF)));
    expect(colors.panelBorder, isNot(scheme.surface));
    expect(scheme.onSurface.computeLuminance(), lessThan(0.06));
    expect(colors.shadow.computeLuminance(), lessThan(0.08));
  });

  testWidgets('light panels and buttons render with the metallic treatment',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: [
              HoloPanel(child: const SizedBox(height: 48)),
              const SizedBox(height: 12),
              NeonButton(label: 'PLAY', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark panels retain their established glass treatment',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: HoloPanel(child: const SizedBox(height: 48)),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile HUD no longer creates a top accent-line widget',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProfileHudPanel(child: const SizedBox(height: 96)),
        ),
      ),
    );

    final profile = find.byType(ProfileHudPanel);
    expect(
      find.descendant(of: profile, matching: find.byType(Positioned)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
