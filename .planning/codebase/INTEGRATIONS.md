# External Integrations

**Analysis Date:** 2026-08-19

## APIs & External Services

**None.**

The app contains no HTTP clients, networking libraries, or remote API calls. All communication with external services is zero. The app operates entirely offline.

Confirmed via codebase grep:
- No `http` package imports
- No `dio` package imports
- No `firebase` package imports
- No analytics SDKs
- No third-party tracking

## Data Storage

**Local Device Storage Only:**
- `shared_preferences` (v2.5.5)
  - File: `lib/settings/setup_preferences.dart`
  - Data stored: Last-used preset duration (minutes, 1–120), last-used scene theme name, mute preference (boolean)
  - Persisted to: Device app storage (sandboxed by OS, never sent anywhere)
  - Read/validation: Occurs on every app launch and every settings change; validates range and type on read to defend against tampering (threat T-02-02)
  - Failure mode: If storage is unavailable, app uses built-in defaults (5-min preset, disc scene, unmuted)

**File Storage:** Not used.

**Caching:** Not used.

## Platform Plugins

### Screen Wake Lock

**Service:** Keep device screen awake while timer runs

- **Plugin:** `wakelock_plus` (v1.6.1)
- **Integration Point:** `lib/timer/wakelock_screen_wake.dart` — ONLY file that imports `WakelockPlus`
- **Public Interface:** `lib/timer/screen_wake.dart` (pure Dart, no plugin imports)
- **Data Crossing Boundary:** None (enable/disable signals only)
- **Called From:** `lib/timer/timer_controller.dart` via injected `ScreenWake` interface
- **Test Mocking:** `NoopScreenWake` class (`lib/timer/screen_wake.dart`) — widget tests use this by default
- **Failure Mode:** If plugin fails or is unavailable, screen can sleep during timer; non-critical (timer continues running, just not visible)

### Audio Playback

**Service:** Play completion chime when timer ends

- **Plugin:** `audioplayers` (v6.8.1)
- **Integration Point:** `lib/audio/audioplayers_chime_player.dart` — ONLY file that imports `AudioPlayer`
- **Public Interface:** `lib/audio/chime_player.dart` (pure Dart, no plugin imports)
- **Data Crossing Boundary:** Synthesized WAV bytes (Uint8List) — generated in memory by `lib/audio/chime_synth.dart`, passed to plugin
- **Called From:** `lib/screens/running_screen.dart` via injected `ChimePlayer` interface
- **Test Mocking:**
  - `NoopChimePlayer` class (`lib/audio/chime_player.dart`) — default for widget tests, does nothing
  - `_FakeChimePlayer` in `test/screens/running_screen_test.dart` — counts invocations for assertions
- **Failure Mode:** If plugin fails, completion is silent; app continues normally, chime preference setting remains intact

### Device Settings Persistence

**Service:** Remember last-used duration and scene theme across app restarts

- **Plugin:** `shared_preferences` (v2.5.5)
- **Integration Point:** `lib/settings/setup_preferences.dart` — ONLY file that imports `SharedPreferences`
- **Data Stored:**
  - `durationMin` (int): Last-used preset duration in minutes; clamped to 1–120 on read
  - `theme` (string): Last-used scene theme's enum name (`disc`, `car`, `sunrise`, `walk`)
  - `soundOn` (bool): Parent's mute choice; defaults to `true` (unmuted)
- **Test Mocking:** `SharedPreferences.setMockInitialValues({})` — tests inject mock storage state before calling `load()`
- **Validation on Read:** All three values are validated on every read, not just at write:
  - `durationMin` out of range → clamped; missing → defaults to 5
  - `theme` unknown enum name → defaults to disc; missing → defaults to disc
  - `soundOn` wrong type or missing → defaults to true
  - Type mismatches (result of manual editing or version changes) are caught and fall back to defaults
- **Write Policy:**
  - Presets are always persisted (`persistIfPreset(showCustom: false)`)
  - Custom durations are NEVER persisted; next launch restores the last preset (design rule D-10)
  - Theme and mute preference are always persisted
- **Failure Mode:** If storage is unavailable on read, defaults are used; if unavailable on write, changes are lost but app continues running

## State Management

**Library:** `provider` (v6.1.5+1)

- **Purpose:** In-memory app state container (not external integration, purely internal)
- **Used In:** `lib/main.dart`, `lib/screens/*.dart`, `lib/scenes/scene_renderer.dart`
- **State Tracked:** Timer progress, scene selections, sound preferences
- **No External Data Flow:** All state is transient, rebuilt on app restart
- **Test Mocking:** `ChangeNotifier` subclasses can be stubbed in tests

## Build & Release Integrations

### Icon Generation

**Tool:** `flutter_launcher_icons` (v0.14.4, dev dependency)

- **Purpose:** Generates Android adaptive app icons at build time from source PNGs
- **Config:** `pubspec.yaml` sections 72–77
- **Input Assets:**
  - `assets/icon/icon_foreground.png` — Icon artwork
  - `assets/icon/icon_background.png` — Gradient background (cannot be expressed as single hex color)
- **Output:** Generates `android/app/src/main/res/mipmap-*/ic_launcher*.png` resources
- **Run Command:** `dart run flutter_launcher_icons` (the form used throughout the v1.0
  plans; the older `flutter pub run flutter_launcher_icons:main` is deprecated)
- **Upstream Input:** `assets/icon/*.png` are themselves generated from the app's own
  painters by `test/tool/generate_launcher_icon_test.dart`, so the icon never drifts from
  the shipping visuals
- **No Runtime Impact:** Build-time only; does not execute during app runtime

### Release Signing

**Deployment Target:** Google Play Console

- **Signing Configuration:** `android/key.properties` (gitignored — contains keystore password and alias)
- **Keystore:** `android/upload-keystore.jks` (gitignored — contains private signing key)
- **Git Remote:** `https://github.com/reiteristvan/zual.git`
- **No Runtime SDK:** Google Play billing, in-app purchases, or Play Services not used
- **Distribution Scope:** Android only for v1 milestone

## Static Content

### Privacy Policy

- **Location:** `docs/index.html`
- **Served From:** GitHub Pages (repository public docs directory)
- **Content:** Plain HTML privacy policy stating the app works offline, collects nothing, uses no analytics or third parties
- **No Programmatic Access:** Static page only; not loaded by app

## Environment Configuration

**No environment variables required.** The app is fully self-contained.

**No API keys, secrets, or configuration tokens are needed at runtime.**

## Offline Capability

**100% offline.** The app:
- Works with no network connection
- Contains no webviews or web calls
- Bundles all assets (fonts, icon images) locally
- Stores all state locally (no cloud sync)
- Generates all audio in-memory (no streaming)
- Renders all scenes in-memory (no remote assets)

## Dependency Audit Summary

**Total direct runtime dependencies:** 5 — the four below plus `cupertino_icons` ^1.0.8, a
`flutter create` scaffold leftover that ships no icons and is a candidate for removal.

| Package | Version | Purpose | Network? | Critical? |
|---------|---------|---------|----------|-----------|
| `wakelock_plus` | 1.6.1 | Screen wake lock | No | No (gracefully fails) |
| `audioplayers` | 6.8.1 | Audio playback | No | No (gracefully fails) |
| `shared_preferences` | 2.5.5 | Device storage | No | No (uses defaults) |
| `provider` | 6.1.5+1 | State management | No | Yes (core architecture) |

**Total external integrations (no runtime network):** 0

---

*Integration audit: 2026-08-19*
