# Phase 3: Scene Themes - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 12 (new) + 1 (modified reference wiring)
**Analogs found:** 12 / 12 (all via in-repo analogs; no external-only files)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/scenes/scene_renderer.dart` | provider/base-class | event-driven (ticker-driven) | `lib/scenes/scene_preview.dart` (`ScenePreviewPainter` abstract base) | role-match (abstraction-boundary discipline, not painting) |
| `lib/scenes/scene_registry.dart` | utility (factory/switch) | transform | `lib/widgets/scene_grid.dart` (`_painters` map + `SceneGrid.build`'s theme→widget mapping) | exact (same "one switch" role) |
| `lib/scenes/disc/disc_painter.dart` | component (CustomPainter) + pure-fn utility | transform | `lib/scenes/scene_preview.dart` (`DiscPreviewPainter`) | exact (same theme, static→animated) |
| `lib/scenes/disc/disc_scene.dart` | component (StatefulWidget) | streaming (ticker-polled progress) | `lib/screens/placeholder_running_screen.dart` (`_PlaceholderRunningScreenState`) | role-match (progress-consuming stateful widget) |
| `lib/scenes/sunrise/sunrise_painter.dart` | component (CustomPainter) + pure-fn utility | transform | `lib/scenes/scene_preview.dart` (`SunrisePreviewPainter`) | exact |
| `lib/scenes/sunrise/sunrise_scene.dart` | component (StatefulWidget) | streaming | `lib/screens/placeholder_running_screen.dart` | role-match |
| `lib/scenes/walk/walk_painter.dart` | component (CustomPainter) + pure-fn utility | transform | `lib/scenes/scene_preview.dart` (`WalkPreviewPainter`) | exact |
| `lib/scenes/walk/walk_scene.dart` | component (StatefulWidget) | streaming | `lib/screens/placeholder_running_screen.dart` | role-match |
| `lib/scenes/car/car_painter.dart` | component (CustomPainter) + pure-fn utility | transform | `lib/scenes/scene_preview.dart` (`CarPreviewPainter`) | exact |
| `lib/scenes/car/car_scene.dart` | component (StatefulWidget) | streaming | `lib/screens/placeholder_running_screen.dart` | role-match |
| `lib/screens/running_screen.dart` | screen/controller (StatefulWidget) | request-response + streaming | `lib/screens/placeholder_running_screen.dart` (the file it replaces) | exact (direct predecessor) |
| `test/support/progress_sweep.dart` | test-utility | batch | (no existing test-helper analog; new pattern) | none — see "No Analog Found" |

## Pattern Assignments

### `lib/scenes/scene_renderer.dart` (provider/base-class, event-driven)

**Analog:** `lib/scenes/scene_preview.dart` lines 1-12 (`ScenePreviewPainter`) for the *abstraction discipline*; `lib/timer/timer_controller.dart` for the *progress/phase contract this base class wraps*.

**Abstraction-boundary pattern to copy** (`lib/scenes/scene_preview.dart:10-12`):
```dart
abstract class ScenePreviewPainter extends CustomPainter {
  const ScenePreviewPainter();
}
```
Copy the same discipline: `SceneRenderer` must be an abstract base that `RunningScreen`/`scene_registry.dart` depend on, never a concrete scene type by name (mirrors D-06 from Phase 2, explicitly called out in CONTEXT.md as the discipline this phase's contract must uphold).

**Progress/phase contract to consume** (`lib/timer/timer_controller.dart:42-53`):
```dart
TimerPhase get phase => _phase;

double get progress {
  final clamped = _rawFraction;
  return clamped > _progressHighWaterMark ? clamped : _progressHighWaterMark;
}
```
`progress` is a pure getter recomputed on every access — safe to poll every frame from a `Ticker` (per RESEARCH.md Pattern 1). `phase` is the low-frequency signal to `context.watch` for ticker start/stop, exactly as `_PlaceholderRunningScreenState.build` already does via `context.watch<TimerController>()` (`lib/screens/placeholder_running_screen.dart:61`).

**Ticker-hosting mixin** — RESEARCH.md's `SceneRendererState<T>` sketch (lines 250-293 of 03-RESEARCH.md) is the concrete pattern to implement verbatim; there is no closer in-repo analog since no ticker-based widget exists yet in this codebase.

---

### `lib/scenes/scene_registry.dart` (utility, transform)

**Analog:** `lib/widgets/scene_grid.dart` lines 108-120 (`SceneGrid._labels` / `_painters` maps)

**Core "one switch" pattern to copy**:
```dart
static const Map<SceneTheme, ScenePreviewPainter> _painters = {
  SceneTheme.disc: DiscPreviewPainter(),
  SceneTheme.sunrise: SunrisePreviewPainter(),
  SceneTheme.walk: WalkPreviewPainter(),
  SceneTheme.car: CarPreviewPainter(),
};
```
`scene_registry.dart` is the real-scene counterpart: a single `SceneTheme -> SceneRenderer` factory/switch, the only file allowed to name concrete scene types (`DiscScene`, `SunriseScene`, `WalkScene`, `CarScene`) by name — exactly as `SceneGrid` is today "the one place allowed to reference concrete painter types by name, per D-06" (comment at `lib/widgets/scene_grid.dart:95-96`).

---

### `lib/scenes/disc/disc_painter.dart` (CustomPainter + pure fns, transform)

**Analog:** `lib/scenes/scene_preview.dart` lines 19-45 (`DiscPreviewPainter`)

**Imports pattern** (line 1):
```dart
import 'package:flutter/material.dart';
```

**Core CustomPainter pattern to extend** (lines 28-41):
```dart
@override
void paint(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _background);

  final center = size.center(Offset.zero);
  const radius = 22.0; // 44px diameter.

  final shadowPaint = Paint()
    ..color = _shadowColor
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  canvas.drawCircle(center + const Offset(0, 3), radius, shadowPaint);

  canvas.drawCircle(center, radius, Paint()..color = _discColor);
}
```
Differences for the real scene: radius is `progress`-derived (shrinking disc formula, design doc §C, locked D-01), and `shouldRepaint` must compare both `progress` and decorative-loop phase fields (RESEARCH.md Pitfall 2) instead of the static `=> false` at line 44.

**Pure-function extraction pattern to add** (from RESEARCH.md Pattern 3, no in-repo precedent — this is new discipline for the codebase):
```dart
Color discColorForRemaining(double remaining) {
  const green = Color(0xFF7FA87A);
  const yellow = Color(0xFFE8B75A);
  const red = Color(0xFFDE6A4B);
  if (remaining > 0.5) return green;
  if (remaining > 0.2) {
    final t = (remaining - 0.2) / (0.5 - 0.2);
    return Color.lerp(yellow, green, t)!;
  }
  final t = remaining / 0.2;
  return Color.lerp(red, yellow, t)!;
}
```
Keep this as a standalone top-level function outside `paint()` so it is unit-testable without pumping a widget tree (D-03 test-layer requirement).

---

### `lib/scenes/disc/disc_scene.dart`, `sunrise_scene.dart`, `walk_scene.dart`, `car_scene.dart` (StatefulWidget, streaming)

**Analog:** `lib/screens/placeholder_running_screen.dart` (whole file, esp. lines 22-38, 59-100)

**Imports pattern to copy** (lines 1-6):
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../timer/timer_phase.dart';
```

**Progress-consumption pattern** (lines 61-64):
```dart
final controller = context.watch<TimerController>();
_maybeAutoPopWhenDone(controller.phase);

final remaining = (1 - controller.progress).clamp(0.0, 1.0);
```
Each scene's `State` replaces this single `context.watch`-driven read with the `SceneRendererState<T>` base class's ticker-polled `progress` getter (per `scene_renderer.dart` above) — `context.watch<TimerController>()` is retained *only* for `.phase`, not for per-frame `.progress` reads (RESEARCH.md Anti-Pattern: "Passing progress into a scene only via context.watch rebuilds").

**Structure to mirror:** one `StatefulWidget` + private `State` class per scene, `CustomPaint` inside `build()`, no `GestureDetector`/tap handling anywhere in the widget tree (SCENE-05 "nothing tappable" requirement — this file currently has an `IconButton` for back-nav, which must NOT be copied into the scene widgets themselves; that stays a `RunningScreen`-composition concern).

---

### `lib/screens/running_screen.dart` (screen, request-response + streaming)

**Analog:** `lib/screens/placeholder_running_screen.dart` (entire file, this is the file it replaces)

**Auto-pop-on-done pattern to preserve exactly** (lines 49-57):
```dart
void _maybeAutoPopWhenDone(TimerPhase phase) {
  if (phase != TimerPhase.done || _leftScreen) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _leaveOnce();
  });
}
```

**Single-pop guard pattern to preserve exactly** (lines 30-38):
```dart
bool _leftScreen = false;

void _leaveOnce() {
  if (_leftScreen) return;
  _leftScreen = true;
  Navigator.of(context).pop();
}
```
`RunningScreen` keeps this navigation/lifecycle shell verbatim and swaps only the body: instead of the inline `Transform.scale` accent circle (lines 70-82), it hosts `sceneFor(theme)` from `scene_registry.dart`. The back-button `IconButton` (lines 83-96) stays here, in the composition root — not pushed down into any scene, preserving SCENE-05's "nothing tappable" contract at the scene level.

---

## Shared Patterns

### `withValues(alpha:)` for opacity (not deprecated `withOpacity`)
**Source:** `lib/scenes/scene_preview.dart:80,85` — `Colors.white.withValues(alpha: 0.8)`
**Apply to:** All four painters, especially `sunrise_painter.dart`'s star/moon opacity formulas — always `.clamp(0.0, 1.0)` the computed value first (RESEARCH.md Pitfall 3), then pass via `withValues(alpha: ...)`, never `withOpacity`.

### Gradient-via-shader for sky/backgrounds
**Source:** `lib/scenes/scene_preview.dart:64-74` (`SunrisePreviewPainter.paint`) and `:123-132` (`WalkPreviewPainter.paint`)
```dart
final rect = Offset.zero & size;
canvas.drawRect(
  rect,
  Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _skyColors,
      stops: _skyStops,
    ).createShader(rect),
);
```
**Apply to:** `sunrise_painter.dart` (progress-driven sky colors, must reconstruct shader each frame since colors change) and any gradient background in `walk_painter.dart`/`car_painter.dart` (these can stay static per RESEARCH.md Pitfall 5 guidance — cache `Paint` objects that don't depend on `progress`).

### `shouldRepaint` override contract
**Source:** `lib/scenes/scene_preview.dart:44,111,193,282` — every preview painter overrides `shouldRepaint` explicitly (always `false` there, since previews are static).
**Apply to:** All four real painters — must return `true`/`false` based on comparing both `progress` and decorative-loop-phase fields (RESEARCH.md Pitfall 2), never omitted, following the same "always explicit" convention already established.

### Theme-token color/style reuse
**Source:** `lib/theme/app_tokens.dart` (e.g. `AppTokens.bg`, `AppTokens.accent`)
**Apply to:** `running_screen.dart` for the screen `Scaffold`'s `backgroundColor` and the back-button icon color, exactly as `placeholder_running_screen.dart:67,93` already do (`AppTokens.bg`, `AppTokens.ink`). The four scene painters themselves use design-doc-locked literal hex colors (D-01, not `AppTokens`), matching how `scene_preview.dart`'s painters already hardcode their own theme-specific hex literals rather than referencing `AppTokens`.

### Provider read vs. watch discipline
**Source:** `lib/screens/placeholder_running_screen.dart:45,61` — `context.read<TimerController>()` for one-shot actions (`endTimer()`), `context.watch<TimerController>()` for the rebuild-driving value.
**Apply to:** `scene_renderer.dart`'s base `State` — `context.read` inside the `Ticker`'s per-frame callback (avoid subscribing to `notifyListeners()` for per-frame polls), `context.watch` only for the low-frequency `.phase` value in `didChangeDependencies`, per RESEARCH.md Pattern 1.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/support/progress_sweep.dart` | test-utility | batch | No existing shared test-helper file in this codebase (Phase 2's tests, if any, don't have this pattern); RESEARCH.md's own Code Examples section (lines 360-367 of 03-RESEARCH.md) and Pitfall 4 guidance (`tester.pump(fixedDuration)` at checkpoints instead of `pumpAndSettle()`) is the reference to build from directly. |

## Metadata

**Analog search scope:** `lib/scenes/`, `lib/screens/`, `lib/widgets/`, `lib/timer/`, `lib/theme/`
**Files scanned:** `scene_preview.dart`, `scene_theme.dart`, `scene_grid.dart`, `timer_controller.dart`, `timer_phase.dart`, `placeholder_running_screen.dart`, `app_tokens.dart`
**Pattern extraction date:** 2026-07-07
