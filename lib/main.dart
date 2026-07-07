import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/setup_screen.dart';
import 'theme/app_tokens.dart';
import 'timer/timer_controller.dart';
import 'timer/timer_lifecycle_binder.dart';
import 'timer/wakelock_screen_wake.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final timerController = TimerController(screenWake: const WakelockScreenWake());
  TimerLifecycleBinder(timerController).attach();

  runApp(MyApp(timerController: timerController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.timerController, this.initialDurationMin = 5});

  final TimerController timerController;

  /// The duration (in minutes) [SetupScreen] pre-selects on first mount.
  /// Plan 04 will replace this literal default with a value preloaded from
  /// SharedPreferences before `runApp`.
  final int initialDurationMin;

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
        home: SetupScreen(initialDurationMin: initialDurationMin),
      ),
    );
  }
}
