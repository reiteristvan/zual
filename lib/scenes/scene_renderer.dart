import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../timer/timer_controller.dart';
import '../timer/timer_phase.dart';

/// Shared contract every full-screen running scene implements: a scene
/// reads exactly one time-varying input -- [TimerController.progress] --
/// and renders pixels (SCENE-05's "progress in, pixels out" contract, per
/// `03-UI-SPEC.md`'s Interaction Contract). Concrete scenes (`DiscScene`,
/// and Plans 02/03's Sunrise/Walk/Car scenes) extend this and back their
/// `State` with [SceneRendererState].
abstract class SceneRenderer extends StatefulWidget {
  const SceneRenderer({super.key});
}

/// Base [State] for every concrete scene.
///
/// Hosts a single [Ticker] that samples [TimerController.progress] fresh
/// every frame via `context.read` -- never via `context.watch`'s 200ms
/// notify cadence, which would cap visible motion at 5fps and fail SCENE-05
/// (`03-RESEARCH.md` Pitfall 1). The same ticker doubles as the frame source
/// for each scene's local decorative-loop animations via [loopPhase]
/// (`03-RESEARCH.md` Pattern 2) -- never a second `AnimationController`.
///
/// The ticker starts when [TimerController.phase] is [TimerPhase.running]
/// and stops for every other phase, freezing the last-rendered frame in
/// place rather than resetting it -- the Decorative Loop Contract's
/// freeze-on-non-running rule (`03-UI-SPEC.md`).
abstract class SceneRendererState<T extends SceneRenderer> extends State<T>
    with TickerProviderStateMixin<T> {
  late final Ticker _ticker;
  double _progress = 0.0;
  Duration _elapsedSinceStart = Duration.zero;

  // Accumulates elapsed time across ticker stop/start segments so
  // loopPhase() never resets when the ticker restarts (D-10).
  Duration _loopBaseOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _progress = context.read<TimerController>().progress;
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    _elapsedSinceStart = _loopBaseOffset + elapsed;
    final fresh = context.read<TimerController>().progress;
    if (fresh != _progress) {
      setState(() => _progress = fresh);
    }
  }

  /// Local decorative-loop phase in `0..1` for a loop of the given [period],
  /// derived from this ticker's own elapsed time. Subclasses/painters use
  /// this for twinkle/bob/spin motion instead of a second
  /// `AnimationController` -- see `03-RESEARCH.md` Pattern 2.
  double loopPhase(Duration period) {
    final periodMs = period.inMilliseconds;
    if (periodMs <= 0) return 0.0;
    return (_elapsedSinceStart.inMilliseconds % periodMs) / periodMs;
  }

  /// The most recently sampled progress value (0..1).
  double get progress => _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phase = context.watch<TimerController>().phase;
    if (phase == TimerPhase.running && !_ticker.isTicking) {
      _ticker.start();
    } else if (phase != TimerPhase.running && _ticker.isTicking) {
      _loopBaseOffset = _elapsedSinceStart; // snapshot before stopping
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
