import 'package:shared_preferences/shared_preferences.dart';

import '../scenes/scene_theme.dart';

/// The minimum allowed persisted duration in minutes.
const int _minDurationMin = 1;

/// The maximum allowed persisted duration in minutes.
const int _maxDurationMin = 120;

/// Key under which the last-used preset duration (minutes) is stored.
const String _durationMinKey = 'durationMin';

/// Key under which the last-used scene theme's [SceneTheme.name] is stored.
const String _themeKey = 'theme';

/// Validating read/preset-only-write wrapper around `shared_preferences` for
/// the two scalars PERSIST-01 remembers: last-used preset duration and
/// last-used scene theme.
///
/// Mirrors [lib/timer/screen_wake.dart]'s interface-wraps-a-plugin shape: the
/// rest of the app never touches `shared_preferences` directly, only this
/// value object and its static loader/writer.
///
/// The clamp/fallback logic in [load] is the Tampering control for
/// threat T-02-02: a `SharedPreferences` store is plain, user-writable local
/// storage (editable on a rooted device, or written by a future app version
/// with a different valid range). A restored value must never be trusted to
/// already be in range or a valid enum name -- it is validated here on every
/// read, not just checked at write time.
class SetupPreferences {
  const SetupPreferences({required this.durationMin, required this.theme});

  /// The last-used preset duration in minutes, always in `1..120`.
  final int durationMin;

  /// The last-used scene theme.
  final SceneTheme theme;

  /// Reads the persisted duration and theme, clamping/validating both so a
  /// corrupted or out-of-range stored value can never propagate into the
  /// app (D-09, T-02-02):
  /// - `durationMin` is clamped into `1..120`; a missing value falls back to
  ///   the D-09 default of 5.
  /// - `theme` is resolved via [SceneTheme.values.firstWhere]; an unknown or
  ///   missing stored string falls back to [SceneTheme.disc] (D-09).
  static Future<SetupPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();

    final storedDuration = prefs.getInt(_durationMinKey);
    final durationMin =
        storedDuration?.clamp(_minDurationMin, _maxDurationMin) ?? 5;

    final storedTheme = prefs.getString(_themeKey);
    final theme = SceneTheme.values.firstWhere(
      (t) => t.name == storedTheme,
      orElse: () => SceneTheme.disc,
    );

    return SetupPreferences(durationMin: durationMin, theme: theme);
  }

  /// Persists the current selection, but only ever writes a *preset*
  /// duration -- never a custom one (D-10, Pitfall 4).
  ///
  /// [theme] is always written. [durationMin] is written only when
  /// [showCustom] is `false`; when a custom value is the live selection, the
  /// previously persisted preset duration (or the built-in default, if none
  /// was ever persisted) is left untouched, so a Custom last-use always
  /// restores to the 5-min default preset on next launch, never a persisted
  /// custom number.
  static Future<void> persistIfPreset({
    required bool showCustom,
    required int durationMin,
    required SceneTheme theme,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    if (!showCustom) {
      await prefs.setInt(_durationMinKey, durationMin);
    }
  }
}
