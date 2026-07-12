import 'package:flutter/material.dart';
import 'package:neon_flap_2100/core/di/service_locator.dart';
import 'package:neon_flap_2100/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise all services and load persisted state before the first frame.
  await setupServiceLocator();
  runApp(const NeonFlapApp());
}
