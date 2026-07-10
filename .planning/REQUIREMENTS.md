# Requirements: Zual

**Defined:** 2026-07-06
**Core Value:** A child with no concept of clock time can look at the screen from across a room and understand, without any numbers or words, roughly how much longer they have to wait.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Timer Foundation

- [x] **TIMER-01**: App maintains a shared timer state machine with phases `setup` / `running` / `paused` / `done`
- [x] **TIMER-02**: Countdown progress is calculated from wall-clock elapsed time (not animation duration), so it doesn't drift over long runs
- [x] **TIMER-03**: Timer correctly pauses and resumes, excluding paused time from the elapsed calculation
- [x] **TIMER-04**: App handles backgrounding/foregrounding during a running timer without losing correct progress
- [x] **TIMER-05**: Screen stays awake (no sleep) while a timer is running

### Setup Screen

- [x] **SETUP-01**: Parent can pick a duration from presets (1, 5, 10, 15, 30 min)
- [x] **SETUP-02**: Parent can pick a custom duration (1–120 min) via a stepper
- [x] **SETUP-03**: Parent can pick one of 4 visual scene themes via thumbnail cards
- [x] **SETUP-04**: Parent starts the timer with a single Start button showing the selected duration
- [x] **SETUP-05**: Setup screen matches Layout A from the design spec pixel-accurately (colors, radii, spacing, typography)

### Scene Themes

- [x] **SCENE-01**: Shrinking Disc theme renders full-screen; disc scales down as time passes with green→yellow→red color zones
- [x] **SCENE-02**: Night to Sunrise theme renders full-screen; sky interpolates night→day, stars/moon fade, sun rises, hill warms
- [x] **SCENE-03**: Walking Home theme renders full-screen; character walks a path toward a house, arriving at time-up
- [x] **SCENE-04**: Car on a Road theme renders full-screen; car drives a path toward a destination, arriving at time-up
- [x] **SCENE-05**: All 4 scenes read only a shared `progress` value (0..1) via a common scene-renderer contract; nothing is tappable by the child

### Parent Controls & Completion

- [x] **CTRL-01**: A hidden ~850ms long-press anywhere on the running screen opens a Parent Controls bottom sheet
- [x] **CTRL-02**: Parent Controls sheet offers Pause/Resume, End timer (returns to Setup), Keep watching (dismiss), and a sound mute toggle
- [x] **CTRL-03**: On completion, the app plays a soft two-tone chime (no alarm, no celebration) and the active scene settles into its end state
- [x] **CTRL-04**: Completed state shows a gently breathing "All done" pill that returns to Setup when tapped by the parent

### Persistence

- [x] **PERSIST-01**: App remembers the last-used duration and theme locally and pre-selects them on next launch

### Play Store Readiness

- [x] **PUBLISH-01**: App has a real `applicationId` and production signing config (not placeholder/debug)
- [x] **PUBLISH-02**: App has Play Store listing assets (icon, screenshots) and a content-rating/target-audience declaration reviewed against Families Policy considerations

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Platforms

- **PLAT-01**: iOS support
- **PLAT-02**: Web support (already scaffolded, but deferred for this milestone)

### Accessibility

- **A11Y-01**: Colorblind-safe audit of the Shrinking Disc's green→yellow→red zones (size-based shrinking already provides a safe primary cue; this is polish)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Tasks/routines and task lists | Not what this app is for — it's a timer, not a productivity tool |
| Accounts / login | No need for single-device parent/child use, no backend |
| Celebration or alarm sounds | Calm-only chime is a deliberate design choice; avoids overstimulating sensitive children |
| Landscape layout | Portrait-only per design spec |
| Child interactivity on the running screen | Nothing is tappable by design — the child only watches |
| iOS and Web platforms (this milestone) | Android only for v1; existing scaffold supports both but they're deferred |
| Network/backend features | App is fully local; only local storage (last-used settings) is in scope |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TIMER-01 | Phase 1 | Complete |
| TIMER-02 | Phase 1 | Complete |
| TIMER-03 | Phase 1 | Complete |
| TIMER-04 | Phase 1 | Complete |
| TIMER-05 | Phase 1 | Complete |
| SETUP-01 | Phase 2 | Complete |
| SETUP-02 | Phase 2 | Complete |
| SETUP-03 | Phase 2 | Complete |
| SETUP-04 | Phase 2 | Complete |
| SETUP-05 | Phase 2 | Complete |
| SCENE-01 | Phase 3 | Complete |
| SCENE-02 | Phase 3 | Complete |
| SCENE-03 | Phase 3 | Complete |
| SCENE-04 | Phase 3 | Complete |
| SCENE-05 | Phase 3 | Complete |
| CTRL-01 | Phase 4 | Complete |
| CTRL-02 | Phase 4 | Complete |
| CTRL-03 | Phase 4 | Complete |
| CTRL-04 | Phase 4 | Complete |
| PERSIST-01 | Phase 2 | Complete |
| PUBLISH-01 | Phase 5 | Complete |
| PUBLISH-02 | Phase 5 | Complete |

**Coverage:**

- v1 requirements: 22 total
- Mapped to phases: 22 ✓
- Unmapped: 0

---
*Requirements defined: 2026-07-06*
*Last updated: 2026-07-06 after roadmap creation*
