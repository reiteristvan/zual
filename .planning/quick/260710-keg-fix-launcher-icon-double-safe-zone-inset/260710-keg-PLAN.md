---
phase: quick-260710-keg
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - pubspec.yaml
  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  - android/app/src/main/res/mipmap-hdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-mdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  - test/tool/generate_store_icon_test.dart
  - store_assets/icon_512.png
autonomous: true
requirements: [WR-01]

must_haves:
  truths:
    - "The generated adaptive launcher foreground drawable no longer applies the tool's 16% inset on top of the art's own baked-in safe-zone padding — the on-device sun disc renders at its intended ~64% diameter."
    - "A single flattened 512x512 RGBA PNG (background composited under foreground) exists for the Play Console 'App icon' / Hi-res store-listing upload."
  artifacts:
    - pubspec.yaml
    - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
    - store_assets/icon_512.png
    - test/tool/generate_store_icon_test.dart
  key_links:
    - "flutter_launcher_icons config -> regenerated ic_launcher.xml (inset must read 0%)"
    - "icon_background.png + icon_foreground.png -> composited store_assets/icon_512.png"
---

<objective>
Fix WR-01 from `05-REVIEW.md`: the adaptive launcher icon's foreground art (`test/tool/icon_painters.dart`) already bakes in Android's adaptive-icon safe-zone padding via its ~32%-of-width sun-disc radius, but `flutter_launcher_icons` was also applying its own default 16% inset — stacking two safe-zone margins and shrinking the visible sun disc to ~43% of intended size. Set the tool's inset to 0 and regenerate. Separately, produce the flattened 512x512 store-listing icon Play Console requires (a single flat RGBA PNG, distinct from the on-device adaptive layer pair).

Purpose: Ship a correctly-sized launcher icon and satisfy the Play Console "Hi-res icon" upload requirement before submission.
Output: Updated `pubspec.yaml` + regenerated Android mipmap assets, and a new `store_assets/icon_512.png`.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/05-play-store-readiness/05-REVIEW.md
@pubspec.yaml
@test/tool/icon_renderer.dart
@test/tool/icon_painters.dart
@test/tool/generate_launcher_icon_test.dart

# Scope guardrails:
# - Do NOT touch the Setup screen, scene rendering, signing/build config, or any
#   other WR-/IN- finding from 05-REVIEW.md. Only WR-01's inset line + the new
#   512x512 store asset are in scope.
# - Do NOT modify the existing icon_painters.dart art or the on-device
#   background/foreground source PNGs — the fix is purely the inset config.
</context>

<tasks>

<task type="auto">
  <name>Task A: Set adaptive foreground inset to 0 and regenerate Android launcher icons</name>
  <files>pubspec.yaml, android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml, android/app/src/main/res/mipmap-*/ic_launcher.png</files>
  <action>
In `pubspec.yaml`, add one line to the existing `flutter_launcher_icons:` block (currently lines 72-77): `adaptive_icon_foreground_inset: 0`, placed after the `adaptive_icon_background:` line, at the same two-space indentation as the sibling keys. This resolves WR-01 — the art at `test/tool/icon_painters.dart` (`_sunRadiusFraction = 0.32`, ~64% diameter) already survives circle/squircle masking, so the tool's default 16% inset is redundant shrinkage. Do not change any other key in the block (`android`, `min_sdk_android`, `image_path`, `adaptive_icon_foreground`, `adaptive_icon_background`) and do not touch the explanatory comments above it.

Then regenerate the Android asset set by running `dart run flutter_launcher_icons`. This rewrites `ic_launcher.xml` (the `<inset ... android:inset="...%">` value is interpolated directly from `adaptiveIconForegroundInset`, so it will now emit `android:inset="0%"` instead of `"16%"`) and re-rasterizes the legacy square `mipmap-*/ic_launcher.png` fallbacks. Confirm the build still compiles the regenerated resources with `flutter build apk --debug`.
  </action>
  <verify>
    <automated>dart run flutter_launcher_icons && grep -q 'android:inset="0%"' android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml && ! grep -q '16%' android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml && flutter build apk --debug</automated>
  </verify>
  <done>`pubspec.yaml` contains `adaptive_icon_foreground_inset: 0` inside the `flutter_launcher_icons` block; `ic_launcher.xml` now reads `android:inset="0%"` (no `16%` remains); the `mipmap-*/ic_launcher.png` fallbacks were regenerated; `flutter build apk --debug` succeeds.</done>
</task>

<task type="auto">
  <name>Task B: Generate the flattened 512x512 store-listing icon</name>
  <files>test/tool/generate_store_icon_test.dart, store_assets/icon_512.png</files>
  <action>
Create a new top-level `store_assets/` directory (parallel to the existing `screenshots/` convention — confirmed no pre-existing store-asset directory exists) to hold Play Console listing graphics. The target file is `store_assets/icon_512.png`.

Play Console's "App icon" store-listing graphic requires a single flat 512x512 32-bit PNG with an alpha channel — this is a separate deliverable from the on-device adaptive foreground/background layer pair. Because `dart:ui`'s rasterization APIs have no headless backend outside the Flutter test engine (see the header note in `test/tool/icon_renderer.dart`), do this generation inside a `flutter test`, mirroring the existing icon pipeline in `test/tool/generate_launcher_icon_test.dart`.

Write `test/tool/generate_store_icon_test.dart` as a `testWidgets` test wrapped in `tester.runAsync(() async { ... })`. Inside it: read the two committed source PNGs (`assets/icon/icon_background.png`, then `assets/icon/icon_foreground.png`) from disk as bytes, decode each via `dart:ui`'s `instantiateImageCodec` + `getNextFrame()` into a `ui.Image`. Draw both onto a single `Canvas(ui.PictureRecorder())` sized 512x512: background first, foreground second, each drawn with `canvas.drawImageRect(img, srcRect=full-image, dstRect=0,0,512,512, Paint())` so both scale down to 512x512. End the recording, rasterize with `picture.toImage(512, 512)`, and re-encode via `image.toByteData(format: ui.ImageByteFormat.png)` (this yields RGBA / PNG color type 6 — a 32-bit-with-alpha PNG). Dispose the intermediate `ui.Image`s and the final image after extracting bytes. Create `store_assets/` recursively and write the bytes to `store_assets/icon_512.png`.

Then assert, in the same test: the output file exists; its first 8 bytes equal the PNG signature `[0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A]`; its IHDR color-type byte (byte at offset 25) equals 6 (truecolor + alpha); and decoding the written bytes via `instantiateImageCodec` yields a frame whose `image.width == 512` and `image.height == 512`. Reuse the `pngSignature` constant pattern already present in `generate_launcher_icon_test.dart`. Do NOT import or re-run `renderPainterToPng`/the painters here — this task composites the already-committed PNG sources, not the painters.
  </action>
  <verify>
    <automated>flutter test test/tool/generate_store_icon_test.dart</automated>
  </verify>
  <done>`store_assets/icon_512.png` exists, is a valid PNG (signature + IHDR color type 6 = RGBA), and is exactly 512x512; `flutter test test/tool/generate_store_icon_test.dart` passes.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

No new trust boundaries introduced. Both tasks operate on developer-controlled, in-repo assets and a pinned, already-audited build-time dev dependency (`flutter_launcher_icons ^0.14.4`, approved in `05-RESEARCH.md`'s Package Legitimacy Audit — no new installs). No runtime code paths, no external input, no network.

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-keg-01 | Tampering | Regenerated Android mipmap assets | low | accept | Assets are deterministically regenerated from committed source PNGs by a pinned dependency; changes are reviewable in git diff before commit. |
</threat_model>

<verification>
- `pubspec.yaml` `flutter_launcher_icons` block contains `adaptive_icon_foreground_inset: 0` and no other keys changed.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` reads `android:inset="0%"` with no `16%` remaining.
- `flutter build apk --debug` succeeds against the regenerated resources.
- `store_assets/icon_512.png` exists: valid PNG, 512x512, RGBA (alpha channel present).
- `flutter test test/tool/generate_store_icon_test.dart` passes.
- No changes outside the icon inset line, the new store-asset test, and the new/regenerated icon files (Setup screen, scenes, signing/build config untouched).
</verification>

<success_criteria>
WR-01 is resolved (foreground inset = 0, verified in regenerated XML) and a Play-Console-ready 512x512 flat RGBA store icon exists at `store_assets/icon_512.png`, with both verifications passing and no unrelated files modified.
</success_criteria>

<output>
Create `.planning/quick/260710-keg-fix-launcher-icon-double-safe-zone-inset/260710-keg-SUMMARY.md` when done.
</output>
