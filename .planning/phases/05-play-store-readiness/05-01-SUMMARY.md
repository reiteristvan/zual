---
phase: 05-play-store-readiness
plan: 01
subsystem: infra
tags: [android, gradle-kotlin-dsl, app-signing, applicationId, play-store]

# Dependency graph
requires: []
provides:
  - "Real applicationId com.ireiter.zual (replacing com.example.zual placeholder)"
  - "Production release signingConfig reading android/key.properties, with a debug-signing fallback when no keystore is present"
  - "Verified upload-signed release .aab (flutter build appbundle --release)"
affects: ["05-03 (store listing/submission, depends on a publishable signed build existing)", "05-04", "05-05"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gradle Kotlin DSL production signing: key.properties loaded via rootProject.file + guarded Properties() load before the android {} block; signingConfigs.create(\"release\") reads keyAlias/keyPassword/storeFile/storePassword; buildTypes.release picks signingConfigs.getByName(\"release\") only when key.properties exists, else falls back to debug — keeps `flutter run --release`/debug builds working with no keystore present"
    - "storeFile path resolution inside a Gradle Kotlin DSL module script must use rootProject.file(...), not the bare file(...) helper, when the referenced file lives at the Gradle root (android/) rather than inside the current module directory (android/app/) — file(...) resolves relative to the enclosing project's own directory"

key-files:
  created: []
  modified:
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml
    - pubspec.yaml

key-decisions:
  - "namespace left as com.example.zual (unchanged) while applicationId became com.ireiter.zual, per 05-RESEARCH.md Pitfall 1 — namespace only controls generated R/BuildConfig location and the existing MainActivity.kt package dir; divergence from applicationId is fully supported and lower-risk than moving MainActivity.kt"
  - "Android launcher label set to short form 'Zual' (not the full Play Store display name 'Zual — Visual Timer for Kids' from D-06) — the em-dash/long form gets trimmed on home screens; the full display name belongs in the Play Console listing (05-03), not AndroidManifest.xml"
  - "pubspec.yaml version kept at 1.0.0+1 as an intentional first-upload baseline rather than bumped, per 05-RESEARCH.md Pitfall 3"
  - "storeFile resolution fixed to rootProject.file(...) instead of file(...) after Task 3's first build attempt failed validateSigningRelease — keeps the keystore at android/upload-keystore.jks (where the Task 2 checkpoint instructed the developer to create it) resolvable from the :app module's build.gradle.kts"

patterns-established:
  - "Any future signingConfigs/key.properties-adjacent Gradle Kotlin DSL edits must resolve file paths via rootProject.file(...) when the referenced file sits at the android/ root, not inside android/app/"

requirements-completed: [PUBLISH-01]

coverage:
  - id: D1
    description: "applicationId is the real com.ireiter.zual identity, not the com.example.zual scaffold placeholder"
    requirement: "PUBLISH-01"
    verification:
      - kind: other
        ref: "grep 'applicationId = \"com.ireiter.zual\"' android/app/build.gradle.kts"
        status: pass
    human_judgment: false
  - id: D2
    description: "Release buildType signs with a production upload-key signingConfig backed by key.properties, falling back to debug signing only when no keystore is present"
    requirement: "PUBLISH-01"
    verification:
      - kind: other
        ref: "flutter build apk --debug (Task 1, no keystore present, guard fallback path)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A real release .aab builds successfully and is signed with the developer's upload certificate, not the Android debug key"
    requirement: "PUBLISH-01"
    verification:
      - kind: other
        ref: "flutter build appbundle --release && keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab"
        status: pass
    human_judgment: false
  - id: D4
    description: "Upload keystore and key.properties exist locally, developer-generated, and are confirmed untracked by git"
    requirement: "PUBLISH-01"
    verification: []
    human_judgment: true
    rationale: "Credential generation and gitignore confirmation is a developer action verified via a human-action checkpoint (Task 2), not an automatable test — already confirmed 'approved' by the user and re-verified by the orchestrator before this continuation began."

# Metrics
duration: ~25min (Task 3 continuation session; Tasks 1-2 completed in prior sessions)
completed: 2026-07-10
status: complete
---

# Phase 05 Plan 01: Real Android identity and production signing Summary

**applicationId com.ireiter.zual with a key.properties-backed release signingConfig, verified against a real upload-signed .aab built via `flutter build appbundle --release`**

## Performance

- **Duration:** ~25 min for this continuation session (Task 3 only); Tasks 1-2 were completed and committed in a prior session
- **Started:** 2026-07-10T08:09:00Z (approx, per commit 47e9be3 timestamp for Task 1)
- **Completed:** 2026-07-10T08:34:26Z
- **Tasks:** 3 (all complete)
- **Files modified:** 4 (android/app/build.gradle.kts, android/app/src/main/AndroidManifest.xml, pubspec.yaml, plus this SUMMARY.md)

## Accomplishments
- Replaced the `com.example.zual` scaffold placeholder with the real, developer-account-scoped `com.ireiter.zual` applicationId (namespace intentionally left unchanged per Pitfall 1)
- Wired a production `release` signingConfig in `android/app/build.gradle.kts` that reads `android/key.properties`, with a graceful fallback to debug signing when no keystore exists — keeps local debug builds working
- Developer generated the upload keystore (`android/upload-keystore.jks`) and `android/key.properties` at the Task 2 human-action checkpoint; confirmed gitignored (`git status --porcelain` prints nothing for either file)
- Built a real release bundle with `flutter build appbundle --release` and verified via `keytool -printcert` that it carries the developer's upload certificate (`CN=Istvan, OU=Reiter, O=Reiter...`), not `CN=Android Debug, O=Android`
- Confirmed the build emits no Play target-API-level warning (targetSdk already inherited from Flutter's Gradle defaults, per Pitfall 4)
- Confirmed the full existing test suite (130 tests) stays green — this plan touched only Android build config and manifest/pubspec metadata, no Dart app logic

## Task Commits

1. **Task 1: Real applicationId, display label, version, and release signing config** - `47e9be3` (feat)
2. **Task 2: Developer generates the upload keystore + key.properties** - human-action checkpoint, no commit (secrets never tracked; verified gitignored)
3. **Task 3: Verify the signed release bundle carries the upload certificate** - `6dba2f1` (fix — storeFile path resolution bug found during this task; see Deviations)

**Plan metadata:** (this commit, following SUMMARY.md write)

## Files Created/Modified
- `android/app/build.gradle.kts` - applicationId, signingConfigs.release block, guarded key.properties load, conditional release signingConfig selection, storeFile path fix
- `android/app/src/main/AndroidManifest.xml` - android:label="Zual"
- `pubspec.yaml` - real description, version held at 1.0.0+1
- `android/key.properties` - developer-created, gitignored (not committed; verified untracked)
- `android/upload-keystore.jks` - developer-created, gitignored (not committed; verified untracked)

## Decisions Made
- namespace left as `com.example.zual` while applicationId became `com.ireiter.zual` (Pitfall 1 — lower risk than moving MainActivity.kt's package dir)
- Launcher label kept short (`Zual`) vs. the full D-06 Play Store display name, which belongs in the Play Console listing produced by plan 05-03
- pubspec.yaml version held at `1.0.0+1` as the intentional first-upload baseline
- storeFile resolution switched from `file(it)` to `rootProject.file(it)` after Task 3 surfaced a real build failure (see Deviations)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] storeFile path resolved against the wrong Gradle project directory**
- **Found during:** Task 3 (first `flutter build appbundle --release` attempt)
- **Issue:** `android/app/build.gradle.kts`'s `signingConfigs.release` used `storeFile = keystoreProperties["storeFile"]?.let { file(it) }`. Inside a Gradle Kotlin DSL module script, the bare `file(...)` helper resolves relative paths against that module's own directory (`android/app/`), not the Gradle root (`android/`) where `key.properties` itself is resolved via `rootProject.file(...)`. The Task 2 checkpoint instructed the developer to generate `upload-keystore.jks` from the `android/` directory, so the actual file lives at `android/upload-keystore.jks` — one level above where `file("upload-keystore.jks")` looked. Build failed at `:app:validateSigningRelease` with `Keystore file 'D:\Projects\zual\android\app\upload-keystore.jks' not found for signing config 'release'.`
- **Fix:** Changed the `storeFile` assignment to `rootProject.file(it)`, matching the resolution already used for `key.properties` itself, so both files resolve consistently against the Gradle root directory where the checkpoint told the developer to place them.
- **Files modified:** android/app/build.gradle.kts
- **Verification:** Re-ran `flutter build appbundle --release` — exited 0, produced `build/app/outputs/bundle/release/app-release.aab` (44.2MB); `keytool -printcert` confirmed the certificate owner is the developer's upload key (`CN=Istvan, OU=Reiter, O=Reiter, L=Szerencs, ST=Borsod, C=HU`), not `CN=Android Debug, O=Android`.
- **Committed in:** `6dba2f1` (separate fix commit, since Task 1's commit `47e9be3` already landed before this bug was discovered)

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** The fix was necessary for Task 3's acceptance criteria (a buildable, upload-signed release bundle) to be met at all. No scope creep — the change is a single-line path-resolution correction, no architectural change, and did not touch the gitignored secrets files.

## Issues Encountered
- First `flutter build appbundle --release` attempt failed at `:app:validateSigningRelease` due to the storeFile path bug above. Root-caused, fixed, and re-verified successfully on the second attempt (see Deviations). No other issues.

## User Setup Required
None for this continuation — the required external step (Task 2's upload keystore generation) was already completed and approved by the developer before this session began.

## Next Phase Readiness
- A real, upload-signed `.aab` can now be produced with `flutter build appbundle --release` — the blocking prerequisite for 05-03 (store listing/submission) and any future Play Console upload.
- No signing credentials are tracked by git (`android/key.properties`, `android/upload-keystore.jks` both confirmed untracked).
- Play App Signing enrollment and the actual Play Console upload remain human/Console-side steps for a later submission session — explicitly out of scope for this plan per Task 3's action notes.

---
*Phase: 05-play-store-readiness*
*Completed: 2026-07-10*

## Self-Check: PASSED

- FOUND: android/app/build.gradle.kts
- FOUND: commit 47e9be3 (Task 1)
- FOUND: commit 6dba2f1 (Task 3 fix)
- FOUND: build/app/outputs/bundle/release/app-release.aab
