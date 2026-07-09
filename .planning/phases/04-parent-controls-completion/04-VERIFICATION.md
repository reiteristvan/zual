---
phase: 04-parent-controls-completion
verified: 2026-07-09T13:00:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 4: Parent Controls & Completion Verification Report

**Phase Goal:** A parent can discreetly control a running timer, and completion resolves into a calm, wordless finished state with a soft chime.
**Verified:** 2026-07-09T13:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A hidden ~850ms long-press anywhere on the running screen opens the Parent Controls bottom sheet | ✓ VERIFIED | `lib/screens/running_screen.dart:23-24,225-238` wraps the scene in a `RawGestureDetector` using `LongPressGestureRecognizer(duration: Duration(milliseconds: 850))`, gated off (`gestureEnabled = !isDone`) once `TimerPhase.done` (D-09). `test/screens/running_screen_test.dart` (CTRL-01 group, lines 122-190) proves: a ≥850ms press opens "Parent controls" (findsOneWidget), a <850ms press opens nothing, and a long-press once done opens nothing. Confirmed passing (`flutter test` 129/129). No visible build-up affordance exists during the hold (D-08). |
| 2 | The sheet offers Pause/Resume, End timer (returns to Setup), Keep watching (dismiss), and a sound mute toggle | ✓ VERIFIED | `_ParentControlsSheet` (`lib/screens/running_screen.dart:252-422`) renders a state-swapping primary button (Pause↔Resume, calling `TimerController.pause()/resume()` at lines 359-364), an End timer button calling `endTimer()` then popping via an injected `onEndTimer` callback (382-406), a "Keep watching" text button that only pops the sheet (408-421), and a header mute `IconButton` toggling the shared `soundOn` ValueNotifier + `SetupPreferences.persistSoundOn` write-through (264-267, 327-348). All 5 behaviors are covered by `test/screens/running_screen_test.dart`'s CTRL-02 group (192-293) and pass. Code-review finding WR-02 (primary button mislabeled "Resume" and silently no-op'd if the timer reaches `done` while the sheet is open) was found and fixed (commit `00ad19f`) — `_buildPrimaryButton` now renders "Done" and no-ops correctly in that edge case. |
| 3 | On completion a soft two-tone chime plays (unless muted) with no alarm or celebration, and the active scene settles into its end visual | ✓ VERIFIED | `lib/audio/chime_synth.dart` synthesizes D5 (587.33 Hz) → G5 (783.99 Hz) sine tones with a 60ms ramp + exponential decay envelope exactly matching `design/README.md` §H/Interactions' End chime spec — proven well-formed/non-silent by `test/audio/chime_synth_test.dart`. `_RunningScreenState._maybeReactToPhaseChange` (`lib/screens/running_screen.dart:131-141`) fires `chimePlayer.play()` exactly once on the edge into `done`, gated on `soundOn.value`, safe against rebuilds and mount-already-done (D-07 foreground-reveal). `test/screens/running_screen_test.dart`'s CTRL-03 group (295-379) proves: plays once on transition, does not replay on further notifications, is skipped when muted, and plays once when mounting directly into `done`. The scene's own progress==1 end visual is untouched (Phase 3 code, not modified). Sound quality / mute / ringer-silent / foreground-reveal-once behavior was human-verified on a real Android emulator during execution (04-05-SUMMARY.md Task 3, approved) — not re-flagged per this verification's scope note. |
| 4 | The finished state shows a gently breathing "All done" pill that returns to Setup when the parent taps it | ✓ VERIFIED | `_buildDonePill()` (`lib/screens/running_screen.dart:172-211`) renders only when `controller.phase == TimerPhase.done`, using a `SingleTickerProviderStateMixin`-driven `AnimationController` (2800ms, `.repeat(reverse: true)`, `Curves.easeInOut`, scale 1→1.05) matching `design/README.md`'s `breathe 2.8s ease-in-out infinite` spec, text "All done — tap when ready" matching the design copy exactly, and an `onTap` (`_handlePillTap`) that calls `TimerController.endTimer()` then pops back to Setup. `test/screens/running_screen_test.dart`'s CTRL-04 group (381-427) and `test/screens/setup_screen_test.dart`'s end-to-end dwell-then-tap-pill case both pass. The former auto-pop-on-done scaffolding (`_maybeAutoPopWhenDone`) was deleted outright (`grep -c "_maybeAutoPopWhenDone" lib/screens/running_screen.dart` returns 0) so `done` is now a visible, dwelled-in state, not a flash. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/audio/chime_synth.dart` | Pure-Dart WAV synthesizer, no Flutter/plugin import | ✓ VERIFIED | Only `dart:math`/`dart:typed_data` imports; RIFF/WAVE header + PCM payload; unit-tested |
| `lib/audio/chime_player.dart` | Plugin-free `ChimePlayer`/`NoopChimePlayer` interface | ✓ VERIFIED | No `package:audioplayers` import; `NoopChimePlayer.play` is a real no-op |
| `lib/audio/audioplayers_chime_player.dart` | Sole `audioplayers` import point, error-swallowing | ✓ VERIFIED | `AudioPlayer().play(BytesSource(...)).catchError((_) {})` |
| `lib/settings/setup_preferences.dart` | `soundOn` scalar with validate-on-read + `persistSoundOn` | ✓ VERIFIED | Default `true`, try/catch fallback, unconditional writer; 3 new tests pass |
| `lib/scenes/scene_renderer.dart` | Loop-phase offset accumulation across ticker stop/start (D-10) | ✓ VERIFIED | `_loopBaseOffset` snapshotted before `_ticker.stop()`, applied in `_onTick`; continuity + additive-accumulation tests pass |
| `lib/theme/app_tokens.dart` | Sheet/pill tokens (`sheetBg`, `destructive`, `destructivePressed`, `sheetShadow`, `scrim`, `pillSurface`, `grabHandle`) | ✓ VERIFIED | All present; `destructivePressed` now in active use post-WR-03 fix (`PressableSurface` on End timer button) |
| `lib/screens/running_screen.dart` | Long-press gate, Parent Controls sheet, chime trigger, breathing pill; back button removed | ✓ VERIFIED | All present and wired (see Observable Truths 1-4); `Icons.arrow_back`/`_handleBack` both return 0 hits |
| `test/screens/running_screen_test.dart` | Widget-test coverage for CTRL-01 through CTRL-04 | ✓ VERIFIED | 13 test cases across 5 groups, all passing |
| `pubspec.yaml` | `audioplayers` dependency | ✓ VERIFIED | `audioplayers: ^6.8.1` present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `lib/main.dart` | `lib/screens/setup_screen.dart` | `chimePlayer`/`soundOn` constructor params | WIRED | `main()` constructs one `AudioplayersChimePlayer` + one `ValueNotifier<bool>` seeded from `SetupPreferences.soundOn`, passed into `MyApp` → `SetupScreen` |
| `lib/screens/setup_screen.dart` | `lib/screens/running_screen.dart` | `RunningScreen(chimePlayer:, soundOn:)` in `_handleStart` | WIRED | Same `chimePlayer`/`soundOn` instances forwarded, not re-created |
| `_ParentControlsSheet` mute icon | `lib/settings/setup_preferences.dart` | `SetupPreferences.persistSoundOn(soundOn.value)` | WIRED | Fire-and-forget with `.catchError((_) {})` (WR-01 fix applied) |
| `_ParentControlsSheet` Pause/Resume/End timer buttons | `lib/timer/timer_controller.dart` | `context.read<TimerController>().pause()/resume()/endTimer()` | WIRED | Direct calls, proven by tests asserting `controller.phase` transitions |
| `_RunningScreenState._maybeReactToPhaseChange` | `lib/audio/chime_player.dart` | `widget.chimePlayer.play(_chimeBytes)` gated on `widget.soundOn.value` | WIRED | Edge-triggered once-only guard proven by `_FakeChimePlayer.playCount` assertions |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite green (single run, no regressions) | `flutter test` | 129/129 passed | ✓ PASS |
| Static analysis clean | `flutter analyze` | "No issues found!" | ✓ PASS |
| `audioplayers` dependency recorded | `grep -n "audioplayers:" pubspec.yaml` | `audioplayers: ^6.8.1` | ✓ PASS |
| Back button/handler fully removed | `grep -c "Icons.arrow_back\|_handleBack" lib/screens/running_screen.dart` | 0 hits both | ✓ PASS |
| All commit hashes referenced in SUMMARYs exist in git history | `git log --oneline \| grep <hashes>` | all 13 referenced commits found (`0d19bb2`, `40039d8`, `4bc68fa`, `041214a`, `cb497f9`, `ef85a58`, `ee580e3`, `270b1c4`, `5c3ee18`, `8994af1`, `8aca6c1`, `00ad19f`, `83a2877`) | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` conventional probes exist in this Flutter project and none are declared in the phase plans/summaries. Step 7c: SKIPPED (no runnable probes for this phase).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| CTRL-01 | 04-04 | Hidden ~850ms long-press opens Parent Controls sheet | ✓ SATISFIED | See Observable Truth 1 |
| CTRL-02 | 04-02, 04-03, 04-04 | Sheet offers Pause/Resume, End timer, Keep watching, mute toggle | ✓ SATISFIED | See Observable Truth 2; 04-03 additionally resolved the carried-forward D-10 loop-snap defect that Pause/Resume would otherwise expose |
| CTRL-03 | 04-01, 04-05 | Soft two-tone chime on completion (mute-gated), scene settles | ✓ SATISFIED | See Observable Truth 3 |
| CTRL-04 | 04-05 | Breathing "All done" pill returns to Setup on tap | ✓ SATISFIED | See Observable Truth 4 |

**Note (documentation lag, non-blocking):** `.planning/REQUIREMENTS.md`'s working tree still shows `CTRL-01` as unchecked (`[ ]`) and `Pending` in the traceability table, while `CTRL-02`/`CTRL-03`/`CTRL-04` are already marked `Complete`. This is a doc-sync gap, not a code gap — the codebase evidence above shows CTRL-01 is fully implemented and tested identically to the other three. Recommend updating `REQUIREMENTS.md` to mark CTRL-01 `[x]`/`Complete` as part of phase close-out.

No orphaned requirements found: REQUIREMENTS.md maps exactly CTRL-01 through CTRL-04 to Phase 4, and all four appear in plan frontmatter `requirements:` fields (04-01: CTRL-03; 04-02: CTRL-02; 04-03: CTRL-02; 04-04: CTRL-01, CTRL-02; 04-05: CTRL-03, CTRL-04).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER debt markers found in any phase-modified file | — | Clean |
| — | — | No empty-return/no-op stub implementations (`return null`, `=> {}`, etc.) found | — | Clean |

Three Warning-tier findings from `04-REVIEW.md` (WR-01 unawaited persistSoundOn error handling, WR-02 sheet primary-button done-state handling, WR-03 missing PressableSurface pressed-color fidelity) were all fixed and verified in `04-REVIEW-FIX.md` (commits `8aca6c1`, `00ad19f`, `83a2877`) — confirmed present in the current code above, not re-flagged here. Two Info-tier findings (IN-01 duplicated default-injection logic between `MyApp`/`SetupScreen`, IN-02 error-swallowing without logging) were explicitly left out of fix scope per the review-fix report and remain low-impact style notes, not gaps against the phase goal.

### Human Verification Required

None. The two on-device checkpoints this phase required (04-04 Task 4: blur smoothness; 04-05 Task 3: chime sound quality/mute/ringer-silent/foreground-reveal) were both already gated `checkpoint:human-verify` during execution and approved on a real Android emulator (`emulator-5554`, Android 16/API 36), documented in `04-04-SUMMARY.md` and `04-05-SUMMARY.md` respectively. Per this verification's scope, these are not re-opened as new human-verification items.

### Gaps Summary

No gaps found. All 4 roadmap success criteria are observably true in the codebase: the hidden long-press gate, the Parent Controls sheet's four actions, the mute-gated once-only completion chime, and the breathing "All done" pill are all implemented, wired end-to-end (`main.dart` → `SetupScreen` → `RunningScreen`), and covered by 13 passing widget tests plus the pre-existing full suite (129/129 green, `flutter analyze` clean). All three code-review Warning findings were fixed and independently re-verified against the current source. The only non-blocking item is a documentation-sync note (REQUIREMENTS.md's CTRL-01 checkbox/table row not yet flipped to Complete), which does not affect goal achievement.

---

*Verified: 2026-07-09T13:00:00Z*
*Verifier: Claude (gsd-verifier)*
