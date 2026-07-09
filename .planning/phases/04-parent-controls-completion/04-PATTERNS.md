# Phase 4: Parent Controls & Completion - Pattern Map

**Mapped:** 2026-07-08
**Files analyzed:** 8 (5 new, 3 modified)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/audio/chime_synth.dart` | utility (pure Dart) | transform | none in-repo (pure-math generator); shape follows domain-value-object style of `lib/timer/timer_controller.dart`'s pure computation methods | no direct analog — see "No Analog Found" |
| `lib/audio/chime_player.dart` | service (interface) | event-driven | `lib/timer/screen_wake.dart` | exact — identical "abstract interface + Noop default" shape |
| `lib/audio/audioplayers_chime_player.dart` | service (plugin adapter) | event-driven | `lib/timer/wakelock_screen_wake.dart` | exact — identical "single file wraps one plugin, implements the app's own interface" shape |
| `lib/settings/setup_preferences.dart` (modified — add `soundOn`) | model/config | CRUD (load/persist) | itself (extend in place) | exact — same file, same pattern for the two existing scalars |
| `lib/screens/running_screen.dart` (modified — gesture, sheet, chime trigger, pill) | screen/controller (composition root) | request-response + event-driven | itself (extend in place); sheet button wiring modeled on `lib/screens/setup_screen.dart`'s controller-calling `onPressed` pattern | exact (self) / role-match (setup_screen for button-to-controller wiring) |
| `lib/scenes/scene_renderer.dart` (modified — D-10 loop offset fix) | component base class | streaming (ticker-driven) | itself (extend in place) | exact — same file, single-file diff |
| `test/audio/chime_synth_test.dart` | test (unit) | transform | `test/settings/setup_preferences_test.dart` (pure-Dart, no widget harness) | role-match |
| `test/screens/running_screen_test.dart` | test (widget) | request-response + event-driven | `test/screens/setup_screen_test.dart` | exact — same harness shape (`ChangeNotifierProvider<TimerController>` + `MaterialApp`), same "injected clock, no wall-clock dependence" convention |
| `test/scenes/scene_renderer_test.dart` (modified — add pause/resume continuity case) | test (widget) | streaming | itself (extend in place) | exact |

## Pattern Assignments

### `lib/audio/chime_player.dart` (service interface, event-driven)

**Analog:** `lib/timer/screen_wake.dart` (read in full above)

**Full pattern to copy** — abstract interface + no-op default, kept free of any plugin import so the domain/composition layers stay platform-agnostic and trivially fakeable in tests:
```dart
/// Abstraction over playing the completion chime.
///
/// Kept as a pure interface with no Flutter plugin imports, so
/// [RunningScreen] can trigger playback without depending on a platform
/// plugin directly, keeping it trivially unit-testable with a fake
/// implementation (mirrors [ScreenWake]'s interface-wraps-a-plugin shape).
abstract interface class ChimePlayer {
  /// Plays the given WAV byte buffer once.
  Future<void> play(Uint8List wavBytes);
}

/// A [ChimePlayer] that does nothing — the default for widget tests so they
/// never touch a real platform channel (Common Pitfall 5, 04-RESEARCH.md).
class NoopChimePlayer implements ChimePlayer {
  const NoopChimePlayer();

  @override
  Future<void> play(Uint8List wavBytes) async {}
}
```
Note the naming convention: `ChimePlayer`/`NoopChimePlayer`, matching `ScreenWake`/`NoopScreenWake` exactly (interface name + `Noop`-prefixed default, both `const` constructible).

---

### `lib/audio/audioplayers_chime_player.dart` (plugin adapter, event-driven)

**Analog:** `lib/timer/wakelock_screen_wake.dart` (read in full above)

**Full pattern to copy** — single file, single plugin import, implements the app's own interface, swallows plugin errors so a playback failure never crashes the running screen:
```dart
import 'package:audioplayers/audioplayers.dart';

import 'chime_player.dart';

/// [ChimePlayer] adapter backed by the `audioplayers` plugin.
///
/// This is the only file in `lib/audio/` that touches the plugin, so the
/// rest of the app and all widget tests never load a platform channel.
class AudioplayersChimePlayer implements ChimePlayer {
  AudioplayersChimePlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(Uint8List wavBytes) =>
      _player.play(BytesSource(wavBytes)).catchError((_) {});
}
```
Follow `WakelockScreenWake`'s `.catchError((_) {})` convention verbatim — a chime failure (e.g. no audio output device) must degrade silently, not throw into `RunningScreen`'s build/callback path.

---

### `lib/settings/setup_preferences.dart` (modified, model/config, CRUD)

**Analog:** itself — the file already contains the exact pattern to replicate for a third scalar (read in full above, lines 1-101)

**Imports pattern** (lines 1-3): unchanged, no new import needed for a `bool` scalar.

**Constructor/field pattern to copy** (lines 31-38): add `soundOn` alongside `durationMin`/`theme`:
```dart
class SetupPreferences {
  const SetupPreferences({
    required this.durationMin,
    required this.theme,
    this.soundOn = true, // D-04 default: unmuted
  });

  final bool soundOn;
  // ...existing durationMin/theme fields unchanged
}
```

**Validate-on-read pattern to copy** (lines 56-79) — same try/catch-per-scalar shape, wrong-typed/missing value falls back to the D-04 default instead of propagating:
```dart
static Future<SetupPreferences> load() async {
  final prefs = await SharedPreferences.getInstance();
  // ...existing durationMin/theme try/catch blocks unchanged...

  var soundOn = true;
  try {
    soundOn = prefs.getBool(_soundOnKey) ?? true;
  } catch (_) {
    soundOn = true;
  }

  return SetupPreferences(durationMin: durationMin, theme: theme, soundOn: soundOn);
}
```

**Write pattern** — add a new key constant near `_durationMinKey`/`_themeKey` (line 12-15):
```dart
const String _soundOnKey = 'soundOn';
```
Per `04-RESEARCH.md` Pattern 4, add a standalone `persistSoundOn(bool)` method (always writes, unlike `durationMin` which is gated behind `showCustom`) rather than folding it into `persistIfPreset` — mute has no "preset vs custom" concept:
```dart
static Future<void> persistSoundOn(bool soundOn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_soundOnKey, soundOn);
}
```

---

### `lib/screens/running_screen.dart` (modified, screen/composition-root)

**Analog:** itself (full file read above, 97 lines) + `lib/screens/setup_screen.dart` for the controller-calling button-wiring convention.

**Imports pattern to add** (existing block, lines 1-8):
```dart
import 'dart:ui'; // ImageFilter.blur
import 'package:flutter/gestures.dart'; // LongPressGestureRecognizer

import '../audio/chime_player.dart';
import '../audio/chime_synth.dart';
import '../settings/setup_preferences.dart';
```

**Existing code to DELETE outright (not kept as fallback):**
```dart
// lines 79-92 -- the visible back IconButton -- replaced entirely by the
// hidden long-press + Parent Controls sheet, per 04-CONTEXT.md scope note.
Positioned(
  top: 8,
  left: 8,
  child: Semantics(
    label: 'End timer and return to setup',
    button: true,
    child: IconButton(
      onPressed: _handleBack,
      ...
    ),
  ),
),
```
Also delete `_handleBack` (lines 50-57) and `_maybeAutoPopWhenDone` (lines 59-67) — replaced by the done-edge chime/pill logic below (Pitfall 1, 04-RESEARCH.md).

**Edge-triggered once-only pattern to copy** (from `04-RESEARCH.md` Pattern 5, itself derived from this file's own existing `_leftScreen` guard idiom at line 40-48) — generalize the same "guard boolean + `_leaveOnce`-style single-fire" shape already established in this file:
```dart
TimerPhase? _previousPhase;
bool _chimePlayed = false;

void _maybeReactToPhaseChange(TimerPhase phase) {
  final justCompleted = phase == TimerPhase.done && _previousPhase != TimerPhase.done;
  _previousPhase = phase;
  if (justCompleted && !_chimePlayed) {
    _chimePlayed = true;
    if (!_soundOn) return;
    unawaited(widget.chimePlayer.play(_chimeBytes));
  }
}
```

**Gesture pattern** (`04-RESEARCH.md` Architecture Pattern 1, `RawGestureDetector` wraps the existing `Positioned.fill(child: sceneFor(widget.theme))` at line 78):
```dart
RawGestureDetector(
  gestures: <Type, GestureRecognizerFactory>{
    LongPressGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 850)),
      (recognizer) => recognizer.onLongPress = _openParentControls,
    ),
  },
  behavior: HitTestBehavior.opaque,
  child: Positioned.fill(child: sceneFor(widget.theme)),
)
```
Gate with D-09: only attach/allow when `controller.phase != TimerPhase.done`.

**Sheet button -> controller wiring convention** — modeled on how `setup_screen.dart`'s Start button calls `context.read<TimerController>().start(...)` directly in an `onPressed` (same "widget reads controller, calls a method, no intermediate ViewModel" convention used throughout this codebase); apply identically for Pause/Resume/End timer:
```dart
onPressed: () => context.read<TimerController>().pause(), // or .resume() / .endTimer()
```

**Error handling / persistence write-through** — mute toggle follows `SetupPreferences`'s "fire-and-forget persistence, no Save step" precedent (`04-UI-SPEC.md` Interaction Contract): call `SetupPreferences.persistSoundOn(newValue)` without awaiting in the UI thread, update local `ValueNotifier<bool>`/`setState` immediately for instant icon feedback.

---

### `lib/scenes/scene_renderer.dart` (modified, D-10 fix)

**Analog:** itself (full file read above, 82 lines) — this is a minimal, targeted diff, not a new pattern from elsewhere.

**Exact diff to apply** (fields at lines 33-35, method at lines 44-50, method at lines 66-74):
```dart
// Add alongside _elapsedSinceStart (line 35):
Duration _loopBaseOffset = Duration.zero;

// _onTick (line 44-50), change line 45:
void _onTick(Duration elapsed) {
  _elapsedSinceStart = _loopBaseOffset + elapsed; // CHANGED from: elapsed;
  final fresh = context.read<TimerController>().progress;
  if (fresh != _progress) {
    setState(() => _progress = fresh);
  }
}

// didChangeDependencies (line 66-74), snapshot before stopping:
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final phase = context.watch<TimerController>().phase;
  if (phase == TimerPhase.running && !_ticker.isTicking) {
    _ticker.start();
  } else if (phase != TimerPhase.running && _ticker.isTicking) {
    _loopBaseOffset = _elapsedSinceStart; // NEW: snapshot before stopping
    _ticker.stop();
  }
}
```
`loopPhase()` (lines 56-60) is untouched — it already derives purely from `_elapsedSinceStart`, so the offset accumulation upstream is sufficient.

---

### `test/screens/running_screen_test.dart` (new, widget test)

**Analog:** `test/screens/setup_screen_test.dart` (read in full above, lines 1-80)

**Harness pattern to copy** (lines 17-31) — same `ChangeNotifierProvider<TimerController>.value` + `MaterialApp` wrapping, injected-clock controller so the suite never depends on wall-clock time:
```dart
Widget _harness(
  TimerController controller, {
  SceneTheme theme = SceneTheme.disc,
  ChimePlayer chimePlayer = const NoopChimePlayer(),
  bool soundOn = true,
}) {
  return ChangeNotifierProvider<TimerController>.value(
    value: controller,
    child: MaterialApp(
      home: RunningScreen(theme: theme, chimePlayer: chimePlayer, soundOn: soundOn),
    ),
  );
}
```

**Pump-past-transition pattern to copy** (lines 33-41) — critical, since `RunningScreen` hosts a `SceneRenderer` whose `Ticker` schedules frames continuously while running; `pumpAndSettle()` will hang:
```dart
Future<void> _pumpPastTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
```

**Long-press test idiom** (new, no existing analog in this file, but follows `WidgetTester`'s standard gesture-simulation API):
```dart
await tester.longPress(find.byType(RunningScreen), warnIfMissed: false);
// or, for precise duration control:
final gesture = await tester.startGesture(center);
await tester.pump(const Duration(milliseconds: 900));
await gesture.up();
```

**Injected-fake-plugin pattern to copy** — mirrors `TimerController(clock: () => now)`'s injected-dependency-for-testability convention (`test/timer/timer_controller_test.dart` uses the same shape); use a fake `ChimePlayer` implementing the interface to assert `play()` was called exactly once, per Common Pitfall 5 (`04-RESEARCH.md`):
```dart
class _FakeChimePlayer implements ChimePlayer {
  int playCount = 0;
  @override
  Future<void> play(Uint8List wavBytes) async {
    playCount++;
  }
}
```

---

### `test/audio/chime_synth_test.dart` (new, pure-Dart unit test)

**Analog:** `test/settings/setup_preferences_test.dart` — pure logic test with no widget harness/`WidgetTester`, just `test()` + plain assertions (no `testWidgets`).

**Pattern to copy:** no Flutter/Widget imports, only `package:flutter_test/flutter_test.dart`'s `test()` (not `testWidgets()`) and `package:zual/audio/chime_synth.dart`; assert on the returned `Uint8List`'s RIFF header bytes, total length, and non-silence (non-all-zero PCM payload) — do not assert exact sample values (Open Question 1, `04-RESEARCH.md`: envelope constants are tunable, not locked).

## Shared Patterns

### Interface-wraps-a-plugin (platform isolation)
**Source:** `lib/timer/screen_wake.dart` + `lib/timer/wakelock_screen_wake.dart`
**Apply to:** `lib/audio/chime_player.dart` + `lib/audio/audioplayers_chime_player.dart`
```dart
// Interface file: no plugin import, abstract interface class + Noop default.
// Adapter file: single plugin import, implements the interface, swallows
// plugin errors with .catchError((_) {}).
```
This is the single most important shared pattern in this phase — it is what makes `test/screens/running_screen_test.dart` possible without `MissingPluginException` (Common Pitfall 5).

### Validate-on-every-read persistence scalar
**Source:** `lib/settings/setup_preferences.dart` lines 56-79 (existing `durationMin`/`theme` handling)
**Apply to:** the new `soundOn` scalar in the same file — same try/catch-per-field, same "corrupted/wrong-typed value falls back to the documented default" shape (T-02-02 precedent).

### Edge-triggered once-only phase reaction
**Source:** `lib/screens/running_screen.dart`'s existing `_leftScreen`/`_leaveOnce()` guard (lines 40-48)
**Apply to:** the new `_chimePlayed`/`_previousPhase` guard for the chime-on-done trigger — same "boolean guard prevents a repeat side effect across rebuilds" idiom, generalized from single-purpose (`_leftScreen`) to phase-transition-detection (`_previousPhase != TimerPhase.done && phase == TimerPhase.done`).

### Injected-clock/injected-dependency testability
**Source:** `lib/timer/timer_controller.dart`'s `clock`/`tickInterval`/`screenWake` constructor injection, used throughout `test/timer/timer_controller_test.dart` and `test/screens/setup_screen_test.dart`
**Apply to:** `RunningScreen`'s new `chimePlayer` constructor parameter (default `AudioplayersChimePlayer()` in production via `main.dart`, injected `NoopChimePlayer`/fake in tests) — same constructor-injection-for-testability convention already established project-wide.

### Fire-and-forget persistence write (no Save step)
**Source:** `lib/settings/setup_preferences.dart`'s `persistIfPreset` called un-awaited from `setup_screen.dart` on every selection change
**Apply to:** the mute toggle's `SetupPreferences.persistSoundOn(...)` call from the sheet's icon `onPressed`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/audio/chime_synth.dart` | utility (pure Dart PCM/WAV generation) | transform | No prior audio/binary-data-generation code exists anywhere in `lib/`. Use `04-RESEARCH.md`'s Code Examples section directly (the `synthesizeChimeWav` sketch) as the starting point instead of an in-repo analog — tune the envelope constants by ear against `design/README.md` §H rather than treating the research snippet's `0.35`/`0.5s` constants as final (Assumption A3, Open Question 1). Keep it a pure-Dart file with `dart:math`/`dart:typed_data` imports only, no Flutter import, so it stays unit-testable exactly like `chime_synth_test.dart` requires.

## Metadata

**Analog search scope:** `lib/screens/`, `lib/scenes/`, `lib/timer/`, `lib/settings/`, `lib/theme/`, `lib/widgets/`, `test/screens/`, `test/scenes/`, `test/timer/`, `test/settings/`
**Files scanned:** 24 lib files, 17 test files (full listing via Glob); 8 read in full for pattern extraction (`running_screen.dart`, `scene_renderer.dart`, `setup_preferences.dart`, `screen_wake.dart`, `wakelock_screen_wake.dart`, `app_tokens.dart`, `timer_controller.dart`, `main.dart`) plus 2 test files (`setup_screen_test.dart` partial, `scene_renderer_test.dart` full)
**Pattern extraction date:** 2026-07-08
