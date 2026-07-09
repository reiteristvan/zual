---
phase: 02-setup-screen
verified: 2026-07-07T10:48:06Z
status: passed
score: 11/13 must-haves verified (1 override, 1 present-behavior-unverified, 1 uncertain/human-only)
behavior_unverified: 1 # WR-02 manual-back-vs-auto-pop race guard: code present + wired, race window not exercised by an automated test
overrides_applied: 1
overrides:

  - must_have: "Destructive #E0805F appears nowhere on the Setup screen or placeholder Running screen"
    reason: "02-UI-SPEC.md's own Scene Mini-Preview table specifies #E0805F for the Walking Home character body; this is a decorative illustration color, not the reserved destructive-action affordance color, and the spec's Color table reservation note was not reconciled with its own preview table when written."
    accepted_by: "reiteristvan"
    accepted_at: "2026-07-07T11:05:00Z"
gaps: []
behavior_unverified_items:

  - truth: "WR-02 fix: a manual back-button tap while an auto-pop-on-done post-frame callback is already scheduled results in exactly one Navigator.pop(), never two"
    test: "On PlaceholderRunningScreen, drive TimerController to TimerPhase.done (scheduling the post-frame auto-pop) and, in the same frame window before that callback runs, tap the back control; assert Navigator.pop() fires exactly once and no Navigator assertion/extra pop occurs."
    expected: "_leftScreen guards both _handleBack and _maybeAutoPopWhenDone's post-frame callback so only one of the two ever calls pop() — no double-pop, no Navigator assertion."
    why_human: "The fix (lib/screens/placeholder_running_screen.dart, commit 6014ae5) is present and wired (single shared _leftScreen bool + _leaveOnce() called from both exit paths), and the existing back-control and done-auto-return tests both pass individually, but no test in test/screens/setup_screen_test.dart schedules the auto-pop callback and then fires a manual back tap before it runs — the exact race window 02-REVIEW-FIX.md itself flags as 'requires human verification of the race-condition behavior specifically' is not exercised by any automated test (confirmed by grep: no reference to _leftScreen/_leaveOnce/double-pop in the test file)."
human_verification:

  - test: "Manual QA: on PlaceholderRunningScreen, let the timer reach completion (or set a very short duration) and tap the back arrow at the exact moment the screen would auto-return; repeat rapidly several times."
    expected: "The app returns to Setup exactly once per attempt — no crash, no Navigator assertion, no visible double-navigation flicker."
    why_human: "Race-condition timing; see behavior_unverified_items above — WR-02's fix has no automated regression test for the specific race it closes."

  - test: "View the four scene mini-preview cards (Shrinking disc / Night to sunrise / Walking home / Car on a road) on an Android emulator/device and compare gradients, shadow/glow rendering, and shape proportions against 02-UI-SPEC.md's Scene Mini-Preview table and design/README.md."
    expected: "Gradients render smoothly, the sunrise glow and disc shadow are visible and soft (not harsh/aliased), and house/character/car proportions read clearly at the 74px preview size."
    why_human: "Colors/geometry were transcribed and unit-tested for structural correctness (shouldRepaint==false, correct subclassing) but pixel-level rendering quality (gradient smoothness, shadow/glow softness) can only be judged visually. Flagged as human_judgment: true / item D4 in 02-02-SUMMARY.md."

  - test: "Run the app on an Android emulator (API 24-28) and compare the Setup screen side-by-side against design/README.md 'A. Setup — Layout A' and design/Zual.dc.html: colors, radii (buttons 22 / cards 26 / scene thumbs 16 / Start 26), spacing, typography (Baloo 2 wordmark, Quicksand body), all copy strings, the 3px selection ring, and pressed-state feedback; confirm zero text/numbers on the placeholder running screen."
    expected: "The rendered screen matches Layout A pixel-for-pixel within reasonable device-rendering tolerance."
    why_human: "This is 02-05-PLAN.md's own explicit <human-check> (SETUP-05 sign-off) — the plan states 'no automated pixel-diff tooling exists in this project; human_verify_mode is end-of-phase.' It has not yet been performed per 02-05-SUMMARY.md's Next Phase Readiness section."
---

# Phase 2: Setup Screen Verification Report

**Phase Goal:** A parent can configure a countdown — duration and scene — and launch it, matching Layout A of the design spec, with last-used settings pre-selected.
**Verified:** 2026-07-07T10:48:06Z
**Status:** human_needed (1 override accepted post-verification — see frontmatter `overrides:`)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Parent can select a preset duration (1/5/10/15/30 min); 5-min default; visible 3px accent ring on selection (SETUP-01) | ✓ VERIFIED | `lib/screens/setup_screen.dart` `_buildPresetCard`/`_buildSelectionRing`; `test/screens/setup_screen_test.dart` "renders the five duration presets..." and "5 min preset is selected by default" both pass (confirmed via `flutter test`, 47/47 green) |
| 2 | Parent can set a custom duration 1–120 min via an accelerating hold-repeat stepper, clamped independent of disable-button state (SETUP-02, V5) | ✓ VERIFIED | `lib/widgets/hold_repeat_button.dart` (accelerating single-shot rescheduling `Timer`, cancelled on end/cancel/dispose); `lib/screens/setup_screen.dart._setCustomMin` clamps unconditionally; `test/screens/setup_screen_test.dart` V5 direct-`onStep` edge tests and `test/widgets/hold_repeat_button_test.dart` (5 tests) all pass |
| 3 | Parent can pick one of 4 scene themes from thumbnail cards; single-select; disc default; card depends only on the `ScenePreviewPainter` abstraction (SETUP-03) | ✓ VERIFIED | `lib/widgets/scene_grid.dart` — `SceneCard` takes `ScenePreviewPainter preview` (never a concrete type by name); `SceneGrid` owns the theme→painter/label maps; `test/screens/setup_screen_test.dart` scene-selection group passes |
| 4 | Pressing Start calls `TimerController.start(selectedMinutes)` and navigates to the running screen (SETUP-04) | ✓ VERIFIED | `lib/screens/setup_screen.dart._handleStart` — `context.read<TimerController>().start(_selectedMinutes)` then `Navigator.push(...PlaceholderRunningScreen())`; E2E test passes |
| 5 | Placeholder running screen shows a shrinking accent circle scaled by `(1-progress)`; back control ends timer + returns to Setup; auto-returns on `TimerPhase.done` | ✓ VERIFIED (core mechanics) | `lib/screens/placeholder_running_screen.dart` — `Transform.scale(scale: remaining)`, `_handleBack`, `_maybeAutoPopWhenDone`; both dedicated tests pass. The specific back-vs-auto-pop *race* is a separate, narrower claim — see item 12 |
| 6 | On next launch, the previously used preset duration and theme are pre-selected before the first frame renders; a Custom last-use never persists a custom number (PERSIST-01, D-10) | ✓ VERIFIED | `lib/main.dart` awaits `SetupPreferences.load()` before `runApp`, forwards into `MyApp`→`SetupScreen`; `SetupPreferences.persistIfPreset` writes `durationMin` only when `!showCustom`; `test/screens/setup_screen_test.dart` persistence group + `test/settings/setup_preferences_test.dart` round-trip test pass |
| 7 | Restored values are validated on read: out-of-range duration clamps to 1..120, unknown/missing theme falls back to disc, and a *wrong-typed* stored value never crashes launch (T-02-02 Tampering) | ✓ VERIFIED | `lib/settings/setup_preferences.dart.load()` wraps `getInt`/`getString` in try/catch (post-CR-01 fix, commit `df13187`); `lib/main.dart` also wraps `SetupPreferences.load()` in try/catch as defense-in-depth; `test/settings/setup_preferences_test.dart` clamp/fallback tests pass |
| 8 | Baloo 2 (700) and Quicksand (400/500/600/700) are bundled as local `.ttf` assets and applied via `AppTokens` — no runtime font fetch (SETUP-05) | ✓ VERIFIED | `assets/fonts/Baloo2-Bold.ttf` + 4 Quicksand weights present on disk (non-trivial file sizes, 78–422KB); declared in `pubspec.yaml`'s `flutter: fonts:` block; `lib/theme/app_tokens.dart` every `TextStyle` carries `fontFamily: fontBaloo`/`fontQuicksand` |
| 9 | Colors/radii/spacing/typography/copy across the Setup + placeholder screens structurally match `02-UI-SPEC.md` (buttons 22px, cards 26px, scene thumbs 16px, Start 26px, header 52/24/8, etc.) | ✓ VERIFIED (structural) | `lib/theme/app_tokens.dart` transcribes the exact hex/radius/shadow constants; `lib/screens/setup_screen.dart` header/grid/footer paddings match the spec's literal values. Pixel-level rendering fidelity is a separate claim — see item 13 |
| 10 | Pressed states use `#FFF7E9` (cards) / `#6E9A68` (Start); selection ring is 3px `#7FA87A` | ✓ VERIFIED | `lib/widgets/pressable_surface.dart` (shared `PressableSurface`, extracted per WR-03 fix, commit `8f86c8c`) uses `AppTokens.pressed`/`AppTokens.accentPressed`; selection rings use `AppTokens.accent` at 3px width throughout `setup_screen.dart` and `scene_grid.dart` |
| 11 | Destructive `#E0805F` appears nowhere on the Setup screen or placeholder Running screen (02-05-PLAN.md must-have, part of SETUP-05) | ✓ PASSED (override) | `lib/scenes/scene_preview.dart:182` uses `#E0805F` for the Walking Home character body per 02-UI-SPEC.md's own Scene Mini-Preview table. Override accepted by reiteristvan on 2026-07-07: this is a decorative illustration color, distinct from the reserved destructive-action affordance color; the spec's Color table reservation note was never reconciled against its own preview table. |
| 12 | WR-02 fix: a manual back tap racing an already-scheduled auto-pop-on-done callback never produces a double `Navigator.pop()` | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Fix is present and wired (`_leftScreen` shared guard + `_leaveOnce()`, commit `6014ae5`); existing tests pass but none schedules the auto-pop callback and then fires a manual back tap before it runs — the exact race is unexercised by any automated test. Flagged in 02-REVIEW-FIX.md as requiring human verification. |
| 13 | The Setup screen visually matches Layout A pixel-for-pixel (colors, radii, spacing, typography, shadow/glow rendering) on a real Android device/emulator | ? UNCERTAIN (human) | No automated pixel-diff tooling exists in this project (confirmed absent); 02-05-PLAN.md's own `<human-check>` and 02-02-SUMMARY.md's D4 both explicitly defer this to end-of-phase human sign-off, which per both summaries' "Next Phase Readiness" sections has not yet been performed. |

**Score:** 11/13 truths verified (1 override, 1 present-behavior-unverified, 1 uncertain/human-only)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/theme/app_tokens.dart` | Design tokens (colors/radii/shadows/text styles incl. fontFamily) | ✓ VERIFIED | All constants present, transcribed from UI-SPEC; fontFamily wired for both families |
| `lib/screens/setup_screen.dart` | Duration presets + Custom stepper + scene grid + Start, wired to TimerController/SetupPreferences | ✓ VERIFIED | Full implementation present; imports and uses TimerController, SetupPreferences, SceneGrid, HoldRepeatButton, PressableSurface |
| `lib/screens/placeholder_running_screen.dart` | Shrinking-circle placeholder, back control, auto-return | ✓ VERIFIED | Present, wired to TimerController via context.watch/read |
| `lib/scenes/scene_theme.dart` | `SceneTheme` enum (disc, sunrise, walk, car) | ✓ VERIFIED | Exact order confirmed |
| `lib/scenes/scene_preview.dart` | `ScenePreviewPainter` abstraction + 4 concrete painters | ✓ VERIFIED (see gap re: color choice) | All 4 painters present, `shouldRepaint == false`; one color value contradicts a separate must-have (item 11) |
| `lib/widgets/scene_grid.dart` | `SceneCard` + `SceneGrid`, abstraction-only dependency | ✓ VERIFIED | `SceneCard` never references a concrete painter type by name |
| `lib/widgets/hold_repeat_button.dart` | Leak-safe accelerating hold-repeat button | ✓ VERIFIED | Timer cancelled on end/cancel/dispose; range-agnostic |
| `lib/widgets/pressable_surface.dart` | Shared pressed-state widget (post-WR-03 extraction) | ✓ VERIFIED | Used by SetupScreen's preset/Custom/Start surfaces and SceneCard |
| `lib/settings/setup_preferences.dart` | `SetupPreferences.load()`/`persistIfPreset()` | ✓ VERIFIED | Clamp/fallback + try/catch (post-CR-01 fix) present |
| `assets/fonts/*.ttf` | Baloo 2 Bold + Quicksand 4 weights, offline | ✓ VERIFIED | 5 files present, non-trivial sizes, declared in pubspec.yaml |
| `test/screens/setup_screen_test.dart`, `test/widgets/hold_repeat_button_test.dart`, `test/settings/setup_preferences_test.dart`, `test/scenes/scene_preview_test.dart`, `test/widget_test.dart` | Full behavioral test coverage | ✓ VERIFIED | `flutter test` run independently by this verifier: 47/47 pass; `flutter analyze`: 0 issues |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `SetupScreen.Start` | `TimerController.start(minutes)` + `Navigator.push` | `_handleStart` | ✓ WIRED | Confirmed by direct code read + passing E2E test |
| `PlaceholderRunningScreen` | `TimerController` | `context.watch`/`context.read` | ✓ WIRED | phase==done → post-frame pop; back control → endTimer()+pop |
| `SceneCard` | `ScenePreviewPainter` (abstraction only) | constructor param | ✓ WIRED | `SceneGrid` is the sole place concrete painter types are named |
| `main()` | `SetupPreferences.load()` → `MyApp`/`SetupScreen` | await before `runApp`, constructor params | ✓ WIRED | No `FutureBuilder`; first-frame-correct restore confirmed by code + test |
| `SetupScreen.Start` | `SetupPreferences.persistIfPreset` | `unawaited(...).catchError((_){})` | ✓ WIRED | Fire-and-forget, failure genuinely swallowed post-WR-01 fix |
| `AppTokens` fontFamily | bundled `.ttf` assets | `pubspec.yaml` `flutter: fonts:` | ✓ WIRED | Family names match declared assets exactly |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| SETUP-01 | 02-01-PLAN.md | Parent can pick a duration from presets (1/5/10/15/30 min) | ✓ SATISFIED | `setup_screen.dart` preset grid + tests |
| SETUP-02 | 02-03-PLAN.md | Parent can pick a custom duration (1–120 min) via a stepper | ✓ SATISFIED | `hold_repeat_button.dart` + Custom stepper row + V5 clamp tests |
| SETUP-03 | 02-02-PLAN.md | Parent can pick one of 4 visual scene themes via thumbnail cards | ✓ SATISFIED | `scene_grid.dart` + `scene_preview.dart` + tests |
| SETUP-04 | 02-01-PLAN.md | Parent starts the timer with a single Start button showing selected duration | ✓ SATISFIED | `_handleStart` + footer Start label + E2E test |
| SETUP-05 | 02-05-PLAN.md | Setup screen matches Layout A pixel-accurately | ✓ SATISFIED | Structural fidelity (tokens/fonts/spacing) verified; destructive-color must-have PASSED (override, item 11); pixel-level Android sign-off still pending as human verification (item 13) |
| PERSIST-01 | 02-04-PLAN.md | App remembers last-used duration/theme and pre-selects on next launch | ✓ SATISFIED | `setup_preferences.dart` + main() preload + persistence tests |

All 6 phase requirement IDs (SETUP-01 through SETUP-05, PERSIST-01) are declared across the five plans' frontmatter and match REQUIREMENTS.md's Phase 2 traceability row-for-row. **No orphaned requirements** — REQUIREMENTS.md maps exactly these 6 IDs to Phase 2, and all 6 are claimed by a plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/scenes/scene_preview.dart` | 182 | Use of the reserved-destructive `#E0805F` hex literal on a Setup-screen-visible painter | ⚠️ Warning | Contradicts an explicit must-have and a SUMMARY.md claim; see Gaps |

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` debt markers found in any Phase 2 file (`lib/screens/`, `lib/widgets/`, `lib/scenes/`, `lib/settings/`, `lib/theme/`, `lib/main.dart`). References to "placeholder" are all the intentional, documented `PlaceholderRunningScreen` name (explicitly in-scope for this phase, replaced in Phase 3) — not stub/incomplete-work markers.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite passes (independently re-run, not trusted from SUMMARY) | `flutter test` | `00:04 +47: All tests passed!` | ✓ PASS |
| Static analysis clean | `flutter analyze` | `No issues found! (ran in 2.7s)` | ✓ PASS |
| WR-02 double-pop race specifically exercised | `grep -n "leftScreen\|_leaveOnce\|double.*pop\|race" test/screens/setup_screen_test.dart` | no matches | ? SKIP — routed to human verification |

### Deviations from SUMMARY Claims

- **02-05-SUMMARY.md** (Accomplishments; coverage item D2) states: *"Confirmed `#E0805F` destructive color appears nowhere on the Setup or placeholder Running screen."* This is contradicted by `lib/scenes/scene_preview.dart:182`, which was written in Plan 02 (before Plan 05 ran) and left unchanged by Plan 05. The claim appears to have been checked against the Setup screen's *own* widgets (`setup_screen.dart`, `scene_grid.dart`) without checking the scene-preview painters those widgets render.
- All other SUMMARY claims reviewed against source (navigation wiring, clamp logic, persistence behavior, font bundling, CR-01/WR-01/WR-02/WR-03 fixes) were independently confirmed accurate by direct code inspection and an independent `flutter test`/`flutter analyze` run.

### Human Verification Required

#### 1. WR-02 double-pop race (manual back tap vs. auto-pop-on-done)

**Test:** On `PlaceholderRunningScreen`, let the timer reach `TimerPhase.done` (or use a very short duration) and tap the back arrow at the exact moment auto-return would fire; repeat several times rapidly.
**Expected:** Exactly one return-to-Setup per attempt; no crash, no Navigator assertion, no visible double-navigation flicker.
**Why human:** The fix is present and wired (shared `_leftScreen` guard), but no automated test schedules the auto-pop callback and then fires a manual back tap before it runs — 02-REVIEW-FIX.md itself flags this exact race as requiring human verification.

#### 2. Scene mini-preview visual fidelity

**Test:** View the four scene cards on an Android emulator/device; compare gradients, shadow/glow rendering, and shape proportions against `02-UI-SPEC.md`'s Scene Mini-Preview table.
**Expected:** Gradients render smoothly; sunrise glow and disc shadow are visibly soft; house/character/car read clearly at 74px preview size.
**Why human:** Colors/geometry are unit-tested only for structural correctness (types, `shouldRepaint`), not pixel rendering quality. Flagged `human_judgment: true` (item D4) in 02-02-SUMMARY.md.

#### 3. Full Layout A fidelity sign-off on Android

**Test:** Run the app on an Android emulator (API 24–28); compare the Setup screen side-by-side against `design/README.md` "A. Setup — Layout A" and `design/Zual.dc.html` — colors, radii, spacing, typography, copy, selection ring, pressed-state feedback; confirm zero text/numbers on the placeholder running screen.
**Expected:** Matches Layout A within normal device-rendering tolerance.
**Why human:** This is 02-05-PLAN.md's own explicit `<human-check>` for the SETUP-05 sign-off; no pixel-diff tooling exists in this project, and per `config.json`'s `human_verify_mode: end-of-phase` it has not yet been performed (confirmed unresolved in 02-05-SUMMARY.md's "Next Phase Readiness").

### Gaps Summary

Phase 2's functional slice — duration selection (preset + custom), scene selection, Start → running-placeholder navigation, and last-used-settings persistence — is solidly implemented and independently confirmed: `flutter analyze` is clean, all 47 tests pass under a verifier-run (not just a SUMMARY claim), and every key link (Start→TimerController, prefs preload→first frame, persistence-on-Start, abstraction boundaries) traces correctly through the actual source.

One concrete gap was found and has since been overridden (see frontmatter `overrides:`): **02-05-PLAN.md's must-have "destructive `#E0805F` appears nowhere on the Setup or placeholder Running screen"** conflicted with the Walking Home scene-preview painter (written in Plan 02, unchanged by Plan 05), which uses that exact color for the character's body per 02-UI-SPEC.md's own Scene Mini-Preview table. Root cause: a self-contradiction inside `02-UI-SPEC.md` itself (its Color table reserves `#E0805F` for Phase 4's destructive action while its own Scene Mini-Preview table calls for that same hex on a decorative character illustration within this phase's Setup screen). Accepted by reiteristvan on 2026-07-07 as an intentional deviation — the two uses are semantically distinct (destructive-action affordance vs. incidental illustration color) and the spec's own tables were never reconciled.

No gaps remain. Three items are routed to human verification rather than automated coverage (as flagged by the executors/reviewer): the WR-02 race-condition behavior, scene mini-preview pixel fidelity, and the end-of-phase Android Layout A comparison. None of these block the functional correctness already confirmed above. Per the verification decision tree, all must-haves are now VERIFIED or PASSED (override), so this report's status is `human_needed` — the phase awaits the three human verification items above before final sign-off, not further gap closure.

---

_Verified: 2026-07-07T10:48:06Z_
_Verifier: Claude (gsd-verifier)_
