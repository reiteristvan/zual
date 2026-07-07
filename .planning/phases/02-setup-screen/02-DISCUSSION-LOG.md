# Phase 2: Setup Screen - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 2-Setup Screen
**Areas discussed:** Running-screen placeholder, Scene thumbnail previews, Custom stepper feel, Defaults & persistence

---

## Running-screen placeholder

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal placeholder screen | Bare full-screen view showing phase/progress simply, no text/numbers, replaced by real scenes in Phase 3 | ✓ |
| No navigation yet | Start updates controller state only; no post-Start screen until Phase 3 | |
| Barebones SceneRenderer contract | Build the actual SceneRenderer interface now with a trivial fallback painter | |

**User's choice:** Minimal placeholder screen — full-screen solid cream background, centered plain shrinking-circle progress indicator, no color zones/polish, no text/numbers.

| Option | Description | Selected |
|--------|-------------|----------|
| Completely inert | No long-press, no tap handling at all; no way back within the screen | |
| Bare End-timer escape hatch | A small unobtrusive control (e.g. back arrow) that calls `endTimer()` and returns to Setup | ✓ |

**User's choice:** Bare End-timer escape hatch.

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-return to Setup | On reaching done, screen auto-navigates back to Setup, no chime/pill | ✓ |
| Just sit at done, no auto-nav | Screen shows done state and stays; no auto-navigation | |

**User's choice:** Auto-return to Setup.

**Notes:** Real Parent Controls (hidden 850ms long-press, bottom sheet, Pause/Resume) and completion chime/"All done" pill are explicitly Phase 4 scope — not folded into this phase's placeholder.

---

## Scene thumbnail previews

| Option | Description | Selected |
|--------|-------------|----------|
| Simplified static previews | Small CustomPainter sketches per theme (green disc, night→day gradient swatch, path+house, path+car), not animated but on-brand | ✓ |
| Flat placeholder swatch | Solid color swatch + label per card, no themed art yet | |

**User's choice:** Simplified static previews.

| Option | Description | Selected |
|--------|-------------|----------|
| Throwaway, Phase 3 replaces them | Phase 2 preview painters are simple/separate; Phase 3 free to replace outright | |
| Design for reuse | Isolate preview logic per theme so Phase 3 can swap in the real scene painter (progress=0, scaled to 74px) without touching Setup screen's grid/card code | ✓ |

**User's choice:** Design for reuse.

**Notes:** Preview colors should pull directly from `design/README.md` Design Tokens, not invented.

---

## Custom stepper feel

| Option | Description | Selected |
|--------|-------------|----------|
| Tap-only, +1/-1 | Each tap changes value by exactly 1 minute; simplest, matches design literally | |
| Long-press accelerates | Tap moves by 1; holding repeats and speeds up | ✓ |

**User's choice:** Long-press accelerates.

| Option | Description | Selected |
|--------|-------------|----------|
| Disable at limits | − greys out at 1 min, + greys out at 120 min | ✓ |
| Clamp silently | Buttons stay tappable but do nothing past the limits | |

**User's choice:** Disable at limits.

---

## Defaults & persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Shrinking Disc as default theme | Disc is the design doc's anchor/hero scene — natural first-launch default | ✓ |
| No theme pre-selected | Forces an intentional first choice; Start disabled until a theme is tapped | |

**User's choice:** Shrinking Disc as default theme.

| Option | Description | Selected |
|--------|-------------|----------|
| Remember exact last state | Including Custom values, e.g. relaunch reopens Custom stepper at 47 min | |
| Always relaunch to nearest preset | Persistence only remembers presets; Custom last-used falls back to nearest/default preset | ✓ |

**User's choice:** Always relaunch to nearest preset.

---

## Claude's Discretion

- Persistence mechanism (`shared_preferences` vs alternative local key-value storage).
- Font bundling approach for Baloo 2 + Quicksand — prefer an approach that works fully offline.
- Exact shape/geometry of the placeholder running screen's progress indicator (must read as "a shrinking circle," zero text/numbers).
- Exact "nearest preset" fallback rounding logic when Custom was last used.

## Deferred Ideas

None — discussion stayed within phase scope. Real Parent Controls, chime, and completion pill were explicitly named as Phase 4 concerns during discussion, not folded into Phase 2.
