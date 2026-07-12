---
phase: 05-play-store-readiness
reviewed: 2026-07-10T16:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - android/app/build.gradle.kts
  - android/app/src/main/AndroidManifest.xml
  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  - assets/icon/icon_background.png
  - assets/icon/icon_foreground.png
  - docs/index.html
  - pubspec.yaml
  - screenshots/car_on_a_road.png
  - screenshots/night_to_sunrise.png
  - screenshots/setup_screen.png
  - screenshots/shrinking_disc.png
  - screenshots/walking_home.png
  - test/tool/generate_launcher_icon_test.dart
  - test/tool/icon_painters.dart
  - test/tool/icon_renderer.dart
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-07-10T16:00:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Fresh full re-review of Phase 5's release-readiness surface (signing config, app identity,
adaptive launcher icon pipeline, privacy policy page, store screenshots) after gap-closure plan
05-06 reverted the 260710-keg launcher-icon regression. Confirmed via `git log` and direct file
read that the revert is complete and consistent: `pubspec.yaml`'s `flutter_launcher_icons` block
no longer sets `adaptive_icon_foreground_inset`, and `ic_launcher.xml` correctly declares
`android:inset="16%"` (the tool default) — matching the state that was on-device-verified
acceptable on a real Samsung A25 in `05-05-SUMMARY.md`, before the since-reverted 260710-keg
overcorrection. All five referenced adaptive-icon drawables exist on disk for every density
bucket, and both `assets/icon/*.png` source files are confirmed valid 1024x1024 8-bit RGBA PNGs
(foreground genuinely carries an alpha channel, as required for adaptive-icon masking). The five
`screenshots/*.png` files are all a consistent 1080x2424 RGBA PNG, matching Play Store portrait
screenshot requirements.

No critical/security issues were found (no secrets, no injection vectors, no unsafe
deserialization — this is a static config + asset-generation surface). The findings below are
carried-forward, still-unresolved robustness/maintainability issues from the release-signing
Gradle config and the launcher-icon test tooling (neither was touched by the 05-06 gap-closure
plan, so they remain exactly as previously identified), plus one new signing-config robustness
finding and a note on the residual regression risk in the icon pipeline itself.

## Warnings

### WR-01: `key.properties` values are force-cast with no validation, producing unclear failures on a malformed file

**File:** `android/app/build.gradle.kts:46-53`
**Issue:** `keyAlias`, `keyPassword`, and `storePassword` are all read via
`keystoreProperties["..."] as String` with no null/blank check. If `android/key.properties`
exists but is missing a key, has a typo'd key name, or has an empty value, `Properties.get(...)`
returns `null` and the `as String` cast throws an unhelpful Kotlin
`ClassCastException`/`NullPointerException` ("null cannot be cast to non-null type
kotlin.String") deep in Gradle configuration, rather than a clear message pointing at the missing
signing property. This is exactly the kind of file a developer hand-edits once and rarely
touches again — a single typo when setting up release signing (e.g. copy-pasting a template with
`keyAlias=` left blank) turns into a confusing stack trace instead of an actionable error.
**Fix:**
```kotlin
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: error("key.properties is missing 'keyAlias'")
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: error("key.properties is missing 'keyPassword'")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
                ?: error("key.properties is missing 'storeFile'")
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: error("key.properties is missing 'storePassword'")
        }
    }
}
```

### WR-02: `key.properties` `FileInputStream` is never closed

**File:** `android/app/build.gradle.kts:11-15`
**Issue:** `keystoreProperties.load(FileInputStream(keystorePropertiesFile))` opens a
`FileInputStream` that is never closed (no `.use { }`, no try-with-resources, no explicit
`.close()`). This runs once per Gradle configuration pass, so the practical impact is small, but
it is a real resource leak and a one-line fix. Still present — unchanged since the prior review
pass, and not touched by the 05-06 gap-closure plan.
**Fix:**
```kotlin
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
```

### WR-03: Release build silently falls back to debug signing with no build-time gate

**File:** `android/app/build.gradle.kts:58-69`
**Issue:** When `android/key.properties` is absent, `buildTypes.release.signingConfig` silently
falls back to the `debug` signing config. This is intentional for local `flutter run --release`
convenience (per the inline comment), but nothing in this file (or a CI/release-task check) fails
loudly if someone runs `flutter build appbundle --release` for an actual Play Store upload
without a real keystore present. A debug-signed release bundle could be built and handed off for
upload with no warning at build time. Still present — unchanged since the prior review pass.
**Fix:**
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

### WR-04: Launcher-icon "test" overwrites tracked, committed binary assets on every run

**File:** `test/tool/generate_launcher_icon_test.dart:49-80`
**Issue:** This file lives under `test/` and matches the `*_test.dart` convention, so it runs as
part of an ordinary `flutter test`. Its second test unconditionally renders
`IconBackgroundPainter`/`IconForegroundPainter` and overwrites `assets/icon/icon_background.png`
and `assets/icon/icon_foreground.png` — both tracked in git — every time it runs, then only
asserts generic properties (PNG header present, size > 1000 bytes). It never diffs against the
already-committed bytes. This is precisely the class of asset the 05-06 gap-closure plan just had
to carefully reason about being "byte-identical, no delta to stage" for — today it happens to be
a no-op because Skia rendering is currently deterministic, but that is incidental, not
guaranteed: a future Flutter/Skia/Impeller engine upgrade that changes PNG encoding or
antialiasing would cause every `flutter test` run (including CI) to silently rewrite the shipped
launcher icon with different bytes, with no failing test to catch it and no visual review gate.
Still present — unchanged since the prior review pass, not in scope for 05-06.
**Fix:** Either (a) move this generation logic out of `test/` into a `tool/` script invoked
explicitly (e.g. `dart run tool/generate_launcher_icon.dart`, run manually when the icon design
changes) rather than on every test run, or (b) if it must stay as a test, change it to a
regression check that reads the existing committed PNG and asserts the freshly-rendered bytes
still match it (failing loudly on drift):
```dart
final existing = await backgroundFile.readAsBytes();
expect(backgroundBytes, equals(existing),
    reason: 'Re-run the icon generator script and review the visual diff before committing.');
```

### WR-05: No regression test locks in the on-device-verified icon proportions, so this exact regression can recur silently

**File:** `test/tool/icon_painters.dart:58-61`, `pubspec.yaml:72-77`,
`android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml:5-8`
**Issue:** The visual balance of the launcher icon depends on two values that live in two
different files and are only tied together by human judgment: the sun disc's own baked-in
safe-zone padding (`_sunRadiusFraction = 0.32` in `icon_painters.dart`, chosen "so the disc
survives circle/squircle safe-zone masking") and `flutter_launcher_icons`'s adaptive-icon inset
(currently implicit at the tool's 16% default, per the just-completed 05-06 revert). The
260710-keg → 05-06 cycle is direct proof this combination is fragile: a plausible, well-reasoned
one-line pubspec change (`adaptive_icon_foreground_inset: 0`) silently broke the on-screen
result, was verified only by config-level "grep passes" (`WR-01` in the prior review round) and
shipped, then had to be caught by a human looking at a real launcher and reverted a full plan
later. There is still no automated check (e.g. a golden-image test that renders the foreground
through the exact same inset math the adaptive-icon system applies, or even a simple documented
"these two numbers must be read together" comment co-located in both files) that would catch a
future edit to either the sun radius or the inset value before it reaches a device. Today's state
is correct, but nothing prevents this exact class of regression from happening again the next
time either value is touched.
**Fix:** Add a cross-referencing comment in both `icon_painters.dart` (near
`_sunRadiusFraction`) and `pubspec.yaml` (near the `flutter_launcher_icons:` block) pointing at
each other and at this incident, and/or add a golden-image regression test that composites the
foreground+background+16%-inset the way Android's adaptive-icon renderer does, so a future change
to either value fails a test instead of requiring a physical device to catch it.

## Info

### IN-01: `ui.Image` (and `ui.Picture`) are never disposed in the headless PNG renderer

**File:** `test/tool/icon_renderer.dart:21-29`
**Issue:** `renderPainterToPng` creates a `ui.Picture` via `recorder.endRecording()` and a
`ui.Image` via `picture.toImage(...)`, and never calls `.dispose()` on either after extracting
byte data. Both hold native (Skia) memory that should be explicitly released once no longer
needed. Low real-world impact since this only runs a handful of times in a dev/test script, but
worth fixing for correctness. Still present — unchanged since the prior review pass.
**Fix:**
```dart
Future<Uint8List> renderPainterToPng(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}
```

### IN-02: Magic number for glow blur sigma with no explanation of its derivation

**File:** `test/tool/icon_painters.dart:69`
**Issue:** `final glowSigma = 40 * 0.57735 + 0.5;` hardcodes both an implicit "blur radius" of 40
and Skia's radius-to-sigma conversion constant (`0.57735 ≈ 1/√3`, matching Flutter's internal
`convertRadiusToSigma`) inline, with no named constant and no comment explaining where `0.57735`
comes from. A future reader adjusting the glow size has no indication that `40` is a blur-radius
value expressed in a different unit than `sunRadius`, nor why the sigma formula is written out by
hand instead of using `Radius`/`BlurStyle` helpers.
**Fix:**
```dart
// Skia's blur sigma = radius * (1 / sqrt(3)) + 0.5 (matches Flutter's internal
// convertRadiusToSigma); expressed as a 40px-equivalent soft glow radius.
static const double _glowBlurRadiusPx = 40;
static const double _radiusToSigma = 0.57735;
...
final glowSigma = _glowBlurRadiusPx * _radiusToSigma + 0.5;
```

### IN-03: Privacy policy "Effective date" is a hand-maintained literal with no link to actual content changes

**File:** `docs/index.html:11`
**Issue:** `<p>Effective date: 2026-07-09</p>` is a hardcoded string with no mechanism tying it to
actual edits of the surrounding policy text — if the page content is edited later without also
remembering to bump this line, the displayed effective date silently goes stale (already one day
behind the reviewed state as of this pass). Very low risk given how rarely this page will change,
but worth a one-line reminder for future maintainers.
**Fix:** Add an HTML comment near the date, e.g.
`<!-- Bump this date any time the policy text below changes. -->`, or generate the page from a
template that derives the date from git history at build time if this repo ever automates
docs publishing.

---

_Reviewed: 2026-07-10T16:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
