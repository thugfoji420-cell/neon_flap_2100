import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/app.dart';

void main() {
  runZonedGuarded<void>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Surface framework errors instead of letting the OS show "keeps stopping".
    FlutterError.onError = (details) => _showFatalError(details.exception, details.stack);
    PlatformDispatcher.instance.onError = (error, stack) {
      _showFatalError(error, stack);
      return true;
    };

    try {
      // Initialise all services and load persisted state before the first frame.
      await setupServiceLocator();
    } catch (error, stack) {
      _showFatalError(error, stack);
      return;
    }

    runApp(const NeonFlapApp());
  }, (error, stack) => _showFatalError(error, stack));
}

/// Replaces the opaque "App keeps stopping" dialog with a readable error
/// screen so the real cause is visible on the device and in crash reports.
void _showFatalError(Object error, StackTrace? stack) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Neon Flap 2100 failed to start',
                  style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '$error\n\n${stack ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
