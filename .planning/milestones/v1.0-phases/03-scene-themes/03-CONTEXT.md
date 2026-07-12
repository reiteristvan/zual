# Phase 3: Scene Themes - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

The four full-screen, wordless, child-facing running scenes (Shrinking Disc, Night to
Sunrise, Walking Home, Car on a Road) that render the active timer's progress. Each scene
is a pure function of the shared `0..1` progress value exposed by `TimerController`
(Phase 1) — no scene owns timer state, gestures, or navigation. Requirements: SCENE-01
through SCENE-05.

Parent Controls (hidden long-press, bottom sheet), the completion chime, and the "All
done" pill are Phase 4's job — this phase's scenes only need to reach a calm, correct
*end state* at progress=1 for Phase 4 to layer controls/chime on top of. The placeholder
running screen from Phase 2 is what this phase's real `RunningScreen` + `SceneRenderer`
implementations replace.

</domain>

<decisions>
## Implementation Decisions

### Scene visual fidelity
- **D-01:** All four scenes' colors, geometry, thresholds, and motion formulas are treated
  as final per `design/README.md` §§C–F — this was not re-litigated in discussion (per
  project Constraints: "Fidelity ... treated as final, not starting points"). The color-zone
  thresholds for Shrinking Disc (`r > 0.5` green, `0.2 < r ≤ 0.5` yellow→green lerp,
  `r ≤ 0.2` red→yellow lerp), the sky/star/moon/sun/hill formulas for Night to Sunrise, and
  the `left = 6 + p*62%` arrival mechanic for Walking Home / Car on a Road are locked
  exactly as written in the design doc — no gray area here.

### Decorative loop-animation feel (star twinkle, character bob, wheel spin)
- **D-02:** Design doc specifies these motions qualitatively ("gentle twinkle", "gentle
  vertical bob", "spinning wheels") without exact timings. Recommended default: subtle and
  slow — twinkle a soft opacity pulse (~2–3s cycle), walk/car bob a small amplitude (a few
  px) at a gentle cadence, wheel spin continuous but unhurried. These are decorative loops
  independent of the shared progress-driven `TickerProviderStateMixin` per Phase 1
  research's `ARCHITECTURE.md`, tuned for the app's calm, non-distracting tone — never
  fast/bouncy/attention-grabbing, consistent with "playful but calm" from PROJECT.md.

### Smooth-animation validation approach (SCENE-05: no visible jank on mid/low-end Android)
- **D-03:** No automated pixel-diff or frame-timing tooling exists in this project
  (confirmed absent during Phase 2 verification). Recommended approach, consistent with
  Phase 2's established pattern (`workflow.human_verify_mode: end-of-phase`): automated
  widget tests cover progress-driven correctness (color-zone thresholds, arrival-at-p=1,
  `shouldRepaint` boundaries, no exceptions across the full 0..1 range) as the CI-checkable
  layer; actual "smooth, no jank" perceptual validation is a human end-of-phase check on a
  real low/mid-end Android device (API 24–28) — already flagged as a Blocker/Concern in
  STATE.md for this phase.

### Claude's Discretion
- Exact file/class structure for the four scene widgets and their painters (already
  strongly guided by `.planning/research/ARCHITECTURE.md`'s `SceneRenderer` contract and
  `scenes/<theme>/` folder layout) — a technical/architectural detail, not a product
  decision.
- Negative-opacity clamping and other formula edge cases (e.g., the star fade formula
  `opacity = 1 − p*2.3` goes negative before p=1) — implementation-level correctness detail,
  not a product-facing gray area.
- Whether decorative loop `AnimationController`s pause/dispose alongside the shared
  `TimerController`'s paused/done phases, or keep running independently while paused —
  technical lifecycle detail; should default to pausing decorative loops whenever the timer
  itself is paused, for consistency with the "timer paused = scene frozen" mental model.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and requirements
- `.planning/PROJECT.md` — full project context, core value, constraints
- `.planning/REQUIREMENTS.md` — SCENE-01 through SCENE-05 (this phase's requirements)
- `.planning/ROADMAP.md` — Phase 3 goal and success criteria

### Design specification
- `design/README.md` §"C. Running — Shrinking Disc" — exact disc scale/color-zone formulas
- `design/README.md` §"D. Running — Night to Sunrise" — exact sky/star/moon/sun/hill formulas
- `design/README.md` §"E. Running — Walking Home" — exact path/house/character mechanics
- `design/README.md` §"F. Running — Car on a Road" — exact path/road/car mechanics
- `design/README.md` §"Design Tokens" — colors, shadows, spacing referenced by all 4 scenes
- `design/Zual.dc.html` — interactive prototype; view scenes in motion (reference only, not
  code to port)

### Project-level research (already resolves most technical gray areas for this phase)
- `.planning/research/ARCHITECTURE.md` §"Pattern 2: SceneRenderer contract" — the
  progress-in/pixels-out contract every scene implements; `scene_registry.dart` extension
  point; Anti-Pattern 1 (scenes must never reach into `TimerController` directly)
- `.planning/research/PITFALLS.md` — check for scene-specific animation/timing pitfalls
  noted at project-research time

### Prior phase context (carried forward)
- `.planning/phases/02-setup-screen/02-CONTEXT.md` D-05/D-06 — the 4 static mini-preview
  painters (`ScenePreviewPainter` abstraction, `lib/scenes/scene_preview.dart`) this phase's
  real scenes are the animated counterpart to; D-06's abstraction-boundary discipline
  (SceneGrid/SceneCard depend only on the abstraction, never a concrete painter) is the same
  discipline this phase's `SceneRenderer` contract must uphold for `RunningScreen`.

### Existing codebase state
- `lib/timer/timer_controller.dart` — `progress`, `phase`, `theme` getters this phase's
  scenes and `RunningScreen` consume
- `lib/scenes/scene_theme.dart` — existing `SceneTheme` enum (`disc | sunrise | walk | car`)
- `lib/scenes/scene_preview.dart` — existing static preview painters/colors per theme,
  reusable as a starting palette reference for the real animated scenes
- `lib/screens/placeholder_running_screen.dart` — the Phase 2 stand-in this phase's real
  `RunningScreen` replaces
- `.planning/codebase/CONVENTIONS.md` — Dart/Flutter naming, formatting conventions to follow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TimerController` (`lib/timer/timer_controller.dart`) — already exposes `progress`,
  `phase`, `theme`; no changes needed for this phase to consume it.
- `SceneTheme` enum (`lib/scenes/scene_theme.dart`) — already defines the 4 theme values;
  this phase's `scene_registry.dart`-style switch will map each to its real animated scene.
- `lib/scenes/scene_preview.dart` — the 4 static preview painters already transcribe the
  exact colors/geometry from the design doc for each theme at rest; useful as a
  cross-reference for color values when building the real animated painters (though the
  real scenes are full-screen and progress-driven, not 74px static previews).

### Established Patterns
- `ScenePreviewPainter` abstract base (D-06 from Phase 2) demonstrates the project's
  established discipline: consumers depend on an abstraction, never a concrete painter
  type. This phase's `SceneRenderer` contract (per `ARCHITECTURE.md`) extends the same
  discipline to the full animated scenes.
- No `lib/scenes/<theme>/` per-theme subfolder structure exists yet — currently
  `scene_preview.dart` and `scene_theme.dart` are flat files in `lib/scenes/`.

### Integration Points
- `lib/screens/placeholder_running_screen.dart` is what this phase's real `RunningScreen`
  (hosting the active `SceneRenderer`) replaces as Start's navigation destination.
- `TimerController.progress`/`phase` are the sole inputs scenes need — no new state-layer
  changes anticipated for this phase.

</code_context>

<specifics>
## Specific Ideas

No specific implementation-style references beyond `design/README.md` §§C–F, which are
final and exact for colors, geometry, and motion formulas. Decorative loop-animation feel
(D-02) should read as calm/gentle, never fast or bouncy, consistent with the app's
"playful but calm" tone from PROJECT.md.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. Parent Controls, chime, and the "All done"
pill are explicitly Phase 4 concerns (already scoped there in ROADMAP.md), not folded into
Phase 3.

</deferred>

---

*Phase: 3-Scene Themes*
*Context gathered: 2026-07-07*
