---
phase: 03
slug: scene-themes
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-08
---

# Phase 03 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| `TimerController.progress` → scene painters (Disc/Sunrise/Walk/Car) | Numeric 0..1 progress crosses from the timer into per-frame draw math; the only "input" any scene painter consumes. Already clamped upstream by `TimerController`. | `double` progress value, internal only |
| `scene_registry.sceneFor` switch | Fixed `SceneTheme` enum mapped to a widget; no external/untrusted input reaches it. | enum value, internal only |
| `spinAngle` (per-scene ticker) → `CarPainter._paintWheel` draw math | Bounded rotation angle derived internally from wall-clock time (`2*pi*loopPhase(...)`), never user- or network-supplied. | `double` angle, internal only |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-03-01 | Denial of Service | `DiscPainter` draw math (radius/scale) | low | mitigate | `remaining = (1-progress).clamp(0,1)` plus the 0.001 radius floor — confirmed present at `lib/scenes/disc/disc_painter.dart:80`. | closed |
| T-03-02 | Tampering | `scene_registry.sceneFor` switch | low | accept | Fixed enum→widget mapping, no external input; exhaustive-switch discipline is the only control needed. | closed |
| T-03-03 | Denial of Service | `starOpacity`/`moonOpacity` + combined star alpha | high | mitigate | `.clamp(0.0,1.0)` on every progress-derived opacity/alpha before `withValues(alpha:)` — confirmed present at `lib/scenes/sunrise/sunrise_painter.dart:10-11,112`; guarded by the full 0..1 sweep widget test. | closed |
| T-03-04 | Denial of Service | Sun glow alpha (`0.3 + p*0.5`) | low | mitigate | `.clamp(0.0,1.0)` on the glow alpha — confirmed present at `lib/scenes/sunrise/sunrise_painter.dart:150`. | closed |
| T-03-05 | Denial of Service | `arrivalLeftFraction` / car+walk position math | low | mitigate | `progress.clamp(0.0,1.0)` re-clamp inside the pure fn — confirmed present at `lib/scenes/walk/walk_painter.dart:15` (comment explicitly cites the T-03-05 mitigation); position offsets are bounded fractions of size. Guarded by 0..1 sweep widget tests. | closed |
| T-03-06 | Tampering | `scene_registry` exhaustive switch | low | accept | Fixed enum→widget mapping with no external input; making the switch exhaustive removed the fallback branch. | closed |
| T-03-07 | Tampering | `CarPainter._paintWheel` spoke marking (gap-closure 03-04) | low | accept | Presentation-only change to a pure `CustomPainter`. No new I/O, network, storage, permission, package, or state surface introduced; the marking is a single bounded `drawLine` inside the existing `save/rotate/restore` block. | closed |
| T-03-08 | Denial of Service | raster-diff regression test (`toImage`/`toByteData`) (gap-closure 03-04) | low | accept | Test-only code path at a small fixed `Size(200, 400)`; runs on the CPU test rasterizer, bounded and deterministic. No runtime/production impact. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-03-01 | T-03-02 | Fixed enum-to-widget registry switch has no external/untrusted input surface; exhaustiveness is the only meaningful control and is already enforced by the Dart compiler. | Plan 03-01 threat model | 2026-07-07 |
| AR-03-02 | T-03-06 | Same fixed enum-to-widget registry; exhaustive switch removed the fallback branch, no further mitigation applicable. | Plan 03-03 threat model | 2026-07-07 |
| AR-03-03 | T-03-07 | Wheel-spoke marking is a presentation-only `CustomPainter` change with no new I/O, network, storage, permission, package, or state surface. | Plan 03-04 threat model | 2026-07-07 |
| AR-03-04 | T-03-08 | Raster-diff test runs only in the test rasterizer at a small fixed size; bounded, deterministic, no production impact. | Plan 03-04 threat model | 2026-07-07 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-08 | 8 | 8 | 0 | Claude (secure-phase, L1 grep-depth short-circuit — register authored at plan time, ASVS L1, threats_open confirmed 0 pre-audit) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-08
