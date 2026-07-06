# Walking Skeleton — Zual

**Phase:** 1
**Generated:** 2026-07-06

## User Story (phase framing)

**As a** parent, **I want to** trust that the countdown always reflects how much time is truly
left — even after I lock the phone or pause for a snack — **so that** when my young child looks
at the screen from across the room it is never wrong about how much longer they have to wait.

> WALKING_SKELETON adaptation: by explicit user decision, Phase 1 is **engine-only, no debug
> UI**. The story above is what the engine serves; this phase proves it with a deterministic
> unit-test suite (drift, pause/resume, backgrounding, screen-wake) rather than a visible,
> tappable screen. The first visible slice arrives in Phase 2 (Setup Screen).

## Capability Proven End-to-End

A single `TimerController`, provided at the app root, drives a correct drift-free countdown
through setup → running → (paused) → done using real wall-clock time — surviving pause/resume
and app backgrounding — and keeps the screen awake while running. Proven by the unit-test suite
and a clean `flutter analyze` + `flutter build apk --debug` on the existing Android scaffold.

## Architectural Decisions

These are locked for the project; later slices build on them without re-litigating.

| Decision | Choice | Rationale |
|---|---|---|
| State management | `provider ^6.1.5` wrapping a single `TimerController extends ChangeNotifier`, provided once at the app root | One shared piece of state driving many read-only consumers; Flutter's own recommended low-ceremony choice. No Riverpod/Bloc codegen. (research/STACK.md, ARCHITECTURE.md Pattern 1) |
| Timing mechanism | Wall-clock `DateTime.now()` deltas (`startedAt` + `pausedTotal` accumulator), **not** `Stopwatch` | Locked decision D-01 requires the countdown to keep advancing while backgrounded / device asleep and to reach `done` while backgrounded. A monotonic `Stopwatch` does not reliably count deep-sleep time on Android; wall-clock deltas do, and match design/README.md's state model. An injected `DateTime Function()` clock makes it deterministically testable. |
| Progress contract | `double progress` in 0..1, monotonic non-decreasing while a run is active | The single value every scene will consume (Phase 3 `SceneRenderer` takes only `progress`). Monotonic guard protects against device-clock tampering. |
| Phase enum shape | `enum TimerPhase { setup, running, paused, done }` | Closed set the whole app switches on; `paused` is a sub-state of running. (design/README.md, TIMER-01) |
| Screen-wake | `ScreenWake` interface (pure) + `WakelockScreenWake` adapter over `wakelock_plus ^1.6.1`, driven by the controller and paired to running-phase entry/exit | Keeps the domain layer plugin-free/testable while satisfying TIMER-05; strict pairing prevents a stuck wakelock (PITFALLS Pitfall 4). |
| Lifecycle handling | `TimerLifecycleBinder` (a `WidgetsBindingObserver`) calls `controller.syncToWallClock()` on `resumed` | Realizes done-while-backgrounded (D-02) and keeps the pure controller free of Widgets imports (PITFALLS Pitfall 2; handles `AppLifecycleState.hidden`). |
| Persistence | **None** for in-progress timer state (D-03) | A process kill returns to setup. Only Phase 2's last-used duration/theme (PERSIST-01) will use `shared_preferences`, and that is out of scope here. |
| Directory layout | `lib/timer/` = pure domain layer (foundation + `dart:async` only, no Material/Widgets); app-layer adapters (`wakelock_screen_wake.dart`, `timer_lifecycle_binder.dart`) and `main.dart` may import Widgets/plugins | Domain-layer isolation is the single most important structural boundary — it makes the engine unit-testable without a widget tree (ARCHITECTURE.md Structure Rationale). Later: `lib/screens/`, `lib/scenes/`, `lib/audio/` per research structure. |

## Stack Touched in Phase 1

Adapted for a fully-local Flutter Android app (no backend, no routing framework, no UI this phase):

- [x] Project scaffold — pre-existing Flutter Android scaffold (`flutter build apk --debug` is the target build; no new scaffold needed)
- [x] Lint / analyze / test runner — `flutter analyze` clean + `flutter test` (first non-widget unit-test suite in the repo)
- [ ] Routing — **N/A / out of scope**: this app uses phase-driven full-screen views (a `PhaseSwitcher`, arriving Phase 2+), not URL routes or `Navigator` stacks
- [ ] Database — **N/A / never**: the app is fully local with no backend; the only local storage (last-used settings) is Phase 2's `shared_preferences` and is out of scope here (D-03)
- [x] Real end-to-end wiring — one `TimerController` provided at the app root via `ChangeNotifierProvider`, reconciled to real time by a lifecycle observer; exercised end-to-end by the deterministic test suite in place of a tappable UI element (engine-only by decision)
- [x] Deployment target — the existing signed-debug Android scaffold; a `flutter build apk --debug` produces an installable build (real `applicationId` + production signing are Phase 5, PUBLISH-01)

## Out of Scope (Deferred to Later Slices)

Explicit so later phases do not re-open Phase 1's minimalism:

- Any child-facing or parent-facing UI (Setup screen, running screen, controls) — Phases 2–4
- The four scene renderers and the `SceneRenderer`/`SceneTheme` contract — Phase 3
- The completion chime / `audioplayers` and any audio — Phase 4
- Persisting last-used duration/theme (`shared_preferences`) — Phase 2 (PERSIST-01)
- Persisting in-progress timer state across a process kill — never (D-03)
- Background notifications / background audio when done-while-backgrounded — never (D-02)
- Real `applicationId`, production signing, store assets — Phase 5 (PUBLISH-01/02)
- iOS / Web platforms — deferred (v2)

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this engine without altering the decisions above:

- **Phase 2 — Setup Screen:** parent picks duration + theme and taps Start → calls `TimerController.start(minutes)`; last-used settings remembered via `shared_preferences` (first UI slice, Layout A).
- **Phase 3 — Scene Themes:** four full-screen `CustomPainter` scenes read only `TimerController.progress` (0..1) through the shared `SceneRenderer` contract; nothing tappable by the child.
- **Phase 4 — Parent Controls & Completion:** hidden long-press → controls sheet calling `pause()`/`resume()`/`endTimer()`; soft chime on `done`; breathing "All done" pill.
- **Phase 5 — Play Store Readiness:** real `applicationId`, production signing, store listing assets, Families-Policy target-audience declaration.
