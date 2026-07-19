# GitHub Copilot Instructions — Neon Flap 2100

## Project Type
Flutter + Flame game (Dart). Cyberpunk neon aesthetic.

## Architecture
- Service locator (GetIt) for DI — `sl<ServiceName>()`
- ChangeNotifier + AnimatedBuilder for state management
- Flame 1.x game engine with procedural Canvas rendering
- Offline-first: SharedPreferences authoritative, Firestore best-effort

## Code Style
- Explicit types on public APIs, `var`/`final` locally
- `_` prefix for private members and classes
- `const` constructors for widgets and data classes
- Firebase writes: `try { ... } catch (_) { /* offline-tolerant */ }`
- Doc comments (`///`) on every class and non-trivial method

## File Organization
- `lib/screens/` — UI screens
- `lib/game/` — Flame game engine + components
- `lib/services/` — Business logic layer
- `lib/firebase/` — Firebase integration
- `lib/widgets/` — Reusable UI widgets
- `lib/models/` — Data classes
- `lib/store/` — Store screens and dialogs
- `lib/core/` — Constants, theme, DI setup

## Key Packages
- `flame: ^1.24.0` — Game engine
- `get_it: ^9.2.1` — Service locator
- `shared_preferences: ^2.3.2` — Local persistence
- `audioplayers: ^6.1.0` — Audio
- `google_mobile_ads: ^9.0.0` — AdMob
- `in_app_purchase: ^3.2.0` — IAP
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_crashlytics`
- `google_sign_in: ^7.2.0`

## Common Patterns

### Service Access
```dart
import 'package:neon_flap1_game/core/di/service_locator.dart';
final service = sl<ServiceName>();
```

### Reactive UI
```dart
AnimatedBuilder(
  animation: sl<SomeService>(),
  builder: (_, __) => Text('${sl<SomeService>().value}'),
);
```

### Offline-Safe Firestore Write
```dart
try {
  await ref.set(data, SetOptions(merge: true));
} catch (_) { /* offline-tolerant */ }
```

### Object Pooling (Game Components)
```dart
// In NeonFlapGame:
final pipe = _acquirePipe();
if (pipe != null) {
  pipe.spawn(x: ..., gap: ..., speed: ...);
}
```

## Testing
- Fakes in `test/helpers/mock_services.dart`
- Run `flutter analyze && flutter test` after changes
- Never disable existing tests

## Rendering
All visuals are procedural (Canvas draws, neon paints). No image/sprites assets.
