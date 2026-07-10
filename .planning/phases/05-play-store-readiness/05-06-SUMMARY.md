---
phase: 05-play-store-readiness
plan: 06
subsystem: android-launcher-icon
tags: [gap-closure, launcher-icon, play-store]
dependency-graph:
  requires: [PUBLISH-02]
  provides: [launcher-icon-inset-reverted]
  affects: [android/app/src/main/res/mipmap-anydpi-v26, store_assets]
tech-stack:
  added: []
  patterns:
    - "flutter_launcher_icons default inset (16%) relied on implicitly by omitting the pubspec key, rather than pinning an explicit override"
key-files:
  created: []
  modified:
    - pubspec.yaml
    - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
decisions:
  - "Removed adaptive_icon_foreground_inset: 0 entirely rather than setting it to 16 explicitly, so the tool's own default (which is what was on-device-verified pre-260710-keg) is the source of truth going forward"
metrics:
  duration: 5min
  completed: 2026-07-10
status: complete
---

# Phase 05 Plan 06: Revert Launcher Icon Inset Overcorrection Summary

Reverted the 260710-keg quick-task overcorrection that set `adaptive_icon_foreground_inset: 0`
in pubspec.yaml, which made the sunrise render near-edge-to-edge on a flat yellow field because
Android's adaptive-icon OS-level mask crop stacks with the tool's own inset. Removing the key
restores flutter_launcher_icons' default 16% inset, recovering the balanced sunrise rendering
already verified on a real Samsung A25 (05-05-SUMMARY.md).

## What Was Built

**Task 1 — Revert inset override and regenerate launcher icon assets:**
Removed the single line `adaptive_icon_foreground_inset: 0` from the `flutter_launcher_icons:`
block in `pubspec.yaml`. Ran `dart run flutter_launcher_icons`, which regenerated
`android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` with `android:inset="16%"`
(the tool default). The legacy `mipmap-*/ic_launcher.png` fallback files came out byte-identical
to their previously-committed versions — the tool composites those flattened PNGs directly from
the source images without applying the adaptive-icon inset value, so there was nothing to
re-stage for those five files. `flutter build apk --debug` succeeded, producing
`build/app/outputs/flutter-apk/app-debug.apk`.

**Task 2 — Regenerate the 512x512 store-listing icon:**
Reran `flutter test test/tool/generate_store_icon_test.dart`. All assertions passed (PNG
signature, RGBA color type, 512x512 dimensions). As predicted by the plan, the compositor test
flattens `assets/icon/icon_background.png` + `icon_foreground.png` directly — it does not
consult the adaptive XML inset value — so the regenerated `store_assets/icon_512.png` was
byte-identical (same md5) to the version already committed in `260710-keg`. No new commit was
needed for this task since there was no file delta to stage.

## Deviations from Plan

None — plan executed exactly as written. Both file-delta expectations in the plan
(mipmap PNGs unchanged, store icon byte-identical) held true and are documented here rather
than treated as anomalies.

### Build Noise (not a deviation)

`flutter build apk --debug` printed several Kotlin incremental-compiler "Suppressed" exceptions
about `RelocatableFileToPathConverter`/mismatched Windows drive roots (comparing a `C:\...`
pub-cache path against the `D:\...` worktree path). This is a known quirk of running Flutter
Android builds from a git worktree on a different drive letter than the global pub cache, not
something introduced by this plan's changes. The build still completed successfully and
produced a valid APK, so no action was taken.

## Verification

- `pubspec.yaml` no longer contains `adaptive_icon_foreground_inset` — confirmed via grep.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` declares `android:inset="16%"` —
  confirmed via grep and full-file read.
- `flutter build apk --debug` exited 0 and produced `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter test test/tool/generate_store_icon_test.dart` passed (1/1).
- `store_assets/icon_512.png` exists and is unchanged (md5 `eb29d10e29ee324b26a2e2f55aa7e709`,
  matching the pre-existing committed file from `260710-keg`).

## Commits

- `299b863`: fix(05-06): revert launcher icon foreground inset to tool default
  (pubspec.yaml, android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml)

Task 2 produced no new commit — the regenerated store icon and legacy mipmap PNGs were
byte-identical to already-committed content, so there was nothing to stage.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or trust-boundary schema
changes were introduced. This plan only touches build-time icon-generation config and
regenerated binary assets.
