---
phase: 4
slug: parent-controls-completion
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-08
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter SDK, already used throughout `test/`) |
| **Config file** | none dedicated (no `dart_test.yaml`; conventions live in existing `test/*_test.dart` files) |
| **Quick run command** | `flutter test test/screens/running_screen_test.dart` (new file) and `flutter test test/scenes/scene_renderer_test.dart` (extended) |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the single most relevant `flutter test <file> -N "<case>"` quick command for the task
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green, plus human-verify checkpoints (chime sound quality, blurred-sheet smoothness, media-volume vs. ringer-silent behavior)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-XX | TBD | 0/1 | CTRL-01 | — | 850ms long-press on the running screen opens the sheet; a shorter press does nothing | widget | `flutter test test/screens/running_screen_test.dart -N "long-press"` | ❌ W0 | ⬜ pending |
| 04-01-XX | TBD | 1 | CTRL-02 | — | Sheet's Pause/Resume/End timer/Keep watching/mute buttons call the right `TimerController`/persistence methods | widget | `flutter test test/screens/running_screen_test.dart -N "parent controls"` | ❌ W0 | ⬜ pending |
| 04-01-XX | TBD | 1 | CTRL-03 | — | On `phase == done` (including already-done-on-foreground-resume), chime plays exactly once (via injected fake `ChimePlayer`) unless muted; scene renders its end visual | widget + unit | `flutter test test/screens/running_screen_test.dart -N "chime"` and `flutter test test/audio/chime_synth_test.dart` | ❌ W0 (both files) | ⬜ pending |
| 04-01-XX | TBD | 1 | CTRL-04 | — | Breathing pill appears at `done`, tapping it calls `endTimer()` and pops to Setup | widget | `flutter test test/screens/running_screen_test.dart -N "all done pill"` | ❌ W0 | ⬜ pending |
| 04-01-XX | TBD | 1 | D-10 (carried defect) | T-02-02 (precedent) | `loopPhase()` continues (does not reset to 0) across a pause -> resume ticker stop/start cycle | widget (extends existing suite) | `flutter test test/scenes/scene_renderer_test.dart -N "resume"` | ❌ W0 (new case in existing file) | ⬜ pending |
| 04-01-XX | TBD | 1 | V5 Input Validation | — | Tampered/wrong-typed stored `soundOn` value falls back to default (`true`) on read, matching `durationMin`/`theme` precedent in `SetupPreferences.load()` | unit | `flutter test test/settings/setup_preferences_test.dart -N "soundOn"` | ❌ W0 (new case) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/screens/running_screen_test.dart` — new file; needs a test harness analogous to `test/screens/setup_screen_test.dart`'s `_harness`/`_pumpPastTransition` helpers. This suite ALSO needs a fake `ChimePlayer` injected into `RunningScreen`, since the real `audioplayers` plugin cannot run under `flutter_test`.
- [ ] `test/audio/chime_synth_test.dart` — new file; pure-Dart unit tests asserting the synthesized WAV byte buffer is well-formed (correct RIFF header fields, non-empty PCM payload, no platform dependency needed)
- [ ] Extend `test/scenes/scene_renderer_test.dart` with a pause -> resume -> pause loop-phase-continuity assertion (D-10)
- [ ] Extend `test/settings/setup_preferences_test.dart` (or equivalent) with a tampered-`soundOn`-value fallback case
- [ ] Framework install: none — `flutter_test` already present; no new test framework needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Chime sound quality (tone envelope, decay, overall pleasantness) | CTRL-03 | Design doc gives descriptive spec, not an exact synthesis formula — needs a human listening check | Run the app, let a timer complete unmuted, listen and confirm the two-tone chime sounds calm/soft, not harsh or alarm-like |
| Blurred bottom-sheet scrim smoothness on a real device | CTRL-01/CTRL-02 | `BackdropFilter` + bottom sheet has documented jank/flicker issues on some Flutter engine versions (flutter/flutter #78356, #160963, #162006) — only observable on real hardware, not in widget tests | Trigger the long-press on a real Android device, confirm the blurred scrim animates in without visible flicker/jank; if janky, fall back to a flat scrim color |
| Media-volume vs. ringer-silent-switch behavior | CTRL-03 | Android's ringer "silent mode" does not mute the `STREAM_MUSIC`/media stream `audioplayers` uses by default — this is a platform nuance, not a bug, and must be confirmed by hand so it isn't mistakenly "fixed" later | With the device ringer set to silent (not media volume at 0) and mute toggle OFF, confirm the chime still plays; confirm it is silent only when the in-app mute toggle is ON or media volume is 0 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
