---
phase: 05-play-store-readiness
verified: 2026-07-10T13:12:33Z
status: human_needed
score: 4/4 roadmap truths verified (2 items flagged for human re-confirmation)
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Visually confirm the corrected adaptive launcher icon (adaptive_icon_foreground_inset: 0, sun disc at its intended ~64% diameter) on a real device launcher, under both circle and squircle icon masks."
    expected: "The sun disc reads as a clearly legible, appropriately-sized shape at 48dp — not the shrunken ~43%-diameter version that WR-01 identified and that the developer's original 05-05 on-device checkpoint approval was based on."
    why_human: "The 05-05 on-device checkpoint (Samsung A25) that confirmed 'the real icon appears' was performed BEFORE code review found WR-01 (double safe-zone inset shrinking the visible sun disc from ~64% to ~43% diameter). The WR-01 fix (quick task 260710-keg) was verified only by config/XML grep + `flutter build apk --debug`, not by a fresh on-device visual look. No human has yet looked at the corrected icon on a real launcher."
  - test: "Review the 5 committed screenshots (screenshots/*.png) for final Play Store listing suitability — confirm each is full-bleed with no unwanted device-frame graphic, and is representative of its scene."
    expected: "Each PNG shows only the raw captured app screen (OS status bar + gesture-nav indicator are expected/normal for a full-bleed capture, not a 'device frame' in the marketing-mockup sense) with no added caption text, and clearly represents its named scene at a good progress point."
    why_human: "Visual representativeness and 'full-bleed, no frame' compliance is inherently a judgment call (both 05-04-SUMMARY and 05-05-SUMMARY explicitly flag their icon/screenshot deliverables as `human_judgment: true`). This verifier's own visual inspection of shrinking_disc.png and night_to_sunrise.png did not find an added marketing frame (the rounded corners/status bar/home-indicator are the raw device screen, consistent with `adb screencap`), but a final human pass before Play Console upload is still warranted."
---

# Phase 5: Play Store Readiness Verification Report

**Phase Goal:** The app is a publishable Android build with real identity, production signing, and store listing assets reviewed against Families Policy considerations.
**Verified:** 2026-07-10T13:12:33Z
**Status:** human_needed
**Re-verification:** No — initial verification

**Process note:** ROADMAP.md marks this phase `Mode: mvp`, but the phase Goal is written in the standard "what must be true" form, not the `As a ___, I want to ___, so that ___.` User Story format (confirmed via `user-story.validate` → `valid: false`). All five plans in this phase share the same non-User-Story goal convention, so this is a pre-existing roadmap-authoring pattern for the whole project, not specific to this phase. Rather than refusing to verify, this report proceeds with the standard goal-backward methodology against the roadmap's own Success Criteria (which is what the phase was actually planned, executed, and reviewed against).

## Goal Achievement

### Observable Truths

| # | Truth (Roadmap Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | The app has a real `applicationId` and a production signing config (no debug/placeholder). | VERIFIED | `android/app/build.gradle.kts`: `applicationId = "com.ireiter.zual"` (not `com.example.zual`); `signingConfigs.create("release")` reads `key.properties` via `rootProject.file(...)`; `buildTypes.release.signingConfig` uses it whenever `key.properties` exists. Built `build/app/outputs/bundle/release/app-release.aab` and ran `keytool -printcert -jarfile ...` live during this verification: `Owner: CN=Istvan, OU=Reiter, O=Reiter, L=Szerencs, ST=Borsod, C=HU` — a real upload certificate, NOT `CN=Android Debug, O=Android`. `android/key.properties` and `android/upload-keystore.jks` exist on disk but `git status --porcelain` and `git ls-files` both confirm they are untracked. |
| 2 | Play Store listing assets (app icon, screenshots) are prepared. | VERIFIED | Adaptive icon: `assets/icon/icon_foreground.png` + `icon_background.png` (generated, checked into git), `pubspec.yaml` `flutter_launcher_icons:` config (PNG-path gradient background, `adaptive_icon_foreground_inset: 0` after WR-01 fix), `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` confirmed on disk with `android:inset="0%"` (not the buggy `16%`). Hi-res store icon `store_assets/icon_512.png` exists (104KB, flattened composite). Screenshots: `screenshots/` contains `shrinking_disc.png`, `night_to_sunrise.png`, `walking_home.png`, `car_on_a_road.png` (one per required scene) plus a bonus `setup_screen.png`. Ran `flutter test test/tool/generate_launcher_icon_test.dart test/tool/generate_store_icon_test.dart` live — all 3 tests pass. |
| 3 | A content-rating / target-audience declaration is completed and reviewed against Families Policy considerations. | VERIFIED | `.planning/phases/05-play-store-readiness/05-STORE-LISTING.md` exists and contains: exact display name "Zual — Visual Timer for Kids"; target-audience declaration ("general audience that also appeals to children," explicitly NOT "Designed for Families") with rationale; an IARC content-rating answer table pointing entirely to the Everyone/lowest tier; the privacy-policy URL; short + full store descriptions. Privacy policy `docs/index.html` (read in full) truthfully states no accounts, no data collection, no ads, offline operation, a children's-privacy section, and a contact email. Ran `curl -sI https://reiteristvan.github.io/zual/` live — `HTTP/1.1 200 OK`, confirming the privacy policy is live and reachable, backing the declaration. STATE.md's "must re-verify at submission" note is consistent with the phase's own scope (a *prepared, reviewed* draft — not a Play-Console-submitted final declaration — matching the roadmap wording "completed and reviewed," not "submitted and confirmed by Google"). |
| 4 | A release build installs and runs a full countdown on a real Android device. | VERIFIED | `05-05-SUMMARY.md` records a `checkpoint:human-verify` gate (Task 1) that the developer approved after installing the signed release build on a physical Samsung A25, confirming the real adaptive icon and a full countdown to the "All done" finished state with no crash. This is not a bare narrative claim: during that exact on-device session the developer discovered a real, device-specific Setup-screen layout overflow bug (fixed as quick task `260710-frr`, commits `a95f594`/`888796a`, git history confirmed present), which strongly corroborates genuine hands-on real-device testing rather than a fabricated checkpoint — a scripted/staged claim would not plausibly surface an A25-specific ~1cm viewport overflow. The developer re-verified on the physical device after the fix before proceeding. |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified). 2 additional items flagged below for human re-confirmation before Play Console submission (see Human Verification Required) — these do not fail any of the 4 truths above but do affect final launch readiness.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `android/app/build.gradle.kts` | Real applicationId + release signingConfig | VERIFIED | Read live: `applicationId = "com.ireiter.zual"`, guarded `key.properties` load, `signingConfigs.create("release")`, conditional release signing. Namespace intentionally left as `com.example.zual` (documented, low-risk per RESEARCH Pitfall 1). |
| `android/app/src/main/AndroidManifest.xml` | Real launcher label | VERIFIED | `android:label="Zual"` confirmed. |
| `pubspec.yaml` | Real description/version + icon config | VERIFIED | Description no longer scaffold default; `flutter_launcher_icons:` block present with corrected `adaptive_icon_foreground_inset: 0`. |
| `android/key.properties`, `android/upload-keystore.jks` | Developer-created, gitignored | VERIFIED | Exist on disk (`ls android/`), confirmed untracked (`git status --porcelain` empty, `git ls-files | grep` empty). |
| `docs/index.html` | Static privacy policy page | VERIFIED | Exists, truthful content confirmed by direct read; live at `https://reiteristvan.github.io/zual/` (curl 200 OK, checked live). |
| `.planning/phases/05-play-store-readiness/05-STORE-LISTING.md` | Play Console answer sheet | VERIFIED | Exists with all required fields (display name, target audience, IARC answers, privacy URL, descriptions). |
| `test/tool/icon_renderer.dart` | Reusable headless PNG render helper | VERIFIED | Exists, painter-agnostic, exercised by passing tests. |
| `test/tool/icon_painters.dart` | Icon foreground/background painters | VERIFIED | `IconBackgroundPainter` (gradient), `IconForegroundPainter` (padded sun disc) present. |
| `assets/icon/icon_foreground.png`, `icon_background.png` | Generated 1024x1024 icon sources | VERIFIED | Both exist (326KB / 19.7KB), committed. |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon descriptor | VERIFIED | Exists, `android:inset="0%"` (post-WR-01-fix), references foreground/background drawables. |
| `store_assets/icon_512.png` | Hi-res Play Console store icon | VERIFIED | Exists (104KB), additive asset from quick task 260710-keg — not required by any plan's must_haves but satisfies the Play Console "Hi-res icon" upload field. |
| `screenshots/*.png` | 4 full-bleed per-scene screenshots | VERIFIED | 4 required scenes present + 1 bonus (`setup_screen.png`). Visual full-bleed/no-frame quality flagged for human re-confirmation (see Human Verification). |
| `build/app/outputs/bundle/release/app-release.aab` | Signed release bundle | VERIFIED | Exists (46.3MB), signing certificate confirmed live via `keytool` during this verification. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `build.gradle.kts` release buildType | `signingConfigs.getByName("release")` | conditional on `key.properties.exists()` | WIRED | Source-confirmed; live build produced a real-certificate `.aab`. |
| `signingConfigs.release` | `key.properties` / `upload-keystore.jks` | `rootProject.file(...)` | WIRED | Path-resolution bug (originally `file(...)`) was found and fixed during 05-01 execution; current code uses `rootProject.file`, confirmed correct by a live successful build + keytool check. |
| `pubspec.yaml` `flutter_launcher_icons` config | `assets/icon/*.png` → `android/.../mipmap-anydpi-v26/ic_launcher.xml` + legacy mipmaps | `dart run flutter_launcher_icons` | WIRED | Config PNG paths confirmed to exist; generated XML confirmed to reference the foreground/background drawables with the corrected 0% inset. |
| `docs/index.html` | GitHub Pages | branch `main`, folder `/docs` | WIRED | `curl -sI https://reiteristvan.github.io/zual/` → `200 OK` (checked live in this verification). |
| `05-STORE-LISTING.md` privacy URL | `docs/index.html` content | URL reference | WIRED | URL in the answer sheet matches the live Pages URL and the served content. |
| Signed `.aab`/`.apk` + adaptive icon | Real device install + launcher | on-device checkpoint | WIRED (human-confirmed) | 05-05-SUMMARY.md records developer approval on a physical Samsung A25; corroborated by an interleaved device-specific bug discovery/fix. |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| PUBLISH-01 | 05-01, 05-05 | Real applicationId + production signing config | SATISFIED | Verified applicationId, signing config, signed .aab certificate, and on-device install/countdown proof. |
| PUBLISH-02 | 05-02, 05-03, 05-04, 05-05 | Store listing assets (icon, screenshots), content-rating/target-audience declaration reviewed against Families Policy | SATISFIED | Verified privacy policy, store listing answer sheet, generated adaptive icon (with WR-01 fix applied), 4+1 screenshots. |

REQUIREMENTS.md cross-check: both PUBLISH-01 and PUBLISH-02 are listed under "Play Store Readiness" (checked `[x]`) and appear in the Traceability table mapped to "Phase 5 / Complete." No orphaned Phase-5 requirement IDs exist in REQUIREMENTS.md beyond these two. Coverage summary states 22/22 v1 requirements mapped, 0 unmapped.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `test/tool/generate_launcher_icon_test.dart` | 49-80 | A `*_test.dart` file unconditionally overwrites tracked, committed binary assets (`assets/icon/*.png`) every time `flutter test` runs, asserting only generic PNG-validity, not a content diff against the committed bytes | Warning (carried over from 05-REVIEW.md WR-02, still unresolved) | Currently a no-op (rendering is deterministic today) but a future Skia/Impeller engine change could silently rewrite the shipped icon with no test failure to catch it |
| `test/tool/icon_renderer.dart` | 21-29 | `ui.Image` from `picture.toImage(...)` is never `.dispose()`d | Info (carried over from 05-REVIEW.md IN-02, still unresolved) | Low real-world impact (dev/test-only script), but a native-memory correctness gap |
| `android/app/build.gradle.kts` | 11-15 | `FileInputStream(keystorePropertiesFile)` opened via `keystoreProperties.load(...)` is never closed | Warning (carried over from 05-REVIEW.md WR-03, still unresolved) | Small resource leak, runs once per Gradle configuration pass |
| `android/app/build.gradle.kts` | 58-69 | Release build type silently falls back to debug signing with no build-time gate/warning when `key.properties` is absent | Warning (carried over from 05-REVIEW.md WR-04, still unresolved) | Could allow an accidental debug-signed release build to be produced for upload with no warning |

None of the above are debt markers (`TBD`/`FIXME`/`XXX`) — a direct grep across all phase-modified files found zero matches. These are Warning/Info-tier code-quality findings already surfaced by `05-REVIEW.md` (only WR-01 was fixed via quick task `260710-keg`; WR-02 through WR-06 remain open). None of them block the phase's goal — the app is genuinely real-identity, production-signed, and has reviewed listing assets — but they represent legitimate follow-up hardening work.

### Human Verification Required

### 1. Re-confirm the corrected adaptive icon on a real device launcher

**Test:** Install the current signed release build (post `260710-keg` fix) on a real Android device and look at the launcher icon under both circle and squircle masks.
**Expected:** The sun disc reads as a clearly legible, appropriately-sized shape at 48dp (the intended ~64% diameter), not the shrunken ~43%-diameter rendering that `05-REVIEW.md` WR-01 identified.
**Why human:** The only on-device visual confirmation on record (`05-05-SUMMARY.md` Task 1, Samsung A25) happened *before* code review discovered the double safe-zone inset bug. The fix (`adaptive_icon_foreground_inset: 0`) was verified only by XML/config inspection and a debug build — not by a fresh human look at the corrected icon on a real launcher.

### 2. Final screenshot quality pass before Play Console upload

**Test:** Open each of the 5 committed screenshots (`screenshots/*.png`) and confirm they are full-bleed (no added marketing device-frame graphic — the OS status bar and gesture-nav indicator visible in the raw capture are expected and normal), free of any caption overlay, and representative of their named scene.
**Expected:** All 5 images read as clean, representative, full-bleed captures suitable for a Play Store listing.
**Why human:** Both `05-04-SUMMARY.md` and `05-05-SUMMARY.md` explicitly flag icon/screenshot visual correctness as `human_judgment: true`. This verifier visually inspected `shrinking_disc.png` and `night_to_sunrise.png` directly and found no added marketing frame (the rounded corners are the device's own rendered corners, consistent with a raw `adb screencap`), but a full human pass across all 5 images before actual Play Console upload is still warranted.

### Gaps Summary

No blocking gaps were found. All 4 roadmap Success Criteria are backed by concrete, live-checked evidence (real signing certificate inspected via `keytool`, live privacy-policy URL checked via `curl`, generated icon/screenshot assets confirmed on disk, both PUBLISH requirements cross-referenced against REQUIREMENTS.md with no orphans). The phase's own code review (`05-REVIEW.md`) already found and the team already fixed the one functionally-significant issue (WR-01, icon double safe-zone inset) via quick task `260710-keg`; the remaining code-review items (WR-02 through WR-06) are minor hardening suggestions, not gaps against the phase goal.

The two items above are routed to human verification rather than reported as gaps because: (a) the underlying artifacts genuinely exist, are substantive, and are wired correctly — this is not a "stub" or "missing" situation — and (b) the specific question left open (does the *corrected* icon look right at 48dp; do the final screenshots read as clean and representative) is inherently a visual judgment call that no grep/build check can resolve, and one of the two (the icon re-check) has a concrete, traceable reason no human has looked at the post-fix result yet.

---

_Verified: 2026-07-10T13:12:33Z_
_Verifier: Claude (gsd-verifier)_
