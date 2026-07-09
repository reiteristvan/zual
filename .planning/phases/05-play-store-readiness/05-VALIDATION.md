---
phase: 5
slug: play-store-readiness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-09
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter SDK) — already used throughout `test/` |
| **Config file** | none — standard `flutter test` invocation, no custom config |
| **Quick run command** | `flutter test test/tool/generate_launcher_icon_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30-60 seconds for full suite (existing project baseline) |

---

## Sampling Rate

- **After every task commit:** Run the relevant quick command for build-adjacent tasks (icon spike, signing config check)
- **After every plan wave:** Run `flutter test` (full existing suite — must stay green; this phase touches no app logic, so a regression would indicate an accidental code change, not an expected one)
- **Before `/gsd-verify-work`:** Full suite green, plus the manual verification checklist (release build installs and runs a full countdown on a real device — Success Criterion #4)
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | TBD | 0 | PUBLISH-02 (icon spike) | — | `SunrisePainter`-derived PNGs render successfully headlessly | unit (flutter_test) | `flutter test test/tool/generate_launcher_icon_test.dart` | ❌ W0 | ⬜ pending |
| 05-0X-0X | TBD | TBD | PUBLISH-01 | T-05-01 (keystore leak) | `applicationId` is `com.ireiter.zual`; release build type uses `release` signing config, not `debug` | manual/build-check | `flutter build appbundle --release` succeeds; verify signed cert is not debug cert | ❌ W0 | ⬜ pending |
| 05-0X-0X | TBD | TBD | PUBLISH-02 (privacy policy) | — | Privacy policy page is live at a stable GitHub Pages URL | manual/smoke | `curl -sI https://<user>.github.io/<repo>/` (expect 200) | ❌ W0 | ⬜ pending |
| 05-0X-0X | TBD | TBD | PUBLISH-02 (screenshots) | — | 4 real-device screenshots exist, one per scene, full-bleed | manual-only | N/A — human/device capture step | — | ⬜ pending |
| 05-0X-0X | TBD | TBD | PUBLISH-02 (content rating/audience) | — | Draft answer sheet exists and is internally consistent with D-07/D-08 | manual-only | N/A — human reviews doc against locked decisions | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: exact Task IDs/plan/wave numbers will be finalized by the planner; this table transcribes RESEARCH.md's Phase Requirements → Test Map (05-RESEARCH.md "Validation Architecture" section) into the per-task shape.*

---

## Wave 0 Requirements

- [ ] `test/tool/generate_launcher_icon_test.dart` — spike proving `SunrisePainter` → PNG rendering works headlessly (Pattern 2 in 05-RESEARCH.md); this gates the entire D-04 icon-generation task. If the spike fails, fall back to a live-device/emulator screenshot of `SunriseScene` at a fixed progress as the icon source.
- [ ] No shared fixtures needed — the app's existing `test/` suite is untouched by this phase's changes.
- [ ] Framework install: none — `flutter_test` already present; only new pub dependency is `flutter_launcher_icons` (dev-only), not a testing dependency.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Release build uses production signing (not debug) | PUBLISH-01 | No automated Dart test can assert Gradle signing config short of a full Gradle build | Run `flutter build appbundle --release`; verify success and that the signed cert is the upload cert, not the debug cert |
| 4 real-device screenshots, one per scene | PUBLISH-02 | Device capture is inherently outside `flutter test`'s reach; D-12 forbids a staged screenshot-harness screen | Run each of the 4 scenes on a real device/emulator at a representative progress point, capture via adb screencap / Android Studio, verify full-bleed with no frame/caption |
| Privacy policy page live and correct | PUBLISH-02 | GitHub Pages deploy/DNS propagation and content correctness aren't verifiable from within the repo alone | After deploy, `curl -sI <url>` expect 200, then manually open the URL and confirm content matches the drafted policy |
| Content rating / target audience answer sheet | PUBLISH-02 | Play Console questionnaire itself is external; nothing in-repo to automate, and wording drifts over time (STATE.md blocker) | Human reviews the drafted answer doc against D-07/D-08 and re-verifies against the live Play Console form at actual submission time |
| Full countdown runs on a real Android device | Success Criterion #4 | End-to-end device behavior, not unit-testable | Install the signed release build on a real device, run a full countdown to completion, confirm no crashes/visual issues |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
