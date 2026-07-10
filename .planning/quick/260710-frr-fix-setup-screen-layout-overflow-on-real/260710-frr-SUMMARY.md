---
phase: quick
plan: 260710-frr
subsystem: ui
tags: [flutter, layoutbuilder, textpainter, responsive-layout, widget-test]

requires: []
provides:
  - Responsive Setup screen sizing that fits the Samsung A25 viewport (~393x851 dp) without clipping or requiring scroll
  - Content-aware (TextPainter-measured, DefaultTextStyle-merged) aspect-ratio safety clamps for the duration grid and scene grid
  - A25-size widget-test regression coverage for the Setup screen
affects: [setup-screen, scene-grid]

tech-stack:
  added: []
  patterns:
    - "Measure real rendered text height via TextPainter merged onto DefaultTextStyle.of(context).style before using it to size a GridView's childAspectRatio — Text() merges unset TextStyle fields (e.g. height) from the ambient DefaultTextStyle, so measuring the bare AppTokens style alone silently under-counts line height on Material 3 (non-1.0 height multiplier) and mispredicts text wrapping."
    - "Joint header/scroll-region layout solve: compute a baseline header height from the design formula, compute the scroll region's true required content height at the content-safety-capped aspect ratios, and only shrink the header further (down to a hard floor) if a shortfall remains — avoids leaning on the SingleChildScrollView safety net for an avoidable gap."

key-files:
  created: []
  modified:
    - lib/screens/setup_screen.dart
    - lib/widgets/scene_grid.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "SceneGrid's childAspectRatio is now an optional constructor parameter (default 1.35, unchanged for every other caller) rather than a hardcoded literal in its GridView.count."
  - "Duration-grid and scene-grid aspect ratios are computed as min(design-preferred ratio, content-safe ratio) — the content-safe ratio is derived from real TextPainter measurement (with maxWidth applied) of the actual worst-case label text, not an assumed constant, so it self-adjusts to whatever font metrics are actually rendering (custom bundled fonts on-device, fallback fonts in tests)."
  - "Header top padding uses the plan's original MediaQuery-height formula (0.055 multiplier, clamp 24-52) as a baseline, but shrinks further (floor 16) when the scroll region's true required height still exceeds what the baseline leaves available — necessary because Material 3's inherited text height multiplier (~1.4x) and the tagline's line-wrap at narrow header widths made the original formula's estimate insufficient on the A25."

requirements-completed: [QUICK-FRR-SETUP-OVERFLOW]

coverage:
  - id: D1
    description: "Setup screen content (wordmark, presets, scene picker) fits a Samsung A25-sized viewport (~393x851 dp) with the Start footer visible and zero scroll extent required"
    requirement: "QUICK-FRR-SETUP-OVERFLOW"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen responsive layout fits the A25 viewport (~393x851 dp) without overflow or scrolling"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sizing is responsive (LayoutBuilder/MediaQuery-driven), not a single magic number tuned to one device; SingleChildScrollView remains as a safety net for extreme screens"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart (full suite, 16 tests, includes non-A25 800x600 default-surface tests that still exercise the SingleChildScrollView's scroll/ensureVisible path)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Zero changes to interaction logic, state, persistence, the 850ms long-press threshold, colors/radii/fonts, or any widget-test keys; all pre-existing tests pass unchanged"
    verification:
      - kind: unit
        ref: "flutter test (full suite) — 132 tests passed"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-07-10
status: complete
---

# Quick Task 260710-frr: Fix Setup screen layout overflow on real device Summary

**Made the Setup screen's duration grid, scene grid, and header shrink using real TextPainter-measured content heights (not assumed constants), closing an ~1cm overflow on the Samsung A25 without touching fonts, colors, or interaction logic.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Setup screen's "How long?" duration grid, "Pick a scene" picker, and header now size themselves from a `LayoutBuilder` + `MediaQuery`-driven computation instead of one fixed device tweak, and correctly fit the Samsung A25's ~393x851 dp viewport with zero required scroll extent
- `SceneGrid` gained an optional `childAspectRatio` parameter (default 1.35, no behavior change for other callers) as a sizing hook for the Setup screen's fit-to-space calculation
- Added a widget-test regression at A25-like dimensions asserting no overflow exception and `maxScrollExtent <= 0.5` on the outer scroll view, plus visibility of both section labels and all four scene cards
- Discovered and fixed the actual root cause of the reported overflow: scene-card labels and the "Custom"/"set your own" pair wrap to two lines on narrow cells, and Material 3's inherited `DefaultTextStyle` height multiplier (~1.4x, since these labels don't set an explicit `height`) makes every line taller than a naive text-height guess — the fix measures real wrapped-text height via `TextPainter` merged onto the ambient `DefaultTextStyle`, exactly mirroring what `Text()` renders

## Task Commits

1. **Task 1: Make the Setup screen content fit responsively** - `a95f594` (fix)
2. **Task 2: Add A25-size regression test and prove existing tests still pass** - `888796a` (fix) — this commit also carries the Rule 1 bug fixes discovered while making the new test actually pass (see Deviations below)

## Files Created/Modified

- `lib/screens/setup_screen.dart` - Header/scroll-region layout now solved jointly via an outer `LayoutBuilder`: adaptive inter-section gap, adaptive duration-grid aspect ratio, fit-to-space scene-grid aspect ratio (all capped by real content-height measurement so no card ever overflows its cell), and a header top padding that shrinks further when the scroll region is still short on space
- `lib/widgets/scene_grid.dart` - `SceneGrid` accepts an optional `childAspectRatio` (default 1.35); no other behavior changed
- `test/screens/setup_screen_test.dart` - New `SetupScreen responsive layout` test group covering the A25 viewport; fixed a test bug (multiple `Scrollable` matches — the two inner `GridView`s are also `Scrollable`s despite `NeverScrollableScrollPhysics`) by selecting `.first`

## Decisions Made

- Kept `SceneGrid`'s theme→label/theme→painter maps, selection-ring keys, and every color/radius/font untouched — every change is spacing/sizing/measurement logic only, per the plan's constraint.
- Chose to measure real font metrics via `TextPainter` (merged onto `DefaultTextStyle.of(context).style`, with `maxWidth` applied where wrapping is possible) rather than hardcode new tuned constants, so the fix is not "a single magic number tuned to one device" (matches the plan's own stated truth) and self-corrects if fonts, text scale, or label copy ever change.
- Where the design's preferred aspect-ratio range (`[1.35, 2.4]` for scene cards, `1.1`/`1.2` for duration cards) would cause real measured content to overflow its cell, the implementation takes `min(designRatio, contentSafeRatio)` — this can push the scene-card ratio below the design's nominal 1.35 floor on very tight viewports, trading a small amount of design-fidelity margin for the actual "no clipping" requirement, which is the higher-priority truth in the plan's frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Duration-grid and scene-grid aspect ratios could still overflow their cells on narrow viewports**
- **Found during:** Task 2, while making the new A25-size regression test pass
- **Issue:** The plan's task 1 formulas (`childAspectRatio: constraints.maxHeight >= 640 ? 1.1 : 1.2` for duration; `[1.35, 2.4]`-clamped fit-to-space ratio for scene) assumed the design's existing aspect ratios always leave enough cell height for their text content. At the A25's narrower cell widths, the "Custom"/"set your own" pair and all four scene-card labels ("Shrinking disc", "Night to sunrise", "Walking home", "Car on a road") wrap to two lines, and — because none of these `TextStyle`s set an explicit `height` — `Text()` inherits Material 3's `DefaultTextStyle` height multiplier (~1.4x), making every rendered line taller than a naive single-line assumption. Both grids threw `RenderFlex overflowed` (clipping the affected cards, exactly the symptom this quick task set out to fix).
- **Fix:** Added `_computeDurationAspectRatio` and hardened `_computeSceneAspectRatio`/`_maxSafeSceneAspectRatio` to measure the actual worst-case cell content (preset vs. Custom card text; all four scene labels) via `TextPainter`, with the style merged onto `DefaultTextStyle.of(context).style` and `maxWidth` set to the cell's real interior width so wrapping is correctly predicted. Each ratio is then `min(designRatio, contentSafeRatio)`.
- **Files modified:** `lib/screens/setup_screen.dart`
- **Verification:** `test/screens/setup_screen_test.dart` A25-size test passes with `tester.takeException()` returning `null` (no overflow); full suite (132 tests) passes.
- **Committed in:** `888796a`

**2. [Rule 1 - Bug] Header shrink formula alone did not free enough height to avoid residual scroll on the A25**
- **Found during:** Task 2, same verification pass
- **Issue:** Even after fix #1 eliminated the overflow exceptions, the outer scroll view still had ~12px of residual `maxScrollExtent` on the A25 — the plan's header-shrink formula (`(MediaQuery.height * 0.055).clamp(24, 52)`) and the tagline's own content-height estimate didn't account for the tagline text ("a gentle timer for little ones") wrapping to two lines at the header's real available width (its natural unconstrained width exceeds the header's content width on a 393dp-wide screen), nor did the original per-`LayoutBuilder` structure let the header react to the scroll region's true space requirement.
- **Fix:** Restructured `build()` around a single outer `LayoutBuilder` (wrapping header + scroll region + footer together) so the header's top padding can be computed jointly with the scroll region's true required height: compute a baseline header height from the design formula, compute the scroll region's actual required height at the content-safe ratios, and shrink the header further (down to a 16dp floor, below the plan's original 24dp floor) only if a shortfall remains. Also fixed `_headerContentHeight` to measure the tagline with its real available width instead of unconstrained.
- **Files modified:** `lib/screens/setup_screen.dart`
- **Verification:** A25-size test's `maxScrollExtent` assertion (`lessThanOrEqualTo(0.5)`) passes exactly; full suite (132 tests) passes.
- **Committed in:** `888796a`

**3. [Rule 1 - Bug] Test used `find.byType(Scrollable)` without narrowing to the outer scroll view**
- **Found during:** Task 2, initial test run
- **Issue:** `find.descendant(of: find.byKey('setup-scroll'), matching: find.byType(Scrollable))` matched three `Scrollable`s (the outer `SingleChildScrollView` plus the two inner `GridView.count`s, which are still `Scrollable`s despite `shrinkWrap: true` + `NeverScrollableScrollPhysics`), causing `tester.state<ScrollableState>(...)` to throw "Too many elements".
- **Fix:** Added `.first` to select the outer (shallowest) `Scrollable`, which is the `setup-scroll`-keyed `SingleChildScrollView`'s own `Scrollable`.
- **Files modified:** `test/screens/setup_screen_test.dart`
- **Verification:** Test locates exactly one `ScrollableState` and reads its `position.maxScrollExtent`.
- **Committed in:** `888796a`

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs found while verifying the plan's own written formulas against real font metrics and real widget-tree structure)
**Impact on plan:** All three fixes were necessary to satisfy the plan's own stated success criteria (no clipping, zero required scroll on the A25, all pre-existing tests passing unchanged). No scope creep — every change remains spacing/sizing/measurement logic; no colors, radii, fonts, interaction logic, or widget-test keys were touched.

## Issues Encountered

- Diagnosing the residual overflow required directly comparing `TextPainter`-based measurement against the real rendered `RenderBox` sizes (via `tester.renderObject`) for several labels, which revealed that `Text()`'s merge with `DefaultTextStyle.of(context).style` inherits a Material 3 `height` multiplier for any `TextStyle` field left unset — a non-obvious source of a ~1.4x line-height inflation that a bare `TextPainter(text: TextSpan(style: theStyleAlone))` measurement does not reproduce. All temporary debug-print statements and a scratch debug test file used during this investigation were removed before the final commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Setup screen now genuinely responsive across device sizes (LayoutBuilder + MediaQuery + real content measurement), not tuned to one device; ready for further real-device verification as part of the broader Play Store readiness milestone.
- No blockers.

---
*Phase: quick*
*Completed: 2026-07-10*

## Self-Check: PASSED

- FOUND: lib/screens/setup_screen.dart
- FOUND: lib/widgets/scene_grid.dart
- FOUND: test/screens/setup_screen_test.dart
- FOUND: commit a95f594
- FOUND: commit 888796a
