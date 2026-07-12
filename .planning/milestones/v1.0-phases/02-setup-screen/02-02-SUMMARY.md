---
phase: 02-setup-screen
plan: 02
subsystem: ui
tags: [flutter, dart, custompainter, widget-testing]

# Dependency graph
requires:
  - phase: 02-setup-screen (Plan 01)
    provides: AppTokens design tokens, SetupScreen with the reserved "Pick a scene" slot, existing selection-ring pattern
provides:
  - lib/scenes/scene_theme.dart — SceneTheme enum (disc, sunrise, walk, car), shared identity for Setup/persistence/Phase 3
  - lib/scenes/scene_preview.dart — ScenePreviewPainter abstraction + four concrete static painters
  - lib/widgets/scene_grid.dart — SceneCard + SceneGrid (2x2 selectable scene-card grid)
  - lib/screens/setup_screen.dart extended with scene-selection state and the SceneGrid wired into the UI
affects: [02-setup-screen (Plans 03-05), 03-scene-themes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ScenePreviewPainter abstract base extends CustomPainter, mirroring ScreenWake's interface-then-adapter shape (D-06) — SceneCard depends only on the abstraction, never a concrete painter type by name"
    - "SceneGrid is the single composition root allowed to reference concrete painter types (theme -> painter/label maps); everything downstream of it stays abstraction-only"
    - "Selection ring pattern from Plan 01 reused verbatim for scene cards: Positioned.fill + IgnorePointer overlay, keyed ValueKey('scene-ring-$labelLowercase') for test discoverability"

key-files:
  created:
    - lib/scenes/scene_theme.dart
    - lib/scenes/scene_preview.dart
    - lib/widgets/scene_grid.dart
    - test/scenes/scene_preview_test.dart
  modified:
    - lib/screens/setup_screen.dart
    - lib/theme/app_tokens.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "SceneGrid owns the SceneTheme -> label / SceneTheme -> painter maps (the one place concrete painter types are named); SceneCard itself only ever receives a ScenePreviewPainter, preserving the D-06 abstraction boundary at the card level, not just the theme level."
  - "Test-only fix: widget tests must call tester.ensureVisible() before tapping 'Walking home' — the Setup screen's scrollable body places the scene grid below the default 800x600 test-surface fold, and WidgetTester.tap() does not auto-scroll."

patterns-established:
  - "Scene mini-preview geometry (star positions, sun glow radius, house/character/car proportions) implemented as literal pixel offsets within the 74px-tall preview box, per 02-UI-SPEC.md's Scene Mini-Preview table — not scaled by card width, since the spec defines fixed-size elements anchored to corners/center within a fixed-height box."

requirements-completed: [SETUP-03]

coverage:
  - id: D1
    description: "SceneTheme enum (disc, sunrise, walk, car) and ScenePreviewPainter abstraction with four concrete static painters (Disc, Sunrise, Walk, Car), each with shouldRepaint == false"
    requirement: "SETUP-03"
    verification:
      - kind: unit
        ref: "test/scenes/scene_preview_test.dart#SceneTheme values are disc, sunrise, walk, car in that order"
        status: pass
      - kind: unit
        ref: "test/scenes/scene_preview_test.dart#ScenePreviewPainter every concrete painter reports shouldRepaint == false (static previews)"
        status: pass
      - kind: unit
        ref: "test/scenes/scene_preview_test.dart#ScenePreviewPainter every concrete painter extends the shared abstraction"
        status: pass
    human_judgment: false
  - id: D2
    description: "Setup screen shows a 2x2 grid of four scene cards with exact labels (Shrinking disc, Night to sunrise, Walking home, Car on a road); Shrinking disc selected by default"
    requirement: "SETUP-03"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen scene selection (SETUP-03) shows all four scene cards with exact labels; Shrinking disc selected by default"
        status: pass
    human_judgment: false
  - id: D3
    description: "Tapping a scene card single-selects it (previous selection ring cleared) and draws the 3px accent ring"
    requirement: "SETUP-03"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen scene selection (SETUP-03) tapping a scene card single-selects it, clearing the previous selection"
        status: pass
    human_judgment: false
  - id: D4
    description: "Visual/pixel fidelity of the four scene mini-previews to design/README.md and 02-UI-SPEC.md's exact gradient stops, shadow/glow values, and shape geometry"
    verification: []
    human_judgment: true
    rationale: "Colors and geometry were transcribed from the spec table and unit-tested for structural properties (shouldRepaint, type), but pixel-level visual fidelity of gradients/shadows/glows can only be confirmed by a human looking at the rendered cards on a device or emulator."

# Metrics
duration: 20min
completed: 2026-07-07
status: complete
---

# Phase 2 Plan 2: Scene Selection Summary

**2x2 scene-card grid (Shrinking disc, Night to sunrise, Walking home, Car on a road) on the Setup screen, each card rendering a static mini-preview through a shared `ScenePreviewPainter` abstraction, with single-select behavior and disc pre-selected by default.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-07T09:10:00Z (approx.)
- **Completed:** 2026-07-07T09:30:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- `SceneTheme` enum (`disc | sunrise | walk | car`) — the shared theme identity for Setup selection, future persistence (Plan 04), and Phase 3's real scene renderers
- `ScenePreviewPainter` abstract base + four concrete static painters (`DiscPreviewPainter`, `SunrisePreviewPainter`, `WalkPreviewPainter`, `CarPreviewPainter`), each transcribing exact colors/geometry from `02-UI-SPEC.md`'s Scene Mini-Preview table, each `shouldRepaint == false`
- `SceneGrid`/`SceneCard`: a 2x2 grid of selectable scene cards, each showing its preview via `CustomPaint(painter: preview)` and the shared 3px `#7FA87A` selection ring; `SceneCard` depends only on the `ScenePreviewPainter` abstraction, never a concrete painter type
- `SetupScreen` now holds `_theme` state (default `SceneTheme.disc` per D-09) and renders the real scene grid in the slot Plan 01 reserved for it
- New unit-test coverage (`test/scenes/scene_preview_test.dart`) pinning the enum order and the static-painter contract, plus new widget-test coverage in `test/screens/setup_screen_test.dart` for the four labels, default selection, and single-select behavior

## Task Commits

Each task was committed atomically as a TDD RED/GREEN pair:

1. **Task 1: SceneTheme enum + ScenePreviewPainter abstraction + 4 concrete painters (D-05/D-06)**
   - `ceee716` (test) — RED: failing test for scene theme + preview painters
   - `67d29ae` (feat) — GREEN: implemented `scene_theme.dart` + `scene_preview.dart`
2. **Task 2: SceneGrid + integrate scene selection into SetupScreen (SETUP-03)**
   - `f53e0d7` (test) — RED: failing test for scene selection UI
   - `d45f091` (feat) — GREEN: implemented `scene_grid.dart`, integrated into `setup_screen.dart`, added `AppTokens.sceneCardLabel`

_Plan-level TDD gate sequence (test -> feat -> test -> feat) confirmed in git log for both tasks._

## Files Created/Modified
- `lib/scenes/scene_theme.dart` - `SceneTheme` enum (disc, sunrise, walk, car)
- `lib/scenes/scene_preview.dart` - `ScenePreviewPainter` abstraction + four concrete static painters
- `lib/widgets/scene_grid.dart` - `SceneCard` + `SceneGrid` (2x2 selectable card grid)
- `lib/screens/setup_screen.dart` - Added `_theme` state and wired `SceneGrid` into the "Pick a scene" section
- `lib/theme/app_tokens.dart` - Added `sceneCardLabel` text style (13/700, ink)
- `test/scenes/scene_preview_test.dart` - New unit tests for `SceneTheme` order and painter static-ness/abstraction
- `test/screens/setup_screen_test.dart` - New scene-selection test group (SETUP-03)

## Decisions Made
- `SceneGrid` (not `SceneCard`) owns the `SceneTheme -> label` and `SceneTheme -> painter` maps, so the single place concrete painter types are referenced by name is the composition root, keeping `SceneCard` itself abstraction-only per D-06.
- Scene mini-preview shapes (stars, sun, house, character, car) are positioned using literal pixel offsets relative to the 74px-tall preview box rather than scaled to card width, matching the design spec's fixed-size, corner/center-anchored geometry.
- No `initialTheme` constructor parameter was added to `SetupScreen` this plan — the default lives as a plain field initializer (`SceneTheme _theme = SceneTheme.disc`), since persistence-driven initial values are explicitly Plan 04's scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test-only fix: scroll the scene grid into view before tapping in the single-select widget test**
- **Found during:** Task 2 (SceneGrid + SetupScreen integration)
- **Issue:** The Setup screen's scrollable body places the "Pick a scene" grid below the default 800x600 widget-test surface fold. `WidgetTester.tap()` does not auto-scroll, so tapping "Walking home" directly threw a hit-test warning ("offset outside root render view") and the selection never occurred, making the test flap between a hit-test warning and a failed key assertion.
- **Fix:** Added `await tester.ensureVisible(find.text('Walking home')); await tester.pumpAndSettle();` before the tap, matching the standard Flutter widget-test idiom for scrollable content.
- **Files modified:** test/screens/setup_screen_test.dart
- **Verification:** `flutter test test/screens/setup_screen_test.dart` passes cleanly (no hit-test warnings) after the fix.
- **Committed in:** d45f091 (Task 2 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 bug, test-only)
**Impact on plan:** No production-code impact; purely a widget-test scrolling fix required to actually exercise the tap interaction the plan specified.

## Issues Encountered
None beyond the test-scrolling deviation above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `lib/scenes/` and `lib/widgets/` are established; Plan 03 (custom stepper) and Plan 04 (persistence) can extend `SetupScreen` further without restructuring.
- `ScenePreviewPainter` is ready for Phase 3 to extend with the real scene-at-progress-0 renderer, per D-06's stated goal — no Setup-screen/SceneGrid/SceneCard code should need to change when that swap happens.
- Visual fidelity of the four mini-previews (gradients, shadows, glow) has not been human-verified on a device/emulator — flagged as D4 above for end-of-phase UAT.
- No blockers. `lib/timer/` was not modified in this plan, consistent with the plan's threat model (T-02-03P, T-02-04P: both accepted, no untrusted input or per-frame repaint cost introduced).

---
*Phase: 02-setup-screen*
*Completed: 2026-07-07*

## Self-Check: PASSED

All created/modified files verified present on disk (lib/scenes/scene_theme.dart,
lib/scenes/scene_preview.dart, lib/widgets/scene_grid.dart,
test/scenes/scene_preview_test.dart, lib/screens/setup_screen.dart,
lib/theme/app_tokens.dart, test/screens/setup_screen_test.dart); all four task
commit hashes (ceee716, 67d29ae, f53e0d7, d45f091) verified present in git log.
