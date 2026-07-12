# Phase 4: Parent Controls & Completion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-08
**Phase:** 4-Parent Controls & Completion
**Areas discussed:** Mute toggle design, Chime sound implementation, Long-press hold feedback, Decorative loop continuity on pause/resume

---

## Mute toggle design

| Option | Description | Selected |
|--------|-------------|----------|
| Small icon button in sheet header | Compact speaker/mute icon next to the grab handle or title — keeps the two main action buttons visually dominant | ✓ |
| Third row below the two main buttons | Full-width row (icon + label) below Pause/Resume and End timer, above Keep watching | |
| You decide | Claude picks based on existing sheet button/spacing tokens | |

**User's choice:** Small icon button in sheet header
**Notes:** None.

| Option | Description | Selected |
|--------|-------------|----------|
| Persists (SharedPreferences) | Same mechanism as last-used duration + theme (PERSIST-01) | ✓ |
| Session-only (resets each launch) | Mute always defaults on at fresh launch | |

**User's choice:** Persists (SharedPreferences)
**Notes:** None.

| Option | Description | Selected |
|--------|-------------|----------|
| Material speaker icons | `Icons.volume_up` / `Icons.volume_off` — standard Material iconography | ✓ |
| You decide | Claude picks closest Material icon pair and color treatment | |

**User's choice:** Material speaker icons
**Notes:** None.

| Option | Description | Selected |
|--------|-------------|----------|
| Unmuted (sound on) | Matches design doc default; parent must actively opt out | ✓ |
| You decide | Claude picks the low-surprise default | |

**User's choice:** Unmuted (sound on)
**Notes:** None.

---

## Chime sound implementation

| Option | Description | Selected |
|--------|-------------|----------|
| Bundled short audio file (asset) | Pre-render the two-tone chime once as WAV/MP3, play with a lightweight audio package | |
| Real-time synthesized tone | Generate the two sine tones procedurally at runtime, closer to the Web Audio API original | ✓ |
| You decide | Claude picks based on package research, favoring simplicity | |

**User's choice:** Real-time synthesized tone
**Notes:** None.

| Option | Description | Selected |
|--------|-------------|----------|
| Respects device silent mode (media stream) | Chime plays through standard media channel; silent mode suppresses it | ✓ |
| Always plays regardless of silent mode | Fixed app volume overrides device silent/vibrate setting | |

**User's choice:** Respects device silent mode (media stream)
**Notes:** None.

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, play on first foreground reveal | Per Phase 1 D-02, chime plays the moment the app is foregrounded and finds itself done | ✓ |
| No chime if already done on foreground | Skip chime for timers that finished while backgrounded | |

**User's choice:** Yes, play on first foreground reveal
**Notes:** Confirms Phase 1's D-02 still applies now that the chime itself is implemented.

---

## Long-press hold feedback

| Option | Description | Selected |
|--------|-------------|----------|
| Fully silent/invisible until it fires | Matches design doc exactly; nothing changes on screen until 850ms elapses | ✓ |
| Subtle building affordance during the hold | Faint darkening/scrim or ripple grows during the hold | |

**User's choice:** Fully silent/invisible until it fires
**Notes:** None.

| Option | Description | Selected |
|--------|-------------|----------|
| No — long-press does nothing once done | Only the single-tap "All done" pill is interactive once finished | ✓ |
| Yes — sheet still opens (End timer still useful) | Keep the gesture live across all non-setup phases | |

**User's choice:** No — long-press does nothing once done
**Notes:** None.

---

## Decorative loop continuity on pause/resume

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, fix it — loops resume from where they froze | Phase 4 is the natural moment since Pause/Resume gets wired to real UI here | ✓ |
| No — accept the snap as a known quirk | Leave ticker-restart behavior as-is; defer to later cleanup | |

**User's choice:** Yes, fix it — loops resume from where they froze
**Notes:** Addresses the carried-forward blocker noted in STATE.md from Phase 3.

---

## Claude's Discretion

- Exact Flutter package/mechanism for real-time tone synthesis.
- Exact fix mechanism for the loop-phase freeze/resume (e.g., tracking a paused-at elapsed offset in `SceneRendererState`).
- Bottom sheet visual details not already locked by `design/README.md` §G (only the mute icon's exact padding/placement within the header is Claude's call).
- Whether `GestureDetector.onLongPress` tolerates minor finger drift during the hold — use Flutter's standard defaults.

## Deferred Ideas

None — discussion stayed within phase scope.
