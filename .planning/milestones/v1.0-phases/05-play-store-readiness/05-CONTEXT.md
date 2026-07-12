# Phase 5: Play Store Readiness - Context

**Gathered:** 2026-07-09
**Status:** Ready for planning

<domain>
## Phase Boundary

The app becomes a publishable Android build: a real `applicationId` and display name
replace the placeholder scaffold values, a production signing config replaces debug
signing, a designed launcher icon replaces Flutter's default icon, Play Store listing
assets (screenshots + description) are prepared, and a target-audience/content-rating
declaration is completed and reviewed against Google Play's Families Policy. Requirements:
PUBLISH-01, PUBLISH-02.

This phase is about publish *infrastructure*, not new app capability — no new scenes,
screens, or timer behavior. A release build must install and run a full countdown on a
real Android device as the final proof this phase is done.

Out of this phase's scope: any in-app feature work (Phases 1-4, done), iOS/Web platform
support (deferred to v2), actual Play Console account setup / submission click-through
(the assets and declarations are prepared here; the human still submits).

</domain>

<decisions>
## Implementation Decisions

### App icon & visual identity
- **D-01:** The launcher icon motif is based on the **Night to Sunrise** scene (sky
  gradient night→day, sun/moon) — not the Shrinking Disc, not an abstract new mark, and
  not Walking Home or Car on a Road.
- **D-02:** Icon background is a **scene-matched gradient** pulled from Night to Sunrise's
  own sky palette — not the app's flat warm-cream UI background token.
- **D-03:** The adaptive-icon foreground stays **big and simple** — one dominant shape,
  generous padding, silhouette-level detail rather than full scene fidelity — so it
  survives circle/squircle masking and stays legible at small launcher sizes (48dp).
- **D-04:** Claude **generates the icon programmatically in Flutter/Dart**, reusing/adapting
  the existing Night to Sunrise painter code to render PNGs at all required launcher
  sizes — no external design tool, no hand-off asset file. Keeps the "no bitmap assets,
  everything vector until export" pattern intact.

### App identity — package ID & display name
- **D-05:** `applicationId` = **`com.ireiter.zual`**, replacing the placeholder
  `com.example.zual` in `android/app/build.gradle.kts`. This is permanent once published
  to Play Console — must be correct before first upload.
- **D-06:** Play Store display name = **"Zual — Visual Timer for Kids"**.

### Target audience & content rating declaration
- **D-07:** Declared target audience is **general audience that also appeals to
  children** — not the "Designed for Families" track. The app is parent-operated (parent
  sets duration/theme; child only watches) with zero ads, accounts, or data collection, so
  the lighter review track is appropriate and avoids the strictest COPPA-style
  restrictions that "Designed for Families" imposes.
- **D-08:** Content rating questionnaire is answered aiming for the **lowest tier**
  (Everyone / ESRB Everyone / PEGI 3 equivalent) — no violence, text, user-generated
  content, ads, or interactions beyond watching.
- **D-09:** A **privacy policy is required** for Play Console submission (Families Policy
  + general Play Store requirement) even though Zual collects nothing. Claude **drafts a
  short static policy page** stating the app has no accounts, no data collection, no ads,
  and works fully offline.
- **D-10:** The drafted privacy policy is **hosted via GitHub Pages from this repo**,
  giving a stable public URL to enter into the Play Console listing form.

### Store listing assets
- **D-11:** Screenshots feature **all 4 scenes, one each** (Shrinking Disc, Night to
  Sunrise, Walking Home, Car on a Road) — shows the full visual variety rather than a
  curated subset.
- **D-12:** Screenshots are **captured live from a real device/emulator** running each
  scene at a representative progress point — not staged/mocked via a dedicated
  screenshot-harness screen.
- **D-13:** Screenshots are **plain full-bleed captures** — no phone device frame, no
  caption/text overlay.
- **D-14:** Store description tone is **short and parent-practical** — leads with the
  concrete problem solved ("helps a child understand how much longer they have to wait,
  without numbers or clocks"), directly matching PROJECT.md's Core Value framing.

### Claude's Discretion
- Exact PNG export sizes and adaptive-icon XML wiring (`mipmap-anydpi-v26`,
  foreground/background layer split) — standard Android tooling mechanics.
- Exact progress point captured per scene for screenshots (e.g., ~40% elapsed) — pick
  whichever point best represents each scene's visual character.
- Exact wording of the short/full store description beyond the "parent-practical" tone
  lock (D-14).
- Production keystore generation/storage mechanics (PUBLISH-01) — standard Flutter/Android
  release-signing practice; not discussed as a gray area since it's pure technical
  execution, not a vision question. `android/.gitignore` and root `.gitignore` already
  exclude `key.properties` and `*.keystore`, so a real keystore can be added without risk
  of accidental commit.
- Whether to use Play App Signing (Google-managed) or a locally-held upload key — follows
  Google's recommended default (Play App Signing) unless research surfaces a reason not
  to.
- `pubspec.yaml`'s `description:` field (currently the placeholder "A new Flutter
  project.") and `version:` (currently `1.0.0+1`) — likely need updating alongside the
  applicationId change; exact wording/version scheme is Claude's call unless it conflicts
  with a locked decision above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and requirements
- `.planning/PROJECT.md` — full project context, core value, constraints
- `.planning/REQUIREMENTS.md` — PUBLISH-01, PUBLISH-02 (this phase's requirements)
- `.planning/ROADMAP.md` Phase 5 section — goal and success criteria (real
  applicationId/signing, listing assets, content-rating declaration, release build runs on
  a real device)
- `.planning/STATE.md` Blockers/Concerns — "Play Store Families Policy and
  target-audience declaration must be re-verified in Play Console at submission time
  (policy wording changes)" — the audience/rating decisions above (D-07, D-08) are this
  phase's best-effort answer, but the human must re-check current Play Console wording at
  actual submission time.

### Existing codebase state (what this phase replaces or reuses)
- `android/app/build.gradle.kts` — current placeholder `applicationId =
  "com.example.zual"` (line 24) and `namespace = "com.example.zual"` (line 9), plus
  `signingConfig = signingConfigs.getByName("debug")` in the `release` build type (line
  37) — both replaced by D-05 and a production signing config.
- `android/app/src/main/res/mipmap-*/ic_launcher.png` — current default Flutter launcher
  icons (hdpi/mdpi/xhdpi/xxhdpi/xxxhdpi) that D-01 through D-04 replace.
- `android/.gitignore` (lines 10-13) and root `.gitignore` (line 65) — already exclude
  `key.properties` and `**/*.keystore`; no keystore exists yet in the repo.
- `lib/scenes/sunrise/sunrise_painter.dart` and `lib/scenes/sunrise/sunrise_scene.dart` —
  the Night to Sunrise painter D-04 reuses/adapts to generate the launcher icon.
- `lib/scenes/scene_renderer.dart`, `lib/scenes/scene_registry.dart` — shared scene
  rendering contract; relevant if icon generation needs to invoke the painter outside its
  normal `Ticker`-driven runtime context.
- `pubspec.yaml` — `name: zual` (line 1), `description: "A new Flutter project."` (line
  2, placeholder), `version: 1.0.0+1` (line 19) — description/version updates are Claude's
  discretion (see above).
- No `flutter_launcher_icons` package or existing icon-generation tooling present in
  `pubspec.yaml` — this phase's planner/researcher choose the concrete mechanism for
  turning D-04's painter-generated PNGs into the full Android adaptive-icon asset set.
- No existing privacy-policy file or GitHub Pages configuration in the repo — both are new
  for this phase (D-09, D-10).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SunrisePainter` / `SunriseScene` (`lib/scenes/sunrise/`) — the existing Night to
  Sunrise scene rendering code is the direct source for the launcher icon's visual
  content (D-01, D-04), likely invoked at a fixed progress value rather than animated.
- `AppTokens` (`lib/theme/app_tokens.dart`) — existing design-token constants; useful if
  the icon's gradient needs to reference exact Night to Sunrise palette values already
  defined there rather than re-deriving colors.

### Established Patterns
- Every scene painter is "a pure function of `TimerController.progress` plus a decorative
  loop phase" (established Phase 3/4 pattern, `03-CONTEXT.md`/`04-CONTEXT.md`) — icon
  generation can likely call the painter directly with a fixed `progress` value and
  `loopPhase = 0`, without needing a live `TimerController` or `Ticker`.
- `shared_preferences`-based persistence pattern (Phase 2 `SetupPreferences`, Phase 4 mute
  toggle) — not directly relevant to this phase, but confirms the app has no other
  existing settings/config file this phase's changes need to coordinate with.

### Integration Points
- `android/app/build.gradle.kts` is the single integration point for applicationId,
  namespace, and signing config changes (D-05, keystore discretion item).
- `android/app/src/main/res/mipmap-*/` (plus a new `mipmap-anydpi-v26/` for adaptive icon
  XML) is the integration point for the generated launcher icon.
- Store listing assets (screenshots, description, privacy policy) are **not** wired into
  the Flutter codebase at all — they're external deliverables (image files + text +
  hosted page) prepared alongside the app, not integrated into app source beyond
  `pubspec.yaml` metadata.

</code_context>

<specifics>
## Specific Ideas

- Icon: Night to Sunrise motif, scene-matched gradient background, big/simple adaptive
  foreground, generated in Dart from the existing `SunrisePainter`.
- Package identity: `com.ireiter.zual`, display name "Zual — Visual Timer for Kids".
- Audience: general audience that also appeals to children (not Designed for Families),
  Everyone-tier content rating, GitHub-Pages-hosted no-data-collection privacy policy.
- Screenshots: all 4 scenes, one each, real-device captures, plain full-bleed (no frame,
  no caption), short parent-practical description tone.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. Actual Play Console account creation and
final submission click-through are explicitly left to the human at execution time (this
phase prepares the assets/config, not the submission act itself).

</deferred>

---

*Phase: 5-Play Store Readiness*
*Context gathered: 2026-07-09*
