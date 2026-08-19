# Codebase Structure

**Analysis Date:** 2026-08-19

## Directory Layout

```
zual/
├── lib/                          # Dart source code (29 files, ~3,874 LOC)
│   ├── main.dart                 # App entry point and composition root
│   ├── audio/                    # Audio playback and synthesis
│   │   ├── chime_player.dart
│   │   ├── audioplayers_chime_player.dart
│   │   └── chime_synth.dart
│   ├── scenes/                   # Scene widgets and per-scene implementations
│   │   ├── scene_registry.dart
│   │   ├── scene_renderer.dart
│   │   ├── scene_theme.dart
│   │   ├── scene_preview.dart
│   │   ├── car/
│   │   │   ├── car_scene.dart    # Car scene widget
│   │   │   └── car_painter.dart  # Car CustomPainter
│   │   ├── disc/
│   │   │   ├── disc_scene.dart
│   │   │   └── disc_painter.dart
│   │   ├── sunrise/
│   │   │   ├── sunrise_scene.dart
│   │   │   └── sunrise_painter.dart
│   │   └── walk/
│   │       ├── walk_scene.dart
│   │       └── walk_painter.dart
│   ├── screens/                  # Full-screen UI layouts
│   │   ├── setup_screen.dart
│   │   ├── running_screen.dart
│   │   └── placeholder_running_screen.dart
│   ├── settings/                 # User preferences and configuration
│   │   └── setup_preferences.dart
│   ├── theme/                    # Design tokens and theming
│   │   └── app_tokens.dart
│   ├── timer/                    # Timer logic and lifecycle
│   │   ├── timer_controller.dart
│   │   ├── timer_phase.dart
│   │   ├── timer_lifecycle_binder.dart
│   │   ├── screen_wake.dart
│   │   └── wakelock_screen_wake.dart
│   └── widgets/                  # Reusable UI components
│       ├── hold_repeat_button.dart
│       ├── pressable_surface.dart
│       └── scene_grid.dart
├── test/                         # Test files (25 files, ~2,846 LOC)
│   ├── widget_test.dart          # Main widget test
│   ├── audio/
│   │   └── chime_synth_test.dart
│   ├── scenes/                   # Per-scene tests mirror lib/scenes/
│   │   ├── car/
│   │   │   ├── car_scene_test.dart
│   │   │   └── car_painter_test.dart
│   │   ├── disc/
│   │   │   ├── disc_scene_test.dart
│   │   │   └── disc_painter_test.dart
│   │   ├── sunrise/
│   │   │   ├── sunrise_scene_test.dart
│   │   │   └── sunrise_painter_test.dart
│   │   ├── walk/
│   │   │   ├── walk_scene_test.dart
│   │   │   └── walk_painter_test.dart
│   │   ├── scene_preview_test.dart
│   │   ├── scene_registry_test.dart
│   │   └── scene_renderer_test.dart
│   ├── screens/
│   │   ├── setup_screen_test.dart
│   │   └── running_screen_test.dart
│   ├── settings/
│   │   └── setup_preferences_test.dart
│   ├── timer/
│   │   └── timer_controller_test.dart
│   ├── widgets/
│   │   └── hold_repeat_button_test.dart
│   ├── support/                  # Shared test helpers (no _test.dart suffix)
│   │   └── progress_sweep.dart   # Used by scene tests
│   └── tool/                     # PNG asset generators (see naming rules below)
│       ├── feature_graphic_test.dart
│       ├── generate_feature_graphic.dart
│       ├── generate_launcher_icon_test.dart
│       ├── generate_store_icon_test.dart
│       ├── icon_painters.dart
│       └── icon_renderer.dart
├── android/                      # Android platform code
│   ├── app/                      # Android app module
│   │   ├── build.gradle.kts      # Android app build config (Kotlin DSL)
│   │   └── src/main/             # Android source and resources
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/           # Kotlin MainActivity
│   │       └── res/              # Android resources
│   └── gradle/wrapper/           # Gradle build tool
├── web/                          # Web platform (scaffold only, not v1 target)
│   ├── index.html
│   ├── manifest.json
│   └── icons/
├── assets/                       # App assets
│   ├── fonts/                    # Custom fonts
│   └── icon/                     # App icons
├── design/                       # Design source of truth (tracked)
├── docs/                         # Documentation and policies
├── screenshots/                  # App screenshots
├── store_assets/                 # Play Store listing assets
├── .planning/                    # GSD planning directory
│   └── codebase/                 # Codebase analysis documents
├── pubspec.yaml                  # Dart/Flutter package manifest
├── pubspec.lock                  # Locked dependency versions
├── analysis_options.yaml         # Dart linter configuration
└── .gitignore                    # Git ignore rules
```

## Directory Purposes

**`lib/`:**
- Purpose: Dart source code organized by concern domain, not architectural layer
- Contains: 29 files spanning 7 concern areas (audio, scenes, screens, settings, theme, timer, widgets) plus composition root
- Key files: `main.dart` (app entry point and root widget setup)

**`lib/audio/`:**
- Purpose: Audio playback and synthesis for the chime when timer completes
- Contains: Chime player interface, platform-specific implementation, synth logic
- Exports: `ChimePlayer` interface, `ChimeSynth` class

**`lib/scenes/`:**
- Purpose: Scene-specific widgets and rendering paired with shared scene infrastructure
- Contains: 4 scene folders (car, disc, sunrise, walk) + shared registry, renderer, theme, preview
- Pattern: Each scene folder has exactly 2 files—a `<scene>_scene.dart` widget and `<scene>_painter.dart` CustomPainter
- Key files: `scene_registry.dart` (scene catalog), `scene_renderer.dart` (shared rendering logic)

**`lib/screens/`:**
- Purpose: Full-screen layouts that compose multiple widgets
- Contains: Setup screen (duration + scene selection), running screen (active timer display)
- Exports: `SetupScreen`, `RunningScreen` widgets

**`lib/settings/`:**
- Purpose: User preferences storage and retrieval
- Contains: Preferences API (wrapping SharedPreferences)
- Exports: `SetupPreferences` class for reading/writing user choices

**`lib/theme/`:**
- Purpose: Design tokens and theming constants
- Contains: Color palette, sizes, durations, radii
- Exports: `AppTokens` class with all design tokens

**`lib/timer/`:**
- Purpose: Timer logic, lifecycle, and screen wake-lock management
- Contains: Timer state machine, controller, phase definitions, wake-lock adapters
- Exports: `TimerController`, `TimerPhase` enum, screen wake interface

**`lib/widgets/`:**
- Purpose: Reusable UI components
- Contains: Button components, surface behaviors, scene grid layout
- Exports: `HoldRepeatButton`, `PressableSurface`, `SceneGrid` widgets

**`test/`:**
- Purpose: Test files organized to mirror `lib/` structure
- Contains: 21 `_test.dart` files (auto-run by `flutter test`) + 4 non-suffixed helpers
- Rule: Test files mimic source structure: `test/scenes/car/car_scene_test.dart` tests `lib/scenes/car/car_scene.dart`

**`test/support/`:**
- Purpose: Shared test helpers and utilities
- Contains: Reusable test data, mock factories, custom matchers
- Naming: No `_test.dart` suffix — these are imported by test files, never auto-run

**`test/tool/`:**
- Purpose: PNG asset generation (feature graphics, app icons)
- Naming rule: Generators that WRITE files avoid `_test.dart` suffix so `flutter test` never auto-runs them
  - Example: `generate_feature_graphic.dart` (never auto-run)
  - Exception: Older generators still use suffix: `generate_launcher_icon_test.dart`, `generate_store_icon_test.dart` (these DO auto-run and regenerate PNGs on test)
- Key files: `icon_painters.dart` (shared rendering), `icon_renderer.dart` (headless PNG writer)

**`android/`:**
- Purpose: Android platform-specific code and build configuration
- Contains: Android manifest, Gradle build scripts, Kotlin activity, native resources
- Key files: `AndroidManifest.xml` (app metadata, activity declaration)

**`web/`:**
- Purpose: Web platform bootstrap (scaffold only — not a v1 target)
- Contains: HTML entry point, PWA manifest, web icons
- Status: Not updated for v1 release

**`assets/`:**
- Purpose: App resources (fonts, icons)
- Contains: Custom fonts in `fonts/`, app icons in `icon/`
- Committed: Yes (referenced in `pubspec.yaml`)

**`design/`:**
- Purpose: Design source of truth — treated as final, not as a starting point
- Contains: `design/README.md` (token palette, typography, radii, timings), plus two
  high-fidelity HTML prototypes: `design/Zual.dc.html` (interactive) and
  `design/Zual - App Screens.dc.html` (annotated screen-flow board). Not Figma exports.
- Committed: Yes — all five files are tracked

**`docs/`:**
- Purpose: The static page published for the Play Store listing's privacy-policy link
- Contains: `docs/index.html` only — a hand-written privacy policy. There is no terms-of-service
  document.
- Committed: Yes

**`.planning/`:**
- Purpose: GSD planning and codebase analysis artifacts
- Contains: `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `STACK.md`, `INTEGRATIONS.md`, `CONCERNS.md`
- Committed: Yes

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Dart app entry point — `main()` function and `MyApp` root widget
- `android/app/src/main/AndroidManifest.xml`: Android entry point
- `web/index.html`: Web entry point (not v1 target)

**Configuration:**
- `pubspec.yaml`: Flutter/Dart package manifest
- `analysis_options.yaml`: Dart linter configuration
- `android/app/build.gradle.kts`: Android build settings, `applicationId`, release signing

**Timer & Scene Logic:**
- `lib/timer/timer_controller.dart`: Main timer state machine
- `lib/scenes/scene_registry.dart`: Scene catalog and lookup
- `lib/scenes/scene_renderer.dart`: Shared scene rendering logic

**UI Composition:**
- `lib/screens/setup_screen.dart`: Duration + scene selection layout
- `lib/screens/running_screen.dart`: Active timer display
- `lib/widgets/scene_grid.dart`: Scene picker grid layout

**Design & Theming:**
- `lib/theme/app_tokens.dart`: All design tokens (colors, sizes, timings)
- `lib/settings/setup_preferences.dart`: User preference storage

**Persistence:**
- `lib/settings/setup_preferences.dart`: Wraps SharedPreferences for user choices

## Naming Conventions

**Files:**
- Source files: `snake_case.dart` (e.g., `main.dart`, `timer_controller.dart`)
- Test files: `snake_case_test.dart` (e.g., `timer_controller_test.dart`)
- Test helpers: `snake_case.dart` without `_test` suffix when in `test/support/` or `test/tool/` (e.g., `progress_sweep.dart`, `icon_painters.dart`)
- Scene pair files: `<scene>_scene.dart` and `<scene>_painter.dart` in per-scene folders
- Android resources: lowercase with underscores (e.g., `ic_launcher.xml`)

**Directories:**
- Dart source: `lib/`
- Tests: `test/` with subdirs mirroring `lib/`
- Concern-based grouping: `audio/`, `scenes/`, `screens/`, `settings/`, `theme/`, `timer/`, `widgets/`
- Per-scene implementation: `lib/scenes/<scene_name>/` and `test/scenes/<scene_name>/`
- Platform-specific: `android/`, `web/`

**Classes and Widgets:**
- PascalCase for all class/widget names (e.g., `TimerController`, `SetupScreen`)
- Widget classes are named for what they ARE and are never suffixed with `Widget` — no class
  in `lib/` carries that suffix. Follow `SceneCard`/`PressableSurface`, not `SceneCardWidget`.
- State classes use `_<WidgetName>State` when splitting State from StatefulWidget
- Private classes/functions: `_underscore` prefix

## Where to Add New Code

**New Scene:**
1. Create folder `lib/scenes/<name>/`
2. Create `<name>_scene.dart` (StatelessWidget or StatefulWidget that builds UI)
3. Create `<name>_painter.dart` (CustomPainter that renders graphics)
4. Add scene metadata to `lib/scenes/scene_registry.dart`
5. Create tests: `test/scenes/<name>/<name>_scene_test.dart` and `test/scenes/<name>/<name>_painter_test.dart`
6. Optional: Create `test/scenes/<name>/<name>_preview_test.dart` if custom preview needed

**New Screen:**
- Primary code: `lib/screens/<feature>_screen.dart`
- Tests: `test/screens/<feature>_screen_test.dart`
- Use: Import in `lib/screens/` namespace or directly in routing

**New Widget (reusable component):**
- Implementation: `lib/widgets/<component>.dart`
- Tests: `test/widgets/<component>_test.dart`
- Usage: Import from `lib/widgets/` where needed

**New Timer Feature:**
- Implementation: `lib/timer/<feature>.dart`
- Tests: `test/timer/<feature>_test.dart`
- Note: Integrate with `TimerController` state machine

**Audio/Sound Logic:**
- Implementation: `lib/audio/<feature>.dart`
- Tests: `test/audio/<feature>_test.dart`
- Must implement or use `ChimePlayer` interface

**Settings/Preferences:**
- Implementation: Add methods to `lib/settings/setup_preferences.dart`
- Tests: Update `test/settings/setup_preferences_test.dart`

**Design Tokens:**
- Add to `lib/theme/app_tokens.dart` (colors, sizes, durations, etc.)
- Reference from all other modules
- No separate test file needed (tokens are constants)

**Test Helpers (shared):**
- Location: `test/support/<helper>.dart` (NO `_test.dart` suffix)
- Usage: Imported by test files, never auto-run by `flutter test`
- Example: `test/support/progress_sweep.dart`

**Asset Generators (tool scripts):**
- Location: `test/tool/<purpose>.dart`
- Naming rule:
  - If generator WRITES files: use `test/tool/generate_<asset>.dart` (NO suffix) so it never auto-runs
  - If integration test verifies generation: `test/tool/<feature>_test.dart` with full suffix (DO auto-run)
- Example: `test/tool/generate_feature_graphic.dart` (no suffix—manual run only)
- Legacy exception: `test/tool/generate_launcher_icon_test.dart` (has suffix—auto-runs and regenerates PNGs)

## Special Directories

**`build/`:**
- Purpose: Compiled build artifacts
- Generated: Yes (by `flutter build`, `flutter run`)
- Committed: No (.gitignore)

**`.dart_tool/`:**
- Purpose: Dart/Flutter tool cache and package resolution
- Generated: Yes (by `flutter pub get`)
- Committed: No (.gitignore)

**`.idea/`:**
- Purpose: Android Studio / IntelliJ IDEA IDE metadata
- Generated: Yes (by IDE)
- Committed: No (.gitignore)

**`store_assets/` and `screenshots/`:**
- Purpose: Play Store listing artwork — `store_assets/icon_512.png`,
  `store_assets/feature_graphic.png`, and five scene/setup screenshots
- Generated: The two `store_assets/` PNGs are rendered from the app's own painters by the
  generators in `test/tool/`, not hand-designed
- Committed: Yes

---

*Structure analysis: 2026-08-19*
