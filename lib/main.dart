import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'scenes/scene_theme.dart';
import 'screens/setup_screen.dart';
import 'settings/setup_preferences.dart';
import 'theme/app_tokens.dart';
import 'timer/timer_controller.dart';
import 'timer/timer_lifecycle_binder.dart';
import 'timer/wakelock_screen_wake.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read persisted prefs once, before runApp, so the very first frame
  // already shows the restored preset/theme (PERSIST-01, Pitfall 3) — a
  // FutureBuilder inside SetupScreen would still show a default frame first.
  //
  // Defense-in-depth against T-02-02: SetupPreferences.load() already
  // validates/falls back on out-of-range, unknown-enum, and wrong-typed
  // stored values, but launch must never be able to fail on *any*
  // unexpected preference-loading error, so this also falls back to the
  // built-in defaults rather than let main() throw before runApp() runs.
  SetupPreferences prefs;
  try {
    prefs = await SetupPreferences.load();
  } catch (_) {
    prefs = const SetupPreferences(durationMin: 5, theme: SceneTheme.disc);
  }

  final timerController = TimerController(screenWake: const WakelockScreenWake());
  TimerLifecycleBinder(timerController).attach();

  runApp(
    MyApp(
      timerController: timerController,
      initialDurationMin: prefs.durationMin,
      initialTheme: prefs.theme,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.timerController,
    this.initialDurationMin = 5,
    this.initialTheme = SceneTheme.disc,
  });

  final TimerController timerController;

  /// The duration (in minutes) [SetupScreen] pre-selects on first mount.
  /// `main()` passes in a value preloaded from [SetupPreferences.load]
  /// (PERSIST-01); this literal default only applies to callers (e.g.
  /// widget tests) that construct [MyApp] directly.
  final int initialDurationMin;

  /// The scene theme [SetupScreen] pre-selects on first mount. `main()`
  /// passes in a value preloaded from [SetupPreferences.load] (PERSIST-01);
  /// this literal default only applies to callers that construct [MyApp]
  /// directly.
  final SceneTheme initialTheme;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimerController>.value(
      value: timerController,
      child: MaterialApp(
        title: 'Zual',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTokens.accent),
          scaffoldBackgroundColor: AppTokens.bg,
        ),
        home: SetupScreen(
          initialDurationMin: initialDurationMin,
          initialTheme: initialTheme,
        ),
      ),
    );
  }
}
