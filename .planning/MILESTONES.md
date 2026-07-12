# Milestones

## v1.0 MVP (Shipped: 2026-07-12)

**Phases completed:** 5 phases, 22 plans, 45 tasks

**Key accomplishments:**

- Wall-clock `TimerController extends ChangeNotifier` with an injected-clock progress engine, drift-free `setup → running → done` transitions, and monotonic progress proven by 6 deterministic unit tests.
- Completed the timer state machine — pausedAt-based pause/resume excluding paused time, wall-clock backgrounding reconciliation (including done-while-backgrounded), a ScreenWake abstraction paired to running-phase lifecycle via wakelock_plus, and a single TimerController wired into the app root through provider + a WidgetsBindingObserver lifecycle binder.
- Duration-preset Setup screen (1/5/10/15/30 min, 5-min default) wired to the existing TimerController, with a minimal placeholder running screen closing the Setup → running → Setup loop end-to-end.
- 2x2 scene-card grid (Shrinking disc, Night to sunrise, Walking home, Car on a road) on the Setup screen, each card rendering a static mini-preview through a shared `ScenePreviewPainter` abstraction, with single-select behavior and disc pre-selected by default.
- A reusable, leak-safe `HoldRepeatButton` (tap = one step, hold = accelerating repeat) plus a Custom duration path on the Setup screen: a sixth "Custom" grid cell reveals a stepper covering the full 1-120 minute range, with disabled edges and a range clamp enforced in state, not just visually.
- `SetupPreferences` wrapper around `shared_preferences` (^2.5.5) that clamps/validates on every read and only ever persists preset durations, wired into `main()`'s pre-`runApp` preload and `SetupScreen`'s Start handler so the last-used duration and scene theme are pre-selected before the first frame renders.
- Bundled offline Baloo 2 (700) + Quicksand (400/500/600/700) fonts extracted from the upstream variable fonts via fonttools, wired into every AppTokens text style, and applied the exact centered 52/24/8 header spacing plus a shared pressed-state widget (#FFF7E9 cards / #6E9A68 Start) across the Setup screen — the production-polish slice completing SETUP-05.
- SceneRenderer/SceneRendererState per-scene-ticker contract, scene_registry.dart, and a fully animated Shrinking Disc scene wired into a new RunningScreen that replaces PlaceholderRunningScreen as Start's destination.
- Progress-driven Night to Sunrise scene (gradient sky, 28 staggered twinkling stars, fading moon, rising glowing sun, warming hill silhouette) wired into scene_registry.dart, replacing the Plan 01 pending fallback.
- WalkPainter/WalkScene and CarPainter/CarScene, sharing one arrivalLeftFraction arrival formula, complete the four-scene set and make scene_registry.sceneFor exhaustive with no pending fallback left.
- Added an asymmetric spoke marking to CarPainter's wheel and a raster-diff regression test, closing the code-review CR-01 gap where the wheel-spin loop was a rotationally symmetric visual no-op.
- Pure-Dart two-tone (D5->G5) WAV chime synthesizer plus a plugin-free ChimePlayer interface backed by an audioplayers 6.8.1 adapter, mirroring the existing ScreenWake pattern.
- SetupPreferences gains a persisted soundOn bool (default true) with validate-on-every-read tamper defense, mirroring the existing durationMin/theme pattern
- Fixed the carried-forward Phase 3 defect (D-10) where `SceneRendererState`'s decorative loop phase snapped back to 0 on every Ticker stop/restart, by accumulating an offset across ticker segments.
- 850ms hidden long-press opens a blurred Parent Controls bottom sheet (Pause/Resume, End timer, Keep watching, mute), replacing the interim visible back button outright -- real-device blur smoothness confirmed smooth, no fallback needed.
- Done-edge chime trigger (edge-guarded, mute-gated, foreground-reveal-safe) plus a breathing "All done — tap when ready" pill replacing the old auto-pop, turning `TimerPhase.done` into a calm, dwelled-in finished state.
- applicationId com.ireiter.zual with a key.properties-backed release signingConfig, verified against a real upload-signed .aab built via `flutter build appbundle --release`
- PASSED: `dart:ui` PictureRecorder/Canvas/Picture.toImage rendering of the real SunrisePainter works headlessly inside `flutter test`, producing a valid PNG — plan 05-04 can proceed with the fully programmatic icon-generation approach (RESEARCH Assumption A1 confirmed, no live-device fallback needed).
- A truthful static privacy policy is live on GitHub Pages at https://reiteristvan.github.io/zual/, paired with a copy-paste-ready Play Console answer sheet covering display name, target-audience, IARC content rating, and store descriptions.
- Programmatically rendered a Night-to-Sunrise sunrise-gradient + sun-disc icon pair via `renderPainterToPng`, then wired `flutter_launcher_icons` to generate the full Android adaptive-icon asset set, replacing Flutter's default launcher icon.
- Signed release build confirmed installing and running a full countdown with the real adaptive icon on a physical Samsung A25, plus 4 required full-bleed per-scene screenshots (and 1 bonus Setup-screen asset) captured for the Play Console listing.

---
