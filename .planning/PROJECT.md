# Zual

## What This Is

Zual is a visual countdown timer for children roughly ages 2–6 who don't yet understand
minutes and hours. A parent sets a duration and picks a scene; the child watches a
full-screen, wordless, number-free visualization that makes time remaining readable at a
glance from across a room. When time is up, a soft chime plays and the visual settles into
a calm finished state. It is deliberately not a productivity tool — playful but calm, suitable
for a bedroom or kitchen counter.

## Core Value

A child with no concept of clock time can look at the screen from across a room and understand,
without any numbers or words, roughly how much longer they have to wait.

## Business Context

- **Customer**: Parents of young children (~2–6), starting with personal/family use
- **Revenue model**: None planned for v1 — free app
- **Success metric**: Successful Play Store publication of a working v1

## Requirements

### Validated

- ✓ Flutter project scaffolded with web + Android platform support — existing scaffold (pre-Zual)

### Active

- [ ] Setup screen (parent-facing): duration via presets (1/5/10/15/30 min) + custom stepper (1–120 min), theme picker (4 scene cards), Start button — Layout A per design spec
- [ ] Running timer screen (child-facing): full-screen portrait, zero text/numbers, nothing tappable by the child
- [ ] Shrinking Disc theme: disc scales down as time passes, green→yellow→red color zones
- [ ] Night to Sunrise theme: sky interpolates night→day, stars/moon fade, sun rises, hill warms
- [ ] Walking Home theme: character walks a path toward a house, arrives at time-up
- [ ] Car on a Road theme: car drives a path toward a destination, arrives at time-up
- [ ] Shared countdown/progress state machine (`setup → running → done`, `paused` substate) driving all 4 themes
- [ ] Completed state: soft two-tone chime, theme settles into end visual, breathing "All done" pill to return to Setup
- [ ] Parent controls overlay: hidden ~850ms long-press on running screen opens bottom sheet (Pause/Resume, End timer, Keep watching)
- [ ] Pixel-accurate implementation of design tokens (colors, typography, radii, spacing, shadows) from `design/README.md`
- [ ] Play Store publish readiness: app icon, store listing assets, versioning

### Out of Scope

- Tasks/routines and task lists — not what this app is for
- Accounts / login — no need, single-device parent/child use
- Celebration or alarm sounds — calm-only chime is a deliberate design choice
- Landscape layout — portrait-only per design spec
- Child interactivity on the running screen — nothing is tappable by design
- iOS and Web platforms for v1 — Android only for now; iOS/Web are possible future milestones
- Persistence/accounts/network — no backend; app is fully local (optionally remember last-used duration + theme)

## Context

- **Existing codebase**: brownfield — Flutter "Hello World" app already scaffolded (web + Android), see `.planning/codebase/` for full map (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS).
- **Design source of truth**: `design/README.md` plus two HTML prototypes (`design/Zual.dc.html` — full interactive prototype; `design/Zual - App Screens.dc.html` — annotated screen-flow board). These are high-fidelity (hifi) — colors, typography, spacing, radii, easing, and timings are final and exact, but the HTML/CSS itself is a reference to recreate using Flutter idioms (CustomPainter/Canvas for scene rendering, AnimationController for the progress-driven loop), not code to port line-for-line.
- **Design tokens**: full color palette, typography (Baloo 2 + Quicksand), radii, shadows, spacing, and animation timings are specified in `design/README.md` — treat as final.
- **Sound**: end chime is two soft sine tones (D5 → G5) with a specific envelope, originally generated via Web Audio API — needs a Flutter equivalent (tone generator or bundled short WAV).
- **No image assets** — all visuals in the reference design are built from shape primitives (circles, gradients, rounded rects, CSS-border triangles); Flutter implementation should use CustomPainter/Canvas or similar vector approaches rather than bitmap assets.

## Constraints

- **Tech stack**: Flutter — build on the existing scaffold rather than switching frameworks, despite the design doc's suggestion of React Native/Expo or SwiftUI for greenfield
- **Platform**: Android only for v1 — existing scaffold also supports web, but web is out of scope for this milestone
- **Fidelity**: Visual/behavioral fidelity to `design/README.md` is high-priority — colors, radii, timings, and interaction thresholds (e.g. 850ms long-press) are treated as final, not starting points
- **Distribution**: Intended for eventual Play Store publication — needs to reach a publishable, polished state, not just a personal prototype

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build in Flutter on the existing scaffold, not React Native/SwiftUI as the design doc suggests | Repo already has a working Flutter Hello World scaffold (web + Android); no reason to discard it | — Pending |
| Android only for v1 | Simplifies initial scope; existing scaffold supports web too but that's deferred | — Pending |
| Build all 4 themes in the same phase rather than disc-first | Themes share the same underlying timer state machine and color-zone logic; splitting adds phase overhead without much isolation benefit | — Pending |
| Publish to Play Store (not just personal use) | User's stated intent | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-06 after initialization*
