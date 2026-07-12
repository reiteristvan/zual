# Phase 3: Scene Themes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 3-Scene Themes
**Areas discussed:** Decorative loop-animation feel, Smooth-animation validation approach

**Mode:** `--auto` — Claude selected recommended options for every question, no interactive
prompts. All selections below are auto-resolved defaults, not user-confirmed choices.

---

## Decorative loop-animation feel (star twinkle, character bob, wheel spin)

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle/slow (calm tone) | Soft opacity pulse (~2–3s) for twinkle, small-amplitude gentle bob, unhurried continuous wheel spin | ✓ |
| Prominent/lively | Faster, larger-amplitude motion to draw the eye | |

**Selected:** Subtle/slow (recommended default)
**Notes:** [auto] Design doc specifies these qualitatively only ("gentle twinkle", "gentle
vertical bob"); auto-selected the interpretation consistent with PROJECT.md's "playful but
calm" tone and the deliberately non-alarm-like brand direction.

---

## Smooth-animation validation approach (SCENE-05: no visible jank on mid/low-end Android)

| Option | Description | Selected |
|--------|-------------|----------|
| Widget tests + human end-of-phase device check | CI-checkable correctness (color zones, arrival, shouldRepaint) via widget tests; perceptual smoothness via human check on real API 24–28 hardware | ✓ |
| Build custom frame-timing instrumentation | Add perf-measurement tooling to assert frame budgets automatically | |

**Selected:** Widget tests + human end-of-phase device check (recommended default)
**Notes:** [auto] No pixel-diff/frame-timing tooling exists in this project (confirmed
absent during Phase 2 verification); matches the already-established
`workflow.human_verify_mode: end-of-phase` pattern and the existing STATE.md Blocker/Concern
flagging a real-device check as needed before this pattern is committed across all 4
scenes.

---

## Claude's Discretion

- Exact scene file/class structure (already guided by `.planning/research/ARCHITECTURE.md`'s
  `SceneRenderer` contract and `scenes/<theme>/` layout).
- Negative-opacity clamping and other formula edge cases in the Night to Sunrise fade math.
- Whether decorative loop animations pause alongside the shared timer's paused state
  (defaulted to: yes, pause with the timer).

## Deferred Ideas

None — discussion stayed within phase scope. Parent Controls, chime, and the "All done"
pill remain scoped to Phase 4 per ROADMAP.md.
