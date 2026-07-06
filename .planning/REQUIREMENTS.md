# Requirements: Zual

**Defined:** 2026-07-06
**Core Value:** A child with no concept of clock time can look at the screen from across a room and understand, without any numbers or words, roughly how much longer they have to wait.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Timer Foundation

- [ ] **TIMER-01**: App maintains a shared timer state machine with phases `setup` / `running` / `paused` / `done`
- [ ] **TIMER-02**: Countdown progress is calculated from wall-clock elapsed time (not animation duration), so it doesn't drift over long runs
- [ ] **TIMER-03**: Timer correctly pauses and resumes, excluding paused time from the elapsed calculation
- [ ] **TIMER-04**: App handles backgrounding/foregrounding during a running timer without losing correct progress
- [ ] **TIMER-05**: Screen stays awake (no sleep) while a timer is running

### Setup Screen

- [ ] **SETUP-01**: Parent can pick a duration from presets (1, 5, 10, 15, 30 min)
- [ ] **SETUP-02**: Parent can pick a custom duration (1–120 min) via a stepper
- [ ] **SETUP-03**: Parent can pick one of 4 visual scene themes via thumbnail cards
- [ ] **SETUP-04**: Parent starts the timer with a single Start button showing the selected duration
- [ ] **SETUP-05**: Setup screen matches Layout A from the design spec pixel-accurately (colors, radii, spacing, typography)

### Scene Themes

- [ ] **SCENE-01**: Shrinking Disc theme renders full-screen; disc scales down as time passes with green→yellow→red color zones
- [ ] **SCENE-02**: Night to Sunrise theme renders full-screen; sky interpolates night→day, stars/moon fade, sun rises, hill warms
- [ ] **SCENE-03**: Walking Home theme renders full-screen; character walks a path toward a house, arriving at time-up
- [ ] **SCENE-04**: Car on a Road theme renders full-screen; car drives a path toward a destination, arriving at time-up
- [ ] **SCENE-05**: All 4 scenes read only a shared `progress` value (0..1) via a common scene-renderer contract; nothing is tappable by the child

### Parent Controls & Completion

- [ ] **CTRL-01**: A hidden ~850ms long-press anywhere on the running screen opens a Parent Controls bottom sheet
- [ ] **CTRL-02**: Parent Controls sheet offers Pause/Resume, End timer (returns to Setup), Keep watching (dismiss), and a sound mute toggle
- [ ] **CTRL-03**: On completion, the app plays a soft two-tone chime (no alarm, no celebration) and the active scene settles into its end state
- [ ] **CTRL-04**: Completed state shows a gently breathing "All done" pill that returns to Setup when tapped by the parent

### Persistence

- [ ] **PERSIST-01**: App remembers the last-used duration and theme locally and pre-selects them on next launch

### Play Store Readiness

- [ ] **PUBLISH-01**: App has a real `applicationId` and production signing config (not placeholder/debug)
- [ ] **PUBLISH-02**: App has Play Store listing assets (icon, screenshots) and a content-rating/target-audience declaration reviewed against Families Policy considerations

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
| TIMER-01 | TBD | Pending |
| TIMER-02 | TBD | Pending |
| TIMER-03 | TBD | Pending |
| TIMER-04 | TBD | Pending |
| TIMER-05 | TBD | Pending |
| SETUP-01 | TBD | Pending |
| SETUP-02 | TBD | Pending |
| SETUP-03 | TBD | Pending |
| SETUP-04 | TBD | Pending |
| SETUP-05 | TBD | Pending |
| SCENE-01 | TBD | Pending |
| SCENE-02 | TBD | Pending |
| SCENE-03 | TBD | Pending |
| SCENE-04 | TBD | Pending |
| SCENE-05 | TBD | Pending |
| CTRL-01 | TBD | Pending |
| CTRL-02 | TBD | Pending |
| CTRL-03 | TBD | Pending |
| CTRL-04 | TBD | Pending |
| PERSIST-01 | TBD | Pending |
| PUBLISH-01 | TBD | Pending |
| PUBLISH-02 | TBD | Pending |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 0 (roadmap not yet created)
- Unmapped: 22 ⚠️

---
*Requirements defined: 2026-07-06*
*Last updated: 2026-07-06 after initial definition*
