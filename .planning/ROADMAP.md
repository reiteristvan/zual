# Roadmap: Zual

## Overview

Zual grows from a scaffolded Flutter "Hello World" into a publishable, wordless visual
countdown timer for young children. The journey starts by locking down the hardest, highest-leverage
part — a drift-free, lifecycle-safe timer state machine that every screen and scene depends on.
From there a parent-facing Setup screen lets an adult configure a countdown, four full-screen
wordless scenes make time-remaining readable at a glance, and a hidden parent-controls surface
plus a calm completion state round out the experience. The final phase turns the working app into
a real, signed, Play-Store-ready Android build.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Timer State-Machine Foundation** - Drift-free, lifecycle-safe countdown engine every screen depends on
- [ ] **Phase 2: Setup Screen** - Parent configures duration + scene and launches the timer; last-used settings remembered
- [ ] **Phase 3: Scene Themes** - Four full-screen wordless scenes driven by a shared progress value
- [ ] **Phase 4: Parent Controls & Completion** - Hidden long-press controls, mute, calm chime, and finished state
- [ ] **Phase 5: Play Store Readiness** - Real app identity, signing, and store listing assets for publication

## Phase Details

### Phase 1: Timer State-Machine Foundation

**Goal**: A correct, drift-free countdown engine that survives pause, resume, and backgrounding, exposing phase and progress to the rest of the app.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: TIMER-01, TIMER-02, TIMER-03, TIMER-04, TIMER-05
**Success Criteria** (what must be TRUE):

  1. Starting a timer for N minutes reaches "done" after N minutes of wall-clock time (within a small tolerance), regardless of animation frame rate.
  2. Pausing then resuming excludes the paused interval — a timer paused for 2 minutes finishes 2 minutes later than an uninterrupted run.
  3. Backgrounding the app mid-run and returning shows progress consistent with real elapsed time (no reset, no drift).
  4. The screen does not sleep while a timer is running, and normal sleep behavior returns once the timer ends.
  5. The engine moves through setup → running → (paused) → done and exposes a normalized 0..1 progress value.

**Plans**: 1/2 plans executed
**Wave 1**

- [x] 01-01-PLAN.md — Wall-clock progress engine: TimerPhase enum + TimerController (start/progress/done) with deterministic tests (TIMER-01, TIMER-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 01-02-PLAN.md — Pause/resume, backgrounding reconciliation, screen-wake, and app-root wiring (TIMER-01, TIMER-03, TIMER-04, TIMER-05)

### Phase 2: Setup Screen

**Goal**: A parent can configure a countdown — duration and scene — and launch it, matching Layout A of the design spec, with last-used settings pre-selected.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: SETUP-01, SETUP-02, SETUP-03, SETUP-04, SETUP-05, PERSIST-01
**Success Criteria** (what must be TRUE):

  1. Parent can select a preset duration (1/5/10/15/30 min) or set a custom value 1–120 min via a stepper.
  2. Parent can pick one of 4 scene themes from thumbnail cards.
  3. Pressing Start launches the running timer with the chosen duration and theme.
  4. On next launch, the previously used duration and theme are pre-selected.
  5. The screen visually matches Layout A (colors, radii, spacing, typography) from the design spec.

**Plans**: TBD
**UI hint**: yes

### Phase 3: Scene Themes

**Goal**: All four wordless scenes render full-screen and make time-remaining readable at a glance from a single shared progress value, with nothing tappable by the child.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: SCENE-01, SCENE-02, SCENE-03, SCENE-04, SCENE-05
**Success Criteria** (what must be TRUE):

  1. Each of the 4 themes (Shrinking Disc, Night-to-Sunrise, Walking Home, Car on a Road) renders full-screen in portrait with zero text or numbers.
  2. The Shrinking Disc scales down and shifts through green→yellow→red color zones as time passes.
  3. Night-to-Sunrise interpolates the sky night→day with stars/moon fading and the sun rising; Walking Home and Car on a Road move toward their destination and arrive exactly at time-up.
  4. All scenes are driven solely by the shared 0..1 progress value via a common scene-renderer contract, and nothing on the running screen is tappable by the child.
  5. Scenes animate smoothly without visible jank on a mid/low-end Android device.

**Plans**: TBD
**UI hint**: yes

### Phase 4: Parent Controls & Completion

**Goal**: A parent can discreetly control a running timer, and completion resolves into a calm, wordless finished state with a soft chime.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: CTRL-01, CTRL-02, CTRL-03, CTRL-04
**Success Criteria** (what must be TRUE):

  1. A hidden ~850ms long-press anywhere on the running screen opens the Parent Controls bottom sheet.
  2. The sheet offers Pause/Resume, End timer (returns to Setup), Keep watching (dismiss), and a sound mute toggle.
  3. On completion a soft two-tone chime plays (unless muted) with no alarm or celebration, and the active scene settles into its end visual.
  4. The finished state shows a gently breathing "All done" pill that returns to Setup when the parent taps it.

**Plans**: TBD
**UI hint**: yes

### Phase 5: Play Store Readiness

**Goal**: The app is a publishable Android build with real identity, production signing, and store listing assets reviewed against Families Policy considerations.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: PUBLISH-01, PUBLISH-02
**Success Criteria** (what must be TRUE):

  1. The app has a real applicationId and a production signing config (no debug/placeholder).
  2. Play Store listing assets (app icon, screenshots) are prepared.
  3. A content-rating / target-audience declaration is completed and reviewed against Families Policy considerations.
  4. A release build installs and runs a full countdown on a real Android device.

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Timer State-Machine Foundation | 1/2 | In Progress|  |
| 2. Setup Screen | 0/TBD | Not started | - |
| 3. Scene Themes | 0/TBD | Not started | - |
| 4. Parent Controls & Completion | 0/TBD | Not started | - |
| 5. Play Store Readiness | 0/TBD | Not started | - |
