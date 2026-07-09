---
phase: 04-parent-controls-completion
plan: 01
subsystem: audio
tags: [audioplayers, dart-audio-synthesis, wav, chime, screen-wake-pattern]

# Dependency graph
requires:
  - phase: 03-scene-themes
    provides: SceneRenderer/Ticker convention establishing the "interface-wraps-a-plugin" precedent (ScreenWake/WakelockScreenWake) this plan mirrors
provides:
  - "synthesizeChimeWav() pure-Dart WAV byte generator for the two-tone completion chime"
  - "ChimePlayer/NoopChimePlayer plugin-free interface, testable without a platform channel"
  - "AudioplayersChimePlayer adapter, the sole importer of package:audioplayers in lib/audio/"
  - "audioplayers ^6.8.1 dependency installed and resolved"
affects: [04-05-running-screen-completion, parent-controls-sheet]

# Tech tracking
tech-stack:
  added: ["audioplayers ^6.8.1"]
  patterns:
    - "Interface-wraps-a-plugin: ChimePlayer/NoopChimePlayer mirrors ScreenWake/NoopScreenWake exactly"
    - "Pure-Dart synthesis kept free of Flutter/plugin imports (dart:math + dart:typed_data only) for platform-channel-free unit testing"

key-files:
  created:
    - lib/audio/chime_synth.dart
    - lib/audio/chime_player.dart
    - lib/audio/audioplayers_chime_player.dart
    - test/audio/chime_synth_test.dart
  modified:
    - pubspec.yaml

key-decisions:
  - "Package legitimacy checkpoint for audioplayers resolved via direct pub.dev verification (blue-fire.xyz publisher, bluefireteam/audioplayers repo, 6.8.1/11 days old, 3.4k likes/150 pub points/1.04M downloads) — approved before flutter pub add ran"
  - "Chime envelope decay time-constant set to 0.22s (tuned so gain falls to ~0 by the ~1.1s envelope duration) — treated as an implementation detail per 04-RESEARCH.md Open Question 1, not a locked formula"
  - "pubspec.lock left untracked — project .gitignore excludes *.lock; only pubspec.yaml committed"

patterns-established:
  - "ChimePlayer/NoopChimePlayer/AudioplayersChimePlayer: second instance of the interface-wraps-a-plugin shape in this codebase, directly copied from ScreenWake/WakelockScreenWake"

requirements-completed: [CTRL-03]

coverage:
  - id: D1
    description: "synthesizeChimeWav() returns a well-formed RIFF/WAVE WAV byte buffer with a PCM fmt chunk (1ch, 16-bit) and non-silent data, no Flutter/plugin import"
    requirement: "CTRL-03"
    verification:
      - kind: unit
        ref: "test/audio/chime_synth_test.dart#synthesizeChimeWav"
        status: pass
    human_judgment: false
  - id: D2
    description: "ChimePlayer/NoopChimePlayer plugin-free interface exists, mirroring ScreenWake; AudioplayersChimePlayer is the sole lib/audio/ file importing package:audioplayers and swallows playback errors via .catchError((_) {})"
    requirement: "CTRL-03"
    verification:
      - kind: unit
        ref: "flutter analyze lib/audio (clean) + grep -c package:audioplayers checks per acceptance criteria"
        status: pass
    human_judgment: false
  - id: D3
    description: "Chime tone quality/envelope sounds calm (not alarm-like) when actually played on-device"
    verification: []
    human_judgment: true
    rationale: "Envelope shape (60ms ramp, exponential decay) is a qualitative 'does it sound calm' check per 04-RESEARCH.md Open Question 1 — no UI wiring exists yet in this plan to audition it; deferred to the plan that wires ChimePlayer into RunningScreen (04-05)"

duration: 25min
completed: 2026-07-09
status: complete
---

# Phase 4 Plan 01: Audio Foundation (Chime Synth + Player) Summary

**Pure-Dart two-tone (D5->G5) WAV chime synthesizer plus a plugin-free ChimePlayer interface backed by an audioplayers 6.8.1 adapter, mirroring the existing ScreenWake pattern.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-09T10:05:00Z
- **Completed:** 2026-07-09T10:30:00Z
- **Tasks:** 3 (1 checkpoint gate, 2 execution tasks)
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments
- `synthesizeChimeWav()` generates a well-formed RIFF/WAVE byte buffer containing hand-synthesized D5 (587.33 Hz) -> G5 (783.99 Hz) sine tones with a 60ms ramp + exponential-decay envelope, entirely in pure Dart (no Flutter or plugin import)
- `ChimePlayer`/`NoopChimePlayer` established as a plugin-free interface, directly mirroring `ScreenWake`/`NoopScreenWake`, so future widget tests never touch a platform channel
- `AudioplayersChimePlayer` wraps `package:audioplayers`' `BytesSource` API as the sole plugin touch point in `lib/audio/`, swallowing playback failures via `.catchError((_) {})`
- `audioplayers ^6.8.1` installed after human legitimacy verification of the `[ASSUMED]`-flagged package (T-04-SC checkpoint satisfied)

## Task Commits

Each task was committed atomically (Task 2 followed TDD RED/GREEN):

1. **Task 1: Package legitimacy verification for audioplayers** - checkpoint, no code change; approved by human before Task 3's install (see Deviations note below)
2. **Task 2 (RED): failing test for chime synthesizer** - `0d19bb2` (test)
3. **Task 2 (GREEN): pure-Dart chime WAV synthesizer** - `40039d8` (feat)
4. **Task 3: ChimePlayer interface, audioplayers adapter, and dependency install** - `4bc68fa` (feat)

**Plan metadata:** committed after this SUMMARY (see final commit)

## Files Created/Modified
- `lib/audio/chime_synth.dart` - Pure-Dart `synthesizeChimeWav()`: two sine tones (D5/G5) with gain-envelope, wrapped in a minimal RIFF/WAVE header
- `lib/audio/chime_player.dart` - `ChimePlayer` abstract interface + `NoopChimePlayer` default (no plugin import)
- `lib/audio/audioplayers_chime_player.dart` - `AudioplayersChimePlayer`, the sole `package:audioplayers` importer in `lib/audio/`
- `test/audio/chime_synth_test.dart` - Pure-Dart unit tests: RIFF/WAVE header, fmt chunk fields, buffer length, non-silent PCM payload
- `pubspec.yaml` - Added `audioplayers: ^6.8.1` dependency

## Decisions Made
- Approved `audioplayers` package after direct pub.dev verification (see key-decisions above) — the Task 1 blocking-human checkpoint from a prior attempt was resolved before this execution began, so no re-verification was needed mid-plan.
- Tuned the chime envelope's exponential decay time-constant to 0.22s so the gain falls to approximately zero by the ~1.1s envelope duration specified in `design/README.md`; this is documented as tunable (not locked) per 04-RESEARCH.md's Open Question 1, and the *actual* sound-quality check is deferred to on-device UAT once the chime is wired into `RunningScreen` (Plan 04-05).
- Left `pubspec.lock` untracked (project `.gitignore` excludes `*.lock`) — matches existing repo convention, not a deviation.

## Deviations from Plan

None — plan executed exactly as written. Task 1's checkpoint was a continuation of a prior halted attempt; the human approval (verified publisher `blue-fire.xyz`, repo `github.com/bluefireteam/audioplayers`, version 6.8.1, 3.4k likes/150 pub points/1.04M downloads, exact name match) was supplied via the orchestrator's continuation context before this execution began, so Task 1 required no further action beyond treating the gate as satisfied and proceeding to Task 2/3.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. `audioplayers` is a standard `flutter pub add` with no native/NDK prerequisite.

## Next Phase Readiness
- `lib/audio/` package (synth + interface + adapter) is ready for Plan 04-05 to wire into `RunningScreen`: inject `AudioplayersChimePlayer()` in production, `NoopChimePlayer`/fake in tests, trigger `play(synthesizeChimeWav())` on the `done`-phase edge.
- No UI wiring exists yet — this plan deliberately scoped to reusable audio primitives only, per the plan's stated objective.
- Chime sound-quality (calm vs. alarm-like) qualitative check remains open until Plan 04-05 makes it audible (04-RESEARCH.md Open Question 1) — flagged as `D3` in this SUMMARY's `human_judgment: true` coverage entry.

---
*Phase: 04-parent-controls-completion*
*Completed: 2026-07-09*
