---
phase: 3
slug: scene-themes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter SDK) |
| **Config file** | none — uses Flutter defaults, per `.planning/codebase/TESTING.md` |
| **Quick run command** | `flutter test test/scenes/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds (full suite, current project size) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/scenes/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green, plus the human device-smoothness checkpoint (D-03) recorded as a UAT item
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SCENE-01 | — | discColorForRemaining returns correct zone/lerp at r=0.6/0.35/0.1 boundaries | unit | `flutter test test/scenes/disc/disc_painter_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | SCENE-01 | — | DiscScene renders without throwing across a 0.0→1.0 progress sweep | widget | `flutter test test/scenes/disc/disc_scene_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | SCENE-02 | — | starOpacity/moonOpacity/sunTopFraction/hillColor never produce an out-of-range value across 0..1 | unit | `flutter test test/scenes/sunrise/sunrise_painter_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | SCENE-02 | — | SunriseScene renders without throwing across a 0.0→1.0 progress sweep (guards the negative-opacity pitfall) | widget | `flutter test test/scenes/sunrise/sunrise_scene_test.dart` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | SCENE-03 | — | arrivalLeftFraction(0.0) == 0.06, arrivalLeftFraction(1.0) == 0.68 (arrival at time-up) | unit | `flutter test test/scenes/walk/walk_painter_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 2 | SCENE-04 | — | arrivalLeftFraction shared/reused correctly by car scene; car renders without throwing across 0..1 sweep | unit + widget | `flutter test test/scenes/car/car_painter_test.dart` | ❌ W0 | ⬜ pending |
| 03-05-01 | 05 | 1 | SCENE-05 | — | sceneFor(theme, progress) registry returns the correct concrete widget for all 4 SceneTheme values | unit | `flutter test test/scenes/scene_registry_test.dart` | ❌ W0 | ⬜ pending |
| 03-05-02 | 05 | 1 | SCENE-05 | — | No GestureDetector/InkWell/tap-reactive ancestor exists anywhere in a mounted scene's subtree | widget | `flutter test test/scenes/scene_renderer_test.dart` | ❌ W0 | ⬜ pending |
| 03-05-03 | 05 | 1 | SCENE-05 | — | shouldRepaint returns false when neither progress nor decorative phase changed, true when either does | unit | included in each scene's painter test file | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Plan/Wave/Task-ID numbering above is a placeholder based on the research's requirement grouping — the planner assigns actual plan IDs and waves; this table is illustrative of coverage, not a locked task list.*

---

## Wave 0 Requirements

- [ ] `test/scenes/disc/disc_painter_test.dart` — covers SCENE-01
- [ ] `test/scenes/disc/disc_scene_test.dart` — covers SCENE-01
- [ ] `test/scenes/sunrise/sunrise_painter_test.dart` — covers SCENE-02
- [ ] `test/scenes/sunrise/sunrise_scene_test.dart` — covers SCENE-02
- [ ] `test/scenes/walk/walk_painter_test.dart` — covers SCENE-03
- [ ] `test/scenes/car/car_painter_test.dart` — covers SCENE-04
- [ ] `test/scenes/scene_registry_test.dart` — covers SCENE-05 (registry contract)
- [ ] `test/scenes/scene_renderer_test.dart` — covers SCENE-05 (no-gesture-handler assertion)
- [ ] `test/support/progress_sweep.dart` — shared test helper for pumping a scene across a progress sweep without `pumpAndSettle` (avoids duplicating the pump-at-fixed-durations loop across all four scene test files)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual motion is smooth/jank-free across all 4 scenes | SCENE-05 | No automated pixel-diff or frame-timing tooling exists in this project; perceptual smoothness cannot be asserted by `flutter_test` | Run the app on a real low/mid-end Android device (API 24–28); watch each scene for a full run (or a shortened test duration); confirm no visible stepping/stutter, especially on the Shrinking Disc's scale animation. Fallback if no physical device is available: throttled emulator profile + DevTools Performance view "Highlight repaints", noted as lower-confidence. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
