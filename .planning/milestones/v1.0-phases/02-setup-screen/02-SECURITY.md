---
phase: 02
slug: setup-screen
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-07
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| parent tap -> app state | Local UI input only; no network, no external/untrusted data | UI gesture -> in-memory widget state |
| stepper interaction -> customMin state -> TimerController.start | Local UI input; only integrity concern is keeping customMin inside 1..120 through any gesture/edge sequence | int (minutes) |
| shared_preferences store -> app (read on launch) | Stored XML can be edited on a rooted device or written by a future app version; values read back are untrusted | int (durationMin), String (theme name) |
| pub.dev -> build (dependency install) | shared_preferences pulled into the build | package source code |
| bundled font assets -> app render | Static local assets shipped in the APK; no runtime fetch | .ttf files |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-02-01P | Denial of Service | Start -> TimerController.start(minutes) | low | accept | Minutes originates from a fixed preset set (1/5/10/15/30); TimerController.start already clamps to 1..120 (Phase 1). No untrusted value path. | closed |
| T-02-02P | Tampering | Preset selection state | low | accept | Pure in-memory local widget state; no persistence or external input in this plan. | closed |
| T-02-03P | Tampering | SceneTheme selection state | low | accept | Single-select in-memory enum state constrained to SceneTheme.values; no untrusted input, no persistence in this plan. | closed |
| T-02-04P | Denial of Service | CustomPainter.paint on scene cards | low | accept | shouldRepaint==false and fixed geometry — no per-frame repaint cost, no unbounded work. | closed |
| T-02-01 | Tampering | SetupScreen `_setCustomMin` / customMin (V5 Input Validation) | high | mitigate | Verified: `_setCustomMin` clamps to `v.clamp(1, 120)` at the sole write path (lib/screens/setup_screen.dart:91), independent of button-disable logic. | closed |
| T-02-05P | Denial of Service | HoldRepeatButton repeat Timer | medium | mitigate | Verified: repeat Timer cancelled on long-press end, long-press cancel, AND dispose (lib/widgets/hold_repeat_button.dart:91-101); single-shot rescheduling Timer, not Timer.periodic. | closed |
| T-02-02 | Tampering | SetupPreferences.load() reading durationMin/theme | high | mitigate | Verified: durationMin clamped via `storedDuration?.clamp(_minDurationMin, _maxDurationMin) ?? 5` and theme resolved via `SceneTheme.values.firstWhere(..., orElse: () => SceneTheme.disc)` (lib/settings/setup_preferences.dart:59-78); both wrapped in try/catch with safe fallback. | closed |
| T-02-06P | Tampering | Custom value leaking into persistence | medium | mitigate | Verified: `persistIfPreset` writes durationMin only when `!showCustom` (lib/settings/setup_preferences.dart:97-99); a Custom last-use restores to the 5-min default. | closed |
| T-02-SC | Tampering | shared_preferences dependency (supply chain) | high | accept | Verdict OK in 02-RESEARCH.md Package Legitimacy Audit — official Flutter-team package, publisher flutter.dev, source github.com/flutter/packages. | closed |
| T-02-07P | Spoofing | Font asset provenance | low | mitigate | Verified: fonts bundled locally in assets/fonts/ (Baloo2-Bold.ttf, Quicksand-{Regular,Medium,SemiBold,Bold}.ttf), pubspec.yaml weight declarations match filenames (700=Bold, etc.); no runtime fetch. | closed |
| T-02-08P | Information Disclosure | Setup/placeholder screens | low | accept | No sensitive data rendered; screens show only non-sensitive duration/scene UI and a wordless placeholder. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-02-01 | T-02-01P | Preset minute values are a fixed, hardcoded set; downstream clamp already exists from Phase 1. | Plan 02-01 threat model | 2026-07-07 |
| R-02-02 | T-02-02P | In-memory-only widget state; no persistence or external input surface in this plan. | Plan 02-01 threat model | 2026-07-07 |
| R-02-03 | T-02-03P | In-memory-only enum selection; no persistence in this plan. | Plan 02-02 threat model | 2026-07-07 |
| R-02-04 | T-02-04P | Painter has fixed geometry and shouldRepaint==false; no unbounded work possible. | Plan 02-02 threat model | 2026-07-07 |
| R-02-05 | T-02-SC | shared_preferences verified as official flutter.dev package via manual pub.dev audit (02-RESEARCH.md). | Plan 02-04 threat model | 2026-07-07 |
| R-02-06 | T-02-08P | Screens render only non-sensitive duration/scene UI; no sensitive data present. | Plan 02-05 threat model | 2026-07-07 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-07 | 11 | 11 | 0 | /gsd-secure-phase (plan-time register, L1 grep-depth verification, short-circuit — no auditor spawn needed) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-07
