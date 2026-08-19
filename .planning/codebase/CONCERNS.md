# Codebase Concerns

**Analysis Date:** 2026-08-19

## Tech Debt

### Icon Generator Test Files Silently Rewrite Committed PNGs

**Issue:** `test/tool/generate_launcher_icon_test.dart` and `test/tool/generate_store_icon_test.dart` are named with the `_test.dart` suffix, so a plain `flutter test` run discovers and auto-executes them. Both tests write PNG files to disk (`assets/icon/icon_background.png`, `assets/icon/icon_foreground.png`, `store_assets/icon_512.png`), silently overwriting the committed versions. Output is byte-stable today so the working tree stays clean, but that is luck — any change to the rendering logic, output encoding, or dependencies will cause these to diverge undetectably until manual diff.

**Files:** 
- `test/tool/generate_launcher_icon_test.dart` (lines 50–77)
- `test/tool/generate_store_icon_test.dart` (lines 20–79)

**Why it matters:** The pattern is flagged as an open anti-pattern in `05-REVIEW.md` (WR-04/WR-05) and explicitly accepted as tech debt in `PROJECT.md` ("Known non-blocking tech debt"). Every developer running `flutter test` could accidentally commit diverged binaries without noticing. A third generator, `test/tool/generate_feature_graphic.dart`, demonstrates the correct pattern: named WITHOUT `_test.dart` suffix (line 16 comment explains this), so it must be invoked explicitly and never silently overwrites on a routine test run.

**Severity:** Medium — byte-stability masks the issue today, but it's a latent sync problem waiting to happen.

**Status:** Accepted tech debt, documented as WR-04/WR-05 in `05-REVIEW.md`. Not blocking v1.0 or v2 scope.

**Fix approach:** 
1. Rename both files to remove `_test.dart` suffix (e.g., `generate_launcher_icon.dart`, `generate_store_icon.dart`).
2. Update CI/build scripts to invoke them explicitly: `flutter test test/tool/generate_launcher_icon.dart` (not auto-discovered by bare `flutter test`).
3. Add a complementary read-only drift-lock `_test.dart` pair for each (e.g., `test/tool/generate_launcher_icon_test.dart`) that re-renders in-memory and byte-diffs against the committed file, failing loudly on divergence instead of silently overwriting.
4. Reference: `test/tool/generate_feature_graphic.dart` (non-`_test.dart` generator) + the pattern described in RETROSPECTIVE.md's "Patterns Established" section.

---

### Unclosed FileInputStream in Android Gradle Build Config

**Issue:** `android/app/build.gradle.kts` line 14 creates a `FileInputStream` to read the keystore properties file but never closes it, leaking the file handle.

**Files:** `android/app/build.gradle.kts` (line 14)

**Code:**
```kotlin
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    // FileInputStream is never closed
}
```

**Why it matters:** Gradle build scripts run in-process during build time, so a leaked file handle consumes a system resource and can cascade if builds run in quick succession (CI pipelines, local builds in a loop). Kotlin idiom is to use `.use { }` scope or try-with-resources to ensure closure.

**Severity:** Low — happens once per build, and system file descriptor limits are usually high (1024+). Only impacts build performance or CI/CD parallelism if many builds run simultaneously.

**Status:** Accepted tech debt, noted in `PROJECT.md` ("Known non-blocking tech debt"). Does not block Play Store publication.

**Fix approach:**
```kotlin
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
```

---

### No Build-Time Gate Against Accidental Debug-Signed Release Builds

**Issue:** `android/app/build.gradle.kts` lines 59–69 fall back to debug signing if `key.properties` doesn't exist, allowing `flutter run --release` to succeed locally with an unsigned/debug-signed APK. A developer could accidentally commit and upload a debug-signed AAB to Play Store if CI doesn't enforce the presence of the signing key.

**Files:** `android/app/build.gradle.kts` (lines 59–69)

**Code:**
```kotlin
buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")  // Silent fallback
        }
    }
}
```

**Why it matters:** Play Store will reject debug-signed APKs/AABs, but the failure only occurs during upload, not at build time. A developer working locally (where `key.properties` is gitignored and not present) will happily build and test `--release` mode against the debug keystore, which could cause confusion or encourage them to upload without re-checking signing config on the CI machine.

**Severity:** Low — mostly a process issue. v1.0 publication was verified by human pre-upload (no automated CI build-and-upload pipeline yet).

**Status:** Accepted tech debt, noted in `PROJECT.md`. Mitigated by manual human verification before each Play Store upload.

**Fix approach:**
- Add an explicit CI environment variable check (e.g., `CI_BUILD`) that errors if `key.properties` is missing.
- Or: wrap the fallback in `error("key.properties not found in release build")` when CI build context is detected.
- Rationale: local builds can fall back to debug (for testing); CI builds must enforce release signing or fail fast.

---

### Android `namespace` Still Reads `com.example.zual`

**Issue:** `android/app/build.gradle.kts` line 20 sets `namespace = "com.example.zual"` while
line 34 sets `applicationId = "com.ireiter.zual"`. The published identity is correct — only
`applicationId` reaches the Play Store — but the `com.example` namespace remains from the
original scaffold.

**Files:** `android/app/build.gradle.kts` (lines 18–20, 34)

**Why it matters:** This is **intentional and documented in-file**: the namespace controls
where generated `R`/`BuildConfig` classes live and must match the existing `MainActivity.kt`
package directory; locked decision D-05 pins only `applicationId`. Recorded here because
`com.example` in a shipped app reliably reads as an oversight to anyone reviewing the build
config, and the next person to notice it should find this entry rather than "fix" it and
break the Kotlin package mapping.

**Severity:** None — cosmetic, and correct as-is.

**Status:** Accepted by design (D-05). Changing it would require moving `MainActivity.kt`
and updating the generated-class references in step.

---

## Dead Code

### Placeholder Running Screen Unreferenced

**Issue:** `lib/screens/placeholder_running_screen.dart` is Phase 1/2 scaffolding (a minimal, inert countdown screen with a shrinking circle and a back button) that was replaced by the real `RunningScreen` in Phase 4. It is never imported anywhere in `lib/` or `test/`, referenced only in two doc-comment links in `running_screen.dart` (lines 26 and 36).

**Files:** 
- `lib/screens/placeholder_running_screen.dart` (entire file, 102 lines)
- Referenced in: `lib/screens/running_screen.dart` (lines 26, 36 — as `[PlaceholderRunningScreen]` Dartdoc links)

**Why it matters:** Dead code inflates the apparent surface area of `lib/screens/`, invites accidental revival, and confuses maintainers wondering if it's still in use. The Dartdoc links are fragile — they break if the file is deleted without updating the comments.

**Severity:** Low — purely organizational. Does not affect functionality or performance.

**Status:** Open action — should be cleaned up before the next milestone or phase.

**Fix approach:**
1. Delete `lib/screens/placeholder_running_screen.dart`.
2. Update the two Dartdoc links in `running_screen.dart` (lines 26 and 36) to reference the git history or commit message instead:
   ```dart
   /// ... replaced by [RunningScreen] in Phase 4 (see git history for PlaceholderRunningScreen)
   ```

---

## Missing Critical Configuration

### No LICENSE File

**Issue:** The repository has no `LICENSE` or `LICENSE.txt` file, so the default GitHub-inferred license is "All rights reserved" (proprietary).

**Files:** Root directory — no LICENSE file present

**Why it matters:** The repository is public on GitHub (`https://github.com/reiteristvan/zual.git`).
With no LICENSE, default copyright applies — nobody may legally copy, modify, or contribute,
and the terms under which the source is published are undefined. Note this is a *repository*
concern, not a Play Store one: Google Play does not inspect for a LICENSE file, and the
separate privacy-policy requirement is already satisfied by `docs/index.html`.

**Severity:** Medium — no effect on the app or on Play review, but it leaves the published
source in a legally ambiguous state.

**Status:** Open action — worth resolving alongside publication, though it does not block it.

**Fix approach:**
1. Choose a license appropriate to the project intent (e.g., `MIT`, `Apache-2.0`, `GPL-3.0`, custom).
2. Create `LICENSE` or `LICENSE.txt` at the root with full license text.
3. Update `README.md` to reference it: "## License: [See LICENSE file]".
4. Recommendation: consult with project owner on usage rights (personal/commercial, open-source vs. proprietary, etc.) before committing.

---

## Known Design/Verification Gaps

### Tablet Form Factor Rendering Bug (Post-Milestone Fix)

**Issue:** The design spec (`design/README.md`) specifies only a 402px phone reference frame. Post-v1.0 dogfooding discovered that on tablets (wider than 402px), the Setup screen's preset and scene grids stretched to full screen width, causing grid cells to grow while their interior content (preset fonts, scene thumbnail) was fixed-size, resulting in oversized cards with tiny text and artwork that filled only a fraction of the cell.

**Files:** 
- **Root cause & fix:** `lib/screens/setup_screen.dart` (lines 64–75 document the fix, lines 172–174 implement it)
- **Comments explain the context:** lines 346–349, 441–446

**What was fixed:** Setup screen content column capped at 440px (slightly above the 402px reference) and centered. Scene card thumbnails changed from fixed 74px to `Expanded` to fill available card width. Fix confirmed on physical tablet + phone.

**Why it matters:** This was a testing/verification gap, not a development gap. The bug was latent in the phone-only design and only exposed when a tablet was tested post-shipping.

**Severity:** Low — only affects tablets; phones are unaffected (they're narrower than 440px, so cap is a no-op). Verified fixed in `.planning/debug/tablet-setup-layout-scaling` session.

**Status:** Resolved — fix is committed and documented. Lesson carried forward: future layout work should include explicit tablet/large-screen testing during phase UAT.

**Recommendation:** Add a tablet-sized device to the verification matrix for future UI-heavy phases (Phases 2, 3, 4, 5).

---

### Colorblind-Safe Audit Not Yet Performed (A11Y-01)

**Issue:** The Shrinking Disc scene conveys timer state largely through color (green → yellow → red zones). No colorblind-safe audit has been performed to verify that the color transitions are distinguishable under common forms of color blindness (deuteranopia, protanopia, tritanopia).

**Files:** 
- `lib/scenes/disc/disc_painter.dart` (color zone definitions and rendering)
- Design reference: `design/README.md` (specifies the color zones)

**Why it matters:** The app targets young children (ages 2–6), and roughly 8% of males have some form of color blindness. If the disc's color zones are indistinguishable under color blindness, children with that condition will have a degraded experience.

**Severity:** Medium — impacts accessibility for a meaningful portion of the user base, though the disc is not the *only* feedback mechanism (the disc still shrinks, providing visual motion cues).

**Status:** Open action, explicitly carried as A11Y-01 into v2 scope (see `PROJECT.md` active items and ROADMAP.md). Not blocking v1.0 publication but should be addressed before wider distribution.

**Fix approach:**
1. Run the scene through a colorblind simulator (e.g., Color Oracle, Coblis online simulator, or a design tool's built-in accessibility checker).
2. If zones are indistinguishable:
   - Add a secondary visual cue (hatching/pattern, or more pronounced scale change in the late-warning zone).
   - Or: adjust color values to maximize contrast under deuteranopia/protanopia.
3. Verify with human reviewers (actual colorblind users, or accessibility consultants).
4. Update `lib/scenes/disc/disc_painter.dart` and design tokens as needed.

---

### Play Store Families Policy Re-Verification Required

**Issue:** The app targets children ages 2–6 and is intended for Play Store publication under Google's Families Policy. The initial submission will require:
1. Confirmation that the app meets Families Policy requirements (no ads, no third-party integrations, no data collection).
2. Target audience declaration (kids).
3. Content rating questionnaire.

These are one-time submission steps, not code issues, but they are a blocker for publishing and require re-verification at each update.

**Files:** 
- Documentation: `.planning/PROJECT.md` (line 42: active item, "Submit the v1.0 build to Google Play Console and publish")
- Privacy policy: `docs/index.html` (the only file in `docs/`; there is no `PRIVACY_POLICY.md`)

**Why it matters:** Google Play may reject the submission if Families Policy requirements are not met. The app is compliant (no ads, no tracking, no third-party SDKs for analytics/ads), but submission requires explicit declaration.

**Severity:** Medium — not a code defect, but a process blocker for publication.

**Status:** Carried blocker in `PROJECT.md`. Not an open action for code changes; it's a human verification step before publication.

**Recommendation:** Before the next Play Store update (v1.1+), re-verify all Families Policy requirements and re-answer the content rating questionnaire to confirm compliance.

---

## Resource Lifecycle Considerations

### TimerLifecycleBinder Observer Never Detached

**Issue:** `lib/timer/timer_lifecycle_binder.dart` provides `attach()` and `detach()` methods to register/unregister as a `WidgetsBindingObserver`. In `lib/main.dart` (line 34), `TimerLifecycleBinder(timerController).attach()` is called during app initialization, but `detach()` is never called. The observer registration persists for the lifetime of the app (which is fine for a global singleton), but if the app ever needs to clean up or re-initialize this observer, the dangling registration could cause issues.

**Files:**
- `lib/timer/timer_lifecycle_binder.dart` (lines 22–31, attach/detach methods)
- `lib/main.dart` (line 34, attach called but never detached)

**Why it matters:** This is a latent lifecycle issue. In the current app (which runs from startup to shutdown), it's benign — the observer is global and lives until process termination. But if future versions implement multiple timer instances, app restart without process restart, or lifecycle-aware cleanup, this could become a leak.

**Severity:** Low — current architecture is monolithic (single app instance), so the observer is never expected to be detached. Only matters if architecture changes to support multiple timer instances or hot restart.

**Status:** Accepted design — the binder is intentionally global and app-lifetime.

**Recommendation:** If future phases add multiple timer instances or dynamic lifecycle management, refactor to:
1. Wrap `TimerLifecycleBinder` creation/attachment in a `Provider` or singleton factory.
2. Ensure `detach()` is called in a cleanup hook (e.g., app exit or instance teardown).
3. Add a test to verify observer cleanup via `WidgetsBinding.instance.observers`.

---

## Potential Performance Characteristics

### Per-Frame CustomPainter Render Cost

**Issue:** Four full-screen scene renderers (`DiscPainter`, `SunrisePainter`, `WalkPainter`, `CarPainter`) are CustomPainter implementations that re-render every frame while the timer is running. Each painter computes gradients, paths, and transforms based on the current progress value (0..1).

**Files:**
- `lib/scenes/disc/disc_painter.dart` (119 lines, progress-driven disc + color zones)
- `lib/scenes/sunrise/sunrise_painter.dart` (190 lines, sky gradient, stars, sun, hill)
- `lib/scenes/walk/walk_painter.dart` (256 lines, path, character, house)
- `lib/scenes/car/car_painter.dart` (272 lines, road, car, wheels)

**Why it matters:** On low-end devices (budget tablets, which are the likely target for parents of young children), per-frame rendering of complex paths and gradients could cause frame drops or battery drain. The app specifies no performance requirements, but a smooth 60 FPS is expected for a child-facing UI.

**Severity:** Low (latent) — v1.0 testing was done on mid-range phones (Samsung A25) and emulators. No performance regression has been reported, but wider tablet testing post-v1.0 revealed the tablet layout bug, suggesting device diversity testing was incomplete.

**Status:** Not an open issue — codebase is generally well-optimized (scene painters use Canvas primitives, not nested widgets; scene rendering is decoupled from UI state changes). Monitor post-publication if low-end device complaints arise.

**Recommendation:**
1. If future phases add more animation detail (e.g., parallax layers, particle effects), profile with Flutter DevTools (`flutter run --profile`, then use the Performance tab).
2. Use `RepaintBoundary` around static elements (e.g., background sky in Sunrise) to reduce invalidation scope.
3. Consider offscreen rendering (via `Picture.toImage()`) for extremely complex scenes on very low-end devices, but current painters are lean enough that this is unlikely to be necessary.

---

## Error Handling & Resilience

### Preference Loading Gracefully Swallows Errors

**Issue:** `lib/settings/setup_preferences.dart` (lines 71–101) and `lib/main.dart` (lines 27–31) wrap preference loading in try-catch blocks that swallow all exceptions and return a hard-coded default. This is intentional (documented in comments as defense-in-depth against tampering, T-02-02), but it masks any real I/O or SharedPreferences errors.

**Files:**
- `lib/settings/setup_preferences.dart` (lines 75–98, three separate try-catch blocks for durationMin, theme, soundOn)
- `lib/main.dart` (lines 27–31, top-level catch during app startup)

**Why it matters:** If SharedPreferences is corrupted or inaccessible (disk full, permission issue), the app will silently succeed and ignore the error. This is by design (the app must never fail to launch), but it means real I/O failures go unlogged and unmonitored.

**Severity:** Low — errors are caught intentionally. If structured logging is added in a future phase, consider logging these swallowed exceptions at a debug/info level for diagnostics, while still falling back to defaults.

**Status:** Accepted design. Documented in comments.

**Recommendation:** No code changes needed for v1.0 or v2. If a future phase adds logging/crash reporting, emit a debug-level log message before returning the default:
```dart
} catch (e) {
  debugPrint('Preference load failed: $e, using default');
  durationMin = 5;
}
```

---

### Sound Preference Persistence Failures Silently Ignored

**Issue:** In `lib/screens/running_screen.dart` line 266, toggling the mute switch calls `SetupPreferences.persistSoundOn(soundOn.value).catchError((_) {})`, which silently swallows persistence failures. The UI immediately updates (the ValueNotifier is updated), but if SharedPreferences write fails (disk full, permissions), the error is discarded and the parent won't know their preference wasn't saved.

**Files:** `lib/screens/running_screen.dart` (line 266)

**Code:**
```dart
void _toggleSound() {
  soundOn.value = !soundOn.value;
  unawaited(SetupPreferences.persistSoundOn(soundOn.value).catchError((_) {}));
}
```

**Why it matters:** Unlike preference *loading* (which must never fail startup), preference *writing* is a UX feedback opportunity. If the write fails, the parent toggled mute but it won't persist — next launch, it's back to the previous state. A user could find this confusing.

**Severity:** Low — the UI responds immediately, and the most likely failure (disk full) is a system-level error that the app can't recover from anyway. Mute preference is also optional (not critical to functionality).

**Status:** Accepted — marked `unawaited()` to indicate intentional fire-and-forget. Not a defect, but could be improved with user feedback if writes fail frequently.

**Recommendation:** If persistence failures become reportable in a future phase (crash reporting, etc.), consider:
1. Logging the error so backend telemetry can detect widespread write failures.
2. Or: showing a transient snack bar if the write fails ("Preference saved" / "Couldn't save preference"), though this adds UI complexity.
For v1.0+v2, silent failure is acceptable.

---

## Test Coverage

### Test Tool Generators Not Paired With Verification Tests

**Issue:** `test/tool/generate_launcher_icon_test.dart` and `test/tool/generate_store_icon_test.dart` write committed PNG assets but are not paired with complementary read-only drift-detection tests. A developer could run these, commit the binaries with diverged output (due to dependency updates, rendering changes, etc.), and the CI would not catch it.

**Files:**
- `test/tool/generate_launcher_icon_test.dart`
- `test/tool/generate_store_icon_test.dart`
- (Should have: `test/tool/generate_launcher_icon_verification_test.dart`, etc., per the feature-graphic pattern)

**Why it matters:** Ensures the committed PNG assets stay in sync with the generating code. Without verification tests, divergence can slip unnoticed into subsequent builds.

**Severity:** Medium — contributes to the "silently overwrite" anti-pattern.

**Status:** Accepted tech debt. Documented as WR-04/WR-05 in `05-REVIEW.md`.

**Fix approach:** Create read-only drift-lock `_test.dart` pairs for each generator (as demonstrated by `test/tool/generate_feature_graphic.dart`), which re-render in-memory and byte-diff against the committed file, failing loudly on divergence.

---

## Summary

**Critical/Blocking Issues:** None. The codebase is in a good state for production use (v1.0 shipped 2026-07-12, 134 tests passing, analyze clean).

**Open Tech Debt (Should Fix):**
1. Icon generator test files need renaming + verification test pairing (WR-04/WR-05, medium priority).
2. Unclosed FileInputStream in Gradle config (low priority, easy fix).
3. No LICENSE file for Play Store publication (medium priority, must add before submission).
4. Placeholder running screen dead code cleanup (low priority, nice-to-have).

**Accepted Debt (Document & Monitor):**
1. Debug-signed release build fallback (mitigated by human pre-upload verification).
2. TimerLifecycleBinder observer never detached (acceptable for current monolithic architecture).
3. Silent preference load/persistence errors (intentional defense-in-depth).

**Post-v1.0 Discovery:**
1. Tablet layout bug fixed (responsive max-content-width pattern established).
2. Colorblind audit deferred to v2 (A11Y-01 open action).
3. Play Store submission requires manual Families Policy re-verification (process, not code).

---

*Concerns audit: 2026-08-19*
