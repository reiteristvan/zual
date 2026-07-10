---
phase: 05-play-store-readiness
reviewed: 2026-07-10T12:36:23Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - .gitignore
  - android/app/build.gradle.kts
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  - docs/index.html
  - lib/screens/setup_screen.dart
  - lib/widgets/scene_grid.dart
  - pubspec.yaml
  - test/screens/setup_screen_test.dart
  - test/tool/generate_launcher_icon_test.dart
  - test/tool/icon_painters.dart
  - test/tool/icon_renderer.dart
findings:
  critical: 0
  warning: 6
  info: 3
  total: 9
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-07-10T12:36:23Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Reviewed Phase 5's direct output (release signing config, app identity, adaptive launcher icon
generation pipeline, privacy policy page) plus the interleaved quick-task layout-overflow fix to
`SetupScreen`/`SceneGrid` (260710-frr). `flutter analyze` and the full `setup_screen_test.dart`
and `generate_launcher_icon_test.dart` suites were run against the working tree and both pass
clean, and the layout responsive-sizing arithmetic was traced by hand and holds up (guards
against divide-by-zero, aspect-ratio clamping is internally consistent, the header-shrink/
scroll-safety-net interaction is sound). No crashes, injection vectors, or hardcoded secrets were
found.

The issues below are all Warning/Info tier: one real functional risk (the launcher icon's
foreground art is very likely rendering visibly smaller than intended once Play Store submission
happens, due to a config gap between the icon's own baked-in safe-zone padding and
`flutter_launcher_icons`'s default adaptive inset), a test-hygiene problem (a "test" file
mutates tracked, committed binary assets as a side effect of running the ordinary test suite), and
several smaller maintainability/robustness items.

## Warnings

### WR-01: Launcher icon foreground is very likely rendering too small (double safe-zone padding)

**File:** `pubspec.yaml:72-77` (config) and `test/tool/icon_painters.dart:58-61` (source art)
**Issue:** `IconForegroundPainter` deliberately pads its sun disc to a 32%-of-width radius
(64% diameter) specifically "so the disc survives circle/squircle safe-zone masking" (see comment
at `icon_painters.dart:58-61`) — i.e. the artwork itself already bakes in Android's adaptive-icon
safe-zone margin. `pubspec.yaml`'s `flutter_launcher_icons` block does not set
`adaptive_icon_foreground_inset`, so the tool uses its own default of 16
(confirmed in the installed package: `flutter_launcher_icons-0.14.4/lib/config/config.dart:31`,
`this.adaptiveIconForegroundInset = 16`). That default unconditionally wraps the generated
foreground drawable in an `<inset android:inset="16%">` (confirmed in
`flutter_launcher_icons-0.14.4/lib/android.dart:197-203`, which is exactly what was emitted into
`android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml:4-8`). Stacking the tool's own 16%
inset on top of art that is already safe-zone-padded shrinks the visible sun disc to roughly
64% × 0.68 ≈ 43% of the icon's diameter — noticeably smaller than a typical launcher icon, and
smaller than the developer clearly intended given the explicit "kept within the 30-34% range...
so the disc survives...masking" comment (which was reasoning about *not being clipped*, not about
wanting extra shrinkage on top).
**Fix:** Set `adaptive_icon_foreground_inset: 0` (the art already handles safe-zone padding) in
the `flutter_launcher_icons` block, regenerate (`dart run flutter_launcher_icons`), and visually
verify the icon at 48dp on a real launcher (circle and squircle masks) before Play Store
submission:
```yaml
flutter_launcher_icons:
  android: "ic_launcher"
  min_sdk_android: 24
  image_path: "assets/icon/icon_foreground.png"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
  adaptive_icon_background: "assets/icon/icon_background.png"
  adaptive_icon_foreground_inset: 0
```

### WR-02: Launcher-icon "test" overwrites tracked, committed binary assets on every run

**File:** `test/tool/generate_launcher_icon_test.dart:49-80`
**Issue:** This file lives under `test/` and matches the `*_test.dart` convention, so it runs as
part of an ordinary `flutter test` (confirmed: `flutter test test/tool/generate_launcher_icon_test.dart`
executes and passes). Its second test unconditionally renders `IconBackgroundPainter`/
`IconForegroundPainter` and overwrites `assets/icon/icon_background.png` and
`assets/icon/icon_foreground.png` — both tracked in git — every single time it runs, then only
asserts generic properties (PNG header present, size > 1000 bytes). It never diffs against the
already-committed bytes. Today this happens to be a no-op because rendering is currently
deterministic (`git status` stays clean after running it), but that is incidental, not
guaranteed: any future Skia/Impeller engine change (a routine Flutter SDK upgrade) that alters PNG
encoding or antialiasing would cause every `flutter test` run (including CI) to silently rewrite
the shipped launcher icon with different bytes, with no test failure to catch it and no visual
review gate.
**Fix:** Either (a) move this generation logic out of `test/` into a `tool/` script invoked
explicitly (e.g. `dart run tool/generate_launcher_icon.dart`, run manually when the icon design
changes) rather than on every test run, or (b) if it must stay as a test, change it to a
regression check that reads the existing committed PNG and asserts the freshly-rendered bytes
still match it (failing loudly on drift) instead of unconditionally overwriting the file:
```dart
final existing = await backgroundFile.readAsBytes();
expect(backgroundBytes, equals(existing),
    reason: 'Re-run the icon generator script and review the visual diff before committing.');
```

### WR-03: `key.properties` FileInputStream is never closed

**File:** `android/app/build.gradle.kts:11-15`
**Issue:** `keystoreProperties.load(FileInputStream(keystorePropertiesFile))` opens a
`FileInputStream` that is never closed (no `.use { }` / try-with-resources / explicit `.close()`).
This runs once per Gradle configuration pass, so the practical impact is small, but it's a real
resource leak and an easy one-line fix.
**Fix:**
```kotlin
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
```

### WR-04: Release build silently falls back to debug signing with no build-time gate

**File:** `android/app/build.gradle.kts:58-69`
**Issue:** When `android/key.properties` is absent, `buildTypes.release.signingConfig` silently
falls back to the `debug` signing config. This is intentional for local `flutter run --release`
convenience (per the inline comment), but there is no assertion anywhere in this file (or a
CI/release-task check) that fails loudly if someone runs `flutter build appbundle --release` for
an actual Play Store upload without a real keystore present. A debug-signed release build could
be built and handed off for upload without any warning at build time.
**Fix:** Add a check in the `release` block (or a dedicated Gradle task wired to `bundleRelease`)
that fails the build when producing an app bundle/APK without real signing configured, e.g.:
```kotlin
release {
    signingConfig = if (keystorePropertiesFile.exists()) {
        signingConfigs.getByName("release")
    } else {
        logger.warn("WARNING: no android/key.properties found — signing release build with the debug key.")
        signingConfigs.getByName("debug")
    }
}
```
(at minimum a `logger.warn`; a hard failure gated behind a `-PforPlayStore` flag is stronger).

### WR-05: Scene-card labels duplicated as a bare literal list, silently driftable

**File:** `lib/screens/setup_screen.dart:354-359`
**Issue:** `_sceneLabelsForMeasurement` restates the four scene labels verbatim as a second copy
of `SceneGrid._labels`'s values (`lib/widgets/scene_grid.dart:119-124`), used only to compute the
worst-case wrapped label height for `_maxSafeSceneAspectRatio`. The comment acknowledges this is
deliberate (avoiding new public API on `SceneGrid`), but there is no compiler or test-level tie
between the two lists — if a future change edits `SceneGrid._labels` (e.g. re-wording "Walking
home"), this file's copy silently goes stale and the fit-to-space aspect-ratio calculation will
under- or over-estimate the worst-case label height with no error surfaced, potentially
reintroducing the exact overflow this quick-task fixed.
**Fix:** At minimum, add a test that asserts `SceneGrid`'s label set (exposed via a small
`@visibleForTesting` static getter, or by comparing `find.text(...)` in a widget test) matches
`_sceneLabelsForMeasurement`, so drift fails loudly instead of silently degrading layout fit.

### WR-06: Persistence errors on Start are swallowed with zero logging, even in debug

**File:** `lib/screens/setup_screen.dart:128-136`
**Issue:** `SetupPreferences.persistIfPreset(...).catchError((_) {})` discards the error object
completely. The design intent (documented in the doc comment above `_handleStart`) — persistence
must never block or crash Start — is reasonable, but suppressing every error with no logging at
all (not even `debugPrint`, which the project's own conventions call out as the sanctioned debug
channel) means a real regression in `SetupPreferences` (e.g. a null-safety bug, a corrupted
`SharedPreferences` backing store) would fail completely silently with no trace during
development.
**Fix:**
```dart
unawaited(
  SetupPreferences.persistIfPreset(
    showCustom: _showCustom,
    durationMin: _durationMin,
    theme: _theme,
  ).catchError((Object e) => debugPrint('SetupPreferences.persistIfPreset failed: $e')),
);
```

## Info

### IN-01: Redundant `.gitignore` entries

**File:** `.gitignore:129-130`
**Issue:** `/android/key.properties` and `/android/upload-keystore.jks` (added at the bottom,
presumably by this phase's release-signing plan) are already fully covered by the pre-existing
`**/android/key.properties` (line 65) and `*.jks` (line 66) patterns above. They're harmless but
dead/duplicate configuration.
**Fix:** Remove lines 129-130, or leave a comment noting they're intentionally explicit if that's
preferred for clarity — but as written they add nothing.

### IN-02: `ui.Image` never disposed in the headless PNG renderer

**File:** `test/tool/icon_renderer.dart:21-29`
**Issue:** `renderPainterToPng` creates a `ui.Image` via `picture.toImage(...)` and never calls
`image.dispose()` after extracting its byte data. `ui.Image` holds native (Skia) memory that
should be explicitly released once no longer needed. Low real-world impact since this only runs a
handful of times in a dev/test script, but worth fixing for correctness.
**Fix:**
```dart
final image = await picture.toImage(size.width.toInt(), size.height.toInt());
try {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
} finally {
  image.dispose();
}
```

### IN-03: New responsive-layout logic has only one tested viewport

**File:** `test/screens/setup_screen_test.dart:384-430`
**Issue:** The new `LayoutBuilder`-driven adaptive sizing in `setup_screen.dart` (header-shrink,
duration/scene aspect-ratio fit-to-space, gap scaling) is exercised by exactly one regression test
at the A25 viewport (~393×851 dp). The logic has several distinct branches (tall vs. short
`baseRatio`/`durationAspectRatio` at the 640 threshold, the `shortfall > 0` header-shrink path
down to its 16.0 floor, `_showCustom` toggled while a short viewport is active) that are untested
at other real device sizes (e.g. a genuinely small/older device, or a tablet in split-screen).
Not a bug in itself, but a coverage gap for logic that was specifically written to fix a
real-device visual bug.
**Fix:** Add at least one additional viewport test at a smaller height (e.g. ~320dp tall, forcing
the header down to its 16.0 floor and/or the scene aspect ratio down to its safe-minimum branch)
to lock in the fix's edge-case behavior.

---

_Reviewed: 2026-07-10T12:36:23Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
