# Architecture Research

**Domain:** Flutter mobile app — single-screen-family state machine driving swappable full-screen animated "scene" renderers
**Researched:** 2026-07-06
**Confidence:** MEDIUM (Flutter core APIs — AnimationController, CustomPainter, ChangeNotifier, provider — are stable, well-documented, HIGH-reputation-source patterns confirmed via Flutter's own docs/architecture guide; folder-structure conventions are community opinion, correctly weighted LOW/advisory)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         App Shell (main.dart)                        │
│  MaterialApp → ChangeNotifierProvider<TimerController>(root)          │
│  → PhaseSwitcher (watches controller.phase)                          │
├───────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐        ┌──────────────────────────────────┐   │
│  │  SetupScreen     │        │        RunningScreen              │   │
│  │  (parent-facing) │───────▶│  (child-facing, phase != setup)   │   │
│  │  duration + theme│  start │  ┌──────────────────────────────┐ │   │
│  │  picker, Start    │        │  │  SceneHost                  │ │   │
│  └─────────────────┘        │  │  (progress → active Scene)   │ │   │
│                               │  └──────────────────────────────┘ │   │
│                               │  ┌──────────────────────────────┐ │   │
│                               │  │ LongPressCaptureLayer        │ │   │
│                               │  │ (~850ms) → opens overlay     │ │   │
│                               │  └──────────────────────────────┘ │   │
│                               │  ┌──────────────────────────────┐ │   │
│                               │  │ ParentControlsSheet (modal)  │ │   │
│                               │  │ DonePill (phase == done)     │ │   │
│                               │  └──────────────────────────────┘ │   │
│                               └──────────────────────────────────┘   │
├───────────────────────────────────────────────────────────────────────┤
│                    Scene Layer (4 interchangeable renderers)          │
│  ┌───────────┐  ┌───────────┐  ┌────────────┐  ┌────────────┐       │
│  │ DiscScene │  │SunriseScene│ │ WalkScene  │  │ CarScene   │       │
│  │ (Custom-  │  │(CustomPaint│ │(CustomPaint│  │(CustomPaint│       │
│  │  Painter) │  │ + gradient)│ │ + painter) │  │ + painter) │       │
│  └───────────┘  └───────────┘  └────────────┘  └────────────┘       │
│  All implement the same `SceneRenderer` contract: progress in, pixels out │
├───────────────────────────────────────────────────────────────────────┤
│                State / Domain Layer (pure Dart, no widgets)           │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  TimerController extends ChangeNotifier                        │ │
│  │  - phase: setup | running | paused | done                      │ │
│  │  - theme: SceneTheme                                            │ │
│  │  - progress: double (0..1), durationMinutes                    │ │
│  │  - start()/pause()/resume()/endTimer()                          │ │
│  │  - internally: Stopwatch + Timer.periodic (tick source)         │ │
│  │  - ChimePlayer dependency (injected, not owned)                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `TimerController` | Single source of truth for phase + progress + theme + duration; owns pause/resume time bookkeeping; the *only* place that knows about elapsed real time | `ChangeNotifier` in `lib/timer/timer_controller.dart`, holds a `Stopwatch` and a `Timer.periodic`, no Flutter Material/widget imports |
| `TimerPhase` (enum) | Encodes `setup / running / paused / done` as a closed set the UI switches on | Plain Dart `enum` |
| `SceneTheme` (enum) | The 4 (soon 5+) selectable themes | Plain Dart `enum`, mapped to a renderer via a registry function, not a switch scattered across the codebase |
| `SceneRenderer` contract | Uniform "given `progress: 0..1`, render full-screen pixels" boundary that all 4 scenes implement | Abstract widget base or simple typedef — a `StatelessWidget` subclass per scene, each taking `progress` (and nothing else) |
| `DiscScene` / `SunriseScene` / `WalkScene` / `CarScene` | Own their theme-specific drawing AND any perpetual decorative loop animation (bob, spin, twinkle, breathe) that is *not* progress-driven | `CustomPaint` + `CustomPainter`, each scene's `State` mixes in `TickerProviderStateMixin` only if it needs its own looping `AnimationController` for decorative motion |
| `SetupScreen` | Parent-facing form: duration presets/stepper + theme picker + Start button | `StatelessWidget`/`StatefulWidget` reading/writing `TimerController` via `context.watch`/`context.read` |
| `RunningScreen` | Child-facing host: renders the active `SceneRenderer`, hosts the hidden long-press capture layer, the parent-controls bottom sheet, and the done-pill overlay | Composition root for phase `running`/`paused`/`done` — **not three separate screens**, one screen with overlays |
| `LongPressCaptureLayer` | Detects the ~850ms hidden long-press without React to normal taps; opens `ParentControlsSheet` | Custom `RawGestureDetector` with a `LongPressGestureRecognizer(duration: ...)`, or manual `onPanDown`/`onPanEnd`/`onPanCancel` + `Timer` |
| `ParentControlsSheet` | Pause/Resume, End timer, Keep watching — talks only to `TimerController` methods | `showModalBottomSheet` reading `TimerController` via `Provider` |
| `ChimePlayer` | Plays the two-tone chime on phase → done | Small service class (e.g. wraps `audioplayers` or a synthesized tone), injected into `TimerController` so the controller stays testable without real audio I/O |

## Recommended Project Structure

```
lib/
├── main.dart                      # runApp, MaterialApp, root Provider wiring
├── app.dart                       # ZualApp widget: theme, PhaseSwitcher composition root
├── timer/                         # domain/state layer — no Material imports
│   ├── timer_controller.dart      # ChangeNotifier: phase, progress, theme, duration
│   ├── timer_phase.dart           # enum TimerPhase { setup, running, paused, done }
│   └── scene_theme.dart           # enum SceneTheme { disc, sunrise, walk, car }
├── audio/
│   └── chime_player.dart          # end-of-timer chime service
├── screens/
│   ├── setup/
│   │   ├── setup_screen.dart
│   │   ├── duration_picker.dart   # presets + custom stepper
│   │   └── theme_picker.dart      # 2x2 card grid, reuses scene thumbnails
│   └── running/
│       ├── running_screen.dart    # composition root for running/paused/done
│       ├── long_press_capture.dart
│       ├── parent_controls_sheet.dart
│       └── done_pill.dart
├── scenes/                        # the swappable renderer layer
│   ├── scene_renderer.dart        # shared contract / base widget
│   ├── scene_registry.dart        # SceneTheme -> SceneRenderer factory (the extension point)
│   ├── disc/
│   │   ├── disc_scene.dart
│   │   └── disc_painter.dart
│   ├── sunrise/
│   │   ├── sunrise_scene.dart
│   │   └── sunrise_painter.dart
│   ├── walk/
│   │   ├── walk_scene.dart
│   │   └── walk_painter.dart
│   └── car/
│       ├── car_scene.dart
│       └── car_painter.dart
└── theme/
    ├── app_colors.dart             # design-token color constants
    ├── app_text_styles.dart        # Baloo 2 / Quicksand text styles
    └── app_theme.dart              # ThemeData assembly
```

### Structure Rationale

- **`timer/` has zero Flutter Material imports.** This is the single most important boundary in this app: the state machine (phase transitions, progress math, pause bookkeeping) must be unit-testable with plain `flutter test` / `dart test` without pumping a widget tree. `ChangeNotifier` lives in `package:flutter/foundation.dart`, not Material, so this constraint is achievable.
- **`scenes/` is one folder per theme, each folder self-contained** (scene widget + painter [+ any local decorative controller]). Adding a 5th theme means: one new folder, one new enum case, one new registry entry — nothing else in the codebase changes. This directly satisfies the "5th theme should be cheap" requirement.
- **`scene_registry.dart` is the *only* place that maps `SceneTheme → widget`.** Both the full-screen `RunningScreen` and the small preview cards on `SetupScreen` call through this registry (passing different `progress`/size), so there is exactly one switch statement over `SceneTheme` in the whole app, not one per screen.
- **`screens/running/` composes but does not implement scenes.** `RunningScreen` never contains theme-specific drawing code — it only asks the registry for "the current scene" and stacks the long-press layer, controls sheet, and done pill on top. This keeps the "hidden gesture + parent overlay" concern orthogonal to "which theme is showing."
- **Feature-first over layer-first** for `screens/`, since each screen (setup vs. running) has very different concerns and low reuse between them; but the domain layer (`timer/`) is deliberately layer-first and isolated, because it's the one piece every screen and every scene depends on.

## Architectural Patterns

### Pattern 1: Single ChangeNotifier as app-wide state machine (via `provider`)

**What:** One `TimerController extends ChangeNotifier` created once at the app root and exposed via `ChangeNotifierProvider`. It is the single source of truth for `phase`, `theme`, `durationMinutes`, and `progress`. All screens/scenes read it with `context.watch<TimerController>()` (rebuild on change) or call it with `context.read<TimerController>()` (fire-and-forget actions like `.pause()`).

**When to use:** Exactly this app's shape — one shared piece of state driving many read-only consumers, no complex async data-fetching pipeline, no need for Riverpod's testability-via-override or Bloc's event/stream ceremony. Flutter's own official app-architecture guide recommends `ChangeNotifier`-based ViewModels for simple-to-moderate apps.

**Trade-offs:** `provider` is a thin, stable, minimal-dependency package (already the Flutter team's recommended starting point) — no extra learning curve or code-gen. The trade-off is it doesn't scale gracefully to many independent, deeply-nested state slices; that's irrelevant here since there is exactly one piece of shared state.

**Example:**
```dart
enum TimerPhase { setup, running, paused, done }
enum SceneTheme { disc, sunrise, walk, car }

class TimerController extends ChangeNotifier {
  TimerController({required ChimePlayer chimePlayer}) : _chime = chimePlayer;
  final ChimePlayer _chime;

  TimerPhase _phase = TimerPhase.setup;
  SceneTheme _theme = SceneTheme.disc;
  Duration _total = Duration.zero;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  TimerPhase get phase => _phase;
  SceneTheme get theme => _theme;
  double get progress => _total.inMilliseconds == 0
      ? 0.0
      : (_stopwatch.elapsedMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);

  void start(int minutes, SceneTheme theme) {
    _theme = theme;
    _total = Duration(minutes: minutes);
    _phase = TimerPhase.running;
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (progress >= 1.0) {
      _stopwatch.stop();
      _ticker?.cancel();
      _phase = TimerPhase.done;
      _chime.play();
    }
    notifyListeners();
  }

  void pause() {
    if (_phase != TimerPhase.running) return;
    _stopwatch.stop();
    _phase = TimerPhase.paused;
    notifyListeners();
  }

  void resume() {
    if (_phase != TimerPhase.paused) return;
    _stopwatch.start();
    _phase = TimerPhase.running;
    notifyListeners();
  }

  void endTimer() {
    _stopwatch..stop()..reset();
    _ticker?.cancel();
    _phase = TimerPhase.setup;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
```
Note: `Stopwatch`-based elapsed time (not raw `DateTime` deltas) already gives free, correct pause/resume bookkeeping — `stop()`/`start()` on the same `Stopwatch` naturally excludes paused duration from `elapsedMilliseconds`, so there is no need to hand-track `pausedTotal`/`pauseStart` as the HTML prototype did. The 100ms tick interval is a UI-refresh cadence choice, not a precision requirement — it is independent of any scene's own decorative-loop frame rate.

### Pattern 2: `SceneRenderer` contract — a dumb, pure function of `progress`

**What:** Every scene widget takes only `progress: double` (0..1) as theme-relevant input (plus perhaps a `Size`/`BoxConstraints` from its parent) and is otherwise self-contained. It knows nothing about `TimerController`, phases, pausing, or gestures.

**When to use:** Always, for this app — it is what makes scenes swappable and independently testable (a `WidgetTester` can pump `DiscScene(progress: 0.7)` in isolation with no controller in the tree at all).

**Trade-offs:** Requires the parent (`RunningScreen`/`SceneHost`) to explicitly read `progress` from `TimerController` and pass it down — one extra prop-drilling hop — but this is a small, worthwhile cost for total decoupling.

**Example:**
```dart
abstract class SceneRenderer extends StatelessWidget {
  const SceneRenderer({super.key, required this.progress});
  final double progress; // 0.0 = just started, 1.0 = time's up
}

class DiscScene extends SceneRenderer {
  const DiscScene({super.key, required super.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DiscPainter(remaining: 1 - progress),
      size: Size.infinite,
    );
  }
}

// scene_registry.dart — the ONE switch over SceneTheme in the app
Widget sceneFor(SceneTheme theme, double progress) => switch (theme) {
      SceneTheme.disc => DiscScene(progress: progress),
      SceneTheme.sunrise => SunriseScene(progress: progress),
      SceneTheme.walk => WalkScene(progress: progress),
      SceneTheme.car => CarScene(progress: progress),
    };
```

### Pattern 3: Progress-driven `CustomPainter` repaint via `Listenable`

**What:** For scenes whose visuals should update every frame purely as a function of `progress` (no independent looping animation), pass the driving `Listenable` (an `Animation<double>` or the `TimerController` itself) into `CustomPainter`'s `repaint:` parameter so the canvas repaints automatically without manual `setState` calls in the painter's owner.

**When to use:** Whenever a `CustomPainter`'s appearance depends purely on a value that changes over time and that value already has a `Listenable`/`Animation` behind it.

**Trade-offs:** Cleanly separates "when to repaint" from "how to draw," but for this app the simpler idiom is to just rebuild the whole `SceneRenderer` subtree each time `TimerController.notifyListeners()` fires (via `context.watch`) and construct a fresh `CustomPainter` with the current `progress` each build — `shouldRepaint` then just compares old vs. new `progress`. Reach for `repaint:`-based wiring only for a scene's *local* decorative loop (e.g., `WalkScene`'s bob/wheel-spin `AnimationController`, which must run continuously regardless of the shared `TimerController`'s 100ms tick cadence).

**Example:**
```dart
class DiscPainter extends CustomPainter {
  DiscPainter({required this.remaining});
  final double remaining;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = 150.0 * remaining;
    canvas.drawCircle(center, radius, Paint()..color = colorForRemaining(remaining));
  }

  @override
  bool shouldRepaint(covariant DiscPainter oldDelegate) =>
      oldDelegate.remaining != remaining;
}
```

## Data Flow

### Request Flow (Start → Running → Done)

```
[Parent taps Start on SetupScreen]
    ↓
context.read<TimerController>().start(minutes, theme)
    ↓
TimerController mutates phase/theme/total, starts Stopwatch + Timer.periodic
    ↓ notifyListeners() every ~100ms
PhaseSwitcher (watches phase) swaps SetupScreen → RunningScreen
    ↓
RunningScreen reads controller.progress + controller.theme every rebuild
    ↓
sceneFor(theme, progress) → active SceneRenderer repaints
    ↓ (progress reaches 1.0 inside TimerController._tick)
phase → done, ChimePlayer.play() fires
    ↓
RunningScreen (unchanged screen) shows DonePill overlay; scene renders progress=1 end-state
    ↓
[Parent/child taps DonePill] → controller.endTimer() → phase → setup → PhaseSwitcher swaps back
```

### State Management

```
TimerController (ChangeNotifier, app-root singleton via ChangeNotifierProvider)
    ↓ (Provider — InheritedWidget-based subscribe)
SetupScreen / RunningScreen / SceneRenderer subtree
    ↔ (read-only for scenes; read+write for screens/controls sheet)
Actions: start() / pause() / resume() / endTimer()
    ↓
TimerController mutates internal Stopwatch/Timer/phase/theme
    ↓
notifyListeners() → all `watch`-ing widgets rebuild with new progress/phase
```

### Key Data Flows

1. **Progress flow (one-directional, high frequency):** `TimerController.progress` → `RunningScreen` → `sceneFor()` → active `SceneRenderer` → `CustomPainter.paint()`. Nothing flows back up this chain; scenes are pure consumers.
2. **Control flow (low frequency, user-triggered):** `ParentControlsSheet` buttons / `DonePill` tap / `SetupScreen` Start button call `TimerController` methods directly (`context.read`, not `watch`, since these are one-shot actions, not rebuild triggers).
3. **Gesture-to-overlay flow:** `LongPressCaptureLayer` (screen-local, ~850ms threshold) sets local overlay-visibility state (can be a small local `ValueNotifier<bool>` or `StatefulWidget.setState` inside `RunningScreen` — this does *not* need to live in `TimerController`, since "is the sheet currently open" is a presentation concern, not a timer-domain concern) → shows `ParentControlsSheet` via `showModalBottomSheet`.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| v1 (4 themes, Android only, no persistence) | The structure above as-is — one `TimerController`, `provider` package, `scenes/` folder-per-theme. No routing framework needed (`PhaseSwitcher` is a simple conditional/`IndexedStack`, not `Navigator`). |
| 5–8 themes, optional "remember last duration/theme" persistence | Add a thin `SettingsRepository` (wraps `shared_preferences`) injected into `TimerController` or a sibling controller; `scene_registry.dart` keeps working unmodified — this is exactly the extension point it exists for. |
| iOS/Web re-enabled, multiple device form factors | No architectural change required — `CustomPainter` scenes are already resolution/DPI-independent (`Size`-driven); confirm `LongPressCaptureLayer` threshold behaves consistently across touch/mouse-emulated web input. |

### Scaling Priorities

1. **First likely friction point:** if a future theme needs *asynchronous* setup (e.g., loading a bundled font or asset before first paint), the `SceneRenderer` contract will need an optional loading/placeholder state. Not needed for the current 4 vector-only themes (no image assets), so defer.
2. **Second likely friction point:** if parent-controls grow beyond Pause/Resume/End (e.g., mute toggle, brightness), `ParentControlsSheet` should read a slightly larger but still single `TimerController`/settings surface rather than spawning a second app-wide state object — keep "one shared state machine" as a hard rule for as long as possible.

## Anti-Patterns

### Anti-Pattern 1: Letting scene widgets reach into `TimerController` directly

**What people do:** Import `TimerController` inside `DiscScene`/`WalkScene` etc. and call `context.watch<TimerController>()` from within the scene to get `progress`, instead of accepting `progress` as a constructor parameter.

**Why it's wrong:** Couples every scene to the app's global state shape. Makes scenes impossible to preview/test in isolation, and turns "add a 5th theme" into "understand the whole state machine" instead of "implement one contract."

**Do this instead:** Only `RunningScreen`/`SceneHost` (and the setup-screen preview cards) touch `TimerController`. Scenes are always constructed with an explicit `progress` value passed in.

### Anti-Pattern 2: One giant `switch(phase)` scattered across multiple widgets

**What people do:** Have `SetupScreen`, `RunningScreen`, `main.dart`, and some shared "AppShell" widget each independently check `controller.phase == TimerPhase.done` to decide what to render, duplicating the phase-to-UI mapping.

**Why it's wrong:** Phase transition rules (e.g., "done is still the running screen, not a new screen") get inconsistently reimplemented; a future phase change (e.g., adding a `TimerPhase.confirmingEnd`) requires hunting down every duplicate check.

**Do this instead:** Exactly one `PhaseSwitcher` widget owns the `phase → screen` mapping at the app root; `RunningScreen` internally owns the `running/paused/done` sub-mapping (pill overlay visibility, controls-sheet gating) since all three sub-phases render the *same* screen scaffold.

### Anti-Pattern 3: Driving progress from wall-clock `DateTime.now()` deltas with manual pause bookkeeping

**What people do:** Port the HTML prototype's `startTs`/`pausedTotal`/`pauseStart` fields verbatim, recomputing `elapsed = now - startTs - pausedTotal` on every frame.

**Why it's wrong:** Reimplements exactly what `Stopwatch` already does correctly and more simply (`start()`/`stop()` naturally exclude paused intervals); manual bookkeeping is a common source of off-by-a-frame or negative-elapsed bugs, especially around pause/resume edges.

**Do this instead:** Use `Stopwatch` (as in Pattern 1's example) for the elapsed-time source of truth; use `Timer.periodic` purely as a "please rebuild now" cadence signal, decoupled from the actual time math.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Audio (end chime) | `ChimePlayer` service class, injected into `TimerController` via constructor | Two soft sine tones (D5→G5); either bundle a short WAV and play via an audio plugin, or synthesize tones — this is an isolated concern behind one interface (`ChimePlayer.play()`), so the concrete implementation can be swapped without touching `TimerController` logic. Do this integration research separately (audio plugin choice) — it's orthogonal to the state-machine/scene architecture. |
| Local persistence (optional, "remember last duration/theme") | `SettingsRepository` wrapping `shared_preferences`, read once at app start, written on `start()` | Out of scope for v1 per PROJECT.md but the architecture already isolates it to one injectable dependency if added later. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `TimerController` ↔ `screens/*` | `provider` (`context.watch`/`context.read`) | Screens are the only layer allowed to both read and mutate the controller. |
| `screens/running` ↔ `scenes/*` | Direct constructor parameter (`progress`, via `scene_registry.dart`) | One-directional; scenes never call back into screens or the controller. |
| `screens/running` ↔ `LongPressCaptureLayer`/`ParentControlsSheet` | Local widget state (`ValueNotifier<bool>` or `setState`) for "is sheet open," then direct `TimerController` method calls (`pause()`/`resume()`/`endTimer()`) for actual state changes | Overlay visibility is presentation-only; timer state changes always funnel through the one controller. |
| `TimerController` ↔ `ChimePlayer` | Constructor injection, called once on phase → done | Keeps `TimerController` testable with a fake/mock `ChimePlayer` in unit tests (no real audio I/O needed to test phase transitions). |

## Sources

- [Guide to app architecture](https://docs.flutter.dev/app-architecture/guide) — official Flutter architecture guidance (ChangeNotifier-based ViewModel pattern), via Context7 `/flutter/website` — MEDIUM confidence (official docs, current)
- Flutter website docs on `CustomPainter`, `AnimationController`, `AnimatedBuilder`, and `repaint:`-driven canvas animation, via Context7 `/flutter/website` — MEDIUM confidence (official docs, current)
- [Flutter Project Structure: Feature-first or Layer-first?](https://codewithandrea.com/articles/flutter-project-structure/) — community folder-structure conventions, LOW confidence (opinionated blog, cross-checked against several similar 2024–2025 posts for consensus, used only for the `screens/`-level organization, not for the domain-layer isolation recommendation which is this document's own architectural judgment)
- `.planning/PROJECT.md`, `design/README.md` — project-specific requirements and design/behavior spec (source of truth for phase machine, theme list, gesture threshold, and chime spec)

---
*Architecture research for: Flutter visual countdown timer with swappable full-screen scene renderers*
*Researched: 2026-07-06*
