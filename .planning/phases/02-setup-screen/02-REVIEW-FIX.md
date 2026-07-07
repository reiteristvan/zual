---
phase: 02-setup-screen
fixed_at: 2026-07-07T12:15:00Z
review_path: .planning/phases/02-setup-screen/02-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-07-07T12:15:00Z
**Source review:** .planning/phases/02-setup-screen/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (fix_scope: critical_warning — 1 critical, 3 warnings; the 2 Info findings were out of scope)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Type-mismatched persisted value crashes app launch, defeating the documented tampering defense

**Files modified:** `lib/settings/setup_preferences.dart`, `lib/main.dart`
**Commit:** `df13187`
**Applied fix:** Wrapped `prefs.getInt(_durationMinKey)` and `prefs.getString(_themeKey)` in `SetupPreferences.load()` in individual `try`/`catch` blocks so a wrong-typed stored value (an unchecked cast `TypeError` inside `shared_preferences`) falls back to the D-09 defaults (`durationMin: 5`, `theme: SceneTheme.disc`) instead of throwing. Added a matching defense-in-depth `try`/`catch` around `SetupPreferences.load()` in `main()`, falling back to `const SetupPreferences(durationMin: 5, theme: SceneTheme.disc)` on any unexpected failure, so launch can never crash on a corrupted/tampered prefs store. Matches the review's suggested fix essentially verbatim.

### WR-01: Fire-and-forget persistence isn't actually guarded to "fail silently" as documented

**Files modified:** `lib/screens/setup_screen.dart`
**Commit:** `69f9ed2`
**Applied fix:** Appended `.catchError((_) {})` to the `SetupPreferences.persistIfPreset(...)` future inside the existing `unawaited(...)` call in `_handleStart`, so a persistence failure (disk full, plugin channel failure, etc.) is truly swallowed rather than surfacing as an unhandled Future error, matching the doc comment's "must fail silently" contract.

### WR-02: Manual back tap can race the auto-pop-on-done callback, risking a double `Navigator.pop()`

**Files modified:** `lib/screens/placeholder_running_screen.dart`
**Commit:** `6014ae5`
**Applied fix:** Replaced the one-way `_popped` guard (which only protected the auto-pop path) with a shared `_leftScreen` guard and a single `_leaveOnce()` helper that both `_handleBack` (manual back tap) and the auto-pop-on-done post-frame callback now call, so at most one of the two exit paths ever invokes `Navigator.of(context).pop()`, closing the race window described in the finding. Matches the review's suggested fix.

**Note:** This fix addresses a timing/race condition between two asynchronous exit paths. `flutter analyze` and the existing `setup_screen_test.dart` suite (including the two `PlaceholderRunningScreen` navigation tests) pass, but the exact race (manual back tapped while an auto-pop post-frame callback is already scheduled) is not itself exercised by an automated test. **Status: fixed: requires human verification** of the race-condition behavior specifically (e.g. rapid-tap manual QA on a real/emulated device, or a dedicated timing test).

### WR-03: Pressed-state tracking logic duplicated between `_PressableSurfaceState` and `_SceneCardState`

**Files modified:** `lib/widgets/pressable_surface.dart` (new), `lib/screens/setup_screen.dart`, `lib/widgets/scene_grid.dart`
**Commit:** `8f86c8c`
**Applied fix:** Extracted the private `_PressableSurface`/`_PressableSurfaceState` pair (previously defined at the bottom of `setup_screen.dart`) into a new public, shared widget `PressableSurface` in `lib/widgets/pressable_surface.dart`. `setup_screen.dart`'s preset/Custom/Start surfaces now import and use this shared widget instead of a private duplicate. `scene_grid.dart`'s `SceneCard` was converted from a `StatefulWidget` (with its own duplicated `_pressed`/`_setPressed` tracking) to a `StatelessWidget` that delegates pressed-state tracking to the same shared `PressableSurface`, wrapping only its thumbnail+label content; the selection ring remains a sibling `Positioned.fill` in the outer `Stack` so it is unaffected by the press-fill swap, matching the original layout exactly. Added an optional `alignment` parameter (defaulting to `Alignment.center`, matching the three existing Setup screen call sites unchanged) so `SceneCard` can pass `alignment: null` and preserve its original full-width, top-aligned content layout.

Verified via `flutter analyze` (clean, 0 issues) and the full `flutter test` suite (all tests pass, no behavioral regressions) after this refactor.

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-07-07T12:15:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
