---
phase: 03-scene-themes
reviewed: 2026-07-07T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - lib/scenes/car/car_painter.dart
  - lib/scenes/car/car_scene.dart
  - lib/scenes/disc/disc_painter.dart
  - lib/scenes/disc/disc_scene.dart
  - lib/scenes/scene_registry.dart
  - lib/scenes/scene_renderer.dart
  - lib/scenes/sunrise/sunrise_painter.dart
  - lib/scenes/sunrise/sunrise_scene.dart
  - lib/scenes/walk/walk_painter.dart
  - lib/scenes/walk/walk_scene.dart
  - lib/screens/running_screen.dart
  - lib/screens/setup_screen.dart
  - test/scenes/car/car_painter_test.dart
  - test/scenes/car/car_scene_test.dart
  - test/scenes/scene_registry_test.dart
  - test/scenes/sunrise/sunrise_painter_test.dart
  - test/scenes/sunrise/sunrise_scene_test.dart
  - test/scenes/walk/walk_painter_test.dart
  - test/scenes/walk/walk_scene_test.dart
  - test/screens/setup_screen_test.dart
  - test/support/progress_sweep.dart
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-07-07T00:00:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the four scene painters/scenes (Disc, Sunrise, Walk, Car), the shared `SceneRenderer`/
`SceneRendererState` ticker contract, `scene_registry.dart`, `RunningScreen`, `SetupScreen`, and
their test suites. `flutter test` passes for the full set (79/79). Overall the code faithfully
implements the documented "progress in, pixels out" contract, defensive clamping is applied in
most of the pure geometry formulas, and paint objects are cached correctly per the codebase's own
"Pitfall 5" convention.

However, one concrete functional bug was found in `CarPainter`: the wheel "spin" animation the
UI-SPEC and this phase's own `done` criterion explicitly require ("arriving at time-up with
spinning wheels") is not actually visible on screen, because the rotated geometry is two
concentric circles with no asymmetric marking — `canvas.rotate` on a rotationally symmetric shape
produces an identical raster every frame. No existing test catches this because the test suite
only checks that `shouldRepaint` differs when `spinAngle` differs, never that the rendered pixels
differ.

Two further issues were found: a latent loop-phase reset when the shared per-scene `Ticker` is
stopped and restarted (relevant once pause/resume is wired to a visible control in a later phase,
which the scene-renderer contract already anticipates), and an inconsistency between the
`SunrisePainter` field doc's claim that "every pure formula" re-clamps `progress` defensively and
the actual code, where two of the four formulas do not.

## Critical Issues

### CR-01: Car wheel "spin" animation is invisible — `canvas.rotate` has no visible effect on a rotationally symmetric shape

**File:** `lib/scenes/car/car_painter.dart:242-249`
**Issue:**
```dart
void _paintWheel(Canvas canvas, Offset center) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(spinAngle);
  canvas.drawCircle(Offset.zero, _wheelDiameter / 2 - 3, _wheelRimPaint);
  canvas.drawCircle(Offset.zero, _wheelDiameter / 2 - 3, _wheelTirePaint);
  canvas.restore();
}
```
Both `drawCircle` calls draw a full, unmarked circle (a filled rim disc plus a concentric stroked
ring — no spoke, valve mark, dash, or any other asymmetric feature). A circle is rotationally
symmetric about its own center, so rotating the canvas by `spinAngle` before drawing it produces
byte-for-byte the same raster at every angle. The `spinAngle` field, the `2 * pi *
loopPhase(const Duration(milliseconds: 700))` computation in `car_scene.dart:27`, and the
`canvas.rotate(spinAngle)` call are all live code that executes every frame but has **zero**
observable effect.

This directly contradicts:
- `03-UI-SPEC.md`'s Decorative Loop Contract: `spin` — "Car on a Road, both wheels ... Continuous
  rotation, 0°→360°".
- `03-03-PLAN.md`'s `done` criterion: "Selecting Car on a Road shows a car driving ... arriving at
  time-up with spinning wheels".
- The class doc comment on `CarPainter` itself: "whose wheels spin continuously per `spinAngle`".

No test in `test/scenes/car/car_painter_test.dart` or `car_scene_test.dart` would catch this —
they only assert `shouldRepaint` toggles when `spinAngle` changes, never that the painted pixels
actually differ, so the suite is green despite the feature not working.

**Fix:** Add an asymmetric marking to the wheel so the rotation is visible, e.g. a small spoke/
valve-stem mark drawn after the rotation:
```dart
void _paintWheel(Canvas canvas, Offset center) {
  final radius = _wheelDiameter / 2 - 3;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(spinAngle);
  canvas.drawCircle(Offset.zero, radius, _wheelRimPaint);
  canvas.drawCircle(Offset.zero, radius, _wheelTirePaint);
  // Valve-stem mark so the rotation is actually visible.
  canvas.drawLine(Offset.zero, Offset(0, -radius), _wheelSpokePaint);
  canvas.restore();
}
```
(Add a corresponding `_wheelSpokePaint` field and any UI-SPEC-approved color for it — this is a
visual-design decision as well as a code fix, so confirm the mark's appearance against
`03-UI-SPEC.md`/design before shipping.)

## Warnings

### WR-01: Decorative loop phase resets to 0 instead of continuing when the per-scene `Ticker` is stopped and restarted

**File:** `lib/scenes/scene_renderer.dart:33-45, 56-60, 66-74`
**Issue:** `loopPhase()` derives twinkle/bob/spin phase from `_elapsedSinceStart`, which is the
`elapsed` argument `Ticker` passes to `_onTick`. Flutter's `Ticker.stop()` clears its internal
start timestamp, so the next `Ticker.start()` restarts `elapsed` from `Duration.zero` rather than
resuming from where it left off. `didChangeDependencies` (lines 66-74) stops the ticker whenever
`TimerController.phase` leaves `running` and restarts it when phase re-enters `running` — this is
exactly the pattern that will run when `TimerController.pause()`/`resume()` (already implemented
in `lib/timer/timer_controller.dart`) are wired to a visible parent control in a later phase, while
`RunningScreen`/the scene widget stay mounted across the pause.

When that happens, resuming will make `loopPhase()` jump back to `0` for every decorative loop —
e.g. a spinning wheel will visibly snap back to angle 0, a mid-bob character will snap to its
resting position, a mid-twinkle star will snap to its dimmest phase — rather than continuing
smoothly from the frozen frame. This contradicts the "freezes in place rather than snapping to a
rest position" intent documented in `03-UI-SPEC.md`'s Decorative Loop Contract, which is currently
only half-implemented (freeze-on-stop works; continue-on-resume does not).

This is not reachable through any UI in this phase (no pause control exists yet), so it is not
currently a visible defect, but the `SceneRendererState` contract is explicitly written to already
support the `paused` phase, so this gap should be fixed here rather than rediscovered when the
Parent Controls pause button lands.

**Fix:** Track a persistent "phase origin" offset independent of the `Ticker`'s own start/stop
cycle, e.g. accumulate elapsed time across stop/start boundaries:
```dart
Duration _accumulatedElapsed = Duration.zero;
Duration _tickerStartedAt = Duration.zero;

void _onTick(Duration elapsed) {
  _elapsedSinceStart = _accumulatedElapsed + (elapsed - _tickerStartedAt);
  ...
}

// In didChangeDependencies, when stopping:
_accumulatedElapsed = _elapsedSinceStart;
_ticker.stop();
// When starting again, record the ticker's next `elapsed` baseline on first tick,
// or simplify by tracking wall-clock time directly instead of Ticker-relative elapsed.
```

### WR-02: `SunrisePainter` field doc claims all pure formulas re-clamp `progress`, but `sunTopFraction` and `hillColor` do not

**File:** `lib/scenes/sunrise/sunrise_painter.dart:10-18, 34-36`
**Issue:** The `progress` field doc states:
```dart
/// 0..1, already clamped upstream by [TimerController] but re-clamped
/// defensively inside each pure formula (threat register T-03-03).
final double progress;
```
but only `starOpacity` and `moonOpacity` (lines 10-11) actually clamp their input/output. The
other two pure formulas that take `progress` do not clamp:
```dart
double sunTopFraction(double progress) => (86 - progress * 64) / 100;
Color hillColor(double progress) =>
    Color.lerp(const Color(0xFF26314F), const Color(0xFF6E9060), progress)!;
```
This is inconsistent with the codebase's own established convention elsewhere in this same phase
— `arrivalLeftFraction` in `walk_painter.dart:14-15` explicitly re-clamps "since this pure
function may gain other call sites (e.g. a scene preview) in the future," which is exactly the
kind of defense-in-depth the `SunrisePainter` doc comment claims to provide but doesn't for these
two functions. Today this has no observable effect because the only call site passes
`TimerController.progress`, which is always 0..1, but if `sunTopFraction`/`hillColor` ever gain a
second call site (e.g. a scene preview thumbnail, mirroring how `arrivalLeftFraction` is reused by
both `WalkPainter` and `CarPainter`) with unclamped input, `sunTopFraction` would place the sun off
the visible geometry range and `Color.lerp` would extrapolate outside the two locked colors.

**Fix:** Either clamp `progress` in both formulas for consistency with the doc's claim and the
`arrivalLeftFraction` precedent:
```dart
double sunTopFraction(double progress) =>
    (86 - progress.clamp(0.0, 1.0) * 64) / 100;

Color hillColor(double progress) => Color.lerp(
      const Color(0xFF26314F),
      const Color(0xFF6E9060),
      progress.clamp(0.0, 1.0),
    )!;
```
or narrow the field doc comment to state precisely which formulas clamp and why (matching what
`starOpacity`/`moonOpacity`'s own doc already explains) so the comment doesn't overstate the
guarantee.

## Info

### IN-01: `_bottomY` helper duplicated verbatim between `CarPainter` and `WalkPainter`

**File:** `lib/scenes/car/car_painter.dart:146-147`, `lib/scenes/walk/walk_painter.dart:150-151`
**Issue:** Both painters define an identical private helper:
```dart
double _bottomY(Size size, double bottomFraction, double extraPx) =>
    size.height - (size.height * bottomFraction + extraPx);
```
This is the same kind of "one pure formula, never redefined" concern the codebase explicitly
solved for `arrivalLeftFraction` (shared via `import '../walk/walk_painter.dart' show
arrivalLeftFraction;` in `car_painter.dart:3`), but this second CSS-`bottom`-conversion helper was
independently duplicated instead of being shared the same way.

**Fix:** Extract `_bottomY` into a shared location (e.g. alongside `arrivalLeftFraction` in
`walk_painter.dart`, or a small `lib/scenes/scene_geometry.dart` utility) and have both painters
import it, consistent with the project's own established pattern for this exact class of helper.

---

_Reviewed: 2026-07-07T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
