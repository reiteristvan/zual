# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-07-12
**Phases:** 5 | **Plans:** 22 | **Tasks:** 45

### What Was Built
- A drift-free, wall-clock timer state machine (`setup → running → paused → done`) surviving pause/resume and backgrounding, with screen-wake tied to the running phase
- A parent-facing Setup screen: duration presets + custom 1–120 min stepper, 4-scene picker, last-used persistence, pixel-accurate Layout A fidelity (now responsive across phone and tablet)
- Four full-screen wordless scene themes (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road) sharing one `SceneRenderer`/Ticker contract
- A hidden long-press Parent Controls sheet (Pause/Resume/End/mute) and a calm, chime-driven completion state
- A publishable, signed Android build with real app identity, an adaptive launcher icon, screenshots, a feature graphic, a privacy policy, and Play Console listing docs — all code-composited from the app's real `CustomPainter`s, no external design tool

### What Worked
- Reusing the real in-app `CustomPainter`s (via `renderPainterToPng`) for every Play Store binary asset (launcher icon, 512px store icon, 1024x500 feature graphic) kept them genuinely pixel-consistent with the shipping app and avoided a parallel, drift-prone "marketing assets" pipeline
- Quick tasks (260710-frr, 260710-keg, 260712-h36) handled small, well-scoped fixes and asset generation without full-phase planning overhead
- The `/gsd-debug` scientific-method loop cleanly isolated the tablet layout regression in one investigation cycle — root cause, fix, and human-verification checkpoint before any commit
- Worktree isolation for executor/quick-task/debug agents kept `main` clean and let background agents run without blocking the conversation

### What Was Inefficient
- The launcher-icon inset "fix" (260710-keg, closing WR-01) was verified only by config-level grep + a debug build, never a real device — it shipped a regression (icon rendering as a near-edge-to-edge sun on a flat yellow field) that a human only caught during UAT, requiring a second gap-closure plan (05-06) and a full re-verification pass to close
- Tablet form factor was never tested during Phase 2/5 UAT or verification — the layout bug (oversized presets, scene art not filling cards) was only discovered post-milestone via real dogfooding, not caught by any automated check or phase gate
- STATE.md's frontmatter `status` field and 05-VERIFICATION.md's `status` field both drifted to non-canonical values (`executing` instead of `complete`; `verified` instead of `passed`) during manual doc edits this session, causing `/gsd-complete-milestone`'s readiness check to initially report Phase 5 as incomplete — required a hand-correction pass before milestone close could proceed

### Patterns Established
- **Non-`_test.dart` generator + companion read-only drift-lock `_test.dart`** for any code-composited binary asset: the generator writes the committed file explicitly (never auto-run by a bare `flutter test`), and a paired `_test.dart` re-renders in-memory and byte-diffs against the committed file, failing loudly on drift instead of silently overwriting it. Established by the feature-graphic generator; the original launcher-icon generator still doesn't follow this pattern (open tech debt, 05-REVIEW.md WR-04).
- **Cap responsive layouts to a phone-proportioned max content width and center on larger screens**, rather than stretching interior content to fill available width — cell dimensions and their interior content (fonts, thumbnails) must scale together, or grow independently and break on tablets. Captured in `.planning/debug/knowledge-base.md` for future layout investigations.

### Key Lessons
1. Treat "grep/build passes" as necessary but not sufficient for any fix touching OS-level or device-rendered visual behavior (adaptive-icon mask crops, tablet layout breakpoints) — schedule an explicit human/device look before marking that class of fix verified, since no unit test in this codebase can observe it.
2. A design spec anchored to a single reference frame (this project's `design/README.md` specifies only a 402px phone frame) silently becomes a phone-only assumption unless another form factor is explicitly tested — worth a deliberate tablet/large-screen pass during UI-heavy phases rather than discovering it after the milestone is marked shipped.
3. GSD tooling status fields (`VERIFICATION.md status`, `STATE.md` frontmatter `status`) expect exact enum values (e.g. `passed`, not `verified`) — when hand-editing these files outside the normal executor/verifier flow, match the tool's expected vocabulary or downstream readiness checks like `/gsd-complete-milestone` will misreport phase completion.

### Cost Observations
- Model mix: primarily Sonnet for execution/debugging agents, Opus for planning and the debug/milestone orchestration agents, per the project's `adaptive` model profile — exact percentages not tracked this milestone.
- Timeline: 6 days (2026-07-06 → 2026-07-12) across 5 phases plus 3 quick tasks and 1 debug session post-Phase-5.
- Notable: two of the three post-Phase-5 quick/debug interventions (launcher-icon gap-closure, tablet layout fix) were fixing gaps in verification coverage itself (visual/device checks, cross-form-factor testing), not gaps in the original feature implementation — worth budgeting for in the next milestone's UAT scope.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Key Change |
|-----------|--------|------------|
| v1.0 | 5 | First milestone — established the code-composited-asset pattern for Play Store binaries and the scientific-method debug loop for post-ship visual regressions |

### Cumulative Quality

| Milestone | Tests | Zero-Dep Additions |
|-----------|-------|---------------------|
| v1.0 | 134 passing (`flutter test`) | 0 — no new pub dependencies beyond `audioplayers` (Phase 4, human-approved at a checkpoint) |

### Top Lessons (Verified Across Milestones)

1. Visual/device-only regressions need an explicit human-verification checkpoint in the plan itself — code-level checks alone let two separate defects (launcher icon, tablet layout) reach post-ship discovery in v1.0.
