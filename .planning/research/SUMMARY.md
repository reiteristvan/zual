# Project Research Summary

**Project:** Zual
**Domain:** Mobile app (Flutter) — visual/wordless countdown timer for young children
**Researched:** 2026-07-06
**Confidence:** MEDIUM

## Executive Summary

Zual is a technically straightforward but precision-dependent Flutter app: a single animated
full-screen countdown timer driven by wall-clock elapsed time, rendered via `CustomPainter`,
with four swappable wordless scene themes and a hidden parent-controls overlay. The recommended
approach is a state-machine-first architecture — one shared `TimerController` (via `provider`)
exposing `phase`/`progress`/`theme`/`duration` — with a `SceneRenderer` contract that decouples
timer logic from theme-specific rendering, so a 5th theme later is just a new folder and one
registry line.

The stack is proven and minimal: Flutter 3.38.7 (verified against the local toolchain), `provider`
for state, built-in `CustomPainter`/`AnimationController` for rendering (no game engine or
animation package needed), `audioplayers` for the completion chime, and `wakelock_plus` to keep
the screen awake during a run. No exotic dependencies, no network, no backend.

The main risks are execution risks, not technology risks: timing drift if the countdown is driven
by `AnimationController.duration` instead of wall-clock time, performance jank if scenes use deep
widget trees instead of a single `CustomPainter` per scene, and battery/lifecycle bugs if wakelock
and controller disposal aren't centralized to the running phase's lifecycle. All three are
addressed by getting the timer/state-machine foundation right in Phase 1 before any scene work
begins.

## Key Findings

### Recommended Stack

Flutter SDK built-ins cover rendering and animation entirely (`CustomPainter`/`Canvas` for shapes,
gradients, shadows; `AnimationController` for the progress-driven loop, replacing the HTML
prototype's `requestAnimationFrame`). State management uses one shared `ChangeNotifier`, which is
enough for this app's single-controller shape — Riverpod/Bloc were considered and rejected as
premature complexity.

**Core technologies:**
- Flutter 3.38.7 / Dart 3.10.7 — matches the already-scaffolded project, verified against local toolchain
- `provider ^6.1.5` — wraps the single `TimerController extends ChangeNotifier` state machine, matches Flutter's own low-ceremony architecture guidance
- `CustomPainter` + `AnimationController` (Flutter SDK, no package) — renders all 4 scenes and drives progress-based animation
- `audioplayers ^6.8.1` — plays a bundled two-tone WAV for the completion chime (beats `just_audio`/`flutter_soloud` for a simple one-shot calm sound)
- `wakelock_plus ^1.6.1` — keeps the screen on during a running timer
- `shared_preferences ^2.5.5` — optional local persistence of last-used duration/theme (no backend, matches PROJECT.md constraints)
- Bundle Baloo 2 / Quicksand `.ttf` fonts directly via `pubspec.yaml` `fonts:` — skip the `google_fonts` package since it has a runtime HTTP-fetch path this fully offline app doesn't want

### Expected Features

Competitor analysis (Time Timer and similar wordless countdown apps) validates the existing
PROJECT.md scope almost entirely, with two notable gaps surfaced by research.

**Must have (table stakes):**
- Shrinking/spatial time metaphor as the primary, evidence-backed pattern (Disc theme is correctly the anchor/hero)
- Calm, non-alarming completion signal (soft chime, no celebration) — matches PROJECT.md exactly
- A way to mute/control sound — **gap**: design doc references a `soundOn` toggle but never places it in any screen; recommend adding a mute control to the Parent Controls sheet

**Should have (competitive):**
- Remember last-used duration + theme locally — currently framed as an "optional nicety" in PROJECT.md; research recommends promoting this to actual v1 scope (low complexity, local-storage-only, addresses a common competitor complaint)
- 4 distinct wordless scene metaphors (most competitors only offer one disc/wedge) — already a planned differentiator
- Hidden 850ms long-press gate for parent controls, vs. competitors' visible/child-reachable settings icons — already planned, validated as a genuine differentiator

**Defer (v2+):**
- Accessibility audit of the disc's green→yellow→red color zones for colorblind users (size-based shrinking already provides a safe primary cue — this is polish, not a launch blocker)

The existing Out-of-Scope list (accounts, gamification/rewards, celebratory sounds, landscape,
ads, chore lists) is validated by research: apps in this category that add these directly
undermine the calm positioning that this audience (including sensory-sensitive/ADHD/autistic
children, a meaningful share of this category's users) needs.

### Architecture Approach

A single `TimerController extends ChangeNotifier` (in a Flutter-Material-free `timer/` layer) is
the shared state machine for `phase` (setup/running/paused/done), `progress`, `theme`, and
`duration`, exposed via `ChangeNotifierProvider`. Elapsed time uses `Stopwatch` rather than manual
`DateTime` delta bookkeeping — `Stopwatch.stop()`/`start()` naturally excludes paused intervals,
eliminating a class of pause/resume bugs the HTML prototype's manual approach invites. A
`SceneRenderer` contract (every theme widget takes only `progress: double`) plus a single
`scene_registry.dart` is the one place that switches over theme — used by both the running screen
and the setup screen's preview thumbnails.

**Major components:**
1. `TimerController` (ChangeNotifier) — phase/progress/duration/theme state machine, wall-clock timing, pause/resume bookkeeping, app-lifecycle handling
2. `SceneRenderer` contract + `scene_registry.dart` — theme-to-renderer mapping; each scene is an independent `CustomPainter` driven only by `progress`
3. `RunningScreen` — single composition root for running/paused/done (not three separate screens); hosts the active scene, the hidden long-press layer, the parent-controls bottom sheet, and the done pill
4. `SetupScreen` — duration presets/stepper, theme picker (using the same scene registry for thumbnails), Start button
5. `ChimePlayer` — isolated interface around `audioplayers` for the completion sound, decoupled from timer logic

### Critical Pitfalls

1. **Timing drift from `AnimationController.duration`** — drifts over multi-minute runs and doesn't compose cleanly with pause/resume or backgrounding; use wall-clock elapsed time (`Stopwatch`/`Timer.periodic`) instead. Address in Phase 1.
2. **Missing app-lifecycle handling** — the existing scaffold has no `AppLifecycleState`/`WidgetsBindingObserver` handling; critical for a timer that can run up to 120 minutes and may be backgrounded. Address in Phase 1.
3. **CustomPainter performance jank** — deep widget-tree animation will jank on low-end Android devices; each scene must be a single `CustomPainter` with disciplined `shouldRepaint`. Validate with the Disc reference implementation on a real low/mid-end device (API 24–28), not just emulator.
4. **Wakelock/controller lifecycle leaks** — easy to leak battery drain across multiple exit paths (completion, "End timer," backgrounding); scope wakelock enable/disable and controller disposal tightly to the running phase's lifecycle (`dispose()`, guaranteed on all exit paths).
5. **Testing looping animations** — the four looping decorative animations (bob/spin/twinkle/breathe) will hang `tester.pumpAndSettle()` in widget tests; use `tester.pump(duration)` instead.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Timer / State-Machine Foundation
**Rationale:** Nothing else can be built or meaningfully tested until phase/progress semantics are locked; this is the highest-leverage phase since every scene and the parent-controls pause/resume depend on it.
**Delivers:** `TimerController` (setup/running/paused/done phases), wall-clock-based progress calculation, pause/resume bookkeeping, `AppLifecycleState` handling, wakelock lifecycle scoping — fully unit-tested without any UI.
**Addresses:** Core countdown behavior from PROJECT.md.
**Avoids:** Pitfalls 1, 2, 4 (timing drift, lifecycle gaps, wakelock/disposal leaks).

### Phase 2: Setup Screen
**Rationale:** Depends only on `TimerController.start()` existing; independent of running-screen/scene concerns, can proceed in parallel with Phase 3 once Phase 1 lands.
**Delivers:** Duration presets + custom stepper, theme picker (2×2 grid), Start button, optional read of last-used duration/theme.
**Uses:** `provider`, `shared_preferences` (if persistence bundled here).
**Implements:** `SetupScreen` component.

### Phase 3: Shrinking Disc Theme (Reference Implementation)
**Rationale:** Establishes the `CustomPainter` + progress-driven repaint pattern for all scenes; simplest scene, so it validates the `SceneRenderer` contract before the other three themes are built.
**Delivers:** Disc scene renderer (scale + green→yellow→red color zones), `SceneRenderer` contract, `scene_registry.dart`.
**Addresses:** Performance-critical pattern validation (Pitfall 3) — real low-end Android device testing here, before replicating the pattern.

### Phase 4: Remaining Three Scene Themes
**Rationale:** Reuse the Disc pattern proven in Phase 3; themes share no code with each other, only the `SceneRenderer` contract, so this is straightforward to parallelize.
**Delivers:** Night-to-Sunrise, Walking Home, Car on Road scene renderers.
**Implements:** Each as an independent `CustomPainter` implementing `SceneRenderer`.

### Phase 5: Parent Controls, Completed State, Mute Toggle
**Rationale:** Depends on `RunningScreen` and at least one scene existing; bundles the remaining interactive/behavioral surface (long-press gesture, bottom sheet, done state, chime, mute).
**Delivers:** Hidden 850ms long-press gesture (custom threshold via `RawGestureDetector`/`LongPressGestureRecognizer`), Parent Controls bottom sheet (Pause/Resume, End timer, Keep watching, mute toggle — closing the sound-control gap from Features research), done-pill return affordance, two-tone completion chime via `ChimePlayer`/`audioplayers`.
**Avoids:** Pitfall 5 (testing looping animations correctly).

### Phase 6: Local Persistence (if not folded into Phase 2)
**Rationale:** Low complexity, low risk — can slip independently without blocking other phases.
**Delivers:** `shared_preferences`-based remember-last-duration-and-theme.

### Phase 7: Play Store Readiness
**Rationale:** Must be a hard gate, not a formality — the scaffold currently has placeholder `applicationId`/debug signing (per `.planning/codebase/CONCERNS.md`).
**Delivers:** Real `applicationId`, production signing config, target-audience/content-rating (IARC) declaration and Families Policy compliance review, 120-minute battery/lifecycle verification pass, CI-pinned golden tests.

### Phase Ordering Rationale

- Timer/state-machine logic must be correct and lifecycle-safe before any scene renders against it — every downstream phase consumes `TimerController.progress`.
- The Disc theme is built alone first specifically to prove the `SceneRenderer` contract and catch performance issues on real hardware before three more scenes are built against the same pattern.
- Setup Screen has no dependency on scene rendering internals (only the registry for thumbnails) and can proceed alongside Phase 3/4 once Phase 1 is done.
- Parent Controls/Completed/mute are grouped together since they're all "running screen surface" concerns that depend on scenes existing but are otherwise independent of which scene is active.
- Play Store readiness is deliberately last — content-rating and signing decisions are cheap to get right once but expensive to redo, so they're treated as a dedicated gate rather than scattered checklist items.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** Wall-clock timing accuracy validation across multi-minute runs; `AppLifecycleState` handling across real device backgrounding scenarios
- **Phase 3:** Real low/mid-end Android device performance testing (API 24–28); first-run shader compilation jank
- **Phase 4:** Integrating decorative loop animations (twinkle/spin/bob) with the shared progress timeline without frame-time regressions, especially the Sunrise scene (28 stars + gradient, the most complex)
- **Phase 5:** 850ms long-press gesture threshold implementation approach (`LongPressGestureRecognizer(duration:)` vs. manual pan-tracking); chime audio envelope verification (must not sound harsh)
- **Phase 7:** Play Store Families Policy specifics (re-verify at submission time — policy wording changes); CI golden-test platform pinning

Phases with standard patterns (skip research-phase):
- **Phase 2:** Setup screen with `provider` and simple widget forms — well-documented Flutter patterns
- **Phase 6:** `shared_preferences` local storage — standard, low-risk Flutter pattern

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Flutter 3.38.7 verified against local toolchain; all rendering/animation/state patterns confirmed via official Flutter docs (Context7) |
| Features | MEDIUM | Competitor/market analysis converges across multiple independent sources; no primary user testing with actual parents/children |
| Architecture | MEDIUM | Core Flutter patterns (ChangeNotifier, CustomPainter, provider) verified via official docs; folder structure is community convention, not authoritative |
| Pitfalls | MEDIUM | Flutter framework mechanics confirmed via official docs; Play Store policy and package-ecosystem comparisons are web-sourced and need re-verification closer to submission |

**Overall confidence:** MEDIUM — the project is technically straightforward with proven, low-risk Flutter patterns, but correct execution of foundational details (wall-clock timing, lifecycle handling, CustomPainter discipline) is what determines success, not tool selection.

### Gaps to Address

- **User validation**: Features research is competitor-based, not primary research with actual parents/children — recommend a small validation pass (5–10 parent interviews or informal testing) once the Setup/Disc phases exist, particularly to confirm the 850ms long-press is discoverable/intuitive for parents. Not a launch blocker.
- **Low-end device performance baseline**: Needs testing on a real Android device (API 24–28), not just emulator, before committing to the CustomPainter approach across all 4 scenes — acquire or arrange device-farm access before Phase 3.
- **Audio implementation approach**: Bundled WAV vs. synthesized tone for the chime is not yet decided — resolve behind the `ChimePlayer` interface during Phase 5 planning; low risk either way.
- **Play Store target-audience declaration**: Whether to formally declare "Children" as part of the target audience in Play Console is a deliberate product decision (Families Policy tradeoffs) that should be made explicitly during Phase 7 planning, not defaulted.

## Sources

### Primary (HIGH confidence)
- Context7 `/flutter/website` — CustomPainter, AnimationController, AppLifecycleState, RepaintBoundary, shouldRepaint
- Local toolchain (`flutter --version`) — Flutter 3.38.7 / Dart 3.10.7 ground truth
- `.planning/codebase/STACK.md`, `ARCHITECTURE.md`, `CONCERNS.md` — existing scaffold state (verified via codebase mapping, not inference)
- `design/README.md` — exact visual/behavioral/state-machine specification

### Secondary (MEDIUM confidence)
- pub.dev package pages (`provider`, `audioplayers`, `wakelock_plus`, `shared_preferences`) — version and capability verification
- Competitor app analysis (Time Timer and similar wordless timer apps) — table stakes/differentiator/anti-feature validation

### Tertiary (LOW confidence)
- Web-sourced community comparisons (audioplayers vs. just_audio vs. flutter_soloud; Provider vs. Riverpod vs. Bloc; folder structure conventions) — used only to support reasoning already grounded in official docs
- Play Store Families Policy specifics — policy wording changes over time, re-verify in Play Console at actual publish-readiness time

---
*Research completed: 2026-07-06*
*Ready for roadmap: yes*
