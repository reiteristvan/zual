# Phase 1: Timer State-Machine Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-06
**Phase:** 1-Timer State-Machine Foundation
**Areas discussed:** Backgrounding behavior, App-kill recovery

---

## Backgrounding behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Keep counting real time | Wall-clock time keeps passing in the background — like a real physical timer. Returning to the app shows exactly where it should be; the timer can even finish while backgrounded. | ✓ |
| Auto-pause when backgrounded | Treats backgrounding as an implicit pause — countdown only progresses while the app is actually in the foreground and visible. | |

**User's choice:** Keep counting real time (Recommended)
**Notes:** Follow-up question asked what happens if the timer finishes while backgrounded.

| Option | Description | Selected |
|--------|-------------|----------|
| Silent until foregrounded | No background audio/notification complexity. The app computes it's done and shows the finished state + plays the chime the moment it's brought back to the foreground. | ✓ |
| Local notification when done | Fire a system notification (and ideally play the chime) even while backgrounded — requires background execution/notification permissions, more complex for v1. | |

**User's choice:** Silent until foregrounded (Recommended)
**Notes:** Keeps this phase free of background-execution/notification-permission complexity.

---

## App-kill recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Lose progress, back to Setup | Simplest for v1 — no persisted running-timer state needed. Matches PERSIST-01 scope (only last-used duration/theme is remembered, not in-progress runs). | ✓ |
| Resume where it left off | Persist start time + duration + theme so a killed app can reconstruct exact progress on relaunch — more robust, more complexity for this phase. | |

**User's choice:** Lose progress, back to Setup (Recommended)
**Notes:** Keeps scope aligned with PERSIST-01, which only covers last-used settings, not in-progress timer state.

---

## Claude's Discretion

- Exact wall-clock timing mechanism (`Stopwatch` vs `DateTime` deltas) — already recommended by project-level research.
- State management library choice — already settled by project-level research (`provider` + `ChangeNotifier`).
- Exact tolerance for "on-time" completion — an engineering QA target, not a product-facing decision.

## Deferred Ideas

None — discussion stayed within phase scope.
