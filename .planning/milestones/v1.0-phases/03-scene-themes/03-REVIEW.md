---
phase: 03-scene-themes
reviewed: 2026-07-08T00:00:00Z
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
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 03: Code Review Report (re-review after gap-closure 03-04)

**Reviewed:** 2026-07-08T00:00:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

This is a re-review of Phase 3 (scene themes) after gap-closure plan 03-04, which was
scoped to fix the prior review's CR-01 finding: `CarPainter._paintWheel` rotated two
rotationally-symmetric concentric circles, making the wheel-spin animation a visual
no-op. I traced the fix end-to-end and confirm **CR-01 is resolved**.
`CarPainter._paintWheel` (`lib/scenes/car/car_painter.dart:248-265`) now draws a
`canvas.drawLine` spoke marking from the wheel center to its rim after
`canvas.rotate(spinAngle)`, which is asymmetric under rotation and therefore makes
the 0.7s spin loop visually observable on screen. The accompanying regression test
(`test/scenes/car/car_painter_test.dart:49-80`) renders the painter to raw RGBA bytes
at `spinAngle=0.0` and `spinAngle=pi/2` and asserts the buffers differ — exactly the
assertion that fails against the old symmetric-circle implementation, so this specific
regression is now guarded against reintroduction. Save/restore balance, radius reuse,
and paint-color reuse in the fix are correct; no new defect was introduced by the fix
itself. `git log` confirms the gap-closure commits (`2e370ee`, `6fc7463`) touched only
`car_painter.dart` and its test, so nothing else in the phase changed as part of this
fix.

Doing a full fresh pass (not limited to the CR-01 diff) across all four scene
painters, the shared `SceneRenderer`/`SceneRendererState` ticker contract,
`scene_registry.dart`, `RunningScreen`, `SetupScreen`, and their test suites turned up
no new Critical/blocker issues, but two Warning-level findings from the prior review
(`WR-01`/`WR-02` below) were **not** addressed by this gap-closure pass — they were
outside 03-04's stated scope (only CR-01), but they remain live defects in files that
are in scope for this review and are carried forward here. I also found one new
test-reliability Warning and several Info-level quality items (an orphaned dead-code
file, duplicated geometry logic, a CWD-fragile test assertion, and minor style
nits).

## Warnings

### WR-01: Decorative loop phase resets to 0 instead of continuing when the per-scene `Ticker` is stopped and restarted (carried over, unaddressed)

**File:** `lib/scenes/scene_renderer.dart:33-45, 52-60, 65-74`
**Issue:** `loopPhase()` derives twinkle/bob/spin phase from `_elapsedSinceStart`, which is
set directly from the `elapsed` argument `Ticker` passes to `_onTick`:
```dart
void _onTick(Duration elapsed) {
  _elapsedSinceStart = elapsed;
  ...
}
```
Flutter's `Ticker.stop()` clears its internal start timestamp, so the next
`Ticker.start()` restarts `elapsed` from `Duration.zero` rather than resuming from
where it left off. `didChangeDependencies` (lines 65-74) stops the ticker whenever
`TimerController.phase` leaves `running` and restarts it when phase re-enters
`running` — this is exactly the pattern that will run once `TimerController.pause()`/
`resume()` (already implemented in `lib/timer/timer_controller.dart`) are wired to a
visible parent control in a later phase, while `RunningScreen`/the scene widget stay
mounted across the pause.

When that happens, resuming will make `loopPhase()` jump back to `0` for every
decorative loop — a spinning car wheel will visibly snap back to angle 0, a mid-bob
walking character will snap to its resting position, a mid-twinkle star will snap to
its dimmest phase — rather than continuing smoothly from the frozen frame. This
contradicts the "freezes in place" intent this same file's own doc comment describes
("freezing the last-rendered frame in place rather than resetting it").

This is not reachable through any UI in this phase (no pause control exists yet), so
it remains a latent, non-currently-visible defect, but `SceneRendererState` is
explicitly written to already support the `paused` phase transition, so this is a
correctness gap in code that is live and in scope today, not speculative future work.
**Fix:** Track elapsed time independent of the `Ticker`'s own internal start/stop
cycle, e.g. accumulate elapsed time across stop/start boundaries so `loopPhase()`
continues from where it froze:
```dart
Duration _accumulatedElapsed = Duration.zero;

void _onTick(Duration elapsed) {
  _elapsedSinceStart = _accumulatedElapsed + elapsed;
  ...
}

// When stopping the ticker in didChangeDependencies:
_accumulatedElapsed = _elapsedSinceStart;
_ticker.stop();
```

### WR-02: `SunrisePainter` field doc claims all pure formulas re-clamp `progress`, but `sunTopFraction` and `hillColor` do not (carried over, unaddressed)

**File:** `lib/scenes/sunrise/sunrise_painter.dart:10-18, 34-36`
**Issue:** The `progress` field doc states:
```dart
/// 0..1, already clamped upstream by [TimerController] but re-clamped
/// defensively inside each pure formula (threat register T-03-03).
final double progress;
```
but only `starOpacity` and `moonOpacity` actually clamp:
```dart
double starOpacity(double progress) => (1 - progress * 2.3).clamp(0.0, 1.0);
double moonOpacity(double progress) => (1 - progress * 1.7).clamp(0.0, 1.0);

double sunTopFraction(double progress) => (86 - progress * 64) / 100;          // no clamp

Color hillColor(double progress) =>
    Color.lerp(const Color(0xFF26314F), const Color(0xFF6E9060), progress)!;   // no clamp
```
This is inconsistent with the codebase's own established convention elsewhere in this
phase — `arrivalLeftFraction` in `walk_painter.dart:14-15` explicitly re-clamps
"since this pure function may gain other call sites (e.g. a scene preview) in the
future," which is exactly the defense-in-depth the `SunrisePainter` field doc claims
to provide but doesn't deliver for these two functions. Today this has no observable
effect because the only call site passes `TimerController.progress`, which the
controller itself already clamps to 0..1. But if `sunTopFraction`/`hillColor` ever
gain a second call site with unclamped input (mirroring how `arrivalLeftFraction` is
already reused by both `WalkPainter` and `CarPainter`), `sunTopFraction` would place
the sun outside the intended geometry range and `Color.lerp` would extrapolate past
the two locked colors (`Color.lerp` does not clamp `t` internally).
**Fix:** Either clamp `progress` in both formulas, consistent with the doc's claim and
the `arrivalLeftFraction` precedent:
```dart
double sunTopFraction(double progress) =>
    (86 - progress.clamp(0.0, 1.0) * 64) / 100;

Color hillColor(double progress) => Color.lerp(
      const Color(0xFF26314F),
      const Color(0xFF6E9060),
      progress.clamp(0.0, 1.0),
    )!;
```
or narrow the field doc comment so it doesn't overstate the guarantee.

### WR-03: `pumpProgressSweep` does not guard `controller.dispose()` with try/finally

**File:** `test/support/progress_sweep.dart:26-52`
**Issue:** The helper creates a `TimerController` (which starts an internal
`Timer.periodic` reconcile ticker via `controller.start(totalMinutes)`) and disposes
it only at the very end of the function, after the `pumpWidget` call and the entire
checkpoint loop:
```dart
final controller = TimerController(clock: () => now);
controller.start(totalMinutes);
await tester.pumpWidget(...);
for (final checkpoint in checkpoints) {
  ...
  await tester.pump(const Duration(milliseconds: 16));
}
controller.dispose();
```
If any `tester.pump()` call or assertion inside a calling test throws before execution
reaches the final `dispose()` (e.g. a widget exception surfaced via `pump()`, or a
future checkpoint assertion a caller adds inline), `controller.dispose()` never runs
and the periodic ticker leaks. This helper is shared by `car_scene_test.dart`,
`sunrise_scene_test.dart`, and `walk_scene_test.dart`; a leaked timer from one failing
test can trip `flutter_test`'s pending-timer invariant check and surface as a
confusing, unrelated failure in a later test in the same run, obscuring the actual
root cause.
**Fix:** Wrap the body in `try { ... } finally { controller.dispose(); }` — this
achieves the same "definitely runs" guarantee the existing comment already argues for
without the `addTearDown` timing conflict it describes:
```dart
final controller = TimerController(clock: () => now);
try {
  controller.start(totalMinutes);
  await tester.pumpWidget(...);
  for (final checkpoint in checkpoints) {
    now = startTime.add(Duration(milliseconds: (totalMs * checkpoint).round()));
    controller.syncToWallClock();
    await tester.pump(const Duration(milliseconds: 16));
  }
} finally {
  controller.dispose();
}
```

## Info

### IN-01: Orphaned `PlaceholderRunningScreen` left in the tree after `RunningScreen` replaced it

**File:** `lib/screens/placeholder_running_screen.dart` (whole file); referenced (as history) from `lib/screens/running_screen.dart:10-22`
**Issue:** `RunningScreen`'s own doc comment states it "replaces `PlaceholderRunningScreen` as
Start's navigation destination," and `SetupScreen` was updated in this phase to push
`RunningScreen` instead of the placeholder (`lib/screens/setup_screen.dart:124`). A
repo-wide search confirms no production code or test still imports
`placeholder_running_screen.dart` — it is now ~100 lines of fully unreachable code,
including its own independent copy of the `_leftScreen` double-pop guard,
`_handleBack`, and `_maybeAutoPopWhenDone` logic that is verbatim-identical to
`RunningScreen`'s. Leaving two divergent copies of the same exit-guard logic around
is a maintenance hazard: a future fix to the pop-guard in `RunningScreen` has no
reason to also touch the dead file, so the two copies can silently drift, and it adds
a false candidate for anyone searching the codebase for "the running screen."
**Fix:** Delete `lib/screens/placeholder_running_screen.dart` now that Plan 03-03 has
fully replaced it, per `running_screen.dart`'s own doc comment.

### IN-02: `_bottomY` geometry helper duplicated verbatim between `CarPainter` and `WalkPainter` (carried over, unaddressed)

**File:** `lib/scenes/car/car_painter.dart:149-153`, `lib/scenes/walk/walk_painter.dart:148-151`
**Issue:** Both painters independently define the identical private method:
```dart
double _bottomY(Size size, double bottomFraction, double extraPx) =>
    size.height - (size.height * bottomFraction + extraPx);
```
This is the same class of "one pure formula, never redefined" concern the codebase
explicitly solved for `arrivalLeftFraction` (shared via `import '../walk/walk_painter.dart'
show arrivalLeftFraction;` in `car_painter.dart:3`), but this second CSS-`bottom`-
conversion helper was independently duplicated instead of shared the same way.
**Fix:** Extract `_bottomY` into a shared location (e.g. alongside `arrivalLeftFraction`
in `walk_painter.dart`, or a small `lib/scenes/scene_geometry.dart` utility) and have
both painters import it, consistent with the project's own precedent for this exact
class of helper.

### IN-03: `scene_registry_test.dart` reads source via a CWD-relative path

**File:** `test/scenes/scene_registry_test.dart:50`
**Issue:** `File('lib/scenes/scene_registry.dart').readAsStringSync()` resolves relative
to the process's current working directory rather than the test file's own location.
This works under the conventional `flutter test` invocation from the repo root, but
throws a `FileSystemException` (not a clean assertion failure) if the suite is ever
run from a different working directory.
**Fix:** Document the CWD assumption inline, or make the check more robust (e.g.
resolve relative to `Platform.script`).

### IN-04: Unused intermediate `Rect` in `CarPainter._paintDashedLine`

**File:** `lib/scenes/car/car_painter.dart:134-147`
**Issue:** `final rect = Rect.fromLTWH(0, bottomY - _dashHeight, size.width, _dashHeight);`
constructs a full-width `Rect` purely to read `rect.top` inside the loop below — the
`Rect` itself is never drawn (each dash draws its own narrower `Rect.fromLTWH`). Minor
readability nit: the name `rect` implies something drawn, when it only carries one
scalar.
**Fix:**
```dart
final dashTop = bottomY - _dashHeight;
...
canvas.drawRect(Rect.fromLTWH(x, dashTop, dashWidth, _dashHeight), _dashPaint);
```

### IN-05: Sun glow color uses an inline RGB literal instead of a named constant

**File:** `lib/scenes/sunrise/sunrise_painter.dart:157`
**Issue:** `Paint()..color = Color.fromRGBO(247, 193, 91, glowAlpha)` is the only color
in this painter expressed as a raw `Color.fromRGBO(...)` literal inline at the call
site, rather than as a documented `static const Color` field the way every other
color in this file (`_skyTopStart`, `_moonColor`, `_sunGradientStart`, etc.) is
declared. Minor inconsistency in an otherwise carefully-documented file.
**Fix:** Hoist to `static const Color _sunGlowColor = Color(0xFFF7C15B);` alongside
the file's other color constants, and reference it at the call site.

---

_Reviewed: 2026-07-08T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
