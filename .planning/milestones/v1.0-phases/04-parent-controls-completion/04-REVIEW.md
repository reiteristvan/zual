---
phase: 04-parent-controls-completion
reviewed: 2026-07-09T11:59:32Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - lib/audio/audioplayers_chime_player.dart
  - lib/audio/chime_player.dart
  - lib/audio/chime_synth.dart
  - lib/main.dart
  - lib/scenes/scene_renderer.dart
  - lib/screens/running_screen.dart
  - lib/screens/setup_screen.dart
  - lib/settings/setup_preferences.dart
  - lib/theme/app_tokens.dart
  - pubspec.yaml
  - test/audio/chime_synth_test.dart
  - test/scenes/scene_renderer_test.dart
  - test/screens/running_screen_test.dart
  - test/screens/setup_screen_test.dart
  - test/settings/setup_preferences_test.dart
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-07-09T11:59:32Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the Parent Controls & Completion phase: the chime synth/player pair, the Parent
Controls sheet and completion pill added to `RunningScreen`, the `SceneRenderer` base
class, and `SetupPreferences` persistence, along with their tests. `flutter analyze`
is clean and the test suite exercises the documented contracts (long-press gate, chime
dedup, custom-stepper clamping, persistence round-trips) well.

No crash-class or security-class defects were found. Three real, code-verified defects
were found at Warning tier: (1) one fire-and-forget persistence call is missing the
error handling every sibling call site in this codebase has, (2) the Parent Controls
sheet's Pause/Resume button doesn't account for the timer completing while the sheet is
open, silently no-op'ing, and (3) the sheet's two buttons don't apply the UI-SPEC's
locked pressed-state colors, leaving one design token completely dead in `lib/` despite
this project's CLAUDE.md explicitly treating color/token fidelity as high-priority, not
a starting point. Two lower-impact Info items round out the report.

## Warnings

### WR-01: `persistSoundOn` future is unawaited without error handling, unlike every other fire-and-forget call in this codebase

**File:** `lib/screens/running_screen.dart:263-266`

**Issue:** `_toggleSound()` fires `SetupPreferences.persistSoundOn(...)` without a
`.catchError`:

```dart
void _toggleSound() {
  soundOn.value = !soundOn.value;
  unawaited(SetupPreferences.persistSoundOn(soundOn.value));
}
```

`persistSoundOn` (`lib/settings/setup_preferences.dart:128-131`) has no internal
try/catch either — it awaits `SharedPreferences.getInstance()` and `setBool` directly.
If either throws (platform-channel failure, corrupted plugin state, etc.), this becomes
an unhandled Future rejection surfaced to the Zone's uncaught-error handler.

Every other fire-and-forget persistence/plugin call in this codebase is explicitly
guarded against this:
- `SetupPreferences.persistIfPreset(...).catchError((_) {})` in
  `lib/screens/setup_screen.dart:130-135` (same class, same "fire-and-forget, must not
  crash" contract documented on `persistIfPreset`'s doc comment).
- `WakelockPlus.enable().catchError((_) {})` / `.disable().catchError((_) {})` in
  `lib/timer/wakelock_screen_wake.dart:13,16`.
- `AudioplayersChimePlayer.play` wraps its own plugin call in `.catchError((_) {})`.

`_toggleSound()` is the one call site that doesn't follow this established pattern.

**Fix:**
```dart
void _toggleSound() {
  soundOn.value = !soundOn.value;
  unawaited(SetupPreferences.persistSoundOn(soundOn.value).catchError((_) {}));
}
```

### WR-02: Parent Controls sheet's primary button doesn't account for the timer reaching `TimerPhase.done` while the sheet is open

**File:** `lib/screens/running_screen.dart:270-271`, `lib/screens/running_screen.dart:352-359`

**Issue:** The sheet is opened via long-press whenever `!isDone`
(`lib/screens/running_screen.dart:217-238`), but nothing stops the countdown from
completing *after* the sheet is already open — `TimerController`'s periodic ticker
(`lib/timer/timer_controller.dart:91`) keeps running regardless of the sheet, and
`syncToWallClock()` can flip `phase` to `TimerPhase.done` at any time
(`lib/timer/timer_controller.dart:150-165`).

`_ParentControlsSheet.build` only distinguishes `running` from "not running":

```dart
final isRunning = controller.phase == TimerPhase.running;
```

If `phase` becomes `done` while the sheet is showing, `isRunning` evaluates to `false`
exactly as it would for `paused`, so `_buildPrimaryButton` renders a **"Resume"**
button. Tapping it calls `TimerController.resume()`
(`lib/timer/timer_controller.dart:114-126`), which is a no-op unless
`phase == TimerPhase.paused` — so the tap silently does nothing, with no feedback to the
parent that the timer already finished. (The mute toggle, End timer, and Keep watching
buttons remain correct in this state; only the primary button's label/behavior is
wrong.)

This path is not covered by any test — `running_screen_test.dart`'s Parent Controls
sheet tests only open the sheet against a `running` controller and never let it
transition to `done` while the sheet stays open.

**Fix:** Make the primary button aware of the terminal phase, e.g.:
```dart
Widget _buildPrimaryButton(BuildContext context, TimerPhase phase) {
  final isRunning = phase == TimerPhase.running;
  final isDone = phase == TimerPhase.done;
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isDone
          ? null
          : () {
              final ctrl = context.read<TimerController>();
              isRunning ? ctrl.pause() : ctrl.resume();
            },
      ...
      child: Text(isDone ? 'Done' : (isRunning ? 'Pause' : 'Resume'), ...),
    ),
  );
}
```
(or simply pop the sheet automatically on the transition into `done`.)

### WR-03: Pause/Resume and End timer buttons don't apply the UI-SPEC's locked pressed-state colors

**File:** `lib/screens/running_screen.dart:352-407`, `lib/theme/app_tokens.dart:37,59`

**Issue:** `04-UI-SPEC.md`'s Color table explicitly **locks** the pressed-state fills
for these two buttons: `#6E9A68` for Pause/Resume (`AppTokens.accentPressed`) and
`#D06E4C` for End timer (`AppTokens.destructivePressed`, described in the spec as "the
first genuine destructive-action use of this hex"). Per this project's `CLAUDE.md`,
"colors, radii, timings, and interaction thresholds ... are treated as final, not
starting points."

`_buildPrimaryButton` and `_buildEndTimerButton` both use a plain `ElevatedButton` with
only `backgroundColor`/`foregroundColor` set — no `overlayColor`/pressed-state override:

```dart
style: ElevatedButton.styleFrom(
  backgroundColor: AppTokens.accent,      // or AppTokens.destructive
  foregroundColor: AppTokens.startLabel,
  padding: const EdgeInsets.symmetric(vertical: 18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
),
```

This means pressing either button renders Material's default state-overlay tint, not
the locked hex. `PressableSurface` (`lib/widgets/pressable_surface.dart`) is the widget
this codebase already built specifically to solve this exact "swap fill to
`pressedColor` while held" contract, and it's used for every other button that has a
locked pressed color (Start, preset/Custom cards, scene cards) — it just wasn't reused
here. As a direct, verifiable consequence, `AppTokens.destructivePressed` is defined
but never referenced anywhere in `lib/` (confirmed via project-wide search), and
`AppTokens.accentPressed` is only used by `setup_screen.dart`'s Start button, not by
this sheet's Pause/Resume button despite sharing the same locked color.

**Fix:** Use `PressableSurface` (as `setup_screen.dart` does) instead of `ElevatedButton`
for both buttons:
```dart
Widget _buildPrimaryButton(BuildContext context, bool isRunning) {
  return SizedBox(
    width: double.infinity,
    child: PressableSurface(
      onTap: () {
        final ctrl = context.read<TimerController>();
        isRunning ? ctrl.pause() : ctrl.resume();
      },
      color: AppTokens.accent,
      pressedColor: AppTokens.accentPressed,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(isRunning ? 'Pause' : 'Resume', ...),
    ),
  );
}
```
(same shape for `_buildEndTimerButton` with `AppTokens.destructive`/`destructivePressed`).

## Info

### IN-01: Fallback-value construction duplicated between `MyApp` and `SetupScreen`, with no disposal owner for the fallback `ValueNotifier`

**File:** `lib/main.dart:51-59`, `lib/screens/setup_screen.dart:25-32`

**Issue:** Both constructors independently repeat the same "supply a default if the
caller didn't inject one" logic:
```dart
: chimePlayer = chimePlayer ?? const NoopChimePlayer(),
  soundOn = soundOn ?? ValueNotifier<bool>(true);
```
The `NoopChimePlayer()` default is harmless (const, stateless), but the
`ValueNotifier<bool>(true)` default is a `ChangeNotifier` created inline in a widget's
constructor with no `State` (and thus no `dispose()`) to ever release it. In production
this only happens once (`main()` always injects an explicit `soundOn`), but any caller
that constructs `MyApp`/`SetupScreen` without an explicit `soundOn` (several widget
tests do) leaks one `ValueNotifier` per instance for the life of the test process.

**Fix:** Low priority given the current call sites, but consider centralizing the
default in one place (e.g. a factory/helper), or documenting that callers passing no
`soundOn` are responsible for the widget's full lifetime, to avoid this becoming a real
leak if a future call site constructs these widgets repeatedly (e.g. in a rebuild loop).

### IN-02: Audio/persistence failures are swallowed everywhere with no logging

**File:** `lib/audio/audioplayers_chime_player.dart:26`, `lib/screens/setup_screen.dart:130-135`

**Issue:** Every `.catchError((_) {})` in this phase (chime playback, preference
persistence) discards the error entirely — not even a `debugPrint` in debug builds.
This is consistent with the documented "must never crash" intent, but it also means a
real device issue (e.g. audio focus denied, storage full) leaves zero trace for
debugging a support report.

**Fix:** Consider `debugPrint('chime playback failed: $e')` (or similar) inside the
catch handlers — `avoid_print`-safe and gated out of release builds by Flutter's own
`debugPrint` no-op-in-profile/release behavior, so it costs nothing in production while
restoring debuggability.

---

_Reviewed: 2026-07-09T11:59:32Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
