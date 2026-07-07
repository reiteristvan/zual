import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zual/scenes/scene_theme.dart';
import 'package:zual/settings/setup_preferences.dart';

void main() {
  group('SetupPreferences', () {
    test('load() with no stored values returns durationMin 5 and theme disc (D-09)', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SetupPreferences.load();

      expect(prefs.durationMin, 5);
      expect(prefs.theme, SceneTheme.disc);
    });

    test('load() clamps an out-of-range stored durationMin (Tampering, T-02-02)', () async {
      SharedPreferences.setMockInitialValues({'durationMin': 999});
      final tooHigh = await SetupPreferences.load();
      expect(tooHigh.durationMin, 120);

      SharedPreferences.setMockInitialValues({'durationMin': 0});
      final tooLow = await SetupPreferences.load();
      expect(tooLow.durationMin, 1);
    });

    test('load() falls back to disc for an unknown stored theme string (Tampering, T-02-02)', () async {
      SharedPreferences.setMockInitialValues({'theme': 'bogus'});

      final prefs = await SetupPreferences.load();

      expect(prefs.theme, SceneTheme.disc);
    });

    test('persistIfPreset(showCustom: true) writes theme but leaves durationMin untouched (D-10)', () async {
      SharedPreferences.setMockInitialValues({'durationMin': 10, 'theme': 'disc'});

      await SetupPreferences.persistIfPreset(
        showCustom: true,
        durationMin: 47,
        theme: SceneTheme.walk,
      );

      final restored = await SetupPreferences.load();
      expect(restored.durationMin, 10); // untouched -- 47 (custom) never written
      expect(restored.theme, SceneTheme.walk);
    });

    test('persistIfPreset(showCustom: false) writes both durationMin and theme', () async {
      SharedPreferences.setMockInitialValues({});

      await SetupPreferences.persistIfPreset(
        showCustom: false,
        durationMin: 15,
        theme: SceneTheme.car,
      );

      final restored = await SetupPreferences.load();
      expect(restored.durationMin, 15);
      expect(restored.theme, SceneTheme.car);
    });

    test('round-trip: persisting a preset then loading restores it exactly', () async {
      SharedPreferences.setMockInitialValues({});

      await SetupPreferences.persistIfPreset(
        showCustom: false,
        durationMin: 30,
        theme: SceneTheme.sunrise,
      );
      final restored = await SetupPreferences.load();

      expect(restored.durationMin, 30);
      expect(restored.theme, SceneTheme.sunrise);
    });
  });
}
