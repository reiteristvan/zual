# Phase 4: Parent Controls & Completion - Context

**Gathered:** 2026-07-08
**Status:** Ready for planning

<domain>
## Phase Boundary

A hidden ~850ms long-press anywhere on the running screen opens a Parent Controls bottom
sheet (Pause/Resume, End timer, Keep watching, sound mute toggle). This sheet **replaces**
the interim visible back `IconButton` that Phase 3 left on `RunningScreen` as scaffolding —
that button goes away entirely in this phase. On completion, a soft two-tone chime plays
(unless muted) and the active scene settles into its end visual; a gently breathing "All
done" pill appears and returns to Setup when the parent taps it. Requirements: CTRL-01
through CTRL-04.

This phase also fixes a carried-forward defect from Phase 3: `SceneRenderer`'s decorative
loop phase (twinkle/bob/spin) resets to 0 whenever its `Ticker` stops/restarts, which will
visibly snap once Pause/Resume is wired to real UI in this phase (see D-09 below).

Out of this phase's scope: the four scenes' progress-driven visuals (Phase 3, done), Play
Store readiness (Phase 5).

</domain>

<decisions>
## Implementation Decisions

### Mute toggle
- **D-01:** The mute toggle is a small icon button in the Parent Controls sheet header
  (near the grab handle/title), not a full-width row — keeps Pause/Resume and End timer as
  the visually dominant actions, consistent with `design/README.md` §G's sheet not drawing
  a mute control at all (REQUIREMENTS.md's CTRL-02 adds it beyond the literal design).
- **D-02:** Mute state persists across app restarts via the same mechanism already used for
  last-used duration + theme (PERSIST-01 / `shared_preferences`) — a parent who mutes it
  wants it to stay muted on a shared bedroom device.
- **D-03:** Use standard Material speaker icons (`Icons.volume_up` / `Icons.volume_off`),
  consistent with the app's existing Material Icons usage.
- **D-04:** Default state on first launch (no persisted preference yet) is **unmuted**
  (sound on) — matches the design doc's default; the chime is core to the calm-completion
  experience and a parent must actively opt out.

### Chime sound implementation
- **D-05:** The chime is a **real-time synthesized tone**, not a pre-rendered bundled audio
  asset — closer to the design doc's original Web Audio API mechanism (two sine tones, D5
  587.33 Hz → G5 783.99 Hz, ~0.3s apart, gain ramp to ~0.16 over 60ms then exponential decay
  to ~0 over ~1.1s, per `design/README.md` §"End chime"). Research/planner select the
  concrete Flutter package or platform-channel approach for real-time tone synthesis.
- **D-06:** The chime plays through the standard media/notification audio channel and
  respects the device's silent/vibrate switch and system media volume — it must not
  override a phone setting the parent intentionally set.
- **D-07:** If the app returns to foreground already in the `done` phase (timer finished
  while backgrounded), the chime still plays on that first foreground reveal — confirms
  Phase 1's D-02 (nothing fires while backgrounded; the chime is the foreground-reveal
  event) still applies now that Phase 4 implements the actual sound.

### Long-press hold feedback
- **D-08:** The 850ms hold is **fully silent/invisible** until it fires — no scrim, ripple,
  or other build-up affordance during the hold. Matches `design/README.md` §G exactly ("the
  child can't reach it with a normal tap"); adding a visible cue during the hold would make
  the gesture more discoverable to a curious child, which is undesirable.
- **D-09:** Once the timer reaches the completed "All done" state, long-press does
  **nothing** — Parent Controls (Pause/Resume, End timer) only apply during
  running/paused. The single-tap "All done" pill is the only interactive affordance once
  done.

### Decorative loop continuity on pause/resume (Phase 3 carried defect, STATE.md)
- **D-10:** Fix the snap: `SceneRenderer`'s decorative loops (star twinkle, character/car
  bob, wheel spin) must resume from the same loop-phase they were frozen at when paused,
  not restart from phase=0. Phase 4 is the natural moment to fix this, since Pause/Resume
  gets wired to real UI for the first time here. Preserves the "timer paused = scene frozen"
  mental model already established in Phase 3 — a resumed loop should continue seamlessly,
  not visibly jump.

### Claude's Discretion
- Exact Flutter package/mechanism for real-time tone synthesis (D-05) — a technical
  implementation detail; research should evaluate options against the "respects silent
  mode" constraint (D-06).
- Exact fix mechanism for the loop-phase freeze/resume (D-10) — e.g., tracking a
  `_pausedAtElapsed` offset in `SceneRendererState` and subtracting it on restart — an
  implementation detail, not a product-facing gray area.
- Bottom sheet visual details not already locked by `design/README.md` §G (sheet
  `#FBF4E8`, `border-radius:30px 30px 0 0`, grab handle, scrim `rgba(40,32,26,0.42)` + 3px
  blur, button colors `#7FA87A`/`#E0805F`) — those are final; only the mute icon's exact
  padding/placement within the header is Claude's call.
- Whether `GestureDetector.onLongPress` tolerates minor finger drift during the hold — use
  Flutter's standard long-press recognizer defaults, not a custom slop tolerance.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and requirements
- `.planning/PROJECT.md` — full project context, core value, constraints
- `.planning/REQUIREMENTS.md` — CTRL-01 through CTRL-04 (this phase's requirements)
- `.planning/ROADMAP.md` — Phase 4 goal and success criteria

### Design specification
- `design/README.md` §"G. Parent Controls" — hidden long-press trigger, bottom sheet
  layout/colors/radius, Pause/Resume + End timer + Keep watching buttons (mute toggle is
  an addition beyond this section, per D-01 through D-04)
- `design/README.md` §"H. Completed" — chime + end-state settle + breathing "All done" pill
  spec, exact colors/radius/padding/animation timing
- `design/README.md` §"Interactions & Behavior" — "Long-press → controls" (850ms threshold,
  release-before-threshold = nothing) and "End chime (calm)" (exact tone frequencies,
  envelope, `soundOn` toggle) subsections
- `design/README.md` §"Design Tokens" — sheet/scrim/pill colors, radii, shadows referenced
  by this phase's UI

### Prior phase context (carried forward)
- `.planning/STATE.md` Blockers/Concerns — "SceneRenderer's loopPhase resets to 0 on ticker
  stop/restart ... must be addressed when Phase 4 wires Pause/Resume" (source of D-10)
- `.planning/phases/03-scene-themes/03-CONTEXT.md` — decorative loop discretion note:
  "should default to pausing decorative loops whenever the timer itself is paused, for
  consistency with the 'timer paused = scene frozen' mental model" — D-10 extends this to
  cover the resume side of that same model
- `.planning/phases/02-setup-screen/02-CONTEXT.md` D-09/D-10 — PERSIST-01 precedent (low-
  surprise defaults, `shared_preferences`) that D-02/D-04 follow for mute state

### Existing codebase state
- `lib/timer/timer_controller.dart` — `pause()`, `resume()`, `endTimer()`, `phase`,
  `progress` already implemented and tested (built ahead of UI in Phase 1); this phase wires
  real UI to these existing methods, no TimerController API changes anticipated
- `lib/screens/running_screen.dart` — hosts the interim visible back `IconButton` (lines
  79-92) that this phase's long-press + bottom sheet **replaces**; also owns the
  auto-pop-on-done logic (`_maybeAutoPopWhenDone`) that must change so the screen shows the
  settled scene + breathing pill instead of immediately popping (CTRL-03/CTRL-04)
- `lib/scenes/scene_renderer.dart` — `SceneRendererState`'s `_ticker`/`loopPhase` /
  `didChangeDependencies` (lines 31-81) is exactly where D-10's freeze/resume fix applies
- `pubspec.yaml` — no audio package present yet; D-05/D-06 require adding one during
  research/planning
- `.planning/codebase/CONVENTIONS.md` — Dart/Flutter naming, formatting conventions to follow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TimerController` (`lib/timer/timer_controller.dart`) already exposes fully-tested
  `pause()`, `resume()`, `endTimer()` — Parent Controls sheet buttons call these directly,
  no new controller logic needed for the pause/resume/end actions themselves.
- `AppTokens` (`lib/theme/app_tokens.dart`) — existing design-token constants (colors,
  radii) from Phase 2, reusable for the sheet/scrim/pill styling.

### Established Patterns
- `SceneRendererState` (`lib/scenes/scene_renderer.dart`) is the single shared base every
  scene extends — the loop-phase freeze/resume fix (D-10) belongs here once, not
  per-scene, consistent with the "one shared animation spine" pattern from Phase 3's
  `03-CONTEXT.md`.
- `scene_registry.sceneFor` maps `SceneTheme` to concrete scene widgets — the completion
  end-state ("disc fully gone / full sunrise / character at the door / car arrived") is
  already reachable since each scene is a pure function of `progress`, and `progress` is
  already clamped to 1.0 at `TimerPhase.done` (`timer_controller.dart`'s
  `_progressHighWaterMark = 1.0` in `syncToWallClock`).

### Integration Points
- `lib/screens/running_screen.dart` is the sole integration point for both the long-press
  gesture detector + bottom sheet AND the completion pill/chime — per its own doc comment,
  composition-root responsibilities (gestures, navigation) live here, never inside a scene.
- No existing mute-state persistence key exists yet in `lib/settings/setup_preferences.dart`
  — D-02 likely extends this file (or a sibling) with a new persisted boolean, following its
  existing load/persist pattern from Phase 2.

</code_context>

<specifics>
## Specific Ideas

No specific implementation-style references beyond `design/README.md` §§G–H and the
"Interactions & Behavior" section, which are final and exact for the sheet layout, chime
tone frequencies/envelope, and completion pill styling/timing. The mute toggle's exact
icon/placement (D-01, D-03) is the one UI element added beyond the literal design doc.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. Play Store readiness (app identity, signing,
listing assets) remains explicitly Phase 5's concern.

</deferred>

---

*Phase: 4-Parent Controls & Completion*
*Context gathered: 2026-07-08*
