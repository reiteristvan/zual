---
phase: 04-parent-controls-completion
plan: 05
subsystem: ui
tags: [flutter, animation, audio, timer-completion, widget-test]

# Dependency graph
requires:
  - phase: 04-parent-controls-completion (04-04)
    provides: RunningScreen chimePlayer/soundOn threading, Parent Controls sheet, long-press gate
provides:
  - Done-edge chime trigger (plays synthesizeChimeWav() through injected ChimePlayer exactly once, mute-gated)
  - Foreground-reveal-safe once-only guard (D-07) via _previousPhase/_chimePlayed edge detection
  - Removal of auto-pop-on-done; done is now a dwelled-in state
  - Breathing "All done — tap when ready" pill (2.8s ease-in-out scale 1→1.05) that returns to Setup on tap
affects: [phase-05, verify-work, ui-review]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Edge-triggered once-only side effect guard (_previousPhase != TimerPhase.done && phase == done) to fire an audio/UI side effect exactly once per completion, safe against rebuilds and foreground-reveal remounts"
    - "SingleTickerProviderStateMixin AnimationController owned directly by RunningScreen (composition-root UI) rather than inside SceneRendererState, per 04-UI-SPEC Design System split"

key-files:
  created: []
  modified:
    - lib/screens/running_screen.dart
    - test/screens/running_screen_test.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "AnimationController for the breathing pill is initialized in initState (not late-final lazy), avoiding a dispose() crash path when the pill is never shown during a test/session"
  - "The pre-existing setup_screen_test.dart auto-pop assertion was rewritten in place (not left stale) to assert the new dwell-then-tap-pill flow, since it directly tested behavior this plan intentionally removed"

patterns-established:
  - "Once-only edge-trigger guard: pair a `TimerPhase? _previousPhase` with a `bool _sideEffectDone` flag, compute `justCompleted` before mutating `_previousPhase`, and gate the effect on both — reusable for any future done-edge side effect"

requirements-completed: [CTRL-03, CTRL-04]

coverage:
  - id: D1
    description: "On the done-edge transition the chime plays exactly once through the injected ChimePlayer, gated on soundOn"
    requirement: CTRL-03
    verification:
      - kind: unit
        ref: "test/screens/running_screen_test.dart#RunningScreen completion (CTRL-03/CTRL-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Further phase notifications while parked in done do not replay the chime; a RunningScreen that mounts already in done (foreground-reveal, D-07) still plays it exactly once"
    requirement: CTRL-03
    verification:
      - kind: unit
        ref: "test/screens/running_screen_test.dart#RunningScreen completion (CTRL-03/CTRL-04)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Auto-pop-on-done is removed; done is a dwelled-in state showing the settled scene"
    requirement: CTRL-03
    verification:
      - kind: unit
        ref: "test/screens/setup_screen_test.dart#SetupScreen -> RunningScreen reaching TimerPhase.done dwells on RunningScreen showing the \"All done\" pill, and tapping it returns to Setup (CTRL-03/CTRL-04)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A gently breathing 'All done — tap when ready' pill appears at done and returns to Setup when tapped"
    requirement: CTRL-04
    verification:
      - kind: unit
        ref: "test/screens/running_screen_test.dart#RunningScreen completion (CTRL-03/CTRL-04)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Chime sound quality is calm/soft (not alarm-like); mute silences it; Android ringer-silent does not affect it (media stream); foreground-reveal plays the chime exactly once on a real device"
    requirement: CTRL-03
    verification:
      - kind: manual_procedural
        ref: "Task 3 checkpoint: Android emulator (emulator-5554, Android 16 API 36) on-device listen-check, all four checks confirmed by human"
        status: pass
    human_judgment: true
    rationale: "Perceptual audio quality and Android silent-mode/media-stream interaction cannot be verified by automated widget tests; requires a human ear and a real/emulated device audio stack"

# Metrics
duration: ~15min
completed: 2026-07-09
status: complete
---

# Phase 4 Plan 5: Timer Completion — Chime + Breathing Pill Summary

**Done-edge chime trigger (edge-guarded, mute-gated, foreground-reveal-safe) plus a breathing "All done — tap when ready" pill replacing the old auto-pop, turning `TimerPhase.done` into a calm, dwelled-in finished state.**

## Performance

- **Duration:** ~15 min (Tasks 1-2 RED/GREEN cycle + Task 3 on-device verification)
- **Tasks:** 3 (2 automated + 1 human-verify checkpoint)
- **Files modified:** 3

## Accomplishments
- Two-tone chime (`synthesizeChimeWav()` bytes from Plan 04-01) plays exactly once on the edge into `TimerPhase.done`, gated on `soundOn`, via the injected `ChimePlayer` threaded in Plan 04-04
- Once-only guard (`_previousPhase`/`_chimePlayed`) is robust to repeat rebuilds while parked in done and to mounting a `RunningScreen` already in `done` (D-07 foreground-reveal case)
- `_maybeAutoPopWhenDone` deleted entirely — completion no longer auto-returns to Setup; the settled scene stays on screen
- A `SingleTickerProviderStateMixin`-driven breathing pill ("All done — tap when ready", 2.8s ease-in-out scale 1→1.05, bottom-centered ~56px offset, blurred pillSurface per 04-UI-SPEC) appears only in done and returns to Setup on tap via `endTimer()` + `_leaveOnce()`
- Verified on a real Android emulator: chime is soft/calm (not alarm-like), mute silences it, ringer-silent does not affect the media-stream chime (expected platform behavior), and the chime plays exactly once on foreground reveal after backgrounding through completion

## Task Commits

Each task was committed atomically:

1. **Task 1: Completion widget-test cases — chime-once + pill (RED)** - `5c3ee18` (test)
2. **Task 2: Done-edge chime trigger + breathing pill; remove auto-pop (GREEN)** - `8994af1` (feat)
3. **Task 3: Chime sound quality + media-volume vs ringer-silent check** - human-verify checkpoint, approved on-device (no code change; see Deviations)

**Plan metadata:** committed alongside this SUMMARY

_Note: TDD RED/GREEN cycle — Task 1 pinned the failing assertions, Task 2 made them pass._

## Files Created/Modified
- `lib/screens/running_screen.dart` - Adds `SingleTickerProviderStateMixin`, `_previousPhase`/`_chimePlayed`/`_chimeBytes` fields, `_maybeReactToPhaseChange()` done-edge chime trigger, `_breatheController`/`_breatheScale`, and the breathing "All done" pill widget; deletes `_maybeAutoPopWhenDone`
- `test/screens/running_screen_test.dart` - Adds completion cases: chime-once on transition, no replay on repeat notifications, mute-gated skip, D-07 mount-already-done, pill presence/absence by phase, tap-the-pill invokes `endTimer()` and pops the screen
- `test/screens/setup_screen_test.dart` - Rewrites the now-obsolete "auto-returns to Setup" assertion to match the new dwell-then-tap-pill completion flow

## Decisions Made
- Moved the `_breatheController` initialization into `initState()` (not a lazy `late final`) after discovering during Task 2 GREEN that lazy init crashed `dispose()` when the pill was never shown in a given test — a direct correctness fix within Task 2's scope (Rule 1)
- Rewrote `setup_screen_test.dart`'s pre-existing auto-pop test in place rather than leaving it stale, since Task 2's required change (removing auto-pop) made the old assertion actively wrong, not just outdated (Rule 1 — the test asserted behavior this task's action explicitly deletes)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed AnimationController lazy-init crash on dispose**
- **Found during:** Task 2 (breathing pill implementation)
- **Issue:** A `late final` `_breatheController` initialized lazily on first pill build would throw in `dispose()` if the widget was torn down before the pill was ever built (e.g., a test that exits `RunningScreen` before reaching `done`)
- **Fix:** Moved `_breatheController` construction and `.repeat(reverse: true)` start into `initState()` so it is always initialized and always safely disposable
- **Files modified:** lib/screens/running_screen.dart
- **Verification:** Full `flutter test` suite green (129/129), no dispose exceptions
- **Committed in:** `8994af1` (Task 2 commit)

**2. [Rule 1 - Bug] Updated setup_screen_test.dart's obsolete auto-pop assertion**
- **Found during:** Task 2 (removing `_maybeAutoPopWhenDone`)
- **Issue:** An existing test in `setup_screen_test.dart` asserted the old auto-pop-to-Setup behavior, which this task's core requirement removes — leaving it as-is would either fail or falsely validate deleted behavior
- **Fix:** Rewrote the test to assert the new contract: reaching done dwells on `RunningScreen` with the pill visible, and tapping the pill returns to Setup
- **Files modified:** test/screens/setup_screen_test.dart
- **Verification:** `flutter test` passes with the new assertions exercising the real completion flow
- **Committed in:** `8994af1` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bug fixes, both direct consequences of Task 2's required scope)
**Impact on plan:** Both fixes were necessary corollaries of the plan's own required change (removing auto-pop) and a latent resource-lifecycle bug surfaced by adding the new AnimationController. No scope creep.

## Issues Encountered

**Executor continuity note:** This plan was executed across two dispatch attempts. Tasks 1-2 were originally committed on worktree branch `worktree-agent-a7dc49c8bb9ba3f99`. The continuation dispatch for Task 3 was spawned into a fresh worktree (`worktree-agent-ade30f0400de9bd61`) whose branch tip did not yet include those two commits. Since the prior branch's history was a clean linear continuation of this branch's tip (`491d8b0`), the two commits were reconciled via `git merge --ff-only` (a non-destructive fast-forward, not a merge commit) before resuming — no code was rewritten, no other worktree's filesystem was touched, and the resulting commit hashes (`5c3ee18`, `8994af1`) are unchanged. Full test suite (129/129) and `flutter analyze` (clean) were re-verified after the fast-forward to confirm the reconciled state matched what the continuation context described.

Task 3's on-device checkpoint (chime quality, mute behavior, ringer-silent vs. media-volume, foreground-reveal once-only) was approved by the human on a real Android emulator per the continuation context; no code changes were required for Task 3.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- CTRL-03 and CTRL-04 are fully implemented and verified (automated + human on-device)
- Phase 4's user-facing completion slice (chime + breathing pill, replacing Phase 3's auto-pop scaffolding) is done
- No blockers for subsequent phases

---
*Phase: 04-parent-controls-completion*
*Completed: 2026-07-09*

## Self-Check: PASSED
- FOUND: lib/screens/running_screen.dart
- FOUND: test/screens/running_screen_test.dart
- FOUND: .planning/phases/04-parent-controls-completion/04-05-SUMMARY.md
- FOUND: commit 5c3ee18
- FOUND: commit 8994af1
