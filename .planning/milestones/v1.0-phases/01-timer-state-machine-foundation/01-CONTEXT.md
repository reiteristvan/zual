# Phase 1: Timer State-Machine Foundation - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning

<domain>
## Phase Boundary

A correct, drift-free countdown engine that survives pause, resume, and backgrounding, exposing
`phase` (setup/running/paused/done) and a normalized `progress` (0..1) value to the rest of the
app. No UI in this phase — this is the shared state machine every screen and scene will consume.
Requirements: TIMER-01 through TIMER-05.

</domain>

<decisions>
## Implementation Decisions

### Backgrounding behavior

- **D-01:** While a timer is running and the app is backgrounded (phone locks, another app opens),
  the countdown keeps progressing against real wall-clock time — like a real physical timer. It is
  NOT auto-paused on backgrounding. Returning to the app shows exactly the progress that should
  exist given real elapsed time; the timer can even reach "done" while backgrounded.
- **D-02:** If the timer reaches "done" while the app is backgrounded, nothing fires in the
  background (no local notification, no background audio). The app computes that it's done and
  shows the finished state + plays the completion chime the moment it's brought back to the
  foreground. This keeps the phase free of background-execution/notification-permission complexity.

### App-kill recovery

- **D-03:** If the OS fully kills the app process (not just backgrounds it) while a timer is
  running, and the parent reopens the app, progress is lost — the app returns to the Setup screen
  as if nothing was running. No running-timer state (start time, duration, theme, phase) is
  persisted across a process kill. This matches PERSIST-01's scope, which only remembers
  last-used duration + theme for the Setup screen, not in-progress-timer state.

### Claude's Discretion

- Exact wall-clock timing mechanism (`Stopwatch` vs `DateTime` deltas) — an implementation detail,
  not a product decision. Project-level research (`.planning/research/ARCHITECTURE.md`) already
  recommends `Stopwatch` for its clean pause/resume semantics.
- State management library choice (`provider` vs raw `ChangeNotifier` vs something else) — already
  settled by project-level research (`.planning/research/STACK.md`): `provider ^6.1.5` wrapping a
  single `ChangeNotifier`.
- Exact tolerance for "on-time" completion (e.g., how many milliseconds of acceptable drift) — an
  engineering QA target for the planner/executor to define, not a product-facing gray area.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and requirements
- `.planning/PROJECT.md` — full project context, core value, constraints
- `.planning/REQUIREMENTS.md` — TIMER-01 through TIMER-05 (this phase's requirements)
- `.planning/ROADMAP.md` — Phase 1 goal and success criteria

### Design specification
- `design/README.md` — state management section ("Phase machine", "Countdown", "Pause / Resume"),
  which describes the reference (HTML prototype) timing model this phase reimplements idiomatically
  in Flutter (wall-clock elapsed time via `Stopwatch`, not the prototype's manual `pausedTotal`
  bookkeeping)

### Project-level research (already resolved most technical gray areas for this phase)
- `.planning/research/ARCHITECTURE.md` — recommended `TimerController extends ChangeNotifier`
  design, `Stopwatch`-based elapsed time, `SceneRenderer` contract (consumed by later phases, not
  this one)
- `.planning/research/STACK.md` — `provider ^6.1.5`, `wakelock_plus ^1.6.1` package choices
- `.planning/research/PITFALLS.md` — wall-clock vs `AnimationController.duration` drift risk,
  missing `AppLifecycleState` handling, wakelock/controller lifecycle leaks, testing pitfall with
  `tester.pumpAndSettle()` and looping animations
- `.planning/research/SUMMARY.md` — Phase 1 rationale and research flags (wall-clock timing
  accuracy validation, `AppLifecycleState` handling across real device backgrounding scenarios)

### Existing codebase state
- `.planning/codebase/ARCHITECTURE.md` — current scaffold is a single-file, stateless, no state
  management layer (confirms this phase is greenfield within the app, not a refactor)
- `.planning/codebase/CONVENTIONS.md` — Dart/Flutter naming, formatting, and error-handling
  conventions already established in the scaffold
- `.planning/codebase/CONCERNS.md` — known issues in the existing scaffold (e.g., placeholder
  `applicationId`) — not this phase's concern, but relevant context

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — the scaffold (`lib/main.dart`) is a single-file Hello World with no state management,
  no models, no services. This phase builds the first real application logic.

### Established Patterns
- No state management pattern currently exists in the codebase (all widgets are `StatelessWidget`).
  This phase introduces the app's first stateful, non-UI logic layer.
- Existing conventions (naming, formatting, null-safety idioms) from `CONVENTIONS.md` apply as-is.

### Integration Points
- This phase's `TimerController` (or equivalent) will be the thing Phase 2 (Setup Screen) calls to
  start a timer, Phase 3 (Scene Themes) reads `progress` from, and Phase 4 (Parent Controls) calls
  to pause/resume/end. No existing code to integrate with beyond the scaffold's `main.dart` entry
  point.

</code_context>

<specifics>
## Specific Ideas

No specific implementation-style references beyond what's already captured in the design doc and
project-level research. The two decisions above (D-01, D-02, D-03) are the concrete product-level
choices for this phase.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Timer State-Machine Foundation*
*Context gathered: 2026-07-06*
