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
- ✓ Shared countdown/progress state machine (`setup → running → paused → done`), driven by wall-clock time, surviving pause/resume and backgrounding, with screen-wake tied to the running phase — Phase 1
- ✓ Setup screen (parent-facing): duration via presets (1/5/10/15/30 min) + custom stepper (1–120 min), theme picker (4 scene cards), Start button — Layout A per design spec — Phase 2
- ✓ Running timer screen (child-facing): full-screen portrait, zero text/numbers, nothing tappable within any scene — Phase 3
- ✓ Shrinking Disc theme: disc scales down as time passes, green→yellow→red color zones — Phase 3
- ✓ Night to Sunrise theme: sky interpolates night→day, stars/moon fade, sun rises, hill warms — Phase 3
- ✓ Walking Home theme: character walks a path toward a house, arrives at time-up — Phase 3
- ✓ Car on a Road theme: car drives a path toward a destination, arrives at time-up, wheels visibly spin — Phase 3 (gap-closure 03-04)
- ✓ Completed state: soft two-tone chime (mute-gated, plays once), theme settles into end visual, breathing "All done" pill returns to Setup on tap — Phase 4
- ✓ Parent controls overlay: hidden ~850ms long-press on running screen opens a blurred-scrim bottom sheet (Pause/Resume, End timer, Keep watching, mute toggle) — replaces the interim visible back `IconButton` from Phase 3 — Phase 4

### Active

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
- **Sound**: end chime is two soft sine tones (D5 → G5) with a specific envelope, originally generated via Web Audio API — implemented as a pure-Dart WAV synthesizer (`lib/audio/chime_synth.dart`, no bundled asset) played through an `audioplayers`-backed adapter, Phase 4.
- **No image assets** — all visuals in the reference design are built from shape primitives (circles, gradients, rounded rects, CSS-border triangles); Flutter implementation should use CustomPainter/Canvas or similar vector approaches rather than bitmap assets.

## Constraints

- **Tech stack**: Flutter — build on the existing scaffold rather than switching frameworks, despite the design doc's suggestion of React Native/Expo or SwiftUI for greenfield
- **Platform**: Android only for v1 — existing scaffold also supports web, but web is out of scope for this milestone
- **Fidelity**: Visual/behavioral fidelity to `design/README.md` is high-priority — colors, radii, timings, and interaction thresholds (e.g. 850ms long-press) are treated as final, not starting points
- **Distribution**: Intended for eventual Play Store publication — needs to reach a publishable, polished state, not just a personal prototype

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build in Flutter on the existing scaffold, not React Native/SwiftUI as the design doc suggests | Repo already has a working Flutter Hello World scaffold (web + Android); no reason to discard it | ✓ Good — Phase 1 shipped clean with `provider` + `ChangeNotifier`, no framework friction |
| Use wall-clock (`DateTime.now()`) deltas instead of research's recommended `Stopwatch` for the timer engine | `Stopwatch` doesn't reliably count time while the device is backgrounded/asleep on Android, but locked decision D-01 requires the countdown to keep advancing (and reach done) while backgrounded | ✓ Good — Phase 1, verified via background-reconciliation tests |
| Android only for v1 | Simplifies initial scope; existing scaffold supports web too but that's deferred | — Pending |
| Build all 4 themes in the same phase rather than disc-first | Themes share the same underlying timer state machine and color-zone logic; splitting adds phase overhead without much isolation benefit | — Pending |
| Publish to Play Store (not just personal use) | User's stated intent | — Pending |
| SceneGrid owns SceneTheme -> label/painter maps; SceneCard depends only on the ScenePreviewPainter abstraction | Keeps SceneCard decoupled from any concrete painter type so new scene themes plug in without touching card logic (D-06) | ✓ Good — Phase 2 |
| SetupPreferences clamps durationMin to 1..120 and resolves theme via firstWhere(orElse) on load | Persisted SharedPreferences values are untrusted (rooted device / future app version); never trust stored values to be in-range or a valid enum name | ✓ Good — Phase 2 |
| persistIfPreset only ever writes a preset duration, never a custom one | A Custom last-use should always restore to the 5-min default preset on next launch, not a persisted custom number (D-10) | ✓ Good — Phase 2 |
| #E0805F color usage accepted as verification override on Setup screen | Verified against design spec during Phase 2 verification; documented deviation, not a defect | ✓ Accepted — Phase 2 |
| All 4 scenes share one `SceneRenderer`/per-scene `Ticker` contract, each painter a pure function of `TimerController.progress` plus a decorative loop phase | One shared animation spine avoids 4 divergent `AnimationController` implementations and keeps scenes swappable via `scene_registry.sceneFor` | ✓ Good — Phase 3 |
| Car wheel spin made visible via a single asymmetric spoke marking (reusing the two already-locked wheel colors), deviating from the design source's rotationally-symmetric wheel | The literal prototype's CSS-rotated plain circle has an identical raster at every angle, so a code review (CR-01/Truth #8) caught the spin as a visual no-op; user approved the minimal fix over silently shipping an invisible animation | ✓ Good — Phase 3 gap-closure 03-04 |
| `ChimePlayer`/`NoopChimePlayer`/`AudioplayersChimePlayer` mirrors the existing `ScreenWake`/`WakelockScreenWake` interface-wraps-a-plugin shape exactly | Keeps the codebase's plugin-isolation pattern consistent — only one file per feature imports the underlying platform plugin, everything else depends on a plugin-free interface | ✓ Good — Phase 4 |
| `audioplayers` package approved via direct pub.dev verification (blue-fire.xyz verified publisher, 1M+ downloads) at a blocking human checkpoint before install | Pub.dev packages fall outside automated npm/pip/cargo legitimacy tooling, so new pub dependencies get a manual look before `flutter pub add` | ✓ Good — Phase 4 |
| `SceneRenderer`'s decorative loop phase accumulates an offset across `Ticker` stop/restart segments instead of resetting to 0 | Carried-forward Phase 3 defect (D-10): loops would visibly snap back to their start phase every time Pause/Resume stopped and restarted the ticker | ✓ Good — Phase 4 |
| Parent Controls sheet buttons use the codebase's `PressableSurface` widget (not plain `ElevatedButton`) | Code review (WR-03) found plain `ElevatedButton` never applied the UI-SPEC's locked pressed-state colors; `PressableSurface` is the established pattern for that | ✓ Good — Phase 4 code review fix |

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
*Last updated: 2026-07-09 after Phase 4: Parent Controls & Completion*
