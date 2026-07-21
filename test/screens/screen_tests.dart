import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/screens/google_sign_in_screen.dart';
import 'package:neon_flap1_game/screens/main_menu_screen.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  // ---------------------------------------------------------------------------
  // GoogleSignInScreen
  // ---------------------------------------------------------------------------
  group('GoogleSignInScreen', () {
    testWidgets('renders with title, subtitle, and sign-in button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const GoogleSignInScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('NEON FLAP'), findsOneWidget);
      expect(find.text('2100'), findsOneWidget);
      expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('sign-in button shows loading indicator when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const GoogleSignInScreen(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('CONTINUE WITH GOOGLE'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has proper layout structure with Column',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const GoogleSignInScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // MainMenuScreen
  // ---------------------------------------------------------------------------
  group('MainMenuScreen', () {
    testWidgets('renders with all menu buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('NEON FLAP'), findsOneWidget);
      expect(find.text('2100'), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('CHARACTER STORE'), findsOneWidget);
      expect(find.text('COIN SHOP'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('DAILY REWARDS'), findsOneWidget);
    });

    testWidgets('displays player name and pilot info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('PLAYER NAME:'), findsOneWidget);
      expect(find.textContaining('PILOT:'), findsOneWidget);
    });

    testWidgets('has proper layout with SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // Account Actions (Logout / Delete / Exit)
  // ---------------------------------------------------------------------------
  group('Account Actions', () {
    testWidgets('account action buttons are present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('LOGOUT'));
      await tester.pump();

      expect(find.text('LOGOUT'), findsOneWidget);
      expect(find.text('DELETE ACCOUNT'), findsOneWidget);
      expect(find.text('EXIT GAME'), findsOneWidget);
    });

    testWidgets('delete account shows confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('DELETE ACCOUNT'));
      await tester.pump();
      await tester.tap(find.text('DELETE ACCOUNT'), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('DELETE FOREVER'), findsOneWidget);
    });

    testWidgets('cancel dismisses delete dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('DELETE ACCOUNT'));
      await tester.pump();
      await tester.tap(find.text('DELETE ACCOUNT'), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('logout shows confirmation dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('LOGOUT'));
      await tester.pump();
      await tester.tap(find.text('LOGOUT'), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Log Out?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('LOG OUT'), findsOneWidget);
    });

    testWidgets('exit shows confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('EXIT GAME'));
      await tester.pump();
      await tester.tap(find.text('EXIT GAME'), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Exit Game?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);
    });
  });
}
