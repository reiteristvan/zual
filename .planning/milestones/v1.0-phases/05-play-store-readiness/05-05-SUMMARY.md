---
phase: 05-play-store-readiness
plan: 05
subsystem: infra
tags: [android, play-store, release-build, screenshots, on-device-verification]

# Dependency graph
requires:
  - phase: 05-play-store-readiness (plan 01)
    provides: "com.ireiter.zual applicationId + key.properties-backed production signing config, signed .aab/apk"
  - phase: 05-play-store-readiness (plan 04)
    provides: "Real Night-to-Sunrise adaptive launcher icon (flutter_launcher_icons asset set)"
provides:
  - "On-device proof: signed release build installs, shows the real adaptive launcher icon, and runs a full countdown to completion on a real Samsung A25 (ROADMAP Phase 5 Success Criterion #4)"
  - "screenshots/ directory with 4 required full-bleed per-scene PNGs (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road) plus 1 bonus Setup-screen asset, for Play Console listing"
affects: ["Play Console submission (final Play Store listing upload uses these screenshots + the signed .aab from 05-01)"]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - screenshots/shrinking_disc.png
    - screenshots/night_to_sunrise.png
    - screenshots/walking_home.png
    - screenshots/car_on_a_road.png
    - screenshots/setup_screen.png
  modified: []

key-decisions:
  - "Developer captured screenshots from a release-build emulator run (not the on-device APK used for Task 1) specifically to avoid the debug banner, per the plan's D-13 no-overlay requirement."
  - "Developer captured a 5th bonus screenshot (Setup screen) beyond the plan's required 4 scene screenshots, kept as an additional Play Store listing asset at the developer's discretion."

patterns-established: []

requirements-completed: [PUBLISH-01, PUBLISH-02]

coverage:
  - id: D1
    description: "Signed release build installs on a real Android device (Samsung A25), shows the real Night-to-Sunrise adaptive launcher icon (not the Flutter default), and runs a full countdown to completion with no crash and no debug banner"
    requirement: "PUBLISH-01"
    verification:
      - kind: manual_procedural
        ref: "Developer on-device verification on Samsung A25 (Task 1 checkpoint), re-confirmed after the interleaved quick-task layout fix (260710-frr)"
        status: pass
    human_judgment: true
    rationale: "Real device install, launcher-icon appearance, and a full end-to-end countdown to completion are inherently physical/visual on-hardware checks that no automated test in this repo can assert."
  - id: D2
    description: "screenshots/ contains 4 full-bleed, no-frame, no-caption-overlay PNGs, one per scene (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road), captured from the real running release-build app"
    requirement: "PUBLISH-02"
    verification:
      - kind: manual_procedural
        ref: "Developer capture via release-build emulator (Task 2 checkpoint); each PNG visually confirmed full-bleed, portrait, no device frame, no caption overlay, no debug banner"
        status: pass
    human_judgment: true
    rationale: "Whether a screenshot is genuinely full-bleed, framed correctly, and representative of each scene's character is a visual judgment call (D-12/D-13) that file-existence checks cannot make."

# Metrics
duration: —
completed: 2026-07-10
status: complete
---

# Phase 05 Plan 05: Publishable Build Verification Summary

**Signed release build confirmed installing and running a full countdown with the real adaptive icon on a physical Samsung A25, plus 4 required full-bleed per-scene screenshots (and 1 bonus Setup-screen asset) captured for the Play Console listing.**

## Performance

- **Duration:** — (spans an on-device verification session; not tracked to the minute)
- **Tasks:** 2 (both `checkpoint:human-verify`/`checkpoint:human-action`)
- **Files modified:** 5 (all new, `screenshots/`)

## Accomplishments
- Confirmed on a real Samsung A25: the signed release build (plan 05-01) installs, the launcher shows the real Night-to-Sunrise adaptive icon (plan 05-04) rather than the Flutter default, and a full countdown runs cleanly to the "All done" finished state with no crash and no debug banner — satisfying ROADMAP Phase 5 Success Criterion #4 and closing out PUBLISH-01's on-device proof.
- During this on-device check the developer found a real layout overflow bug on the A25 (Setup screen's "How long" + scene-picker sections overflowed the viewport by ~1cm) — see Deviations below. After the fix, the developer re-verified on-device and confirmed the viewport now fits correctly.
- Captured 4 required full-bleed, no-frame, no-caption-overlay screenshots — one per scene (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road) — from a release-build emulator run (chosen specifically to avoid the debug banner that would appear in a debug-build capture).
- Captured 1 bonus screenshot (Setup screen) beyond the plan's required 4, kept as an additional Play Store listing asset at the developer's discretion.
- All 5 screenshots committed to `screenshots/` at the repo root.

## Task Commits

Each task was a human checkpoint (no in-repo code changes to commit per-task); the resulting artifact was committed once both checkpoints were approved:

1. **Task 1: On-device signed-release install + full countdown verification** — approved by developer (no direct commit; verification-only). The layout bug found during this check was fixed and merged separately as quick task `260710-frr` (commit range `a95f594..a224407`; see `.planning/quick/260710-frr-fix-setup-screen-layout-overflow-on-real/260710-frr-SUMMARY.md`), outside this plan's own commit history.
2. **Task 2: Capture 4 full-bleed per-scene screenshots** — approved by developer; artifact committed as `e6f5fa5` (feat: add Play Store listing screenshots).

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `screenshots/shrinking_disc.png` - Required full-bleed screenshot of the Shrinking Disc scene.
- `screenshots/night_to_sunrise.png` - Required full-bleed screenshot of the Night to Sunrise scene.
- `screenshots/walking_home.png` - Required full-bleed screenshot of the Walking Home scene.
- `screenshots/car_on_a_road.png` - Required full-bleed screenshot of the Car on a Road scene.
- `screenshots/setup_screen.png` - BONUS: extra Setup/home screen asset, not required by the plan, kept as an additional listing image per developer's explicit choice.

## Decisions Made
- Screenshots captured from a release-build emulator (not from the physical Samsung A25 used for Task 1's on-device install check) specifically to guarantee no debug banner appears, satisfying D-13's no-overlay requirement.
- The 5th Setup-screen screenshot was an unplanned addition the developer chose to keep; it does not replace or count against the plan's 4 required per-scene screenshots.

## Deviations from Plan

### Auto-fixed Issues (interleaved, not part of this plan's own tasks)

**1. [Rule 1 - Bug, handled as a separate quick task] Setup screen layout overflow on real device**
- **Found during:** Task 1 (on-device signed-release verification on Samsung A25)
- **Issue:** The Setup screen's "How long" duration presets and scene-picker sections overflowed the real device's viewport by roughly 1cm, clipping content that fit fine in emulator/development testing.
- **Fix:** Made the Setup screen's content layout responsive so it fits the real viewport without clipping; a regression test targeting the A25's screen dimensions was added.
- **Files modified:** Setup screen layout files (see quick task summary for the full file list) — not part of this plan's `files_modified` scope (`screenshots/`).
- **Verification:** Developer re-verified on the physical Samsung A25 after the fix and confirmed the Setup screen now fits the viewport correctly, before proceeding to Task 2 of this plan.
- **Committed in:** Handled entirely outside this plan as quick task `260710-frr`, commit range `a95f594..a224407` (merged via `b55b887`). Not a deviation within 05-05's own task execution — documented here because it was discovered during this plan's Task 1 checkpoint.

---

**Total deviations:** 1, handled as an interleaved quick task rather than an in-plan auto-fix (the bug was in a different plan's deliverable — Setup screen, from Phase 2 — not in this plan's own scope of `screenshots/`). No deviations occurred within this plan's own two checkpoint tasks.
**Impact on plan:** None on this plan's scope; the quick task unblocked re-verification of Task 1 and did not require replanning 05-05 itself.

## Issues Encountered
None beyond the interleaved layout bug documented above, which was resolved and re-verified before this plan's tasks were considered complete.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- This is the last plan in Phase 5 (Play Store Readiness) and the last plan in the v1 milestone roadmap. Both PUBLISH-01 and PUBLISH-02 are now fully satisfied:
  - PUBLISH-01 (real applicationId + production signing): proven end-to-end on real hardware in this plan's Task 1, building on 05-01.
  - PUBLISH-02 (store listing assets, icon, screenshots, content-rating/target-audience review): privacy policy + store listing (05-03), icon (05-04), and now screenshots (05-05) are all complete.
- ROADMAP Phase 5 Success Criteria 1-4 are all satisfied. The app is ready for Play Console submission (upload the signed `.aab` from 05-01, the icon asset set from 05-04, and the 5 screenshots from this plan).
- Remaining non-blocking note carried in STATE.md: Play Store Families Policy and target-audience declaration wording should be re-verified in Play Console at actual submission time, since policy wording can change between now and submission.
- No blockers for milestone completion.

## Self-Check: PASSED

- FOUND: screenshots/shrinking_disc.png
- FOUND: screenshots/night_to_sunrise.png
- FOUND: screenshots/walking_home.png
- FOUND: screenshots/car_on_a_road.png
- FOUND: screenshots/setup_screen.png
- FOUND commit: e6f5fa5 (feat: add Play Store listing screenshots)

---
*Phase: 05-play-store-readiness*
*Completed: 2026-07-10*
