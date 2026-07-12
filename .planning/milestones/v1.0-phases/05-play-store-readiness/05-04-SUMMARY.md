---
phase: 05-play-store-readiness
plan: 04
subsystem: infra
tags: [flutter, android, flutter_launcher_icons, custom-painter, adaptive-icon, dart-ui]

# Dependency graph
requires:
  - phase: 05-play-store-readiness (plan 02)
    provides: "renderPainterToPng(CustomPainter, Size) -> Future<Uint8List>: reusable headless PNG-export helper, proven against the real SunrisePainter"
provides:
  - "assets/icon/icon_foreground.png, assets/icon/icon_background.png -- generated 1024x1024 Night-to-Sunrise icon sources"
  - "flutter_launcher_icons config in pubspec.yaml producing the full Android adaptive-icon asset set"
  - "Real, on-brand Night-to-Sunrise launcher icon replacing Flutter's default"
affects: ["05-05 (any remaining Play Store readiness plans referencing the app icon/branding)"]

# Tech tracking
tech-stack:
  added: ["flutter_launcher_icons ^0.14.4 (dev dependency)"]
  patterns:
    - "Icon source PNGs generated programmatically via renderPainterToPng + dedicated icon-only CustomPainters, restating (not importing) the scene painter's private palette constants"

key-files:
  created:
    - test/tool/icon_painters.dart
    - assets/icon/icon_foreground.png
    - assets/icon/icon_background.png
  modified:
    - test/tool/generate_launcher_icon_test.dart
    - pubspec.yaml
    - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml (generated)
    - android/app/src/main/res/mipmap-*/ic_launcher.png (regenerated)
    - android/app/src/main/res/drawable-*/ic_launcher_background.png, ic_launcher_foreground.png (generated)

key-decisions:
  - "Used `android: \"ic_launcher\"` in the flutter_launcher_icons config instead of 05-RESEARCH.md's example value \"launcher_icon\", so the tool overwrites the existing ic_launcher mipmap resource in place rather than renaming it and rewriting AndroidManifest.xml's icon reference."

patterns-established:
  - "Icon-only CustomPainters (test/tool/icon_painters.dart) restate a scene painter's private palette hexes with a comment citing the source, rather than importing private constants across files."

requirements-completed: [PUBLISH-02]

coverage:
  - id: D1
    description: "Two source PNGs (scene-matched sunrise gradient background, big simple padded sun foreground) rendered programmatically at 1024x1024 from the Night-to-Sunrise palette"
    requirement: "PUBLISH-02"
    verification:
      - kind: unit
        ref: "test/tool/generate_launcher_icon_test.dart#renders and writes the launcher icon foreground and background source PNGs (05-04-PLAN.md Task 1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "flutter_launcher_icons generates the full Android adaptive-icon asset set (mipmap-anydpi-v26/ic_launcher.xml + legacy mipmap-*/ic_launcher.png) from the two PNGs, and the app builds with the new icon"
    requirement: "PUBLISH-02"
    verification:
      - kind: other
        ref: "dart run flutter_launcher_icons (manual invocation, generated files committed) + flutter build apk --debug"
        status: pass
    human_judgment: true
    rationale: "Visual correctness of the rendered launcher icon (does it actually look like a recognizable Night-to-Sunrise sun on-device/in-launcher, at 48dp, under circle/squircle masking) requires a human to look at the installed app, not just automated file-existence/build-success checks."

# Metrics
duration: 22min
completed: 2026-07-10
status: complete
---

# Phase 05 Plan 04: Adaptive Launcher Icon Generation Summary

**Programmatically rendered a Night-to-Sunrise sunrise-gradient + sun-disc icon pair via `renderPainterToPng`, then wired `flutter_launcher_icons` to generate the full Android adaptive-icon asset set, replacing Flutter's default launcher icon.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-10T08:39:46Z (approx, from STATE.md session timestamp)
- **Completed:** 2026-07-10T08:57:29Z
- **Tasks:** 2
- **Files modified:** 6 tracked source/config files + ~16 generated Android icon resources

## Accomplishments
- Created `IconBackgroundPainter` (vertical sunrise-sky gradient) and `IconForegroundPainter` (single dominant sun disc with soft glow and a simple hill arc), both restating `SunrisePainter`'s Night-to-Sunrise palette hexes per D-02.
- Rendered both painters headlessly at 1024x1024 via the plan 05-02 `renderPainterToPng` helper and wrote `assets/icon/icon_foreground.png` / `assets/icon/icon_background.png`, verified by an automated test asserting PNG signature and size.
- Wired `flutter_launcher_icons ^0.14.4` with the PNG-path form of `adaptive_icon_background` (required since D-02's background is a gradient, not a flat color) and generated the full Android adaptive-icon asset set: `mipmap-anydpi-v26/ic_launcher.xml`, legacy `mipmap-*/ic_launcher.png` fallbacks, and `drawable-*/ic_launcher_{foreground,background}.png` layers.
- Verified `flutter build apk --debug` succeeds with the new icon resources and the full existing test suite (132 tests, including the two new icon tests) stays green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Render the sunrise-motif foreground + background source PNGs** - `0e56dce` (feat)
2. **Task 2: Wire flutter_launcher_icons and generate the adaptive icon set** - `ad3f055` (feat)

_No TDD RED/GREEN split — plan tasks are `type="auto"`, not `tdd="true"`._

## Files Created/Modified
- `test/tool/icon_painters.dart` - NEW: `IconBackgroundPainter` (sunrise gradient fill) and `IconForegroundPainter` (padded sun disc + glow + simple hill), both restating `SunrisePainter`'s private palette hexes with a sourcing comment.
- `test/tool/generate_launcher_icon_test.dart` - EXTENDED with a second `testWidgets` case that renders both icon painters at 1024x1024 via `renderPainterToPng` and writes them to `assets/icon/`.
- `assets/icon/icon_foreground.png`, `assets/icon/icon_background.png` - NEW generated 1024x1024 icon source PNGs.
- `pubspec.yaml` - Added `flutter_launcher_icons: ^0.14.4` dev dependency and a `flutter_launcher_icons:` config block (`android: "ic_launcher"`, `min_sdk_android: 24`, `image_path`/`adaptive_icon_foreground` -> foreground PNG, `adaptive_icon_background` -> background PNG).
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` - NEW adaptive icon descriptor (generated by `flutter_launcher_icons`).
- `android/app/src/main/res/mipmap-*/ic_launcher.png` - Regenerated legacy per-density fallbacks (no longer Flutter's default icon).
- `android/app/src/main/res/drawable-*/ic_launcher_background.png`, `ic_launcher_foreground.png` - NEW per-density adaptive icon layer bitmaps (generated).

## Decisions Made
- **Deviated from 05-RESEARCH.md's example config value.** RESEARCH's Pattern 4 example used `android: "launcher_icon"`, but running `flutter_launcher_icons` with that value created a brand-new `launcher_icon` mipmap resource alongside the untouched default `ic_launcher` resource, and rewrote `AndroidManifest.xml`'s `android:icon` reference from `@mipmap/ic_launcher` to `@mipmap/launcher_icon` — contradicting the plan's own instruction to "leave AndroidManifest's `android:icon="@mipmap/ic_launcher"` reference as-is." Switched the config to `android: "ic_launcher"` so the tool overwrites the existing resource name in place; the manifest reference required no change and the plan's verification (`mipmap-anydpi-v26/ic_launcher.xml` exists, references a foreground layer) passed as written.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected flutter_launcher_icons resource-name config to match the plan's own verification/manifest-preservation intent**
- **Found during:** Task 2 (wiring flutter_launcher_icons)
- **Issue:** The plan's `<action>` instructed using `android: "launcher_icon"` (per 05-RESEARCH.md's Pattern 4 example) while also asserting `mipmap-anydpi-v26/ic_launcher.xml` would be generated and `AndroidManifest.xml`'s `@mipmap/ic_launcher` reference would remain unchanged. Running the tool with `"launcher_icon"` instead created a new `launcher_icon`-named resource set and rewrote the manifest to point at it, leaving the old default `ic_launcher.png` files untouched — self-contradictory with the plan's stated expectations and verify step.
- **Fix:** Reverted the manifest and deleted the mistakenly-generated `launcher_icon`-named resources, then re-ran `dart run flutter_launcher_icons` with `android: "ic_launcher"` in the config. This overwrote the existing `ic_launcher.png` mipmaps in place and generated `mipmap-anydpi-v26/ic_launcher.xml`, with zero changes needed to `AndroidManifest.xml`.
- **Files modified:** `pubspec.yaml`, `android/app/src/main/res/mipmap-*/ic_launcher.png`, `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `android/app/src/main/res/drawable-*/ic_launcher_{foreground,background}.png`
- **Verification:** `test -f android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `grep -qi "foreground"` on that file, `flutter build apk --debug` — all pass exactly as the plan's `<verify>` block specifies.
- **Committed in:** `ad3f055` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug fix — config value correction, no scope creep)
**Impact on plan:** The fix keeps every plan-stated acceptance criterion (manifest untouched, `ic_launcher.xml` generated, legacy PNGs regenerated in place) true as originally intended; only the RESEARCH.md example's icon-name string was wrong for this codebase's existing `ic_launcher` naming.

## Issues Encountered

`flutter build apk --debug` printed a suppressed Kotlin incremental-compiler exception ("this and base files have different roots") originating from `wakelock_plus`'s Gradle module while writing incremental caches — caused by the git worktree living on a different path root (`D:\Projects\zual\.claude\worktrees\...`) than the pub cache (`C:\Users\...\Pub\Cache\...`). The exception is caught/suppressed by Gradle's incremental-cache layer and does not fail the build; `app-debug.apk` was produced successfully. This is a pre-existing environment quirk of building in this worktree location, not something introduced by this plan's changes, and is out of this plan's scope to fix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PUBLISH-02's icon requirement is now satisfied: the app builds with a real, on-brand Night-to-Sunrise adaptive launcher icon in place of Flutter's default.
- A human should still visually confirm the icon on a real device/emulator launcher (D2 above) — file-existence and build-success checks alone can't judge whether the rendered sun/gradient reads well at 48dp under circle/squircle masking; this is flagged as `human_judgment: true` in this SUMMARY's coverage block for the verifier to route to UAT.
- No blockers for subsequent Phase 05 plans.

## Self-Check: PASSED

- FOUND: test/tool/icon_painters.dart
- FOUND: assets/icon/icon_foreground.png
- FOUND: assets/icon/icon_background.png
- FOUND: android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
- FOUND commit: 0e56dce (feat: Task 1)
- FOUND commit: ad3f055 (feat: Task 2)

---
*Phase: 05-play-store-readiness*
*Completed: 2026-07-10*
