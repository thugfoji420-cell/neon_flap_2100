# AI_RULES.md — Coding Rules for AI Agents

## General Rules

1. **Understand before changing** — Always read and analyze existing code before proposing or making changes. Never assume you know the implementation.

2. **One change at a time** — Fix issues individually. After each change, run `flutter analyze` and `flutter test` before moving to the next.

3. **Preserve existing functionality** — Do not change business logic unless explicitly instructed. Do not refactor unrelated code.

4. **Use existing patterns** — Match the project's coding style, architecture, and conventions. If the project uses `ChangeNotifier` for state, do not introduce a new state management approach.

## Code Style

1. **Explicit types on public APIs** — Use `CoinService service` not `var service` for public method parameters and return types.
2. **`var`/`final` locally** — Inside method bodies, use `var` or `final` for local variables.
3. **`_` prefix for private** — All private members and private classes use `_` prefix.
4. **Try-catch for Firebase** — Every Firestore write must be wrapped in try-catch with `/* offline-tolerant */` comment.
5. **No image assets** — All rendering is procedural via Canvas. Never add sprite or image assets.
6. **`const` constructors** — Use `const` for widgets and immutable data classes where possible.

## Architecture Rules

1. **Service Locator only** — Access services via `sl<T>()` from `package:neon_flap1_game/core/di/service_locator.dart`. Never pass services through constructors for business-logic dependencies.
2. **No BLoC/Provider/Riverpod** — State management is `ChangeNotifier` + `AnimatedBuilder` only.
3. **Game → Controller bridge** — The Flame game writes to `GameController` (ChangeNotifier). Flutter UI reads from it. Services are accessed directly via `sl<T>()` inside the game.
4. **No per-frame allocations in game loop** — Pre-allocate paints, paths, and vectors. The `update()` and `render()` methods run every frame.
5. **Pool game objects** — Pipes, coins, and obstacles must use the existing pool system in `NeonFlapGame`. Never `add()`/`remove()` components during gameplay.

## Testing Rules

1. Run `flutter analyze` and `flutter test` after every change.
2. Fix all analysis issues before marking a task complete.
3. Use fakes from `test/helpers/mock_services.dart` for tests.
4. Do not disable, skip, or remove existing tests.
5. If a test fails due to your change, fix the production code, not the test.

## File Organization

- `lib/screens/` — UI screens (Flutter widgets)
- `lib/game/` — Flame game engine + components
- `lib/services/` — Business logic, persistence, ads, audio, IAP
- `lib/firebase/` — Firebase integration layer
- `lib/models/` — Data classes
- `lib/widgets/` — Reusable UI widgets
- `lib/store/` — Store screens, dialogs, shop
- `lib/settings/` — Settings screen
- `lib/routing/` — Route constants + transitions
- `lib/core/` — Constants, DI setup, theme, utilities
- `lib/domain/` — Domain entities + repository interfaces
- `lib/data/` — Data layer implementations
