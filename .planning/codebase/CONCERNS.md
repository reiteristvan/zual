# Codebase Concerns

**Analysis Date:** 2026-07-06

## Tech Debt

### Pre-release Flutter Version Constraint

**Issue:** The SDK constraint in `pubspec.yaml` specifies a pre-release Flutter version (`flutter: ">=3.18.0-18.0.pre.54"`), which may not guarantee API stability or long-term support.

**Files:** `pubspec.yaml` (line 213)

**Impact:** Production builds against unstable channels carry risk of API changes or deprecations in future releases.

**Fix approach:** Update to a stable channel constraint (e.g., `>=3.18.0`). Run `flutter channel stable` and update the constraint to lock to stable releases only.

### Android Application ID is Placeholder

**Issue:** The Android app uses the default placeholder ID `com.example.zual` rather than a unique, production-ready package name.

**Files:** `android/app/build.gradle.kts` (line 24)

**Impact:** Cannot deploy to Google Play Store with this ID. Multiple apps on the same device would collide.

**Fix approach:** Before any release, change to a proper reverse-domain ID (e.g., `dev.reiteristvan.zual`). This must happen before first Play Store submission.

### Android Release Build Signing Not Configured

**Issue:** Release builds are signed with debug keys; there is no production signing config. This is explicitly flagged as a TODO in the Gradle file.

**Files:** `android/app/build.gradle.kts` (lines 35–37)

**Impact:** Release APK/AAB cannot be signed with a production key for Play Store deployment. Every release will use debug keys.

**Fix approach:** Configure a keystore and signing config for release builds. Add `signingConfig` reference to the release build type pointing to the production keystore (keep keystore file in `.gitignore`).

## Architecture & Design Gaps

### Entire App in Single File with No State Management

**Issue:** All UI and logic is in `lib/main.dart`. The app uses only `StatelessWidget` despite needing:
- Timer countdown logic (progress tracking)
- Multiple screens (setup → running → done)
- Pause/resume state
- Theme/scene selection
- Parent control sheet interaction
- Audio playback on completion

**Files:** `lib/main.dart` (all)

**Impact:** Impossible to implement state transitions, animations driven by elapsed time, or pause/resume logic. Prop drilling will be unmaintainable. The design spec calls for `phase: 'setup' | 'running' | 'done'` state machine that cannot be modeled in stateless widgets.

**Fix approach:** 
1. Introduce a state management solution (Provider, Riverpod, or Bloc) to hold the timer state (phase, duration, progress, paused).
2. Break the single file into modules:
   - `lib/models/` - state models (TimerState, Scene, etc.)
   - `lib/screens/` - Setup, Running (per-scene), Completed screens
   - `lib/widgets/` - reusable components (buttons, grids, sheets)
   - `lib/providers/` or `lib/services/` - timer logic, scene rendering
3. Implement the design spec's state machine (setup → running → done, plus paused sub-state).

### No Animation Infrastructure

**Issue:** The design spec requires sophisticated animations:
- Progress-driven disc shrinking (scale from 1 → 0 based on elapsed time)
- Color transitions (green → yellow → red) driven by progress
- Looping animations (bob, spin, twinkle, breathe) on multiple scenes
- Smooth 0.12s–0.4s linear transitions on transforms and colors
- None of this infrastructure exists.

**Files:** `lib/main.dart` - only static UI

**Impact:** Running scenes (Shrinking Disc, Sunrise, Walking, Car) cannot be implemented without animation framework.

**Fix approach:**
1. Choose an animation approach:
   - **CustomPainter** for performance-critical scenes (disc, paths, characters) with `AnimationController` driving `progress` 0→1 over the timer duration.
   - **Animated**/`TweenAnimationBuilder` for simpler color/position transitions.
   - **Rive** or **Flare** for pre-built character animations if walking/car need refinement.
2. Create a shared progress stream/provider that drives all scene animations from a single timer.
3. Use `requestAnimationFrame`-like behavior via Flutter's animation system (vsync, display link).

### No Audio/Sound Implementation

**Issue:** The design spec defines a critical UX element: a **soft chime on timer completion** (two sine notes: D5 587.33 Hz, G5 783.99 Hz, with specific envelope). No audio packages or implementation exist.

**Files:** None (missing entirely)

**Impact:** Cannot signal completion to the child. Silent timer defeat the design intent.

**Fix approach:**
1. Add audio dependency:
   - **Android/iOS:** `just_audio` or `audioplayers` package
   - **Web:** Use `web_audio_api` or a Dart FFI wrapper
2. Implement audio generation in a `AudioService`:
   - Generate the two sine tones with specified frequencies and envelope timing
   - Or bundle a matching short WAV file (preferred for consistency)
3. Trigger playback in the timer completion callback.
4. Make optional (design mentions `soundOn` toggle).

### Missing State Models & Enums

**Issue:** The design spec defines a complex state machine that is not yet modeled in code:
- `phase`: `'setup' | 'running' | 'done'` (plus `paused` sub-state)
- `theme`: `'disc' | 'sunrise' | 'walk' | 'car'`
- `durationMin`, `customMin`, `showCustom`, `progress`, `paused`, `controlsOpen`

No data classes, enums, or state holders exist.

**Files:** None (missing)

**Impact:** State will be scattered across multiple widgets or widget trees, making it unmaintainable and error-prone.

**Fix approach:** Create `lib/models/` module:
```dart
enum Phase { setup, running, done }
enum Scene { disc, sunrise, walk, car }

class TimerState {
  final Phase phase;
  final Scene scene;
  final int durationMin;
  final int customMin;
  final bool showCustom;
  final double progress;  // 0..1
  final bool paused;
  final bool controlsOpen;
  // ... timing internals: totalMs, startTs, pausedTotal, pauseStart
}
```

## Feature Implementation Gaps

### Scene Rendering Not Started

**Issue:** The design spec defines four distinct running scenes with complex visuals:
1. **Shrinking Disc** — a 300px circle shrinking with color zones (green → yellow → red)
2. **Night to Sunrise** — sky gradient interpolating night → day, stars fading, moon fading, sun rising
3. **Walking Home** — character walking left→right with vertical bob, approaching a house
4. **Car on Road** — car driving left→right along a road with spinning wheels

None of these are implemented beyond the placeholder "Hello, World!" UI.

**Files:** `lib/main.dart` (only MyHomePage scaffold exists)

**Impact:** Core feature is missing; cannot verify design-to-code fidelity or performance.

**Fix approach:**
1. Create `lib/screens/running/` directory with separate screens per scene:
   - `shrinking_disc_screen.dart`
   - `sunrise_screen.dart`
   - `walking_screen.dart`
   - `car_screen.dart`
2. Each scene should accept `progress` (0..1) as input and render accordingly.
3. Use `CustomPainter` for visual scenes (shapes, gradients, paths) for performance.
4. Use animation primitives (Transform, Opacity, Container) for simpler elements.

### Setup Screen Components Not Implemented

**Issue:** The Setup screen (per design spec) requires multiple interactive components:
- Duration picker: 3×2 grid of preset buttons (1, 5, 10, 15, 30 min + Custom)
- Custom duration stepper: − / value / + controls, range 1–120 min
- Scene picker: 2×2 grid of theme cards (Disc, Sunrise, Walking, Car) with preview thumbnails
- Start button with duration label

None of these exist.

**Files:** None (missing)

**Impact:** User cannot configure timer or choose scenes.

**Fix approach:**
1. Create `lib/screens/setup_screen.dart` with layout and state handlers.
2. Create reusable widgets:
   - `lib/widgets/preset_button.dart` — selectable preset button
   - `lib/widgets/duration_stepper.dart` — − / value / + with validation
   - `lib/widgets/scene_card.dart` — scene selector with preview
3. Hook to state provider to save selections and transition to running screen.

### Parent Controls Sheet Not Implemented

**Issue:** The design specifies a bottom sheet revealed by long-press (≈850ms) on running screen:
- Pause/Resume button
- End Timer button (returns to setup)
- Keep Watching button (dismisses)
- Scrim overlay with blur

Not implemented.

**Files:** None (missing)

**Impact:** Parent cannot pause or reset timer; child's normal taps open controls (design intent is long-press only).

**Fix approach:**
1. Create `lib/widgets/parent_controls_sheet.dart`.
2. Detect long-press in running screen with `GestureDetector(onLongPress)`.
3. Implement pause/resume logic in timer state (freeze progress, accumulate paused time).
4. Implement End Timer to reset state to setup phase.

### Design Tokens & Theme Not Extracted

**Issue:** The design spec provides exact color values, typography, spacing, and radii. Currently hardcoded in Flutter's default `ThemeData` (deepPurple colorScheme).

**Files:** `lib/main.dart` (lines 14–16)

**Impact:** 
- Colors won't match spec (design is warm/earthy, not purple)
- Typography isn't using specified fonts (Baloo 2, Quicksand)
- Spacing/radius values are not reusable or consistent
- No visual fidelity to design

**Fix approach:**
1. Create `lib/theme/design_tokens.dart` with constants:
   ```dart
   const Color appBackground = Color(0xFFF6EBDD);
   const Color cardSurface = Color(0xFFFFFCF6);
   const Color primaryGreen = Color(0xFF7FA87A);
   const Color discYellow = Color(0xFFE8B75A);
   const Color discRed = Color(0xFFDE6A4B);
   // ... (all colors from design spec)
   ```
2. Create `lib/theme/app_theme.dart` with `ThemeData`:
   ```dart
   ThemeData buildTheme() => ThemeData(
     useMaterial3: true,
     colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
     // Custom text themes for Quicksand/Baloo 2
   );
   ```
3. Update fonts in `pubspec.yaml` (Google Fonts dependency or local bundles).

## Testing Gaps

### Minimal Test Coverage

**Issue:** Only one basic widget test exists (`test/widget_test.dart`), which tests only the "Hello, World!" text. The app has:
- No timer countdown logic tests
- No state transition tests
- No pause/resume tests
- No animation tests
- No scene rendering tests

**Files:** `test/widget_test.dart` (1 test total)

**Impact:** Untested code: timer logic, paused-time accumulation, progress-driven scene rendering, parent controls, audio callback.

**Fix approach:**
1. Add unit tests for timer logic:
   - `test/models/timer_state_test.dart` — state transitions, progress calculation
   - `test/services/timer_service_test.dart` — countdown, pause/resume, completion callback
2. Add widget tests for UI components:
   - `test/widgets/preset_button_test.dart`
   - `test/widgets/duration_stepper_test.dart`
   - `test/screens/setup_screen_test.dart`
3. Add integration tests for full timer cycle (setup → running → completion).
4. Aim for >80% coverage of critical paths (timer logic, state transitions).

## Performance & Optimization

### No Performance Optimization for Animated Scenes

**Issue:** The running scenes (especially Sunrise with stars, Walking character, Car wheels) involve:
- Multiple animated elements (stars twinkling, sun rising, character bobbing, wheels spinning)
- Per-frame color interpolation (disc color zones)
- Progress-driven transforms

If built naively with a deep widget tree of `Opacity`, `Transform`, `Container` per element, this will cause high frame drops on low-end devices (target audience includes young children, so devices may be lower-spec tablets).

**Files:** None (scenes not yet implemented)

**Impact:** Jank during timer playback; poor user experience; high battery drain.

**Fix approach:**
1. Use `CustomPainter` for visually complex scenes (Shrinking Disc, Sunrise backdrop, Walking/Car paths).
2. Minimize widget rebuilds by:
   - Extracting animated elements into separate `AnimationBuilder` widgets
   - Using `RepaintBoundary` around static elements
3. Use `FrameCallback` or `Ticker` to drive animations at 60 FPS (vsync).
4. Profile with Flutter DevTools before shipping.

### No Handling of Background/Foreground Transitions

**Issue:** No lifecycle handling for when the app is paused (user switches apps) or resumed. Timer may continue or jump unexpectedly.

**Files:** None (missing)

**Impact:** Timer progress can become out-of-sync with wallclock time; confusing UX ("I was gone for 5 seconds, but timer jumped 30 seconds").

**Fix approach:**
1. Use `WidgetsBindingObserver` to listen to `AppLifecycleState` changes.
2. Pause timer on `paused` state.
3. Recalculate elapsed time on `resumed` state (in case wallclock changed).

## Known Limitations & Design Constraints

### No Persistence / "Remember Last Settings"

**Issue:** The design spec notes "Optional nicety: remember last-used duration + theme locally." Currently no local storage or persistence logic exists.

**Files:** None (missing)

**Impact:** Parent must re-select duration and scene every app launch (minor UX friction).

**Fix approach:** Optional; if implemented, use `shared_preferences` or `hive` to cache last-used settings and restore on app startup.

### Setup Layout B Not Implemented or Toggled

**Issue:** Design spec provides two setup layouts (A = default grid layout, B = explicit step cards). The prototype toggles with `setupLayout: 'A' | 'B'`. Currently only Layout A is designed; no toggle or B implementation.

**Files:** `lib/main.dart` — only empty scaffold exists

**Impact:** Cannot evaluate Layout B UX without building it.

**Fix approach:** After implementing Layout A, implement Layout B as an alternative. Add a feature flag or settings screen to toggle between them for A/B testing.

### Web Audio API Not Used on Web Platform

**Issue:** The design spec mentions "on web: Web Audio API" for generating the chime tones. Flutter web has limited audio support; Web Audio API would need to be called via JavaScript interop.

**Files:** None (missing)

**Impact:** Web build may not play chime; audio implementation will need platform-specific code paths.

**Fix approach:**
1. Use `js` package to call Web Audio API directly on web.
2. Use `just_audio` or `audioplayers` on mobile (may also work on web).
3. Wrap in platform channel or conditional compilation.

---

*Concerns audit: 2026-07-06*
