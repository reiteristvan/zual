---
phase: 02-setup-screen
plan: 05
subsystem: ui
tags: [flutter, dart, fonts, design-fidelity, widget-testing]

# Dependency graph
requires:
  - phase: 02-setup-screen (Plan 01)
    provides: AppTokens design tokens, SetupScreen/PlaceholderRunningScreen structure
  - phase: 02-setup-screen (Plan 02)
    provides: SceneCard/SceneGrid (converted this plan to add pressed-state tracking)
  - phase: 02-setup-screen (Plan 03)
    provides: Custom stepper row (whose widget-tests needed re-scrolling after the header grew taller)
  - phase: 02-setup-screen (Plan 04)
    provides: persistence-on-Start flow (unchanged, re-verified green)
provides:
  - assets/fonts/ — Baloo 2 Bold + Quicksand 400/500/600/700 static .ttf instances, bundled offline
  - AppTokens text styles carrying real fontFamily values (Baloo 2 wordmark, Quicksand everything else)
  - Setup screen header centered per Layout A, at the exact 52/24/8 padding
  - Shared `_PressableSurface` widget: pressed-state fill (#FFF7E9 cards, #6E9A68 Start) replacing default Material ripple
  - SceneCard converted to StatefulWidget for independent pressed-state tracking (same public API)
affects: [03-scene-themes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fonttools varLib.instancer used offline to extract static named-weight instances (Bold, Regular, Medium, SemiBold) from upstream google/fonts variable fonts, verified via OS/2.usWeightClass + head.macStyle bold bit before bundling — avoids shipping a variable font or a mislabeled weight"
    - "_PressableSurface: a single private StatefulWidget shared by preset/Custom cards and the Start button, tracking pressed state via onTapDown/onTapUp/onTapCancel and swapping fill color — used instead of ElevatedButton's default ripple so the pressed color matches the UI-SPEC's exact hex value"

key-files:
  created:
    - assets/fonts/Baloo2-Bold.ttf
    - assets/fonts/Quicksand-Regular.ttf
    - assets/fonts/Quicksand-Medium.ttf
    - assets/fonts/Quicksand-SemiBold.ttf
    - assets/fonts/Quicksand-Bold.ttf
  modified:
    - pubspec.yaml
    - lib/theme/app_tokens.dart
    - lib/screens/setup_screen.dart
    - lib/widgets/scene_grid.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "Sourced font files from the upstream google/fonts GitHub repo (the canonical origin fonts.google.com itself serves) rather than fonts.googleapis.com's CSS API, since the API only returns browser-optimized woff2; extracted static instances from the variable fonts with fonttools varLib.instancer using each font's own named fvar instance (Bold=700 for Baloo 2; Regular/Medium/SemiBold/Bold=400/500/600/700 for Quicksand) rather than guessing static-file URLs."
  - "Header padding applied literally as 52/24/8 per 02-UI-SPEC.md/design/README.md, on top of the existing SafeArea wrapper — matches the design's explicit numeric contract; SafeArea is kept for real-device notch/status-bar safety rather than removed to avoid double-counting the inset."
  - "Scene card corner radius kept at 26px (AppTokens.cardRadius), not changed to the raw Zual.dc.html prototype's 22px — per this plan's own read_first note, design/README.md's Design Tokens table (\"cards 26px\") is the cited radii authority, and 02-UI-SPEC.md's must_haves explicitly lock in 26px for cards; the html's 22px on scene-card buttons is treated as reusing the button radius rather than a stated intent to diverge from README's cards token."
  - "Pressed-state tracking implemented as a single shared _PressableSurface widget (setup_screen.dart) rather than duplicating GestureDetector+setState boilerplate at each of the 7 call sites (5 presets, Custom, Start) — keeps the pressed/normal color swap logic in exactly one place."

patterns-established:
  - "Any future tappable surface needing the UI-SPEC's pressed-state contract should reuse or extend _PressableSurface rather than re-implementing onTapDown/onTapUp/onTapCancel tracking."

requirements-completed: [SETUP-05]

coverage:
  - id: D1
    description: "Baloo 2 (700) and Quicksand (400/500/600/700) are bundled as local .ttf assets and applied via AppTokens text styles — no runtime font fetch"
    requirement: "SETUP-05"
    verification:
      - kind: unit
        ref: "flutter analyze lib/theme/app_tokens.dart (clean) + flutter test test/screens/ test/widgets/ test/settings/ (all pass, confirming AppTokens renders with the new fontFamily values without breaking existing assertions)"
        status: pass
      - kind: other
        ref: "fonttools inspection: Baloo2-Bold.ttf OS/2.usWeightClass=700, head.macStyle bold bit set, name-table subfamily 'Bold' (Pitfall 5 — confirmed genuinely Bold-instanced, not a mislabeled Regular)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Setup screen matches Layout A: exact colors, radii, shadows, spacing, typography, and copy strings from 02-UI-SPEC.md, including pressed states (#FFF7E9 cards / #6E9A68 Start) and the 3px selection ring; #E0805F appears nowhere"
    requirement: "SETUP-05"
    verification:
      - kind: unit
        ref: "flutter test (full suite, 47 tests) — pass; flutter analyze — clean"
        status: pass
    human_judgment: true
    rationale: "Pixel-level visual fidelity (exact color rendering, font weight appearance, pressed-state feel, shadow rendering) can only be confirmed by a human viewing the rendered screen on an Android emulator/device — no automated pixel-diff tooling exists in this project, and human_verify_mode is configured as end-of-phase (config.json), consistent with Plans 01-04's same deferred visual sign-off pattern."

# Metrics
duration: 15min
completed: 2026-07-07
status: complete
---

# Phase 2 Plan 5: Design Fidelity Polish Summary

**Bundled offline Baloo 2 (700) + Quicksand (400/500/600/700) fonts extracted from the upstream variable fonts via fonttools, wired into every AppTokens text style, and applied the exact centered 52/24/8 header spacing plus a shared pressed-state widget (#FFF7E9 cards / #6E9A68 Start) across the Setup screen — the production-polish slice completing SETUP-05.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-07T10:50:00Z (approx.)
- **Completed:** 2026-07-07T11:05:00Z
- **Tasks:** 2
- **Files modified:** 9 (5 created, 4 modified) + 1 test file

## Accomplishments
- Extracted genuine static-weight `.ttf` instances (Baloo 2 Bold; Quicksand Regular/Medium/SemiBold/Bold) from the upstream `google/fonts` variable fonts using `fonttools varLib.instancer`, verified each instance's `OS/2.usWeightClass` and `head.macStyle` bold bit before bundling (Pitfall 5) — no `google_fonts` runtime fetch, the app renders text fully offline
- `AppTokens` now carries real `fontFamily` values on every `TextStyle`: `'Baloo 2'` for the wordmark, `'Quicksand'` for everything else
- Setup screen header corrected to the exact `52px top / 24px sides / 8px bottom` padding, centered (was left-aligned at 20px top) — matches the Layout A reference markup's `text-align: center`
- Added the UI-SPEC's pressed/touch-feedback contract via a new shared `_PressableSurface` widget: preset/Custom cards and Start now swap fill to `#FFF7E9`/`#6E9A68` respectively while held, replacing the default Material ripple that previously gave no exact-color feedback
- `SceneCard` converted from `StatelessWidget` to `StatefulWidget` (unchanged public API) so each scene card independently tracks and renders its own pressed state
- Confirmed `#E0805F` destructive color appears nowhere on the Setup or placeholder Running screen; confirmed the placeholder Running screen's background/circle/back-control contract needed no changes (already correct from Plan 01)
- Full test suite (47 tests) green; `flutter analyze` clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Bundle Baloo 2 + Quicksand fonts and wire them into AppTokens** - `6dea706` (feat)
2. **Task 2: Apply exact Layout A spacing/typography/color/copy across the Setup + placeholder screens (SETUP-05)** - `f64f029` (feat)

## Files Created/Modified
- `assets/fonts/Baloo2-Bold.ttf` - Static Bold (700) instance extracted from the upstream Baloo 2 variable font
- `assets/fonts/Quicksand-Regular.ttf` - Static Regular (400) instance
- `assets/fonts/Quicksand-Medium.ttf` - Static Medium (500) instance
- `assets/fonts/Quicksand-SemiBold.ttf` - Static SemiBold (600) instance
- `assets/fonts/Quicksand-Bold.ttf` - Static Bold (700) instance
- `pubspec.yaml` - Declared both font families in `flutter: fonts:`
- `lib/theme/app_tokens.dart` - Added `fontBaloo`/`fontQuicksand` constants; added `fontFamily` to every `TextStyle`
- `lib/screens/setup_screen.dart` - Header padding/alignment fix; added `_PressableSurface` shared widget; preset/Custom cards and Start now use it
- `lib/widgets/scene_grid.dart` - `SceneCard` converted to `StatefulWidget` with pressed-state tracking
- `test/screens/setup_screen_test.dart` - Added `tester.ensureVisible()` before several existing Custom-stepper taps (test-only fix, see Deviations)

## Decisions Made
- Sourced font files from the upstream `google/fonts` GitHub repository rather than the `fonts.googleapis.com` CSS API (which only serves browser-optimized `woff2`), and used `fonttools varLib.instancer` with each font's own named `fvar` instance to produce genuine static weights rather than guessing static-file URLs.
- Applied the UI-SPEC's `52/24/8` header padding literally, on top of the existing `SafeArea` wrapper, rather than removing `SafeArea` to avoid double-counting the status-bar inset — keeps real-device notch safety while matching the design's explicit numeric contract.
- Kept scene-card corner radius at `26px` (`AppTokens.cardRadius`) rather than the raw `Zual.dc.html` prototype's `22px` for scene-card buttons — per this plan's own `read_first` note, `design/README.md`'s Design Tokens table ("cards 26px") is the cited radii authority, and `02-UI-SPEC.md`'s `must_haves` explicitly lock in 26px for cards.
- Implemented pressed-state tracking as one shared `_PressableSurface` widget instead of duplicating gesture/state boilerplate at each of the 7 call sites (5 presets, Custom, Start).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test-only fix: re-scroll several Custom-stepper widget-test taps after the header grew taller**
- **Found during:** Task 2 (Layout A fidelity edits)
- **Issue:** Correcting the header padding from `20px` to the spec's `52px` top pushed the rest of the scrollable body — including the "Custom" grid cell and, once open, the "10" preset — further down, past the default 800×600 widget-test viewport fold. Seven existing tests that called `tester.tap(find.text('Custom'))` (or `find.text('10')` while the Custom row was open) directly, without scrolling first, started failing with hit-test warnings/`StateError: No element`.
- **Fix:** Added `await tester.ensureVisible(...); await tester.pumpAndSettle();` before each affected tap, matching the same pattern Plans 02–03 already established for the scene grid and stepper row.
- **Files modified:** test/screens/setup_screen_test.dart
- **Verification:** `flutter test` (full suite, 47 tests) passes cleanly with zero hit-test warnings.
- **Committed in:** f64f029 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug, test-only)
**Impact on plan:** No production-code or interaction-logic change — purely a widget-test scrolling fix required because the (correct) header-padding fidelity fix pushed existing content further down the scrollable body. No scope creep.

## Issues Encountered
None beyond the test-scrolling deviation above.

## User Setup Required

None - no external service configuration required. Font files were sourced from the same upstream (`google/fonts`, OFL-licensed) that `fonts.google.com` itself serves; no API keys, accounts, or network access needed at runtime (already bundled offline).

## Next Phase Readiness
- SETUP-05 is functionally complete: both font families render via `AppTokens`, and every spacing/typography/color/radius/shadow/copy value on the Setup and placeholder Running screens matches `02-UI-SPEC.md`/`design/README.md`, including pressed-state feedback and the selection ring.
- The manual Android emulator (API 24–28) side-by-side comparison against Layout A — this plan's own `<human-check>` — has not yet been performed; per `config.json`'s `human_verify_mode: end-of-phase`, it is deferred to the phase's end-of-phase UAT pass, consistent with Plans 01–04's identically deferred visual sign-offs (D4/D6 in those summaries).
- No blockers. `lib/timer/` was not modified in this plan (`git diff --name-only` confirms), consistent with the plan's threat model and the phase's "do not touch `lib/timer/`" guidance.
- This is Phase 02's final plan (5 of 5) — the Setup screen slice is now complete end-to-end (duration presets + custom stepper, scene selection, persistence, and design fidelity) and ready for Phase 3's real scene renderers, which extend `ScenePreviewPainter`/`SceneTheme` without touching Setup-screen code.

---
*Phase: 02-setup-screen*
*Completed: 2026-07-07*

## Self-Check: PASSED

All created/modified files verified present on disk (assets/fonts/Baloo2-Bold.ttf,
assets/fonts/Quicksand-Regular.ttf, assets/fonts/Quicksand-Medium.ttf,
assets/fonts/Quicksand-SemiBold.ttf, assets/fonts/Quicksand-Bold.ttf, pubspec.yaml,
lib/theme/app_tokens.dart, lib/screens/setup_screen.dart, lib/widgets/scene_grid.dart,
test/screens/setup_screen_test.dart); both task commit hashes (6dea706, f64f029)
verified present in git log.
