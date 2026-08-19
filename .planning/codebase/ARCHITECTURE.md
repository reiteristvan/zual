<!-- refreshed: 2026-08-19 -->
# Architecture

**Analysis Date:** 2026-08-19 (v1.0 shipped)

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│  Composition Root — lib/main.dart                                    │
│  main() loads SetupPreferences, constructs TimerController,          │
│  attaches TimerLifecycleBinder, builds the chime player + soundOn    │
│  notifier, then runApp(MyApp).                                       │
│  MyApp = ChangeNotifierProvider<TimerController> → MaterialApp       │
└──────────────────────────────────────────────────────────────────────┘
        │ home:
        ▼
┌───────────────────────────────┐   Navigator.push   ┌──────────────────────────┐
│ SetupScreen (parent-facing)   │ ─────────────────► │ RunningScreen (child)    │
│ lib/screens/setup_screen.dart │ ◄───────────────── │ lib/screens/             │
│ presets · custom stepper ·    │   pop on End /     │   running_screen.dart    │
│ scene picker · Start          │   "All done" tap   │ long-press → Parent      │
└───────────────────────────────┘                    │ Controls sheet           │
        │ widgets                                    └──────────────────────────┘
        ▼                                                     │ sceneFor(theme)
┌───────────────────────────────┐                             ▼
│ lib/widgets/                  │                    ┌──────────────────────────┐
│ SceneGrid · SceneCard ·       │                    │ lib/scenes/              │
│ PressableSurface ·            │                    │ scene_registry.sceneFor  │
│ HoldRepeatButton              │                    │  → Disc/Sunrise/Walk/Car │
└───────────────────────────────┘                    │    Scene (SceneRenderer) │
                                                     │  → *Painter (CustomPaint)│
                                                     └──────────────────────────┘
                     ┌───────────────────────────────────────┴──────┐
                     ▼ reads progress                                ▼ tokens
┌──────────────────────────────────────────┐   ┌──────────────────────────────┐
│ lib/timer/ — TimerController             │   │ lib/theme/app_tokens.dart    │
│ ChangeNotifier · wall-clock progress ·   │   │ colors · radii · shadows ·   │
│ TimerPhase state machine                 │   │ text styles (design source)  │
└──────────────────────────────────────────┘   └──────────────────────────────┘
        │ depends on plugin-free interfaces
        ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Platform adapters — one plugin import per file                       │
│ ScreenWake ← WakelockScreenWake (wakelock_plus) / NoopScreenWake     │
│ ChimePlayer ← AudioplayersChimePlayer (audioplayers) / NoopChimePlayer│
│ SetupPreferences (shared_preferences)                                │
└──────────────────────────────────────────────────────────────────────┘
        ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Android runtime — android/ (Flutter embedding, unmodified Kotlin)    │
└──────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **`main()`** | Composition root: loads prefs before the first frame, wires controller/chime/wakelock, attaches the lifecycle binder | `lib/main.dart` |
| **`MyApp`** | Provides `TimerController` to the tree; configures `MaterialApp` with `AppTokens`-derived theme | `lib/main.dart` |
| **`SetupScreen`** | Parent-facing duration + scene selection; owns selection state and persists it on Start | `lib/screens/setup_screen.dart` |
| **`RunningScreen`** | Child-facing full-screen scene host; detects the edge into `done`, fires the chime once, hosts the long-press Parent Controls sheet and the "All done" pill | `lib/screens/running_screen.dart` |
| **`TimerController`** | Wall-clock progress engine and `TimerPhase` state machine; the app's single source of truth | `lib/timer/timer_controller.dart` |
| **`TimerLifecycleBinder`** | `WidgetsBindingObserver` that calls `syncToWallClock()` on foreground return, realizing done-while-backgrounded | `lib/timer/timer_lifecycle_binder.dart` |
| **`sceneFor()`** | The only function allowed to name a concrete scene widget by type | `lib/scenes/scene_registry.dart` |
| **`SceneRenderer` / `SceneRendererState`** | Shared animation spine: one `Ticker` per scene, samples `TimerController.progress`, exposes a decorative loop phase | `lib/scenes/scene_renderer.dart` |
| **Scene painters** | `DiscPainter`, `SunrisePainter`, `WalkPainter`, `CarPainter` — pure functions of progress + loop phase | `lib/scenes/{disc,sunrise,walk,car}/` |
| **`ScenePreviewPainter`** | Static scene-at-rest thumbnails for the Setup screen's scene cards | `lib/scenes/scene_preview.dart` |
| **`AppTokens`** | Every color, radius, shadow, and `TextStyle` in the app, transcribed from `design/README.md` | `lib/theme/app_tokens.dart` |
| **`SetupPreferences`** | Validate-on-every-read persistence of duration, theme, and mute | `lib/settings/setup_preferences.dart` |
| **`ChimeSynth`** | Generates the two-tone completion chime as WAV bytes in pure Dart | `lib/audio/chime_synth.dart` |
| **`PressableSurface`** | The single implementation of the design's pressed-state contract, shared by every tappable surface | `lib/widgets/pressable_surface.dart` |
| **`HoldRepeatButton`** | Tap-or-hold stepper button with accelerating repeat, driven by accumulated scheduled durations (not wall clock) so it is testable under fake time | `lib/widgets/hold_repeat_button.dart` |

## Pattern Overview

**Overall:** A small, layered Flutter app with one shared `ChangeNotifier` at its center and
a strict painter-per-scene rendering layer. No backend, no repositories, no DI container.

**Key characteristics:**
- Two screens, one `Navigator.push`/`pop` transition. No routing framework.
- One `ChangeNotifier` (`TimerController`) provided at the root; everything else is local
  widget state or plain constructor injection.
- Rendering is `CustomPainter` end to end — no bitmaps, no animation-file runtime.
- Every platform plugin sits behind a plugin-free interface with a no-op test double.
- Constructor injection everywhere (clock, tick interval, screen-wake, chime player), so
  the whole app is testable without platform channels or real elapsed time.

## Layers

**Composition root:**
- Location: `lib/main.dart`
- Constructs every long-lived object and injects it downward. Deliberately loads
  `SetupPreferences` *before* `runApp` so the very first frame already shows the restored
  preset and scene, and wraps that load in a catch-all fallback so launch can never fail on
  a corrupt preference store.

**Screens:**
- Location: `lib/screens/`
- `SetupScreen` (stateful; owns duration/scene selection) and `RunningScreen` (stateful;
  owns done-edge detection, chime latch, and the "All done" pill's breathing animation).
- `placeholder_running_screen.dart` also lives here but is **dead code** — an interim Phase
  1/2 artifact superseded by `RunningScreen`, referenced only from doc comments.

**Scenes:**
- Location: `lib/scenes/`
- `SceneRenderer` is an abstract `StatefulWidget`; `SceneRendererState` mixes in
  `SingleTickerProviderStateMixin` and owns the per-scene `Ticker`. Each concrete scene
  supplies a `CustomPainter` that is a pure function of `(progress, loopPhase)`.
- The loop phase accumulates an offset across `Ticker` stop/restart segments rather than
  resetting to zero, so decorative loops do not visibly snap back on Pause/Resume.

**Timer core:**
- Location: `lib/timer/`
- Pure Dart, no Flutter widgets beyond `ChangeNotifier`. `TimerController` derives progress
  from injected-clock timestamps, not a `Stopwatch` or tick count.

**Design tokens:**
- Location: `lib/theme/app_tokens.dart`
- An `abstract class` used purely as a namespace of `static const` values. Widgets never
  hardcode a color, radius, shadow, or text style.

**Platform adapters:**
- Location: `lib/timer/wakelock_screen_wake.dart`, `lib/audio/audioplayers_chime_player.dart`,
  `lib/settings/setup_preferences.dart`
- Exactly one file imports each plugin. Everything upstream depends on the interface.

## Data Flow

### Starting a timer

1. `main()` loads `SetupPreferences`, builds `TimerController` + adapters, runs `MyApp`.
2. `MyApp` provides the controller and renders `SetupScreen` seeded with the restored
   duration and theme.
3. Parent picks a duration (preset or custom stepper) and a scene; `SceneGrid` reports the
   selection back up.
4. Start → `SetupPreferences.persistIfPreset(...)` (custom durations are never persisted),
   then `TimerController.start(minutes)` and `Navigator.push(RunningScreen)`.
5. `start()` clamps to 1–120 minutes, records the start timestamp, sets
   `TimerPhase.running`, enables screen wake, and starts a 200 ms reconcile ticker.

### Rendering a frame

1. The scene's `Ticker` fires; `SceneRendererState` samples
   `context.read<TimerController>().progress` plus its own loop phase.
2. `setState` triggers a repaint; the scene's `CustomPainter` draws the frame as a pure
   function of those two numbers.
3. Painters never read the controller or hold state of their own.

### Completing

1. Either the periodic ticker or `TimerLifecycleBinder` (on foreground return) calls
   `syncToWallClock()` — the single reconcile path.
2. If elapsed ≥ total, phase flips to `TimerPhase.done`, the ticker stops, progress pins to
   1.0, and screen wake is released.
3. `RunningScreen` detects the *edge* into `done` (not every rebuild), plays the chime once
   if unmuted, and shows the breathing "All done" pill.
4. Tapping the pill (or End timer in the Parent Controls sheet) calls `endTimer()` and pops
   exactly once, guarded so two exit paths cannot double-pop.

### Backgrounding

Progress is a pure function of wall-clock elapsed time, so a backgrounded app whose timers
the OS throttled still computes the correct progress the moment it is reconciled. Per
locked decision D-01 backgrounding never pauses the timer — only an explicit parent action
does.

**State management:**
- `provider` + `ChangeNotifier`. One `ChangeNotifierProvider<TimerController>.value` at the
  root; scenes read it via `context.read`/`watch`.
- Everything else is local `State` (selection on Setup, chime latch and pill animation on
  Running) or a `ValueNotifier<bool>` for the shared mute preference.

## Key Abstractions

**`TimerController` (ChangeNotifier):**
- The single source of truth for `phase` and `progress`.
- Progress is monotonic non-decreasing via a high-water mark, so a backward device-clock
  change cannot rewind a running countdown.

**`SceneRenderer` contract:**
- One animation spine for all four scenes. Adding a scene means adding a widget + painter
  and one `case` in `sceneFor()` — `RunningScreen` never changes.

**Plugin-isolation interfaces:**
- `ScreenWake` / `ChimePlayer`: plain interface, real adapter, no-op double. Widget tests
  never touch a platform channel.

**`AppTokens`:**
- Namespaced design constants. The mechanism that makes "pixel-accurate to `design/README.md`"
  enforceable rather than aspirational.

**`PressableSurface`:**
- One implementation of the pressed-state contract, so every tappable surface behaves
  identically. (Android has no hover, so the design's hover state is realized as pressed.)

## Entry Points

**Dart:**
- `lib/main.dart` → `Future<void> main()` — loads prefs, wires dependencies, `runApp(MyApp(...))`

**Android:**
- `android/app/src/main/AndroidManifest.xml` — declares `MainActivity`; `applicationId` is
  `com.ireiter.zual`

**Asset generators (developer-only):**
- `test/tool/generate_launcher_icon_test.dart`, `generate_store_icon_test.dart`,
  `generate_feature_graphic.dart` — headless painter → PNG pipelines run under
  `flutter test` (`dart:ui` rasterization has no headless backend outside the Flutter test
  engine)

## Architectural Constraints

- **Platform:** Android only for v1. `web/` is scaffold-only and unverified; there is no
  `ios/` directory.
- **Orientation:** portrait only, by design.
- **Offline:** no network code anywhere. No accounts, analytics, ads, or third-party SDKs.
- **No bitmaps in the running UI:** all scene visuals are `CustomPainter` shape primitives.
- **Design fidelity:** colors, radii, timings, and interaction thresholds (e.g. the 850 ms
  long-press) come from `design/README.md` and are treated as final.
- **Nothing tappable inside a running scene:** the only affordances are the hidden
  long-press and, at `done`, the "All done" pill.
- **Persisted values are untrusted:** every `SetupPreferences` read re-validates range,
  enum membership, and type.

## Anti-Patterns

The three anti-patterns recorded against the original scaffold — all code in one file, no
state-management layer, and a hardcoded theme — were all resolved during v1.0 (`lib/` is
now 29 files across seven directories; `provider` + `ChangeNotifier` carries shared state;
`AppTokens` centralizes the theme). What follows are the *current* standing issues.

### Test files that mutate committed binaries

**What happens:** `test/tool/generate_launcher_icon_test.dart` and
`generate_store_icon_test.dart` carry the `_test.dart` suffix, so a plain `flutter test`
run silently rewrites their committed PNGs.

**Why it's wrong:** A test run should not have side effects on tracked files. Output is
byte-stable today, so the working tree stays clean — but that is luck, not a guarantee.

**Do this instead:** Follow the pattern established by `generate_feature_graphic.dart`:
name generators *without* the `_test.dart` suffix so `flutter test` never discovers them,
and pair each with a read-only drift-lock test that asserts the committed bytes still match.
(Recorded as accepted risk in `05-REVIEW.md` WR-04/WR-05.)

### Dead interim screen still in `lib/`

**What happens:** `lib/screens/placeholder_running_screen.dart` is unreferenced — no import
anywhere in `lib/` or `test/`, only mentions in doc comments.

**Why it's wrong:** Dead code invites accidental revival and inflates the apparent surface
area of `lib/screens/`.

**Do this instead:** Delete it and rewrite the two doc-comment references in
`running_screen.dart` to describe the history without a dangling `[PlaceholderRunningScreen]`
link.

### Android release-build gaps

**What happens:** `android/app/build.gradle.kts` leaves a `FileInputStream` unclosed when
reading `key.properties`, and has no build-time gate preventing an accidentally
debug-signed release build.

**Why it's wrong:** A debug-signed `.aab` is rejected by Play, and the failure surfaces
late. The unclosed stream is a minor resource leak in the build script.

**Do this instead:** Use `.use { }` for the properties read, and fail the release build
explicitly when signing config is absent rather than falling back to debug signing.
(Recorded as accepted non-blocking debt in `05-REVIEW.md`.)

## Error Handling

**Strategy:** Fail soft on anything that could block launch or a running countdown; there
is no error UI, because a child-facing timer showing an error dialog is worse than a timer
quietly falling back to defaults.

**Patterns:**
- Preference loading is double-guarded: `SetupPreferences.load()` validates range, enum
  membership, and type per key, and `main()` additionally wraps the whole load in a
  catch-all that falls back to the built-in defaults.
- `TimerController` clamps its inputs (`minutes` to 1–120), floors negative elapsed at
  zero, and pins progress with a high-water mark — malformed state cannot propagate.
- Phase transitions are no-ops when called from the wrong phase (`pause()` outside
  `running`, `resume()` outside `paused`), so double-taps and races are harmless.
- Exit paths are latch-guarded so two routes to the same `Navigator.pop()` cannot double-pop.
- Flutter's default red-screen error handling is untouched — no custom `ErrorWidget`.

## Cross-Cutting Concerns

**Logging:** none. No logging framework, no `print`/`debugPrint` in `lib/`. The app has no
diagnostics surface and collects nothing.

**Validation:** concentrated at the two trust boundaries — persisted preferences
(`SetupPreferences`) and duration input (`TimerController.start` plus
`_SetupScreenState._setCustomMin`, which clamps independently of any button's disabled
state).

**Authentication / networking / telemetry:** none, by design. See `docs/index.html`.

**Accessibility:** the running screen is intentionally wordless and number-free, so there
is no text to read out. A colorblind-safe audit of the Shrinking Disc's green→yellow→red
zones is an open v2 candidate (A11Y-01).

**Responsiveness:** the design source specifies only a 402 px phone reference frame. The
Setup screen caps its content column at 440 px and centers it so grid cells stay
phone-proportioned on tablets; scene-card thumbnails use `Expanded` to scale into their
cards. Future screen work should hold that line — "responsive" here means both "does not
overflow a small phone" and "does not stretch absurdly on a tablet".

---

*Architecture analysis: 2026-08-19*
