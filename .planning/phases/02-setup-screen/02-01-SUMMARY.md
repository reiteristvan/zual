---
phase: 02-setup-screen
plan: 01
subsystem: ui
tags: [flutter, dart, provider, widget-testing]

# Dependency graph
requires:
  - phase: 01-timer-state-machine-foundation
    provides: TimerController (start/endTimer/phase/progress) consumed directly by SetupScreen and PlaceholderRunningScreen
provides:
  - lib/theme/app_tokens.dart design-token class (colors, radii, shadows, text styles)
  - lib/screens/setup_screen.dart — duration-preset picker (1/5/10/15/30 min) + Start
  - lib/screens/placeholder_running_screen.dart — inert Start destination (shrinking circle, back control, auto-return)
  - lib/main.dart rewired to boot into SetupScreen instead of the Hello World scaffold
affects: [02-setup-screen (Plans 02-05), 03-scene-themes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Selection ring as a conditionally-rendered Positioned.fill + IgnorePointer overlay, keyed ValueKey('preset-ring-$minutes') for test discoverability"
    - "AppTokens static-const design-token class, sourced verbatim from 02-UI-SPEC.md/design/README.md, with a documented placeholder for Plan 05's bundled-font swap"
    - "Placeholder screens consume TimerController via context.watch; mutating actions go through context.read inside handlers"
    - "Post-frame-callback + boolean guard for one-shot auto-navigation on a ChangeNotifier state reaching a terminal phase"

key-files:
  created:
    - lib/theme/app_tokens.dart
    - lib/screens/setup_screen.dart
    - lib/screens/placeholder_running_screen.dart
    - test/screens/setup_screen_test.dart
  modified:
    - lib/main.dart
    - test/widget_test.dart

key-decisions:
  - "Start button label rendered as two adjacent Text widgets in a Row ('Start' + '· {N} min'), not a single RichText/TextSpan — simpler to test via find.text() while still satisfying the UI-SPEC's 'two text runs, two styles' contract."
  - "Added a minimal compile-only PlaceholderRunningScreen stub in Task 2 (ahead of Task 3's real implementation) because SetupScreen's Start handler must reference a concrete PlaceholderRunningScreen type to compile — documented as a Rule 3 deviation."

patterns-established:
  - "lib/screens/ and lib/theme/ established as the first UI-layer directories in this codebase, per STRUCTURE.md's suggested layout."
  - "Design tokens centralized in AppTokens rather than scattered hex literals — future screens should extend this file, not duplicate constants."

requirements-completed: [SETUP-01, SETUP-04]

coverage:
  - id: D1
    description: "Setup screen renders the five duration presets (1/5/10/15/30 min); tapping one selects it and draws the 3px accent selection ring; 5-min preset selected by default"
    requirement: "SETUP-01"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen renders the five duration presets and selects the tapped one (SETUP-01)"
        status: pass
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen the 5 min preset is selected by default before any tap"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tapping Start calls TimerController.start(selectedMinutes) and navigates to the placeholder running screen"
    requirement: "SETUP-04"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen tapping Start after selecting a preset calls TimerController.start and navigates to the placeholder running screen (SETUP-04)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Placeholder running screen shows a shrinking accent circle scaled by (1 - progress); back control ends the timer and returns to Setup with no dialog; reaching TimerPhase.done auto-returns to Setup"
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen -> PlaceholderRunningScreen the back control ends the timer and returns to Setup with phase set to setup"
        status: pass
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen -> PlaceholderRunningScreen reaching TimerPhase.done auto-returns to Setup"
        status: pass
    human_judgment: false
  - id: D4
    description: "Visual/pixel fidelity to design/README.md (exact fonts, precise shadows/spacing) — platform-default font used as an intentional interim per Plan 05's scope"
    verification: []
    human_judgment: true
    rationale: "Font bundling (Baloo 2/Quicksand) and full spacing/shadow fidelity are explicitly deferred to Plan 05; a human should confirm the interim look is acceptable for this walking-slice plan before Plan 05 lands."

# Metrics
duration: 18min
completed: 2026-07-07
status: complete
---

# Phase 2 Plan 1: Setup Screen Walking Slice Summary

**Duration-preset Setup screen (1/5/10/15/30 min, 5-min default) wired to the existing TimerController, with a minimal placeholder running screen closing the Setup → running → Setup loop end-to-end.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-07T09:00:00Z (approx.)
- **Completed:** 2026-07-07T09:06:33Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- `AppTokens` design-token class centralizing all colors/radii/shadows/text-styles from `02-UI-SPEC.md`/`design/README.md`
- `SetupScreen`: 3-column duration-preset grid with a 3px accent selection ring, 5-min default, and a Start button whose label reflects the current selection
- `PlaceholderRunningScreen`: shrinking accent circle driven by `TimerController.progress`, an accessible back control that ends the timer and returns to Setup, and auto-return on `TimerPhase.done`
- `main.dart` rewired: `SetupScreen` is now the app's home; the Hello World scaffold (`MyHomePage`) is deleted
- Full E2E widget-test coverage (`test/screens/setup_screen_test.dart`) pinning SETUP-01, SETUP-04, the 5-min default, back-control return, and done-auto-return

## Task Commits

Each task was committed atomically:

1. **Task 1: Failing end-to-end widget test for duration select + Start (RED)** - `a3d84fb` (test)
2. **Task 2: AppTokens + SetupScreen + main.dart rewire (GREEN)** - `5e61e75` (feat)
3. **Task 3: PlaceholderRunningScreen + Start navigation makes the E2E test green (GREEN)** - `410a1a7` (feat)

_TDD tasks 2 and 3 each landed as a single feat commit; the RED test commit (Task 1) precedes both, satisfying the plan-level TDD gate sequence (test → feat → feat)._

## Files Created/Modified
- `lib/theme/app_tokens.dart` - Static design-token constants (colors, radii, shadows, text styles)
- `lib/screens/setup_screen.dart` - Duration-preset picker + Start button, wired to `TimerController.start`
- `lib/screens/placeholder_running_screen.dart` - Shrinking-circle placeholder Start destination with back control + auto-return
- `lib/main.dart` - Async `main()`, `SetupScreen` as `home`, `MyHomePage` deleted
- `test/screens/setup_screen_test.dart` - New E2E widget-test suite (5 tests)
- `test/widget_test.dart` - Updated to assert the "Zual" wordmark instead of the removed "Hello, World!" text

## Decisions Made
- Rendered the Start button's two-run label ("Start" / "· {N} min") as two `Text` widgets in a `Row` rather than a single `RichText`/`TextSpan` — visually equivalent per the UI-SPEC's two-styles requirement, and much simpler to assert against in widget tests.
- Used a keyed, conditionally-rendered ring overlay (`ValueKey('preset-ring-$minutes')`) for the selection indicator so tests can assert selection state by presence/absence rather than inspecting decoration internals.
- Implemented the back control as `Semantics(label: 'End timer and return to setup', button: true)` wrapping an `IconButton` with `constraints: BoxConstraints.tightFor(width: 44, height: 44)`, matching the 44×44 minimum tap-target requirement while keeping the icon itself unlabeled (child-facing, wordless constraint even as a stub).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a minimal compile-only PlaceholderRunningScreen stub ahead of Task 3**
- **Found during:** Task 2 (AppTokens + SetupScreen + main.dart rewire)
- **Issue:** `SetupScreen`'s Start handler pushes `MaterialPageRoute(builder: (_) => const PlaceholderRunningScreen())`, so the file must exist and export a concrete `PlaceholderRunningScreen` type for `lib/screens/setup_screen.dart` and `lib/main.dart` to compile — but the plan's Task 2 `files_modified` list doesn't include this file, and its full implementation is scoped to Task 3.
- **Fix:** Created `lib/screens/placeholder_running_screen.dart` in Task 2 as a trivial `StatelessWidget` (bare `Scaffold` with the app background color) — just enough to satisfy the type reference and let `flutter test`/`flutter analyze` pass for Task 2's own verification. Task 3 then replaced the entire file body with the real D-01..D-04 implementation (shrinking circle, back control, auto-return).
- **Files modified:** lib/screens/placeholder_running_screen.dart (created as a stub in Task 2's commit, fully replaced in Task 3's commit)
- **Verification:** `flutter test test/widget_test.dart` and `flutter analyze` both passed after the Task 2 commit; the file was then fully implemented and re-verified in Task 3.
- **Committed in:** 5e61e75 (Task 2 commit, stub), 410a1a7 (Task 3 commit, full implementation)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep Task 2 independently compilable given the plan's stated task boundaries; no scope creep — Task 3 still fully owns the real `PlaceholderRunningScreen` behavior exactly as specified.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `lib/screens/` and `lib/theme/` are established; Plan 02 (scene selection) can extend `SetupScreen` with the scene grid in the reserved "Pick a scene" slot without restructuring.
- `AppTokens` is ready to be extended by Plan 02's scene-card tokens and Plan 05's font-family additions.
- No blockers. `lib/timer/` was not modified in this plan, consistent with the plan's threat model (T-02-01P, T-02-02P: both accepted, no untrusted input paths introduced).

---
*Phase: 02-setup-screen*
*Completed: 2026-07-07*
