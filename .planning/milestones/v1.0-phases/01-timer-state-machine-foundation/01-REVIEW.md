---
phase: 01-timer-state-machine-foundation
reviewed: 2026-07-07T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/timer/timer_phase.dart
  - lib/timer/timer_controller.dart
  - lib/timer/screen_wake.dart
  - lib/timer/timer_lifecycle_binder.dart
  - lib/timer/wakelock_screen_wake.dart
  - lib/main.dart
  - test/timer/timer_controller_test.dart
  - test/widget_test.dart
  - pubspec.yaml
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-07-07T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the timer state-machine foundation: `TimerController` (wall-clock-driven phase engine), the `ScreenWake` abstraction and its `wakelock_plus` adapter, the `TimerLifecycleBinder` app-lifecycle glue, and the `main.dart`/test wiring. `flutter analyze` is clean and the full test suite (17 tests) passes.

The core wall-clock model (deriving `progress`/`phase` from real timestamps rather than tick counts, with a monotonic high-water-mark and negative-elapsed flooring) is sound and I could not break it with backward-clock or pause/resume interleavings — I wrote and ran throwaway verification tests for a suspected "negative paused-total from a backward clock jump during pause" bug and confirmed the subtraction telescopes correctly (no bug there; the paused-interval clock reading cancels out algebraically).

However, I found two confirmed runtime defects (verified with scratch tests, not just static reading) around resource lifecycle: `pause()` never cancels the periodic ticker (it keeps firing and calling `notifyListeners()` indefinitely while paused), and `dispose()` never releases an active screen-wake lock if the controller is torn down while running. Both are real, reproducible bugs in the lifecycle contract of this class, not style nits. I've also flagged unhandled fire-and-forget async calls into the screen-wake plugin, and a duplicated progress-fraction formula that risks drifting out of sync.

## Warnings

### WR-01: `pause()` does not cancel the periodic ticker — timer keeps running while "paused"

**File:** `lib/timer/timer_controller.dart:94-100`

**Issue:** `pause()` freezes `_elapsed` computation (by recording `_pausedAt`) but never cancels `_ticker`. The `Timer.periodic` started in `start()`/`resume()` keeps firing at `_tickInterval` (default 200ms) indefinitely while the controller sits in `TimerPhase.paused`, repeatedly invoking `syncToWallClock()` → `notifyListeners()`. I verified this empirically: with a 10ms tick interval, pausing and waiting 120ms still produced 12 listener notifications.

Every other phase transition (`start`, `resume`, `endTimer`) explicitly manages `_ticker` (cancel-then-create or cancel-and-null); `pause()` is the only one that doesn't, which is inconsistent with the class's own contract and with the doc comment "Freezes the countdown" (which implies computation should stop, not just its externally-visible result). Because `_phase == TimerPhase.paused` guards the done-transition inside `syncToWallClock()`, this does not cause an incorrect phase transition — but it does mean a paused, never-resumed timer keeps waking the event loop, calling `notifyListeners()`, and rebuilding any listening UI forever, until `resume()`, `start()`, `endTimer()`, or `dispose()` is called.

**Fix:**
```dart
void pause() {
  if (_phase != TimerPhase.running) return;
  _pausedAt = _clock();
  _phase = TimerPhase.paused;
  _ticker?.cancel();
  _ticker = null;
  _screenWake.disable();
  notifyListeners();
}
```
(`resume()` already does `_ticker?.cancel()` before creating a fresh one, so this is safe to pair with the existing `resume()` implementation unchanged.)

### WR-02: `dispose()` does not release the screen-wake lock if disposed while running

**File:** `lib/timer/timer_controller.dart:162-166`

**Issue:** `dispose()` only cancels `_ticker`; it never calls `_screenWake.disable()`. If the controller is disposed while `_phase == TimerPhase.running` (screen-wake currently enabled), the wakelock is never released — verified with a scratch test: `start()` then `dispose()` leaves the fake screen-wake's `disableCalls` at `0`. Since `wakelock_plus` operates at the OS/plugin level (not scoped to the `TimerController` instance), this means the device screen can be left permanently prevented from sleeping until the app process itself is killed. `main.dart` currently never disposes its single app-lifetime controller so this is dormant today, but it is a real gap in the class's resource-cleanup contract for any future caller (e.g. a per-screen controller, or tests that construct/dispose multiple controllers).

**Fix:**
```dart
@override
void dispose() {
  _ticker?.cancel();
  if (_phase == TimerPhase.running) {
    _screenWake.disable();
  }
  super.dispose();
}
```

### WR-03: Fire-and-forget async screen-wake calls have no error handling

**File:** `lib/timer/timer_controller.dart:86, 98, 116, 132, 156`

**Issue:** `_screenWake.enable()`/`_screenWake.disable()` return `Future<void>` (see `lib/timer/screen_wake.dart:11,14`) but every call site in `TimerController` (`start`, `pause`, `resume`, `endTimer`, `syncToWallClock`) calls them without `await`, without storing the returned future, and without a `.catchError`/`try-catch`. If the underlying `WakelockPlus` plugin call throws (unsupported platform, missing platform registration, permission issue), the rejection becomes an unhandled Future error with no place to observe or log it, surfacing as an unhandled-exception zone error at runtime.

**Fix:** Either await-and-swallow at the call sites, or (preferably, so `TimerController` stays synchronous) make the adapter defensive:
```dart
// wakelock_screen_wake.dart
@override
Future<void> enable() => WakelockPlus.enable().catchError((_) {});
@override
Future<void> disable() => WakelockPlus.disable().catchError((_) {});
```

### WR-04: Duplicated raw-fraction/clamp formula between `progress` and `syncToWallClock()`

**File:** `lib/timer/timer_controller.dart:50-55` and `lib/timer/timer_controller.dart:142-149`

**Issue:** Both the `progress` getter and `syncToWallClock()` independently compute `_elapsed.inMilliseconds / _total.inMilliseconds` and clamp it to `0.0..1.0`. They currently agree, but because the same formula is written out twice (once as a pure read, once as the mutation that feeds `_progressHighWaterMark`), a future change to the formula (e.g. an easing curve, a different rounding/guard rule) is likely to be applied to only one call site, silently desynchronizing displayed progress from the high-water-mark logic that drives completion.

**Fix:**
```dart
double get _rawFraction {
  if (_total.inMilliseconds == 0) return 0.0;
  return (_elapsed.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
}
```
and use `_rawFraction` in both `progress` and `syncToWallClock()`.

## Info

### IN-01: `start()` leaves a stale `_pausedAt` when restarting from a paused state

**File:** `lib/timer/timer_controller.dart:77-88`

**Issue:** `start()` resets `_total`, `_startTime`, `_pausedTotal`, and `_progressHighWaterMark`, but not `_pausedAt`. If `start()` is called while the controller is currently `TimerPhase.paused` (a "restart" without an intervening `endTimer()`), `_pausedAt` retains its old value. This is currently harmless because `_elapsed` only reads `_pausedAt` when `_phase == TimerPhase.paused`, and `start()` unconditionally sets `_phase = TimerPhase.running` — but it's fragile state that silently outlives the transition it belonged to.

**Fix:** Add `_pausedAt = null;` alongside the other resets in `start()`.

### IN-02: `TimerController` is wired into the widget tree but never consumed

**File:** `lib/main.dart:11-34`

**Issue:** `main()` constructs a `TimerController`, wires a `TimerLifecycleBinder`, and provides it via `ChangeNotifierProvider`, but `MyHomePage` still renders the unrelated stock "Hello, World!" scaffold and never reads the provided controller. Expected for a state-machine-foundation phase with no UI phase yet, but flagging so it isn't mistaken for finished integration.

### IN-03: `TimerLifecycleBinder` instance in `main()` is unretained — `detach()` can never be called

**File:** `lib/main.dart:12`

**Issue:** `TimerLifecycleBinder(timerController).attach();` discards the binder reference immediately. Since this is a single app-lifetime instance that's expected to live as long as the process, never calling `detach()` is not currently harmful — but the class's own doc comment states `detach()` "must be called when the binder is no longer needed to avoid leaking the observer registration," and there is no way to honor that contract from this call site. Worth reconsidering if `TimerLifecycleBinder`/`TimerController` are ever created per-screen rather than as app-lifetime singletons.

---

_Reviewed: 2026-07-07T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
