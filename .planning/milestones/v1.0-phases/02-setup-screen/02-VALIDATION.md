---
phase: 2
slug: setup-screen
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter SDK; already used in `test/widget_test.dart` and `test/timer/timer_controller_test.dart`) |
| **Config file** | none — no `dart_test.yaml`; standard `flutter test` discovery over `test/` |
| **Quick run command** | `flutter test test/screens/ test/widgets/ test/settings/` (once created) |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~10-20 seconds (Phase 1's suite of 17 tests ran well under this; widget tests add modest overhead) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <changed test file>`
- **After every plan wave:** Run `flutter test` (full suite, including Phase 1's existing `timer_controller_test.dart` and `widget_test.dart` — the latter must be updated since it currently asserts on the "Hello, World!" scaffold text this phase removes)
- **Before `/gsd-verify-work`:** Full suite must be green, plus one manual Android-emulator pass against Layout A (SETUP-05 has no automated pixel-diff tooling)
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

*Task IDs are assigned by the planner; this table maps each phase requirement to its required test coverage so the planner allocates a task per row.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | SETUP-01 | — | N/A | widget | `flutter test test/screens/setup_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | SETUP-02 | — | Clamp 1–120 in state setter, not just via disabled buttons (V5) | widget | `flutter test test/widgets/hold_repeat_button_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | SETUP-03 | — | N/A | widget | `flutter test test/screens/setup_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | SETUP-04 | — | N/A | widget | `flutter test test/screens/setup_screen_test.dart` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | SETUP-05 | — | N/A | manual | manual QA against `design/README.md` §A / `Zual.dc.html` on Android emulator | n/a | ⬜ pending |
| TBD | TBD | TBD | PERSIST-01 | T-2-01 | Clamp/validate restored values on read (out-of-range `durationMin`, unknown `theme` string) — fall back to `disc`/`5` rather than trusting stored data (Tampering) | unit + widget | `flutter test test/settings/setup_preferences_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/screens/setup_screen_test.dart` — stubs for SETUP-01, SETUP-03, SETUP-04
- [ ] `test/widgets/hold_repeat_button_test.dart` — stubs for SETUP-02 (tap-once, hold-accelerate, disabled-edge, dispose-mid-hold cases)
- [ ] `test/settings/setup_preferences_test.dart` — stubs for PERSIST-01 and the D-10 preset-only-persistence rule
- [ ] `test/widget_test.dart` — must be **updated**, not left as-is (currently expects `MyHomePage`'s "Hello, World!" text, which `SetupScreen` replaces)
- [ ] No new test framework install needed — `flutter_test` already present; use its official `SharedPreferences.setMockInitialValues()` helper for prefs tests rather than hand-rolling a fake backend

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual/pixel fidelity to Layout A (colors, radii, spacing, typography) | SETUP-05 | No automated pixel-diff tooling configured in this project | Run the app on an Android emulator (API 24–28 per Phase 3's blocker note), compare side-by-side against `design/README.md` §"A. Setup — Layout A" and `design/Zual.dc.html` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
