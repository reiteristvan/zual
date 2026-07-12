# Phase 2: Setup Screen - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

A parent-facing configuration screen where a parent picks a duration (preset or custom
1–120 min stepper) and one of 4 scene themes, then taps Start to launch the timer with
those settings. Matches Layout A from the design spec pixel-accurately. Remembers the
last-used duration and theme across launches. Requirements: SETUP-01 through SETUP-05,
PERSIST-01.

Scene Themes (the actual animated running-screen visuals) are Phase 3's job — this phase
only needs a minimal stand-in destination for Start to prove the setup→running transition
works, plus static mini-previews for the scene-picker cards.

</domain>

<decisions>
## Implementation Decisions

### Running-screen placeholder (Start destination)
- **D-01:** Start navigates to a minimal, inert placeholder running screen — full-screen,
  no text/numbers (consistent with the child-facing constraint even as a stub). It shows
  progress advancing over time via a plain shrinking-circle style indicator, with no color
  zones or polish (that refinement belongs to Phase 3's real Shrinking Disc theme).
- **D-02:** The placeholder has one small, always-visible escape hatch (e.g. a plain
  top-left back control) that calls `TimerController.endTimer()` and returns to Setup. This
  is explicitly not the real Parent Controls UX (hidden 850ms long-press, bottom sheet) —
  that's Phase 4's job. It exists only so the screen is usable/testable before Phase 4 lands.
- **D-03:** No long-press gesture, no bottom sheet, no pause/resume affordance in this
  phase's placeholder — completely out of scope until Phase 4.
- **D-04:** When the controller reaches `TimerPhase.done`, the placeholder auto-navigates
  back to Setup. No chime, no "All done" pill (Phase 4 scope) — just close the loop simply.

### Scene thumbnail previews
- **D-05:** Build simplified static mini-previews for each of the 4 scene cards (74px per
  design) — not animated, but visually representative of each theme at rest: a solid green
  circle for Disc, a small night→day gradient swatch for Sunrise, a tiny ground+house
  silhouette for Walk, a tiny road+car silhouette for Car. Use the exact colors from
  `design/README.md`'s Design Tokens section for each.
- **D-06:** Structure each mini-preview as its own isolated painter/widget per theme (not
  inlined into the grid/card layout code), so Phase 3 can later swap in "render the real
  scene painter at progress=0, scaled to 74px" without touching the Setup screen's card or
  grid code. The Setup screen should depend on a per-theme preview abstraction, not on each
  theme's literal implementation details.

### Custom stepper feel
- **D-07:** Tapping − or + changes the value by exactly 1 minute. Holding either button
  repeats and accelerates the rate the longer it's held, so reaching either end of the
  1–120 range doesn't require up to 119 individual taps.
- **D-08:** The − button disables (visually greyed, non-interactive) at 1 minute; the +
  button disables at 120 minutes. Clear affordance that the range edge has been reached.

### Defaults & persistence
- **D-09:** On a very first launch (no persisted "last used" value yet), the Shrinking Disc
  theme is pre-selected by default — it's the design doc's designated anchor/hero scene, a
  low-surprise default. Default duration remains 5 min per the design spec.
- **D-10:** Persistence (PERSIST-01) only remembers preset durations and the last-used
  theme. If a Custom value was last used, relaunching does NOT reopen the custom stepper
  with that exact value — it falls back to the nearest/default preset instead. Simpler
  persisted state; "last used" is scoped to presets only.

### Claude's Discretion
- Persistence mechanism (`shared_preferences` vs alternative local key-value storage) — a
  technical implementation detail, not a product decision.
- Font bundling approach for Baloo 2 + Quicksand (bundled asset fonts vs a fonts package) —
  technical detail; app should work fully offline so prefer an approach that doesn't require
  network access at runtime.
- Exact shape/geometry of the placeholder running screen's progress indicator, as long as it
  reads as "a shrinking circle" and shows zero text/numbers.
- Exact "nearest preset" fallback logic when Custom was last used (e.g., round to closest of
  1/5/10/15/30, or always fall back to the 5-min default) — an edge-case detail, not a
  product-facing gray area the user needs to weigh in on.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and requirements
- `.planning/PROJECT.md` — full project context, core value, constraints
- `.planning/REQUIREMENTS.md` — SETUP-01 through SETUP-05, PERSIST-01 (this phase's requirements)
- `.planning/ROADMAP.md` — Phase 2 goal and success criteria

### Design specification
- `design/README.md` §"A. Setup — Layout A (default)" — the exact layout, spacing, colors,
  radii, and button behavior for the screen this phase builds. Treat as final, pixel-accurate spec.
- `design/README.md` §"Design Tokens" — colors, typography (Baloo 2 + Quicksand), radii,
  shadows, spacing values referenced throughout Layout A.
- `design/README.md` §"State Management" — confirms `durationMin` (default 5), `customMin`
  (default 3, range 1–120), `theme` enum (`disc | sunrise | walk | car`), and the
  "remember last-used duration + theme locally" nicety this phase implements as PERSIST-01.
- `design/Zual.dc.html` — interactive prototype; open in a browser to see Layout A's actual
  stepper/selection behavior in motion (useful as a visual sanity check, not code to port).

### Existing codebase state
- `lib/timer/timer_controller.dart` — `TimerController.start(int minutes)`,
  `TimerController.endTimer()`, and `phase`/`progress` getters this screen's Start button
  and placeholder running screen consume directly.
- `lib/main.dart` — current app root; wires `ChangeNotifierProvider<TimerController>`, which
  the Setup screen will read via `context.watch`/`context.read`.
- `.planning/codebase/CONVENTIONS.md` — Dart/Flutter naming, formatting conventions to follow.
- `.planning/codebase/STRUCTURE.md` — suggests `lib/screens/`, `lib/widgets/` directories
  for new screen and reusable-component code (not yet created).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TimerController` (`lib/timer/timer_controller.dart`) — already exposes `start(minutes)`,
  `endTimer()`, `phase`, and `progress`. The Setup screen's Start button calls `start()`
  directly; the placeholder running screen reads `phase`/`progress` and calls `endTimer()`
  from its escape hatch.
- `ChangeNotifierProvider<TimerController>` is already wired in `lib/main.dart` — the Setup
  screen and placeholder running screen consume it via `provider`, no new DI plumbing needed.

### Established Patterns
- No screen/widget directory structure exists yet — `lib/main.dart` is still a single-file
  scaffold. This phase should establish `lib/screens/` (or similar) per `STRUCTURE.md`'s
  suggested layout, since it's the first phase adding real UI beyond the Phase 1 scaffold.
- No design-token constants (colors, radii, spacing) exist in code yet — this phase likely
  needs to introduce a small theme/tokens file to avoid scattering hex literals across widgets.

### Integration Points
- `lib/main.dart`'s `MyHomePage` placeholder ("Hello, World!") is what the real Setup screen
  replaces as the app's home/entry screen.
- The placeholder running screen this phase creates is a temporary integration point that
  Phase 3 will replace with real scene-driven rendering, and Phase 4 will layer Parent
  Controls onto.

</code_context>

<specifics>
## Specific Ideas

No specific implementation-style references beyond the design doc and the decisions above.
The mini-preview color choices for each scene card should pull directly from
`design/README.md`'s Design Tokens (e.g. Disc green `#7FA87A`, Sunrise night/day gradient
colors, house/car colors) rather than inventing new ones.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Real Parent Controls, chime, and completion
pill were explicitly named as Phase 4 concerns during discussion, not folded into Phase 2.)

</deferred>

---

*Phase: 2-Setup Screen*
*Context gathered: 2026-07-07*
