import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:neon_flap1_game/core/di/service_locator.dart';
import 'package:neon_flap1_game/core/theme/app_theme.dart';
import 'package:neon_flap1_game/app.dart';

/// Single root-zone startup. `WidgetsFlutterBinding.ensureInitialized()` and
/// `runApp()` MUST live in the same zone (the root zone here) — wrapping either
/// in a separate `runZonedGuarded` creates a second zone and makes Flutter
/// throw "Zone mismatch." when it dispatches errors.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore offline persistence -------------------------------------------
  // On Android and iOS, disk persistence is enabled by default in the
  // underlying native SDKs (24-hour cache, ~100 MB default limit). The
  // enablePersistence() call is a no-op when already enabled — we call it
  // explicitly here so the intent is documented and to ensure future SDK
  // changes don't accidentally disable it.
  //
  // On web, offline persistence is not supported (the web SDK uses a
  // different indexed-DB mechanism) and enablePersistence() throws an
  // UnsupportedError, so we skip it there.
  //
  // The app uses best-effort writes throughout: local SharedPreferences is
  // always authoritative; Firestore is the sync target. With persistence
  // enabled, cached reads succeed during brief outages and pending writes
  // are queued until connectivity returns.
  if (!kIsWeb) {
    // Settings.persistent is the explicit-persistence property. On Android
    // and iOS the underlying native SDKs default to persistent=true, and
    // cloud_firestore's Settings class mirrors that. The call below is
    // declarative — it documents our intent to use offline persistence and
    // fail-fast if a future SDK change flips the default.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('${details.stack}');
    _showFatalError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    debugPrint('PLATFORM ERROR: $error');
    debugPrint('$stack');
    _showFatalError(error, stack);
    return true;
  };

  try {
    await setupServiceLocator();
  } catch (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    _showFatalError(error, stack);
    return;
  }

  runApp(const MyApp());
}

/// Replaces the opaque "App keeps stopping" dialog with a readable error
/// screen so the real cause is visible on the device and in crash reports.
void _showFatalError(Object error, StackTrace? stack) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Neon Flap 2100 failed to start',
                  style: TextStyle(
                    color: AppTheme.darkScheme.error,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '$error\n\n${stack ?? ''}',
                      style: TextStyle(
                        color: AppTheme.darkScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
