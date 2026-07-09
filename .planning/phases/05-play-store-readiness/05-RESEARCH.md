# Phase 5: Play Store Readiness - Research

**Researched:** 2026-07-09
**Domain:** Android release engineering (Gradle signing, adaptive icons), Google Play Console policy (content rating, target audience/Families), static site hosting, on-device asset capture
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**App icon & visual identity**
- D-01: Launcher icon motif is the **Night to Sunrise** scene (sky gradient night→day, sun/moon) — not Shrinking Disc, not an abstract mark, not Walking Home or Car on a Road.
- D-02: Icon background is a **scene-matched gradient** pulled from Night to Sunrise's own sky palette — not the app's flat warm-cream UI background token.
- D-03: The adaptive-icon foreground stays **big and simple** — one dominant shape, generous padding, silhouette-level detail rather than full scene fidelity — so it survives circle/squircle masking and stays legible at 48dp.
- D-04: Claude **generates the icon programmatically in Flutter/Dart**, reusing/adapting the existing Night to Sunrise painter code to render PNGs at all required launcher sizes — no external design tool, no hand-off asset file.

**App identity — package ID & display name**
- D-05: `applicationId` = **`com.ireiter.zual`**, replacing the placeholder `com.example.zual` in `android/app/build.gradle.kts`. Permanent once published — must be correct before first upload.
- D-06: Play Store display name = **"Zual — Visual Timer for Kids"**.

**Target audience & content rating declaration**
- D-07: Declared target audience is **general audience that also appeals to children** — not "Designed for Families". Parent-operated (parent sets duration/theme; child only watches), zero ads/accounts/data collection.
- D-08: Content rating questionnaire answered aiming for **lowest tier** (Everyone / ESRB Everyone / PEGI 3 equivalent) — no violence, text, UGC, ads, or interactions beyond watching.
- D-09: A **privacy policy is required** for Play Console submission even though Zual collects nothing. Claude drafts a short static policy page (no accounts, no data collection, no ads, fully offline).
- D-10: The privacy policy is **hosted via GitHub Pages from this repo** — stable public URL for the Play Console listing form.

**Store listing assets**
- D-11: Screenshots feature **all 4 scenes, one each** (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road).
- D-12: Screenshots **captured live from a real device/emulator** — not staged/mocked via a dedicated screenshot-harness screen.
- D-13: Screenshots are **plain full-bleed captures** — no phone device frame, no caption/text overlay.
- D-14: Store description tone is **short and parent-practical** — leads with the concrete problem solved, matching PROJECT.md's Core Value framing.

### Claude's Discretion
- Exact PNG export sizes and adaptive-icon XML wiring (`mipmap-anydpi-v26`, foreground/background layer split) — standard Android tooling mechanics.
- Exact progress point captured per scene for screenshots (e.g., ~40% elapsed).
- Exact wording of the short/full store description beyond the "parent-practical" tone lock (D-14).
- Production keystore generation/storage mechanics (PUBLISH-01) — standard practice; `key.properties`/`*.keystore` already gitignored.
- Play App Signing (Google-managed) vs. locally-held upload key — follow Google's recommended default (Play App Signing) unless research surfaces a reason not to.
- `pubspec.yaml`'s `description:` and `version:` fields — likely need updating alongside the applicationId change.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. Actual Play Console account creation and final submission click-through are explicitly left to the human at execution time; this phase prepares assets/config only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PUBLISH-01 | App has a real `applicationId` and production signing config (not placeholder/debug) | Gradle Kotlin DSL signing pattern (Standard Stack/Architecture Patterns below), keytool keystore generation, Play App Signing recommendation, namespace/applicationId divergence pitfall |
| PUBLISH-02 | App has Play Store listing assets (icon, screenshots) and a content-rating/target-audience declaration reviewed against Families Policy considerations | Programmatic adaptive-icon generation from `SunrisePainter`, `flutter_launcher_icons` config shape, Play Console target-audience/content-rating flow, Families Policy implications, GitHub Pages privacy policy hosting, real-device screenshot capture workflow |
</phase_requirements>

## Summary

This phase has two independent tracks that can be planned as separate waves: (1) a **build/signing track** — swap `com.example.zual` for `com.ireiter.zual`, add a production `signingConfigs` block reading `key.properties`, generate an upload keystore, and enroll in Play App Signing — and (2) a **listing-assets track** — generate an adaptive launcher icon programmatically from the existing `SunrisePainter`, capture 4 real-device screenshots, draft and host a privacy policy on GitHub Pages, and prepare the content-rating/target-audience answers a human will submit in Play Console.

The signing track is mechanically well-documented and low-risk: Flutter's own deployment docs give the exact `build.gradle.kts` shape (`[VERIFIED: pub.dev/flutter docs]`), and this repo already has `key.properties`/`*.keystore` gitignored with no keystore present yet, so there's no risk of accidental exposure. The one non-obvious technical risk in this phase is the icon-generation approach: rendering `SunrisePainter` to PNGs "headlessly" (D-04) requires either a `flutter test` (which runs against a real, headless Skia engine — the same mechanism Flutter's own golden-file tests rely on) or a live device/emulator; there is no plain `dart run` path because `dart:ui` has no headless-Skia backend outside the Flutter engine embedder. This should be spiked early (Wave 0) since the whole D-04 decision hinges on it working.

On the policy side, Google's "general audience that also appeals to children" declaration still triggers Families Policy obligations (a privacy policy is mandatory before that section can be completed at all), even though it's a lighter track than "Designed for Families." Content rating is a separate IARC questionnaire. Both are Play Console UI steps the human executes at submission time — this phase's job is only to prepare correct *answers* and a working privacy-policy URL, which fits the CONTEXT.md scope boundary ("assets and declarations are prepared here; the human still submits").

**Primary recommendation:** Treat this as two build-system commits (applicationId/signing; icon asset pipeline) plus three prepared-but-not-submitted artifacts (privacy policy page + URL, screenshot PNGs, content-rating/target-audience answer sheet), with a Wave 0 spike proving the headless `SunrisePainter`→PNG rendering path before committing to the full adaptive-icon-set generation task.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| applicationId / signing config | Android build config (Gradle) | — | Gradle Kotlin DSL owns build-time identity and signing; no Dart/Flutter code involved |
| Adaptive launcher icon generation | Flutter/Dart (asset pipeline, dev-time) | Android resources (`res/mipmap-*`) | Painter code lives in Dart; final consumable artifact is Android XML/PNG resources under `res/` |
| Privacy policy page | Static hosting (GitHub Pages) | — | Fully external to the Flutter app; no in-app code references it beyond the Play Console listing form |
| Screenshots | Manual/device capture workflow | Flutter app (running scenes) | The app renders scenes normally; capture is an external OS/tooling action, not app code |
| Content rating / target audience declaration | Play Console (human-submitted) | Project docs (prepared answers) | This phase only prepares the answer set; the actual declaration is filled in Play Console outside the repo |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Android Gradle Plugin | 8.11.1 (already pinned in `android/settings.gradle.kts`) | Release build, signing config, adaptive icon packaging | Already in use; AGP 8.x is required for current Flutter/Android tooling `[VERIFIED: android/settings.gradle.kts]` |
| Flutter Gradle plugin (bundled) | ships with Flutter 3.44.5 | Provides `flutter.compileSdkVersion`/`minSdkVersion`/`targetSdkVersion` defaults consumed in `build.gradle.kts` | Already wired in scaffold; defaults are 36/24/36 `[VERIFIED: flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt, local Flutter SDK install]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_launcher_icons` | 0.14.4 (pub.dev, published 2025-06-10) `[VERIFIED: pub.dev registry]` | Turns generated foreground/background PNGs into the full Android adaptive-icon asset set (`mipmap-anydpi-v26/ic_launcher.xml`, legacy per-density fallback PNGs, `colors.xml`) | Add as a `dev_dependency`; run `dart run flutter_launcher_icons` once the two source PNGs (foreground silhouette, background gradient) exist on disk |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_launcher_icons` | Hand-place PNGs into every `mipmap-*` density folder + hand-write `mipmap-anydpi-v26/ic_launcher.xml` and `colors.xml` | More manual/error-prone (5 densities × 2 layers + legacy fallback + XML); `flutter_launcher_icons` does exactly this mechanical work and already supports PNG-path (not just hex) backgrounds, which D-02's gradient requires |
| Play App Signing | Locally-held upload key only (no Play App Signing enrollment) | Google's current default/recommended path is Play App Signing (Google holds the app signing key, developer holds only an upload key that can be reset if lost); local-only means losing the keystore permanently locks you out of updating the app. No reason surfaced in research to deviate from Google's default here. |

**Installation:**
```bash
# pubspec.yaml (dev_dependencies)
flutter_launcher_icons: ^0.14.4
```

**Version verification:** `flutter_launcher_icons` confirmed via `pub.dev` registry API: latest `0.14.4`, published 2025-06-10T17:43:36Z `[VERIFIED: pub.dev/api/packages/flutter_launcher_icons]`. This is a well-established package (fluttercommunity org, 407 Context7 code snippets, high source reputation) — no npm cross-ecosystem confusion risk since it's Dart/pub-only and has no name-alike npm package in scope here.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|--------------|---------|-------------|
| `flutter_launcher_icons` | pub.dev | First published 2017-12-04 (current `0.14.4` from 2025-06-10) | Widely used community package (`fluttercommunity` org) | github.com/fluttercommunity/flutter_launcher_icons | OK | Approved |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

*Note: `gsd-tools package-legitimacy check` only supports `npm`/`pypi`/`crates` ecosystems; this phase's one new dependency is `pub` (Dart), so legitimacy was verified manually against the pub.dev registry API directly (age, publisher, source repo) instead. No cross-ecosystem confusion risk applies since there's no similarly-named npm/pypi package in play here.*

## Architecture Patterns

### System Architecture Diagram

```
[Dart: SunrisePainter, fixed progress + twinklePhase=0]
        │  (direct paint() call, no widget tree needed)
        ▼
[PictureRecorder → Canvas → Picture.toImage(w,h) → ByteData PNG]
        │  (runs inside `flutter test`'s headless Skia binding,
        │   via tester.runAsync for real file I/O)
        ▼
[assets/icon/icon_foreground.png]   [assets/icon/icon_background.png]
        │                                   │
        └──────────────┬────────────────────┘
                        ▼
        [pubspec.yaml: flutter_launcher_icons: config]
                        │  `dart run flutter_launcher_icons`
                        ▼
  [android/app/src/main/res/mipmap-*/ic_launcher.png (legacy fallback)]
  [android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml + colors.xml]
                        │
                        ▼
              [Android launcher shows adaptive icon]

── separately ──

[android/app/build.gradle.kts]
   applicationId "com.ireiter.zual"  (was com.example.zual)
   signingConfigs { create("release") { ... from key.properties ... } }
        │
        ▼
[keytool -genkey → upload-keystore.jks (gitignored, local only)]
        │
        ▼
[flutter build appbundle --release]  →  signed .aab  →  Play Console upload
                                                              │
                                                     (human enrolls in
                                                      Play App Signing)

── separately ──

[running app on real device/emulator, each of 4 scenes]
        │  adb screencap / Android Studio screenshot tool
        ▼
[4 full-bleed PNG screenshots, no frame/caption]  →  Play Console listing

[docs/privacy-policy.html or index.html]  →  GitHub Pages  →  stable URL
                                                              │
                                                     → Play Console
                                                       "Target audience and
                                                        content" section
```

### Recommended Project Structure
```
android/
├── app/
│   ├── build.gradle.kts          # applicationId, signingConfigs (edited)
│   ├── key.properties            # NEW, gitignored, local machine only
│   └── src/main/
│       ├── kotlin/com/example/zual/MainActivity.kt   # namespace pkg dir (see Pitfall below)
│       └── res/
│           ├── mipmap-{h,m,x,xx,xxx}dpi/ic_launcher.png  # regenerated (legacy fallback)
│           ├── mipmap-anydpi-v26/ic_launcher.xml         # NEW
│           └── values/ic_launcher_background.xml         # NEW (or values/colors.xml addition)
assets/
└── icon/
    ├── icon_foreground.png        # NEW, generated from SunrisePainter-derived shape
    └── icon_background.png        # NEW, generated gradient PNG
test/
└── tool/
    └── generate_launcher_icon_test.dart   # NEW: flutter-test-driven PNG export script
docs/                               # NEW: GitHub Pages source (or use gh-pages branch)
└── index.html                      # privacy policy page
pubspec.yaml                        # version/description bump, flutter_launcher_icons config + dev dep
```

### Pattern 1: Direct CustomPainter → PNG rendering (no widget tree)
**What:** `SunrisePainter` (and any `CustomPainter`) can be painted directly onto a `ui.Canvas` backed by a `ui.PictureRecorder`, entirely bypassing the widget tree / `RepaintBoundary` / `BuildContext`. This is simpler than the common "wrap in `RepaintBoundary`, find `RenderRepaintBoundary` via `GlobalKey`" pattern because `SunrisePainter` only needs `progress` and `twinklePhase` as constructor args (confirmed: it has no `BuildContext`/`InheritedWidget` dependency — see `lib/scenes/sunrise/sunrise_painter.dart`).
**When to use:** Generating static PNG exports of a scene at a fixed timer progress (icon foreground/background, and potentially reference stills), where no live `Ticker`/`TimerController` is available or needed.
**Example:**
```dart
// Source: dart:ui API (api.flutter.dev/flutter/ui/PictureRecorder-class.html,
// api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html) [CITED: api.flutter.dev]
final recorder = ui.PictureRecorder();
final canvas = Canvas(recorder);
const size = Size(432, 432); // adaptive-icon foreground canvas, e.g.
SunrisePainter(progress: 0.5, twinklePhase: 0).paint(canvas, size);
final picture = recorder.endRecording();
final image = await picture.toImage(size.width.toInt(), size.height.toInt());
final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
final bytes = byteData!.buffer.asUint8List();
```

### Pattern 2: Running the render inside `flutter test` (headless Skia), not plain `dart run`
**What:** `dart:ui` (`PictureRecorder`, `Image.toImage`, `Codec`) has no software/headless backend outside a Flutter engine embedder. A plain `dart run some_script.dart` script cannot call these APIs at all. The one headless-and-device-free environment where `dart:ui` really renders via Skia is the `flutter test` binding (`TestWidgetsFlutterBinding`) — the exact same mechanism Flutter's own golden-file tests (`matchesGoldenFile`) rely on to produce byte-identical PNGs in CI without a device.
**When to use:** Whenever D-04's "generate the icon programmatically... no external design tool" needs to run in CI/dev-machine without an emulator. Write a normal test file (e.g. `test/tool/generate_launcher_icon_test.dart`) that calls the Pattern 1 code, then use `tester.runAsync(() async { await File(path).writeAsBytes(bytes); })` to escape the test's fake-async zone and perform real file I/O (`dart:io` is otherwise unsafe to use directly inside a `testWidgets` body).
**Example:**
```dart
// Source: pattern synthesized from documented dart:ui/RenderRepaintBoundary
// API [CITED: api.flutter.dev] + flutter_test's runAsync contract
// (flutter_test golden-file precedent) [ASSUMED — no single official doc
// walks through "write a PNG-export script as a flutter test"; verify with
// a Wave 0 spike before relying on it for the full icon set]
testWidgets('generate sunrise icon PNGs', (tester) async {
  await tester.runAsync(() async {
    final bytes = await renderSunriseIconPng(progress: 0.5, size: 432);
    await File('assets/icon/icon_foreground.png').writeAsBytes(bytes);
  });
});
```

### Pattern 3: Gradle Kotlin DSL production signing config
**What:** Read `key.properties` before the `android {}` block; declare a `release` entry under `signingConfigs`; point `buildTypes.release.signingConfig` at it instead of `signingConfigs.getByName("debug")`.
**When to use:** PUBLISH-01, replacing the current scaffold's debug-signed release build.
**Example:**
```kotlin
// Source: flutter.dev Android deployment docs [CITED: flutter/website
// deployment/android.md via Context7 /flutter/website]
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.zual" // see Pitfall: namespace vs applicationId
    // ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    defaultConfig {
        applicationId = "com.ireiter.zual"
        // ...
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```
`key.properties` (project root of `android/`, already gitignored):
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
```
Keystore generation (documented, cross-platform):
```bash
# Source: flutter.dev deployment docs [CITED: flutter/website deployment/android.md]
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -storetype JKS -keysize 2048 -validity 10000 -alias upload
```

### Pattern 4: `flutter_launcher_icons` config for a gradient adaptive background
**What:** `adaptive_icon_background` accepts either a hex color string or a PNG path — the PNG-path form is required here because D-02's background is a **gradient**, not a flat color, which cannot be expressed as a single hex value.
**When to use:** Once `assets/icon/icon_foreground.png` and `assets/icon/icon_background.png` exist from Pattern 1/2.
**Example:**
```yaml
# Source: fluttercommunity/flutter_launcher_icons README + configuration
# docs [CITED: github.com/fluttercommunity/flutter_launcher_icons via Context7]
flutter_launcher_icons:
  image_path: "assets/icon/icon_foreground.png" # legacy/fallback icon source
  android: "launcher_icon"
  min_sdk_android: 24 # matches this project's flutter.minSdkVersion (see Pitfalls)
  adaptive_icon_background: "assets/icon/icon_background.png"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
```
Run with: `dart run flutter_launcher_icons`

### Anti-Patterns to Avoid
- **Building a screenshot-harness screen to fake progress for captures:** explicitly rejected by D-12 — screenshots must come from the real running app, not a staged debug screen.
- **Using `adaptive_icon_background` as a flat hex color:** loses D-02's gradient requirement; must use the PNG-path form.
- **Leaving `signingConfig = signingConfigs.getByName("debug")` in the release build type:** blocks PUBLISH-01 entirely; Play Console rejects debug-signed release bundles.
- **Trying to run the icon-generation script via plain `dart run`:** `dart:ui`'s `PictureRecorder`/`Image` APIs are not available outside a Flutter engine embedder (no device, no `flutter test`, no `flutter run`) — this will fail with an unsupported-operation or missing-binding error, not silently degrade.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Adaptive icon asset set (5 densities × fg/bg + legacy fallback + `mipmap-anydpi-v26` XML + `colors.xml`) | Manual per-density PNG placement and hand-written XML | `flutter_launcher_icons` (pub.dev) | Mechanical, error-prone density math (108dp adaptive canvas → 5 legacy px sizes) is exactly what this package automates; it already supports the PNG-background case D-02 needs |
| Upload keystore lifecycle / signing config wiring | A custom Gradle script or manual `jarsigner` invocation | Standard AGP `signingConfigs` block + `keytool` | This is the officially documented, universally-used pattern; deviating adds risk with zero benefit for a single-module app |

**Key insight:** Both hand-roll risks in this phase (icon asset generation, signing config) have single, canonical, well-documented tools/patterns — the only genuinely novel piece is *sourcing* the icon's pixels from `SunrisePainter` instead of a static design file, which is this phase's actual scope, not something to avoid.

## Runtime State Inventory

*Not applicable — this phase does not rename/refactor an existing production identity. `com.example.zual` is a placeholder that has never been published (no existing Play Console listing, no installed devices in the wild carrying that applicationId). It is a first-time identity assignment, not a migration.*

- **Stored data:** None — no data stores reference `com.example.zual` (confirmed: no backend, no analytics, no crash-reporting SDK in `pubspec.yaml`).
- **Live service config:** None — no external service (Firebase, ads SDK, etc.) is configured anywhere in the repo.
- **OS-registered state:** None on the development machine beyond the debug-installed APK using the old applicationId, which will simply be replaced by a new package on next install (Android treats it as a different app; the old placeholder-ID debug build can be uninstalled manually, not a migration concern).
- **Secrets/env vars:** None reference the applicationId string.
- **Build artifacts:** `android/app/src/main/kotlin/com/example/zual/MainActivity.kt` lives in a package-name-matching directory tied to the current **namespace** (not applicationId) — see Pitfall below; this is the one build-artifact-adjacent detail relevant to the identity change, but it is a namespace, not applicationId, concern.

## Common Pitfalls

### Pitfall 1: Confusing `namespace` and `applicationId`
**What goes wrong:** Developers assume changing `applicationId` (D-05) also requires moving `MainActivity.kt` into a new package directory and updating `namespace`, or conversely assume they must always match.
**Why it happens:** Pre-AGP-8, the manifest `package` attribute served both purposes; AGP 8 split them into `namespace` (controls generated `R`/`BuildConfig` code location) and `applicationId` (controls the actual Play Store / installed-app identity) `[CITED: developer.android.com/build/configure-app-module via WebSearch]`.
**How to avoid:** D-05 only requires changing `applicationId` in `build.gradle.kts`. The existing `namespace = "com.example.zual"` and the matching `MainActivity.kt` package directory (`android/app/src/main/kotlin/com/example/zual/MainActivity.kt`, confirmed present) can be left untouched — AGP copies `applicationId` into the final built manifest's `package` attribute regardless of `namespace`. Google's docs recommend keeping them equal as a style preference, but divergence is fully supported and functionally risk-free `[CITED: developer.android.com/build/configure-app-module]`. Planner should explicitly decide: leave `namespace` as-is (zero-risk, less consistent) or also rename it + move `MainActivity.kt` (more churn, fully cosmetic benefit) — CONTEXT.md's D-05 wording only locks `applicationId`, so leaving `namespace` alone is the lower-risk default unless the planner wants full consistency.

### Pitfall 2: `dart:ui` PNG rendering assumed to work in a plain script
**What goes wrong:** Attempting `dart run tool/generate_icon.dart` (a non-Flutter Dart script) that imports `dart:ui` and calls `PictureRecorder`/`Canvas`/`Image.toImage` fails — there is no headless Skia backend wired up outside a Flutter engine embedder.
**Why it happens:** `dart:ui` looks like a normal importable library, but its native implementation is only initialized by the Flutter engine (a running app, `flutter test`'s tester binary, or `flutter drive`/integration tests on a device).
**How to avoid:** Do the rendering inside a `flutter test` file (`TestWidgetsFlutterBinding`), using `tester.runAsync` for the real file-write step, per Pattern 2 above. Spike this in Wave 0 before committing to the full multi-size icon-generation task, since it's this phase's single riskiest unknown.
**Warning signs:** `Codec`/`Image`-related "Unsupported operation" or binding-not-initialized errors when running a plain script.

### Pitfall 3: Play Store version code/name bump omitted
**What goes wrong:** Uploading a build with the same `versionCode` as a previous upload (even a debug-only local build with no prior Play Console history) — or forgetting to bump it at all before the *first* upload — causes upload rejection.
**Why it happens:** `pubspec.yaml`'s `version: 1.0.0+1` is still the scaffold default; Play Console requires each successive AAB upload to have a strictly increasing `versionCode` (the `+1` build number).
**How to avoid:** For the *first* Play Console upload, any starting `versionCode` (e.g. keep `1.0.0+1` or bump to something intentional like `1.0.0+1`) is acceptable since there's no prior upload to collide with — but bump `version:` deliberately as part of this phase's "identity becomes real" work (Claude's discretion per CONTEXT.md) so subsequent updates start from a clean, intentional baseline rather than the placeholder.
**Warning signs:** Play Console upload UI explicitly errors with "version code X has already been used."

### Pitfall 4: Target API level policy (2026) — likely already satisfied, but verify
**What goes wrong:** Assuming a manual `targetSdk`/`compileSdk` bump is needed for Play Store compliance.
**Why it happens:** Play Console enforces a yearly-shifting minimum target API level; as of the policy in effect around this phase's timeframe, new apps/updates must target API 36 (Android 16), existing apps at least API 35, with the hard deadline around Aug 31 2026 (extension to Nov 1 2026 available) `[CITED: support.google.com/googleplay/android-developer/answer/11926878 and answer/16561298 via WebSearch — LOW confidence, policy dates shift; re-verify at actual submission time]`.
**How to avoid:** This project already inherits `compileSdkVersion=36`, `targetSdkVersion=36`, `minSdkVersion=24` from Flutter 3.44.5's bundled Gradle plugin defaults `[VERIFIED: local Flutter SDK, flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt]` — no manual override needed. Still worth a one-line explicit confirmation step in the plan (e.g. `flutter build appbundle --release` succeeds with no SDK-level warnings) rather than assuming silently.
**Warning signs:** Play Console upload warning/rejection citing target API level.

### Pitfall 5: Content rating / target audience answers drift from what's actually true at submission time
**What goes wrong:** This phase's prepared answer sheet (D-07/D-08) becomes stale if Play Console's questionnaire wording or policy scope changes between now and actual human submission.
**Why it happens:** Already flagged in `.planning/STATE.md` Blockers/Concerns: "Play Store Families Policy and target-audience declaration must be re-verified in Play Console at submission time (policy wording changes)."
**How to avoid:** Treat D-07/D-08's prepared answers as a **draft answer sheet artifact** (e.g. a short doc/checklist) rather than assuming they map 1:1 to whatever the live questionnaire asks; the plan's verification step should say "human confirms these answers still match the live Play Console form" rather than "declaration is submitted."
**Warning signs:** N/A — this is a process/timing risk, not a build-time error.

## Code Examples

### Verifying the render pipeline works before generating all sizes (Wave 0 spike)
```dart
// Source: dart:ui + flutter_test APIs [CITED: api.flutter.dev]
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zual/scenes/sunrise/sunrise_painter.dart';

Future<void> main() async {
  test('spike: render SunrisePainter to a PNG file', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(432, 432);
    SunrisePainter(progress: 0.5, twinklePhase: 0).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('build/spike_icon.png').create(recursive: true);
    await File('build/spike_icon.png').writeAsBytes(byteData!.buffer.asUint8List());
    expect(File('build/spike_icon.png').existsSync(), isTrue);
  });
}
```
Note: plain `test()` (not `testWidgets()`) inside a `flutter_test`-imported file still runs under `TestWidgetsFlutterBinding` once `TestWidgetsFlutterBinding.ensureInitialized()` is called or a `testWidgets` case runs earlier in the suite; the safest, most standard form is a `testWidgets` case with `tester.runAsync(...)` wrapping the file I/O, per Pattern 2.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Single legacy PNG launcher icon (`mipmap-*/ic_launcher.png` only) | Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml` with separate foreground/background layers + monochrome themed variant) | Android 8.0 (API 26) introduced adaptive icons; Android 13 added themed/monochrome icons | Legacy PNG-only icons still work as a fallback for very old devices (`min_sdk_android` in `flutter_launcher_icons` controls whether that fallback is even generated), but the adaptive format is what Play Store review and modern launchers expect |
| Manifest `package` attribute doing double duty (code namespace + app identity) | AGP 8 split `namespace` (build.gradle) from `applicationId` | AGP 8.0 (April 2023) | Enables the namespace/applicationId divergence described in Pitfall 1 |

**Deprecated/outdated:**
- Upload-key-only signing without Play App Signing: still supported, but Google's own guidance and default flow favor Play App Signing (key-loss recovery, smaller APKs via app-bundle optimizations) — no reason found in research to deviate here.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A `flutter test`-based script (Pattern 2) is the correct/only practical way to render `SunrisePainter` to PNG without a device — no official doc walks through this exact "PNG-export script as a test file" pattern; it's inferred from `dart:ui`'s documented API plus the well-known golden-file testing precedent | Architecture Patterns Pattern 2, Code Examples | If wrong, the Wave 0 spike simply fails fast and the plan falls back to capturing icon source PNGs from a live device/emulator screenshot of the running `SunriseScene` at a fixed progress instead — no scope change, just a slower/manual substitute for D-04's "programmatic" claim |
| A2 | Google Play's 2026 target-API-level deadline specifics (Aug 31 2026 new-app cutoff, API 36) reflect the currently correct policy | Common Pitfalls, Pitfall 4 | If Play Console's actual current requirement differs, the plan's verification step ("no SDK-level warning on `flutter build appbundle --release`") still holds since this project already targets the newest API (36) regardless of the exact deadline date |
| A3 | "General audience that also appeals to children" still requires a privacy policy and is subject to (a lighter form of) Families Policy obligations, distinct from full "Designed for Families" | Architecture Patterns diagram, Pitfall 5 | If Play Console's actual live questionnaire has reorganized this distinction, the human-verification step at submission time (already flagged in STATE.md) catches it — this phase's answer sheet is explicitly a draft, not a submission |

**If this table is empty:** N/A — see entries above.

## Open Questions

1. **Exact pixel sizes to export for `flutter_launcher_icons` input PNGs**
   - What we know: `flutter_launcher_icons` wants a single square foreground/background source image per platform (commonly 1024×1024 for `image_path`, with adaptive foreground typically designed on a 108dp/432px "safe zone" canvas at xxxhdpi).
   - What's unclear: The exact recommended source resolution isn't pinned to one specific number across all `flutter_launcher_icons` docs fetched.
   - Recommendation: Export at 1024×1024 for both foreground and background source PNGs (a safe, commonly-used size that downsamples cleanly to every required density) — this is Claude's discretion per CONTEXT.md and doesn't need re-litigation.

2. **Whether GitHub Pages should serve from a `gh-pages` branch, `/docs` folder on `main`, or a GitHub Actions build**
   - What we know: All three are supported; `/docs` folder on `main` requires zero extra tooling (no Action, no extra branch) and is the simplest for a single static HTML page.
   - What's unclear: Repo-specific preference (e.g. does the user want `.planning`/build hygiene concerns to keep `docs/` clean of unrelated content?).
   - Recommendation: Use `/docs` folder on `main` unless the planner finds a reason to prefer a dedicated `gh-pages` branch — simplest, zero-additional-CI setup, matches "minimal setup" framing in CONTEXT.md's research ask.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Flutter SDK | Entire phase | ✓ | 3.44.5 (stable) | — |
| Android SDK (`sdk.dir` in `local.properties`) | Build/signing | ✓ | (configured, path present) | — |
| `keytool` (bundled with JDK) | Upload keystore generation | ✓ (assumed present — ships with any JDK, and AGP/Flutter Android tooling requires a JDK already) | — | If missing, install a JDK (Android Studio bundles one) |
| Android Studio or a running emulator/real device | Screenshot capture (D-12), Wave 0 spike fallback | Not probed directly (no `adb devices`/emulator check run in this research session — this machine's dev environment for the actual capture step is the executing agent's/human's concern at execution time) | — | If no device/emulator available at execution time, this blocks D-11/D-12 entirely — flag as a human-required step, not something the planner can route around |
| GitHub Pages (GitHub-hosted) | Privacy policy URL (D-10) | ✓ (repo is on GitHub per git remote conventions; no explicit remote URL check run this session) | — | — |

**Missing dependencies with no fallback:**
- A real Android device or emulator for screenshot capture (D-11/D-12) and, if the Pattern 2 spike fails, for a manual icon-source screenshot fallback — this is inherently a human/execution-time dependency, not resolvable in research.

**Missing dependencies with fallback:**
- None identified beyond the above.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK) — already used throughout `test/` |
| Config file | none — standard `flutter test` invocation, no custom config |
| Quick run command | `flutter test test/tool/generate_launcher_icon_test.dart` (icon-generation spike/verification) |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| PUBLISH-01 | `applicationId` is `com.ireiter.zual`, release build type uses the `release` signing config (not `debug`) | manual/build-check (no automated Dart test can assert Gradle config short of a Gradle build) | `flutter build appbundle --release` (succeeds, and `unzip -p build/.../base.apk META-INF/*.RSA \| keytool -printcert` shows the upload cert, not debug) | ❌ Wave 0 — this is a build-tool check, not a `flutter test`, so "file exists" doesn't apply; document as a manual verification step in the plan instead |
| PUBLISH-02 (icon) | `SunrisePainter`-derived PNGs render successfully and `flutter_launcher_icons` produces a valid adaptive icon set | automated (widget/unit) | `flutter test test/tool/generate_launcher_icon_test.dart -x` (spike, per Code Examples) | ❌ Wave 0 — new test file to create |
| PUBLISH-02 (screenshots) | 4 real-device screenshots exist, one per scene, full-bleed | manual-only (device capture is inherently outside `flutter test`'s reach) | N/A — human/manual step; justification: no automated harness can drive a real device screenshot within this repo's test infra, and D-12 explicitly forbids a staged screenshot-harness screen | — |
| PUBLISH-02 (privacy policy) | Privacy policy page is live at a stable GitHub Pages URL | manual/smoke (a `curl`/`WebFetch` check that the URL returns 200 with expected content, post-deploy) | `curl -sI https://<user>.github.io/<repo>/` (expect `200`) | ❌ Wave 0 — page doesn't exist yet |
| PUBLISH-02 (content rating/audience) | Draft answer sheet exists and is internally consistent with D-07/D-08 | manual-only (Play Console questionnaire itself is external; nothing in-repo to automate) | N/A — human reviews the drafted answer doc against locked decisions | — |

### Sampling Rate
- **Per task commit:** run the relevant quick command above for build-adjacent tasks (icon spike, signing config).
- **Per wave merge:** `flutter test` (full existing suite — must stay green; this phase touches no app logic, so a regression here would indicate an accidental code change, not an expected one).
- **Phase gate:** Full suite green, plus the manual verification checklist above (release build installs and runs a full countdown on a real device — the phase's literal Success Criterion #4) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/tool/generate_launcher_icon_test.dart` — spike proving `SunrisePainter` → PNG rendering works headlessly (Pattern 2); this gates the entire D-04 icon-generation task.
- [ ] No existing test infra needs new shared fixtures for this phase — the app's existing `test/` suite is untouched by this phase's changes.
- [ ] Framework install: none — `flutter_test` already present; only new pub dependency is `flutter_launcher_icons` (dev-only), not a testing dependency.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | App has no accounts/login (confirmed out of scope in REQUIREMENTS.md) |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | Single-user, single-device, no roles |
| V5 Input Validation | No | This phase adds no user-facing input surfaces |
| V6 Cryptography | Partial — signing key handling only | Standard Android `keytool`-generated RSA keystore + Play App Signing (Google-managed key custody); never hand-roll signing/crypto — use the documented `keytool`/AGP `signingConfigs` path exactly as shown in Architecture Patterns Pattern 3. Do not commit `key.properties` or `*.keystore` (already gitignored — verify this remains true after this phase's edits). |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| Upload keystore committed to git / leaked | Information Disclosure | Already mitigated: `android/.gitignore` excludes `key.properties`, `**/*.keystore`, `**/*.jks`; root `.gitignore` excludes `*.jks`. Verify these patterns still cover whatever exact filename the generated keystore uses (this research recommends `upload-keystore.jks`, which matches `*.jks`). |
| App impersonation via a similar `applicationId` on Play Store | Spoofing | Not directly mitigatable by this phase beyond choosing a real, developer-account-scoped `applicationId` (`com.ireiter.zual`) rather than a generic/example one — already satisfied by D-05. |
| Privacy policy page silently going offline (GitHub Pages outage, repo deleted/renamed) breaking the Play Console link | Denial of (listing) availability | Low severity for a solo/small project; not worth over-engineering — a plain static page on GitHub Pages is the industry-standard low-risk choice for exactly this use case. |

## Sources

### Primary (HIGH confidence)
- None — no `[VERIFIED]`-tier source in this research came from a tool cross-checked against a second independent authoritative source (the bar this session's `classify-confidence` seam applies for HIGH). The two closest-to-HIGH facts (Flutter Gradle plugin defaults; `flutter_launcher_icons` pub.dev registry metadata) were confirmed by direct inspection of the installed SDK / the pub.dev API respectively and are marked `[VERIFIED]` inline even though the seam's automatic tiering for those exact calls returned MEDIUM/LOW — see Metadata below for the reasoning.

### Secondary (MEDIUM confidence)
- Context7 `/flutter/website` — Android release signing (`build.gradle.kts` signingConfigs pattern, `key.properties`, `keytool` command)
- Context7 `/fluttercommunity/flutter_launcher_icons` — adaptive icon configuration options, YAML shape, `min_sdk_android`
- pub.dev registry API (`https://pub.dev/api/packages/flutter_launcher_icons`) — version/publish-date verification
- Local Flutter SDK inspection (`flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`) — `compileSdkVersion`/`minSdkVersion`/`targetSdkVersion` defaults
- `developer.android.com/build/configure-app-module` (via WebSearch synthesis) — namespace vs applicationId

### Tertiary (LOW confidence)
- WebSearch/WebFetch synthesis of `support.google.com/googleplay/android-developer` pages (content rating, target audience, Families Policy) — official source, but fetched via a summarizing tool rather than read verbatim; re-verify wording at actual Play Console submission time (already flagged in STATE.md)
- WebSearch synthesis on Google Play target API level 2026 deadlines — dates/policy specifics should be re-checked close to submission
- WebSearch on GitHub Pages setup steps and `dart:ui`/`RenderRepaintBoundary` headless rendering precedent (Pattern 2 is an inference from documented APIs, not a single found tutorial)

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — `flutter_launcher_icons` version/registry facts are directly verified; Gradle signing pattern is from official Flutter docs via Context7.
- Architecture: MEDIUM — Signing pattern and icon config shape are well-cited; the headless-PNG-rendering approach (Pattern 2) is a reasoned inference from documented `dart:ui` APIs plus golden-file-testing precedent, not a directly-found tutorial — flagged as Assumption A1 and gated behind a Wave 0 spike.
- Pitfalls: LOW-MEDIUM — namespace/applicationId and versionCode pitfalls are well-established Android knowledge; target-API-level and Families Policy specifics are time-sensitive and explicitly flagged for re-verification at submission time (consistent with STATE.md's existing blocker note).

**Research date:** 2026-07-09
**Valid until:** ~30 days for the Gradle/icon-generation mechanics (stable); the Play Console policy sections (content rating, target audience, Families Policy, target API level deadlines) should be treated as valid for guidance only and re-verified at actual submission time regardless of elapsed days, per STATE.md's existing blocker.
