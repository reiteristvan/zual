---
phase: 02-setup-screen
reviewed: 2026-07-07T00:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - assets/fonts/Baloo2-Bold.ttf
  - assets/fonts/Quicksand-Bold.ttf
  - assets/fonts/Quicksand-Medium.ttf
  - assets/fonts/Quicksand-Regular.ttf
  - assets/fonts/Quicksand-SemiBold.ttf
  - lib/main.dart
  - lib/scenes/scene_preview.dart
  - lib/scenes/scene_theme.dart
  - lib/screens/placeholder_running_screen.dart
  - lib/screens/setup_screen.dart
  - lib/settings/setup_preferences.dart
  - lib/theme/app_tokens.dart
  - lib/widgets/hold_repeat_button.dart
  - lib/widgets/scene_grid.dart
  - test/scenes/scene_preview_test.dart
  - test/screens/setup_screen_test.dart
  - test/settings/setup_preferences_test.dart
  - test/widget_test.dart
  - test/widgets/hold_repeat_button_test.dart
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-07-07T00:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Reviewed the Setup screen slice: `SetupScreen`, `SceneGrid`/`SceneCard`, the scene preview painters, `HoldRepeatButton`, `AppTokens`, `SetupPreferences`, the placeholder running screen, `main.dart`, and their tests, plus the five bundled font assets. `flutter analyze` is clean and the full test suite (31 tests across the listed files) passes.

The implementation is generally careful — the D-10/PERSIST-01 preset-only persistence rule, the V5 clamp-independent-of-disable-state contract for the Custom stepper, and the color/shadow token transcriptions were all verified against their documented values and hold up under direct inspection and reproduction.

However, `SetupPreferences.load()` — the one piece of code whose own doc comments explicitly claim to defend against a tampered/corrupted `SharedPreferences` store (T-02-02) — has a real gap: it validates *range* and *enum membership* but not the *stored value's runtime type*, and an actual type mismatch throws unhandled all the way up through `main()`, crashing the app before it ever renders a frame. This was reproduced directly (see CR-01). There are also a few smaller robustness/duplication issues below.

## Critical Issues

### CR-01: Type-mismatched persisted value crashes app launch, defeating the documented tampering defense

**File:** `lib/settings/setup_preferences.dart:47-61` (also `lib/main.dart:12-30`)
**Issue:**
`SetupPreferences.load()`'s doc comment (lines 25-30) explicitly states this method is "the Tampering control for threat T-02-02" because a `SharedPreferences` store is "plain, user-writable local storage (editable on a rooted device...)" and "a restored value must never be trusted to already be in range or a valid enum name." The implementation clamps an out-of-range `int` and falls back on an unknown theme string — but it never guards against the stored value being the *wrong type* for the key, which `shared_preferences`' `getInt`/`getString` implement as an unchecked cast (`_preferenceCache[key] as int?` / `as String?` in `shared_preferences_legacy.dart`).

If the `durationMin` key ever holds a non-int value (a rooted-device edit of the prefs XML/plist, a future app version that stored a different type under the same key, or a plugin-level corruption), `prefs.getInt(_durationMinKey)` throws a `TypeError` (`type 'String' is not a subtype of type 'int?' in type cast`). Reproduced directly:

```dart
SharedPreferences.setMockInitialValues({'durationMin': 'not-an-int'});
await SetupPreferences.load(); // throws: type 'String' is not a subtype of type 'int?' in type cast
```

This exception is never caught anywhere in the call chain. `main()` (`lib/main.dart:18`) does `final prefs = await SetupPreferences.load();` with no `try`/`catch`, and this runs *before* `runApp()` — so the exception propagates out of `main()` itself and the app fails to launch at all (a crash-on-boot Denial of Service on any device with a corrupted/tampered/mismatched-type prefs value), which is precisely the class of failure T-02-02 claims to prevent. The same problem applies to `getString(_themeKey)`.

**Fix:**
```dart
// lib/settings/setup_preferences.dart
static Future<SetupPreferences> load() async {
  final prefs = await SharedPreferences.getInstance();

  var durationMin = 5;
  try {
    final storedDuration = prefs.getInt(_durationMinKey);
    durationMin = storedDuration?.clamp(_minDurationMin, _maxDurationMin) ?? 5;
  } catch (_) {
    durationMin = 5; // wrong-typed/corrupted value -- fall back, never crash.
  }

  var theme = SceneTheme.disc;
  try {
    final storedTheme = prefs.getString(_themeKey);
    theme = SceneTheme.values.firstWhere(
      (t) => t.name == storedTheme,
      orElse: () => SceneTheme.disc,
    );
  } catch (_) {
    theme = SceneTheme.disc;
  }

  return SetupPreferences(durationMin: durationMin, theme: theme);
}
```
As defense-in-depth, `main()` should also not be able to fail to launch on *any* unexpected preference-loading failure:
```dart
// lib/main.dart
SetupPreferences prefs;
try {
  prefs = await SetupPreferences.load();
} catch (_) {
  prefs = const SetupPreferences(durationMin: 5, theme: SceneTheme.disc);
}
```

## Warnings

### WR-01: Fire-and-forget persistence isn't actually guarded to "fail silently" as documented

**File:** `lib/screens/setup_screen.dart:113-125`
**Issue:** `_handleStart`'s doc comment (lines 107-112) states persistence "is fire-and-forget — navigation must not wait on it, and a persistence failure must fail silently... rather than block or crash the Start flow." The code only wraps the call in `unawaited(...)`:
```dart
unawaited(
  SetupPreferences.persistIfPreset(
    showCustom: _showCustom,
    durationMin: _durationMin,
    theme: _theme,
  ),
);
```
`unawaited` only silences the "unawaited_futures" lint — it does not swallow exceptions. If `SharedPreferences.getInstance()`/`setInt`/`setString` throws (disk full, plugin channel failure, etc.), the exception surfaces as an unhandled Future error (reported to the zone's uncaught-error handler / crash reporting) rather than truly failing silently as documented.
**Fix:**
```dart
unawaited(
  SetupPreferences.persistIfPreset(
    showCustom: _showCustom,
    durationMin: _durationMin,
    theme: _theme,
  ).catchError((_) {}),
);
```

### WR-02: Manual back tap can race the auto-pop-on-done callback, risking a double `Navigator.pop()`

**File:** `lib/screens/placeholder_running_screen.dart:32-46`
**Issue:** `_maybeAutoPopWhenDone` guards against scheduling its own post-frame pop twice via `_popped`, but nothing prevents `_handleBack` (the manual back button) from popping while a previously-scheduled auto-pop callback is still pending. If the controller reaches `TimerPhase.done` and schedules the post-frame pop, and the user taps back before that callback runs, `_handleBack` pops synchronously; the still-pending callback then finds `mounted == true` (the popped route's widget isn't disposed until its exit transition completes) and calls `Navigator.of(context).pop()` a second time — popping past the intended destination or hitting a Navigator assertion, depending on route stack depth at that moment. The window is narrow but real, since `mounted` is the only guard and it does not become `false` synchronously on `pop()`.
**Fix:** Share one guard between both exit paths, e.g.:
```dart
bool _leftScreen = false;

void _leaveOnce() {
  if (_leftScreen) return;
  _leftScreen = true;
  Navigator.of(context).pop();
}

void _handleBack() {
  context.read<TimerController>().endTimer();
  _leaveOnce();
}

void _maybeAutoPopWhenDone(TimerPhase phase) {
  if (phase != TimerPhase.done || _leftScreen) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _leaveOnce();
  });
}
```

### WR-03: Pressed-state tracking logic duplicated between `_PressableSurfaceState` and `_SceneCardState`

**File:** `lib/screens/setup_screen.dart:407-433`, `lib/widgets/scene_grid.dart:44-49`
**Issue:** `_PressableSurfaceState` (setup_screen.dart) and `_SceneCardState` (scene_grid.dart) both implement essentially identical "track `_pressed` via `onTapDown`/`onTapCancel`/`onTapUp`, swap fill color" logic independently. Any future change to the pressed-state contract (timing, color, tap-vs-long-press interaction) has to be made in two places and can silently drift out of sync.
**Fix:** Extract a shared `_PressableFill` (or similar) widget/mixin used by both `SceneCard` and the Setup screen's preset/Custom/Start surfaces.

## Info

### IN-01: `SceneGrid`'s theme->painter/label maps rely on a non-null assertion instead of exhaustiveness checking

**File:** `lib/widgets/scene_grid.dart:122-134,145-148`
**Issue:** `_painters[theme]!` and `_labels[theme]!` (line 147-148) assume every `SceneTheme` value has an entry in both `static const Map`s. This holds today, but adding a new `SceneTheme` value without updating both maps compiles cleanly and only fails at runtime (`Null check operator used on a null value`) the first time that theme is rendered.
**Fix:** Replace the maps with an exhaustive `switch` expression per theme (the analyzer flags a missing case for a new enum value at compile time), or add a test that asserts `SceneTheme.values.every((t) => _painters.containsKey(t) && _labels.containsKey(t))`.

### IN-02: Scene selection-ring key is derived from display copy, not the theme identity

**File:** `lib/widgets/scene_grid.dart:96`
**Issue:** `ValueKey('scene-ring-${widget.label.toLowerCase()}')` ties the widget/test key to the exact label string. A copy change (e.g. "Shrinking disc" -> "Shrinking Disc") silently changes every dependent key and breaks `test/screens/setup_screen_test.dart`'s `ValueKey('scene-ring-shrinking disc')` lookups without any compiler signal.
**Fix:** Derive the key from the enum instead, e.g. `ValueKey('scene-ring-${widget.theme.name}')` (passing the `SceneTheme` down to `SceneCard`, or deriving the key in `SceneGrid` where the theme is already known).

---

_Reviewed: 2026-07-07T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
