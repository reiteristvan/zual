---
phase: 04-parent-controls-completion
fixed_at: 2026-07-09T12:08:12Z
review_path: .planning/phases/04-parent-controls-completion/04-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 04: Code Review Fix Report

**Fixed at:** 2026-07-09T12:08:12Z
**Source review:** .planning/phases/04-parent-controls-completion/04-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (Warning tier; `fix_scope: critical_warning` — the review's two
  Info findings, IN-01 and IN-02, were out of scope and left untouched)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: `persistSoundOn` future is unawaited without error handling, unlike every other fire-and-forget call in this codebase

**Files modified:** `lib/screens/running_screen.dart`
**Commit:** 8aca6c1
**Applied fix:** Added `.catchError((_) {})` to the `unawaited(SetupPreferences.persistSoundOn(...))` call in `_ParentControlsSheet._toggleSound()`, matching the established fire-and-forget pattern used by `SetupPreferences.persistIfPreset(...)` and `WakelockPlus.enable()/.disable()` elsewhere in this codebase.

### WR-02: Parent Controls sheet's primary button doesn't account for the timer reaching `TimerPhase.done` while the sheet is open

**Files modified:** `lib/screens/running_screen.dart`
**Commit:** 00ad19f
**Applied fix:** `_ParentControlsSheet.build` now passes the full `TimerPhase` (not just a `running` boolean) to `_buildPrimaryButton`, which computes `isDone` alongside `isRunning`. When `isDone`, the button's action becomes a no-op and its label reads "Done" instead of falling through to an incorrectly-labeled, silently-no-op "Resume". Verified against the existing `running_screen_test.dart` suite (13/13 passing), including the CTRL-02 primary-button label test.

### WR-03: Pause/Resume and End timer buttons don't apply the UI-SPEC's locked pressed-state colors

**Files modified:** `lib/screens/running_screen.dart`
**Commit:** 83a2877
**Applied fix:** Replaced `ElevatedButton` with `PressableSurface` (the widget this codebase already uses for every other locked-pressed-color button: Start, preset/Custom cards, scene cards) in both `_buildPrimaryButton` and `_buildEndTimerButton`. `_buildPrimaryButton` now uses `AppTokens.accent` / `AppTokens.accentPressed`; `_buildEndTimerButton` now uses `AppTokens.destructive` / `AppTokens.destructivePressed`, putting the previously-dead `destructivePressed` token into use. Added the `PressableSurface` import. Since `PressableSurface.onTap` is non-nullable (unlike `ElevatedButton.onPressed`), the done-state no-op from WR-02 is preserved as a no-op closure rather than `null`; the button still shows the "Done" label and takes no action, but does not render a Material-style disabled/greyed treatment. Verified with `flutter analyze` (no issues) and the full `flutter test` suite (129/129 passing).

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-07-09T12:08:12Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
