import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'timer/timer_controller.dart';
import 'timer/timer_lifecycle_binder.dart';
import 'timer/wakelock_screen_wake.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final timerController = TimerController(screenWake: const WakelockScreenWake());
  TimerLifecycleBinder(timerController).attach();

  runApp(MyApp(timerController: timerController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.timerController});

  final TimerController timerController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimerController>.value(
      value: timerController,
      child: MaterialApp(
        title: 'Zual',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Zual'),
      ),
      body: const Center(
        child: Text(
          'Hello, World!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
