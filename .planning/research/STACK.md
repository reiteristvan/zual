# Stack Research

**Domain:** Full-screen, wordless, animation-heavy children's app (Flutter, Android v1)
**Researched:** 2026-07-06
**Confidence:** HIGH (core SDK/rendering choices verified against local toolchain + official Flutter docs) / MEDIUM (package picks, Context7-sourced) / LOW (fast-moving ecosystem opinions, web-sourced — flagged inline)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter SDK | 3.38.7 (stable channel) | App framework | This is the SDK **actually installed and verified on the dev machine** (`flutter --version`) and matches the existing scaffold's `pubspec.yaml` constraint (`sdk: ^3.10.7`). Web search surfaced references to a later "3.44" stable, but that could not be corroborated against the real toolchain and Flutter's docs-site content is not reliably dated — trust the verified local version over the search result. Confidence: HIGH (verified locally) for the version-in-use; treat any claim of a newer stable as unverified until you run `flutter upgrade` and confirm. |
| Dart SDK | 3.10.7 (bundled with Flutter) | Language | Bundled with the Flutter SDK above; no separate install. |
| `CustomPainter` / `Canvas` (Flutter SDK, built-in) | — | Vector rendering of all 4 scenes (disc, sky/sun/moon, character, car, road, house) | This is the **direct Flutter analogue of Canvas/SVG drawing** used in the HTML prototype. No package needed — `Canvas` exposes `drawCircle`, `drawRRect`, `drawPath`, `drawShadow`, gradient `Shader`s (`LinearGradient`/`RadialGradient` via `Paint.shader`), all of which map cleanly onto the design's circles, rounded rects, gradients, and CSS-border triangles (draw as a `Path` with 3 points). Confidence: HIGH — official pattern, confirmed via Context7 (`docs.flutter.dev`). |
| `AnimationController` + `TickerProviderStateMixin` (Flutter SDK, built-in) | — | Progress-driven animation loop (0.0 → 1.0 over the countdown duration) | This is Flutter's built-in equivalent of the prototype's `requestAnimationFrame` loop — and the design doc explicitly recommends "a timed animation driver" over a manual per-frame loop. Set `AnimationController(duration: totalDuration, vsync: this)` and call `.forward()`; its `.value` (0→1) is the single source of truth fed into every theme's paint logic. It uses an internal `Ticker` synced to the engine's vsync/frame-scheduling, so it is already display-refresh-rate-aware (60fps and beyond on higher-refresh devices) without any extra plumbing. Confidence: HIGH. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `provider` | ^6.1.5 | Shared countdown/theme state exposed to the whole widget tree (Setup ↔ Running ↔ Completed, all 4 theme painters) | A single `ChangeNotifier` (e.g. `TimerController`) holding `phase`, `theme`, `durationMin`, `progress`, `paused` is exactly the shape `provider` is built for: no codegen, no build_runner, officially endorsed by Flutter's own state-management guidance as the low-ceremony starting point. Wrap the app in one `ChangeNotifierProvider<TimerController>` and consume with `context.watch`/`Consumer` in the Setup screen, the running-screen scaffold, and each theme's `CustomPainter` wrapper. Confidence: MEDIUM (Context7 + cross-checked against 2026 community writeups). |
| `audioplayers` | ^6.8.1 | Play the short two-tone completion chime | Recommended over `just_audio` for this use case: `just_audio` is built for streaming/playlists/gapless sequencing (heavier API surface, and one community benchmark found its audio quality worse than `audioplayers`'), whereas `audioplayers` is the simpler, actively-maintained choice for firing a single short local sound effect once — it's also what Flutter's own Flame game engine embeds for its audio plugin, i.e. it's the de facto "just play this sound" package in the ecosystem. Usage: `AudioPlayer().play(AssetSource('audio/chime.wav'))`. Confidence: MEDIUM (Context7 API docs) / LOW on the comparative "which is better" framing (web-sourced opinion) — but the decision doesn't hinge on latency here, since the chime plays once at a non-interactive moment, so the simpler package wins regardless. |
| `wakelock_plus` | ^1.6.1 | Keep the screen on for the entire running countdown | A child staring at a slowly-shrinking disc across a room must **not** have the screen dim/lock mid-countdown — this is a functional requirement, not a nicety. Call `WakelockPlus.enable()` on entering the running screen and `WakelockPlus.disable()` on leaving it (Setup/Completed). Confidence: MEDIUM (Context7). |
| `shared_preferences` | ^2.5.5 | Optional local persistence of last-used duration + theme | PROJECT.md explicitly allows "optionally remember last-used duration + theme locally" with no backend. `shared_preferences` is the standard, zero-config key-value store for exactly this; don't reach for anything heavier (Hive, Isar, sqflite) for two scalar values. Confidence: MEDIUM (Context7). |
| Font assets bundled directly via `pubspec.yaml` `fonts:` (no package) | — | Baloo 2 (700 weight, wordmark) + Quicksand (400/500/600/700, UI text) | Download the static `.ttf` files from Google Fonts once, place them under e.g. `assets/fonts/`, and declare them in the `flutter: fonts:` section of `pubspec.yaml`. This app is fully offline/local (no network calls anywhere per PROJECT.md constraints) — pulling in the `google_fonts` package (which defaults to HTTP-fetching font files at runtime, only falling back to bundled assets if you also ship the files as assets) adds a dependency and a "first-load may hit network" code path that buys nothing here. Skip it; declare the fonts directly. Confidence: MEDIUM — verified via Context7 that `google_fonts` supports asset-first bundling, which confirms direct `pubspec.yaml` font declaration (a strict subset of that same mechanism) is fully supported and simpler. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `flutter_lints` ^6.0.0 (already in scaffold) | Static analysis / lint rules | Keep as-is; no change needed. |
| `flutter_test` (SDK, already in scaffold) | Widget/unit tests | Use for state-machine unit tests (progress math, pause/resume elapsed-time accounting, color-zone lerp functions) and golden/widget tests per theme painter. |
| Android `minSdk` = `flutter.minSdkVersion` (currently effectively API 24 / Android 7.0 on this Flutter version) | Android platform floor | Recent Flutter stable releases raised the default floor from API 21 to 24; the scaffold already delegates to `flutter.minSdkVersion` in `android/app/build.gradle.kts` rather than hardcoding a number — leave it delegated so it tracks the SDK. Confidence: LOW on the exact API level (web-sourced, changes across Flutter releases) — verify with `flutter doctor`/Gradle sync at build time rather than hardcoding a number into planning docs. |

## Installation

```bash
# Core UI/state
flutter pub add provider

# Audio (completion chime)
flutter pub add audioplayers

# Keep screen awake during countdown
flutter pub add wakelock_plus

# Optional: remember last-used duration + theme
flutter pub add shared_preferences

# Dev dependencies — already present in scaffold, no action needed
# flutter_test, flutter_lints ^6.0.0
```

No `google_fonts` install — bundle Baloo 2 / Quicksand `.ttf` files under `assets/fonts/` and declare them in `pubspec.yaml`'s `flutter: fonts:` section instead (see Supporting Libraries above).

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `CustomPainter` + `AnimationController` (built-in) | `flame` game engine | Only if the app grows real game mechanics (collision, sprite batching, physics, an entity-component tree). Zual is 4 declarative scenes driven by one scalar `progress` value with no player interaction, collision, or entity management — Flame's game-loop/ECS machinery is pure overhead here. Revisit only if a future milestone adds interactive play. |
| `provider` | `riverpod` | If the app later grows async data sources (network, multiple independent feature modules needing compile-time-safe DI, heavy testing matrices), Riverpod's stronger type-safety and BuildContext-independence pay for their extra ceremony. For a single shared `ChangeNotifier` driving one small app, that ceremony isn't justified yet. |
| `provider` | `flutter_bloc` | If a larger team wants an enforced event→state pipeline for auditability/consistency across many contributors. Overkill for a single-developer small app with one state machine. |
| `audioplayers` | `just_audio` | If audio needs grow to background playback, streaming, gapless playlists, or precise queue/session management — none of which apply to a single one-shot local chime. |
| `audioplayers` | `flutter_soloud` | Only if sample-accurate, near-zero-latency audio triggering becomes a hard requirement (e.g., a rhythm game). The chime here plays once at a calm, non-interactive moment — audioplayers' latency profile is irrelevant. |
| Bundled `.ttf` fonts via `pubspec.yaml` | `google_fonts` package | If you want to experiment with many font families quickly during design iteration (fetching on demand) before settling on final fonts. Once fonts are finalized (they are — Baloo 2 + Quicksand, per design tokens), drop the package and bundle directly. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Manual per-frame `Timer.periodic` / hand-rolled "requestAnimationFrame" loop | Battery-inefficient, not vsync-synced, easy to drift out of sync with actual elapsed wall-clock time (which is exactly the class of bug the design doc warns about — "on native prefer a timed animation driver … for battery-friendly smoothness"). Reimplements what `AnimationController` already gives you for free. | `AnimationController(duration: totalMs, vsync: this)`, driven forward once on Start; pause via `.stop()`, resume via `.forward(from: controller.value)`. |
| Bitmap/image assets (PNG/SVG import) for the scenes | The design is explicit: "No image assets… all visuals built from shape primitives." Introducing raster or even `flutter_svg` assets would diverge from both the design intent and the "no image assets" constraint, and adds asset-scaling/DPI concerns for no benefit. | `CustomPainter` primitives: `drawCircle`, `drawRRect`, `drawPath` (triangles for roofs), `Paint()..shader = LinearGradient(...).createShader(rect)`. |
| `flutter_bloc` / `riverpod` with code generation (`build_runner`) as a default choice | Adds a build-time codegen step and cognitive overhead disproportionate to a single shared state object in a small app; slows iteration during a fast-moving UI-heavy build. | `provider` + a plain `ChangeNotifier`. |
| `google_fonts` package with default runtime HTTP fetching left enabled | The app has zero network dependency by design (PROJECT.md: "no backend; app is fully local"). Leaving the package on its default fetch-then-cache behavior means the first run on a fresh device could attempt a network call for fonts — inconsistent with an offline kids' app meant to run reliably on a kitchen counter / bedroom device that may have no Wi-Fi. | Bundle the `.ttf` files directly and declare them in `pubspec.yaml`. |
| Hardcoding `applicationId = "com.example.zual"` through to Play Store submission | Fine for scaffold/dev, but Play Store requires a real, permanent, unique application ID before publish — changing it later requires care (it's the app's permanent identity on the Store). Not a "stack" pick per se, but worth flagging now since Play Store publish-readiness is an explicit v1 requirement. | Decide and set the real `applicationId` (e.g. `com.<yourdomain>.zual`) early, ideally before the first Play Store internal-testing upload, not right before public release. |

## Stack Patterns by Variant

**If a theme's animation needs secondary *looping* motion independent of countdown progress** (e.g. the walking character's bob, the car's wheel spin, star twinkle, the "breathe" pill) — per the design doc these are all separate looping CSS keyframes, not driven by `progress`:
- Use a **second, independent `AnimationController`** with `..repeat()` (e.g. `bobController` at 620ms, `spinController` at 700ms linear, `breatheController` at 2.8s) alongside the primary progress controller.
- Because each theme only needs 1–2 of these loops, keep them scoped to that theme's widget/painter (`dispose()` them with the widget), not hoisted into the shared global state — they're presentation-only, not state-machine data.

**If you want paused/resumed timing to survive exactly as the design specifies** ("freeze progress; accumulate paused time so resume continues correctly"):
- Don't naively `AnimationController.stop()`/`forward()` across a long real-world pause and trust wall-clock re-derivation — instead keep the design's own model explicit in your controller class: track `totalMs`, `startTs`, `pausedTotal`, `pauseStart` as plain fields (exactly as spelled out in `design/README.md`'s State Management section) and derive `progress` from those on every tick, then feed that derived value into the `AnimationController`'s driven value (or bypass `AnimationController.forward()` entirely and instead drive an `Animation`/`ValueNotifier<double>` from a lightweight periodic ticker keyed off elapsed wall-clock time). This guarantees the countdown reflects real elapsed time even if the app is backgrounded/resumed, which pure `AnimationController.forward(duration:)` alone does not guarantee as robustly across process lifecycle events.

**If future milestones add iOS/Web** (explicitly out of scope for v1 per PROJECT.md):
- All picks above (`provider`, `audioplayers`, `wakelock_plus`, `shared_preferences`, `CustomPainter`) are already cross-platform (Android/iOS/Web/desktop), so no stack change is anticipated when those platforms are added later — this was a deliberate factor in each pick.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `provider ^6.1.5` | Flutter 3.38.7 / Dart 3.10.7 | No known constraint conflicts; `provider` has tracked stable Flutter releases without breaking changes for several years. |
| `audioplayers ^6.8.1` | Flutter 3.38.7 | Federated plugin (`audioplayers_android`, `audioplayers_darwin`, etc. resolved automatically) — Android-only v1 scope means only `audioplayers_android` needs to resolve, simplest possible surface. |
| `wakelock_plus ^1.6.1` | Flutter 3.38.7 | Federated plugin, Android/iOS/Web/desktop; no special Android setup beyond adding the dependency. |
| `shared_preferences ^2.5.5` | Flutter 3.38.7 | Uses newer `SharedPreferencesAsync` API surface on recent versions — fine for this app's tiny read/write footprint. |
| Existing scaffold `pubspec.yaml` (`sdk: ^3.10.7`, `cupertino_icons ^1.0.8`, `flutter_lints ^6.0.0`) | All of the above | No conflicts; additions are purely additive to the existing scaffold. |

## Sources

- Local verified toolchain: `flutter --version` (Flutter 3.38.7 stable, Dart 3.10.7) — HIGH confidence, ground truth for this machine/repo.
- `.planning/codebase/STACK.md`, `.planning/codebase/ARCHITECTURE.md` — existing scaffold state (brownfield baseline).
- Context7 `/websites/flutter_dev` — AnimationController/Ticker/CustomPainter/Canvas official patterns (docs.flutter.dev). MEDIUM confidence.
- Context7 `/bluefireteam/audioplayers` — AssetSource playback API, pubspec asset setup. MEDIUM confidence.
- Context7 `/websites/pub_dev_just_audio_0_10_5` — just_audio API surface, evaluated and set aside. MEDIUM confidence.
- Context7 `/websites/pub_dev_packages_google_fonts` — asset-bundling vs HTTP-fetch behavior. MEDIUM confidence.
- Context7 `/fluttercommunity/wakelock_plus` — WakelockPlus API. MEDIUM confidence.
- Context7 `/websites/pub_dev_packages_shared_preferences` — SharedPreferences API. MEDIUM confidence.
- pub.dev package pages (fetched directly): audioplayers 6.8.1, provider 6.1.5+1, wakelock_plus 1.6.1, shared_preferences 2.5.5, google_fonts 8.1.0 — MEDIUM confidence (live pub.dev page fetch, single source).
- WebSearch: "Flutter state management Provider vs Riverpod vs flutter_bloc 2026", "audioplayers vs just_audio comparison", "Flame vs CustomPainter" — LOW confidence (community opinion/blogs), used only to corroborate the *reasoning* behind picks already grounded in official docs, not as the sole basis for any recommendation.
- `design/README.md` — exact design/behavioral spec (fonts, sound envelope, animation timings, state fields) driving several "why" rationales above.

---
*Stack research for: Zual — Flutter visual countdown timer for young children (Android v1)*
*Researched: 2026-07-06*
