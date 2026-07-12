---
phase: 02-setup-screen
plan: 03
subsystem: ui
tags: [flutter, dart, gesture, timer, widget-testing]

# Dependency graph
requires:
  - phase: 02-setup-screen (Plan 01)
    provides: AppTokens design tokens, SetupScreen with the duration-preset grid and Start flow
  - phase: 02-setup-screen (Plan 02)
    provides: Scene selection pattern (selection-ring overlay convention) reused for the Custom card
provides:
  - lib/widgets/hold_repeat_button.dart — reusable, leak-safe accelerating hold-repeat button (tap = one step, hold = accelerating repeat)
  - lib/screens/setup_screen.dart extended with a sixth "Custom" grid cell, a stepper row, and a hard-clamped customMin state setter
affects: [02-setup-screen (Plans 04-05)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "HoldRepeatButton tracks held duration as an accumulator of already-elapsed scheduled Timer intervals, not DateTime.now() -- deterministic under both real wall-clock time and flutter_test's fake Timer clock (tester.pump), unlike the research-cited DateTime.now()-based pattern"
    - "Range-owning parent supplies enabled + a clamped onStep to a range-agnostic HoldRepeatButton -- the button itself contains zero 1-120 logic"
    - "Clamp-in-setter (V5): _setCustomMin(v) always assigns v.clamp(1, 120), independent of whichever button the UI currently disables, so a disable-logic bug cannot desync from the true valid range"

key-files:
  created:
    - lib/widgets/hold_repeat_button.dart
    - test/widgets/hold_repeat_button_test.dart
  modified:
    - lib/screens/setup_screen.dart
    - lib/theme/app_tokens.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "Deviated from 02-RESEARCH.md's cited HoldRepeatButton code example: replaced its DateTime.now()-based held-duration tracking with an accumulated-Timer-interval counter, because DateTime.now() does not advance under flutter_test's fake async Timer clock, making the acceleration curve untestable (and, more importantly, non-deterministic in principle even outside tests, since it depends on real wall-clock reads rather than the Timer's own scheduled cadence)."
  - "Added a ValueKey('stepper-value') to the Custom stepper's value Text so tests can assert its content unambiguously -- plain find.text('1') collides with the existing '1 min' preset card, which also renders the string '1'."

patterns-established:
  - "Stepper row rendered as a 7th widget below the fixed 6-cell duration grid (not inside it), so revealing/hiding it never changes the grid's own layout -- satisfies the 'grid does not reflow' contract for future extensions to this screen."

requirements-completed: [SETUP-02]

coverage:
  - id: D1
    description: "Tapping - or + on a HoldRepeatButton fires onStep once; holding accelerates the repeat rate (~500ms -> 350ms -> 150ms -> 60ms cadence)"
    requirement: "SETUP-02"
    verification:
      - kind: unit
        ref: "test/widgets/hold_repeat_button_test.dart#HoldRepeatButton a quick tap fires onStep exactly once, with no repeat"
        status: pass
      - kind: unit
        ref: "test/widgets/hold_repeat_button_test.dart#HoldRepeatButton a long-press held across the acceleration thresholds fires onStep more frequently the longer it is held"
        status: pass
      - kind: unit
        ref: "test/widgets/hold_repeat_button_test.dart#HoldRepeatButton releasing (long-press end) stops further repeat steps"
        status: pass
    human_judgment: false
  - id: D2
    description: "HoldRepeatButton's repeat Timer is cancelled on end/cancel/dispose -- no exception and no ghost onStep calls if the widget is unmounted mid-hold (Pitfalls 1/2), and disabled buttons never fire onStep"
    requirement: "SETUP-02"
    verification:
      - kind: unit
        ref: "test/widgets/hold_repeat_button_test.dart#HoldRepeatButton unmounting the widget mid-hold cancels the repeat Timer cleanly (no exception, no further onStep calls)"
        status: pass
      - kind: unit
        ref: "test/widgets/hold_repeat_button_test.dart#HoldRepeatButton when enabled is false, neither tap nor hold fires onStep"
        status: pass
    human_judgment: false
  - id: D3
    description: "Tapping Custom reveals the stepper row (grid unchanged) and moves the selection ring to the Custom card; selecting a preset while Custom is open hides the row"
    requirement: "SETUP-02"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen custom stepper (SETUP-02, V5) tapping Custom reveals the stepper row and moves the selection ring"
        status: pass
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen custom stepper (SETUP-02, V5) selecting a preset while Custom is open hides the stepper row"
        status: pass
    human_judgment: false
  - id: D4
    description: "customMin can never leave 1..120 for any sequence of steps -- proven via direct onStep invocation that bypasses the disabled-button gesture layer entirely (V5, threat T-02-01)"
    requirement: "SETUP-02"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen custom stepper (SETUP-02, V5) stepping - down to the 1-minute floor disables it, and calling onStep directly still cannot push customMin below 1 (V5, T-02-01)"
        status: pass
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen custom stepper (SETUP-02, V5) stepping + up to the 120-minute ceiling disables it, and calling onStep directly still cannot push customMin above 120 (V5, T-02-01)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Start uses customMin when the Custom row is open (not the stale preset default); customMin persists across closing/reopening the row within the same session"
    requirement: "SETUP-02"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen custom stepper (SETUP-02, V5) tapping + increments customMin; Start launches the timer with the custom value"
        status: pass
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen custom stepper (SETUP-02, V5) customMin is not reset when toggling the Custom row closed and reopened"
        status: pass
    human_judgment: false
  - id: D6
    description: "Visual/pixel fidelity of the Custom card and stepper row to design/README.md (exact 48px circular buttons, 20px internal gaps, ~35% disabled opacity, typography)"
    verification: []
    human_judgment: true
    rationale: "Colors, sizes, and text styles were transcribed directly from 02-UI-SPEC.md and unit-tested for structural/behavioral correctness, but pixel-level visual fidelity (exact disabled-opacity look, shadow rendering, typography kerning) can only be confirmed by a human viewing the rendered screen, consistent with Plans 01-02's same deferred visual sign-off."

# Metrics
duration: 11min
completed: 2026-07-07
status: complete
---

# Phase 2 Plan 3: Custom Duration Stepper Summary

**A reusable, leak-safe `HoldRepeatButton` (tap = one step, hold = accelerating repeat) plus a Custom duration path on the Setup screen: a sixth "Custom" grid cell reveals a stepper covering the full 1-120 minute range, with disabled edges and a range clamp enforced in state, not just visually.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-07T10:23:00Z (approx.)
- **Completed:** 2026-07-07T10:34:18Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- `HoldRepeatButton`: a range-agnostic `StatefulWidget` where a tap fires `onStep` once and a hold past the ~500ms long-press threshold begins an accelerating repeat (350ms -> 150ms -> 60ms as hold duration grows), with the repeat `Timer` cancelled on long-press end, cancel, AND dispose
- `SetupScreen`'s duration grid gained a sixth "Custom" cell ("Custom" / "set your own") that reveals a stepper row (`-`, value block, `+`) below the still-fixed 6-cell grid without reflowing it
- `_setCustomMin` is the sole write path for `customMin`, clamping to `1..120` independent of the stepper buttons' own disable state -- satisfies the V5/T-02-01 threat mitigation, verified by tests that call `onStep` directly while bypassing the disabled gesture layer entirely
- Start and the footer's "· N min" label now use `customMin` when the Custom row is open, otherwise the selected preset; `customMin` persists across closing/reopening the row within a session (only resets on app restart, per D-10 -- out of this plan's scope to persist across restarts)
- New `test/widgets/hold_repeat_button_test.dart` (5 tests) and 6 new tests in `test/screens/setup_screen_test.dart` covering the full Custom-stepper interaction surface, including the two Pitfall 1/2 dispose-mid-hold and V5 direct-state-clamp cases

## Task Commits

Each task was committed atomically as a TDD RED/GREEN pair:

1. **Task 1: HoldRepeatButton (accelerating hold-repeat, leak-safe) + tests (SETUP-02)**
   - `e468de6` (test) — RED: failing test for HoldRepeatButton
   - `e0cd30b` (feat) — GREEN: implemented `hold_repeat_button.dart`
2. **Task 2: Integrate Custom stepper into SetupScreen with clamped setter + disabled edges (SETUP-02, V5)**
   - `7917ef0` (test) — RED: failing tests for Custom stepper integration
   - `76e2fba` (feat) — GREEN: implemented the Custom card, stepper row, and `_setCustomMin` clamp; fixed two test-only issues surfaced while turning the suite green (see Deviations)

_Plan-level TDD gate sequence (test -> feat -> test -> feat) confirmed in git log for both tasks._

## Files Created/Modified
- `lib/widgets/hold_repeat_button.dart` - Accelerating hold-repeat button widget, leak-safe Timer lifecycle
- `test/widgets/hold_repeat_button_test.dart` - 5 tests covering tap-once, hold-accelerate, release-stops, disabled-no-op, dispose-mid-hold
- `lib/screens/setup_screen.dart` - Custom grid cell, `_showCustom`/`_customMin` state, `_setCustomMin` clamp, stepper row, Start/footer wired to `_selectedMinutes`
- `lib/theme/app_tokens.dart` - Added `customLabel`, `customSublabel`, `stepperGlyph`, `stepperValue`, `stepperUnit` text styles
- `test/screens/setup_screen_test.dart` - 6 new tests for the Custom stepper (reveal/select, Start-uses-custom, V5 clamp at both edges, preset-hides-stepper, persistence-across-toggle)

## Decisions Made
- Replaced the `DateTime.now()`-based held-duration tracking from `02-RESEARCH.md`'s cited code example with an accumulator of already-elapsed scheduled `Timer` intervals. `DateTime.now()` does not advance under `flutter_test`'s fake async `Timer` clock (only `Timer` scheduling is faked by `tester.pump(duration)`), which made the acceleration curve silently never trigger in widget tests -- and, more fundamentally, made production behavior depend on real wall-clock reads rather than the `Timer`'s own deterministic cadence. Tracking accumulated interval durations instead is correct and testable in both contexts.
- Added `ValueKey('stepper-value')` to the stepper's value `Text` widget so tests can assert its exact displayed value; a plain `find.text('1')` is ambiguous once the stepper reaches 1, since the existing "1 min" preset card also renders the string "1".
- The V5/T-02-01 clamp is verified by calling `HoldRepeatButton.onStep` directly on the widget instance retrieved via `tester.widget<HoldRepeatButton>(...)`, bypassing the disabled-button gesture layer entirely -- this proves the clamp holds even under the threat model's stated failure mode ("a bug in the disable logic"), not just under normal UI interaction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed HoldRepeatButton's acceleration tracking to not rely on `DateTime.now()`**
- **Found during:** Task 1 (HoldRepeatButton implementation)
- **Issue:** Following `02-RESEARCH.md`'s cited pattern verbatim (tracking `_holdStart` via `DateTime.now()` and computing `held = DateTime.now().difference(_holdStart)`) caused the acceleration test to fail: `flutter_test`'s `tester.pump(duration)` advances a fake `Timer`/microtask clock but does not affect `DateTime.now()`, so `held` never actually grew past a few real-time microseconds during the test, and both the "before 2s" and "after 2s" windows fired at the identical ~350ms initial interval (5 calls in each 1900ms window instead of an accelerating rate).
- **Fix:** Replaced the wall-clock read with a `Duration _heldDuration` accumulator that adds the just-used interval after each tick fires, before scheduling the next one. This is deterministic under both real time (production) and fake time (tests), since it derives held-time purely from the `Timer` schedule itself rather than a second, independently-advancing clock.
- **Files modified:** lib/widgets/hold_repeat_button.dart
- **Verification:** `flutter test test/widgets/hold_repeat_button_test.dart` -- the acceleration test now correctly shows more `onStep` calls in the second 1900ms window (after crossing the 2s mid-acceleration mark) than the first.
- **Committed in:** e0cd30b (Task 1 GREEN commit)

**2. [Rule 1 - Bug] Test-only fixes: scroll the Custom stepper row into view before tapping; disambiguate the "1" text match**
- **Found during:** Task 2 (Custom stepper integration)
- **Issue:** (a) The revealed stepper row sits below the default 800x600 widget-test viewport once the Custom row is open, so `tester.tap()` on `stepper-minus`/`stepper-plus`/preset/`Custom` targets sometimes landed off-screen (hit-test warnings, and in one case a silently-no-op tap that would have made the test pass without actually exercising the toggle behavior it claimed to verify). (b) `find.text('1')` is ambiguous once `customMin` reaches 1, because the existing "1 min" preset card also renders the string "1", causing "Found 2 widgets" failures.
- **Fix:** (a) Added `tester.ensureVisible(...)` + `tester.pumpAndSettle()` before each stepper-row/preset/Custom tap that could fall outside the fold, matching the same pattern Plan 02 used for the scene grid. (b) Added `ValueKey('stepper-value')` to the stepper's value `Text` and switched the ambiguous assertions to read `tester.widget<Text>(...).data` via that key instead of `find.text('1')`.
- **Files modified:** test/screens/setup_screen_test.dart, lib/screens/setup_screen.dart (added the key)
- **Verification:** `flutter test test/screens/setup_screen_test.dart` passes cleanly with zero hit-test warnings and no ambiguous-finder failures.
- **Committed in:** 76e2fba (Task 2 GREEN commit)

---

**Total deviations:** 2 auto-fixed (2 bugs: one production-code correctness fix, one test-only fix)
**Impact on plan:** No scope change. The `DateTime.now()` fix is a genuine improvement over the research-cited example (deterministic scheduling instead of wall-clock reads); the test-visibility/disambiguation fixes were necessary to actually exercise the behaviors the plan's acceptance criteria require, not just to make assertions pass superficially.

## Issues Encountered
None beyond the two deviations documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `lib/widgets/hold_repeat_button.dart` is a fully generic, range-agnostic hold-repeat primitive -- available for reuse by any future stepper-style control without modification.
- `SetupScreen` now exposes the complete SETUP-02 surface (preset OR custom 1-120 duration); Plan 04 (persistence) can read/write `_durationMin`/`_theme` without needing to touch the Custom-stepper code path, since `customMin` is explicitly never persisted (D-10, out of this plan's scope).
- No blockers. `lib/timer/` was not modified in this plan, consistent with the plan's threat model and `02-RESEARCH.md`'s explicit "do not touch `lib/timer/`" guidance.
- Visual fidelity of the stepper row and disabled-opacity look has not been human-verified on a device/emulator -- flagged as D6 above for end-of-phase UAT, consistent with Plans 01-02's same deferred visual sign-off.

---
*Phase: 02-setup-screen*
*Completed: 2026-07-07*

## Self-Check: PASSED

All created/modified files verified present on disk (lib/widgets/hold_repeat_button.dart,
test/widgets/hold_repeat_button_test.dart, lib/screens/setup_screen.dart,
lib/theme/app_tokens.dart, test/screens/setup_screen_test.dart); all four task
commit hashes (e468de6, e0cd30b, 7917ef0, 76e2fba) verified present in git log.
