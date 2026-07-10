---
phase: 05-play-store-readiness
plan: 02
subsystem: testing
tags: [dart-ui, flutter-test, picture-recorder, png-rendering, custom-painter, icon-generation-spike]

# Dependency graph
requires:
  - phase: 03-scenes
    provides: SunrisePainter (pure CustomPainter, no BuildContext dependency) used as the real-world proof subject for this spike
provides:
  - "renderPainterToPng(CustomPainter, Size) -> Future<Uint8List>: reusable headless PNG-export helper for any CustomPainter"
  - "Proof that the programmatic (dart:ui/flutter test) icon-generation path from D-04 actually works against the real SunrisePainter"
affects: ["05-04 (adaptive launcher icon generation)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Headless CustomPainter -> PNG rendering via PictureRecorder/Canvas/Picture.toImage/Image.toByteData, run inside flutter test's Skia binding (TestWidgetsFlutterBinding), with real file I/O escaped via tester.runAsync"

key-files:
  created:
    - test/tool/icon_renderer.dart
    - test/tool/generate_launcher_icon_test.dart
  modified: []

key-decisions:
  - "RESEARCH Assumption A1 CONFIRMED: the flutter-test-based headless render path (Pattern 2) works against the real SunrisePainter -- plan 05-04 can proceed with the fully programmatic icon-generation approach rather than the live-device screenshot fallback."

patterns-established:
  - "renderPainterToPng: painter-agnostic helper (no SunrisePainter import) reusable by plan 05-04 for both icon foreground and background painters"

requirements-completed: [PUBLISH-02]

coverage:
  - id: D1
    description: "Headless CustomPainter -> PNG render helper (renderPainterToPng) proven against the real SunrisePainter, producing a valid, non-empty PNG file"
    requirement: "PUBLISH-02"
    verification:
      - kind: unit
        ref: "test/tool/generate_launcher_icon_test.dart#renderPainterToPng renders SunrisePainter to a valid PNG file headlessly, with no device and no live Ticker"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-07-10
status: complete
---

# Phase 05 Plan 02: Headless CustomPainter-to-PNG Render Spike Summary

**PASSED: `dart:ui` PictureRecorder/Canvas/Picture.toImage rendering of the real SunrisePainter works headlessly inside `flutter test`, producing a valid PNG — plan 05-04 can proceed with the fully programmatic icon-generation approach (RESEARCH Assumption A1 confirmed, no live-device fallback needed).**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-10T05:48:00Z (approx)
- **Completed:** 2026-07-10T06:10:39Z
- **Tasks:** 1 (TDD: RED -> GREEN)
- **Files modified:** 2 created

## Accomplishments
- De-risked the single riskiest unknown in Phase 5 (RESEARCH Assumption A1) BEFORE plan 05-04 commits to generating the full multi-layer adaptive-icon asset set.
- Proved the headless `CustomPainter` -> PNG rendering path works against the real `SunrisePainter` (not a toy painter), with no device, no widget tree, and no live `Ticker`/`TimerController`.
- Produced a reusable, painter-agnostic `renderPainterToPng` helper that plan 05-04 can call directly for both the icon foreground and background painters.
- Full existing test suite (130 tests) stays green — the new files are purely additive test tooling with zero impact on app code.

## Task Commits

Each task was committed atomically following the plan's `tdd="true"` RED/GREEN cycle:

1. **Task 1 RED: add failing test for headless CustomPainter -> PNG render** - `f7470fe` (test)
2. **Task 1 GREEN: implement headless CustomPainter to PNG renderer** - `73e0a19` (feat)

_No REFACTOR commit needed — implementation was already minimal and clean after the GREEN step (one lint fix folded into the GREEN commit before it was made)._

## Files Created/Modified
- `test/tool/icon_renderer.dart` - Exports `renderPainterToPng(CustomPainter painter, Size size) -> Future<Uint8List>`: builds a `ui.PictureRecorder`-backed `Canvas`, calls `painter.paint(canvas, size)` directly, ends recording, converts to an `Image` via `picture.toImage`, and encodes via `image.toByteData(format: ui.ImageByteFormat.png)`. Deliberately has no `SunrisePainter` import, keeping it reusable for any painter.
- `test/tool/generate_launcher_icon_test.dart` - `flutter_test` spike test: inside a `testWidgets` case, uses `tester.runAsync` to render `SunrisePainter(progress: 0.75, twinklePhase: 0)` at `Size(432, 432)`, asserts the returned buffer is a real PNG (length > 1000 bytes, correct 8-byte magic signature), writes it to `build/spike_icon.png`, and re-reads the file to assert the same on-disk.

## Decisions Made
- **RESEARCH Assumption A1 confirmed true.** The `flutter test`-based headless Skia render path (Pattern 2) is not just theoretically documented but empirically proven against the real `SunrisePainter` — `picture.toImage`/`toByteData` did not throw any binding/unsupported-operation error. Plan 05-04 should proceed with the fully programmatic icon-generation approach (D-04) and does NOT need the live-device screenshot fallback.
- Renamed a local test variable from `_pngSignature` to `pngSignature` during the GREEN step to satisfy `flutter_lints`' `no_leading_underscores_for_local_identifiers` rule (leading underscore is reserved for library-private members, not locals) — folded into the GREEN commit rather than a separate fixup, since it was caught by `flutter analyze` before that commit was made.

## Deviations from Plan

None — plan executed exactly as written. The one lint-naming fix (`_pngSignature` -> `pngSignature`) was applied and verified before the GREEN commit landed, so it is not tracked as a separate deviation; it is documented above under Decisions Made for completeness.

## Issues Encountered

None. The spike succeeded on the first real implementation attempt — no binding-not-initialized or unsupported-operation errors were encountered when calling `picture.toImage`/`image.toByteData` inside `tester.runAsync`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05-04 (adaptive launcher icon generation) is unblocked and can proceed with the **fully programmatic** icon pipeline: reuse/adapt `SunrisePainter`-derived foreground/background painters, call `renderPainterToPng` (this plan's helper) to export both `assets/icon/icon_foreground.png` and `assets/icon/icon_background.png`, then run `flutter_launcher_icons` per RESEARCH Pattern 4.
- No blockers. `build/spike_icon.png` is a real artifact on disk (gitignored, not committed) confirming the pipeline end-to-end.

---
*Phase: 05-play-store-readiness*
*Completed: 2026-07-10*
