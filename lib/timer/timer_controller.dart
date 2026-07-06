import 'dart:async';

import 'package:flutter/foundation.dart';

import 'timer_phase.dart';

/// The minimum allowed timer duration in minutes.
const int _minMinutes = 1;

/// The maximum allowed timer duration in minutes.
const int _maxMinutes = 120;

/// Wall-clock progress engine for Zual's countdown timer.
///
/// Derives a normalized [progress] (0..1) and [phase] from real elapsed
/// wall-clock time (not tick count or `Stopwatch`), so completion is a pure
/// function of elapsed time — correct regardless of animation/tick frame
/// rate, and correct even if the app is backgrounded and its timers are
/// throttled or paused by the OS.
class TimerController extends ChangeNotifier {
  TimerController({DateTime Function()? clock, Duration? tickInterval})
    : _clock = clock ?? DateTime.now,
      _tickInterval = tickInterval ?? const Duration(milliseconds: 200);

  final DateTime Function() _clock;
  final Duration _tickInterval;

  TimerPhase _phase = TimerPhase.setup;
  Duration _total = Duration.zero;
  DateTime? _startTime;
  Duration _pausedTotal = Duration.zero;
  double _progressHighWaterMark = 0.0;
  Timer? _ticker;

  /// The current timer phase.
  TimerPhase get phase => _phase;

  /// Normalized elapsed fraction in the 0..1 range.
  ///
  /// Monotonic non-decreasing while a run is active: returns the maximum of
  /// the freshly computed raw elapsed fraction and a stored high-water mark,
  /// so a backward device-clock movement cannot rewind a running countdown.
  double get progress {
    if (_total.inMilliseconds == 0) return 0.0;
    final rawFraction = _elapsed.inMilliseconds / _total.inMilliseconds;
    final clamped = rawFraction.clamp(0.0, 1.0);
    return clamped > _progressHighWaterMark ? clamped : _progressHighWaterMark;
  }

  /// Elapsed time since [_startTime], minus paused time, floored at zero so a
  /// backward clock movement cannot produce a negative elapsed duration.
  Duration get _elapsed {
    final start = _startTime;
    if (start == null) return Duration.zero;
    final delta = _clock().difference(start) - _pausedTotal;
    return delta.isNegative ? Duration.zero : delta;
  }

  /// Starts a new countdown of [minutes] (clamped into the inclusive range
  /// 1..120), resets progress bookkeeping, transitions to [TimerPhase.running],
  /// and begins the periodic reconcile ticker.
  void start(int minutes) {
    final clampedMinutes = minutes.clamp(_minMinutes, _maxMinutes);
    _total = Duration(minutes: clampedMinutes);
    _startTime = _clock();
    _pausedTotal = Duration.zero;
    _progressHighWaterMark = 0.0;
    _phase = TimerPhase.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) => syncToWallClock());
    notifyListeners();
  }

  /// The single reconcile path: recomputes progress from elapsed wall-clock
  /// time and transitions to [TimerPhase.done] once elapsed time reaches the
  /// total duration. Completion is a pure function of elapsed time, so this
  /// method produces the correct result whether it is invoked by the
  /// periodic ticker or by a foreground-return lifecycle hook (added in
  /// Plan 02).
  void syncToWallClock() {
    if (_total.inMilliseconds != 0) {
      final rawFraction = (_elapsed.inMilliseconds / _total.inMilliseconds)
          .clamp(0.0, 1.0);
      if (rawFraction > _progressHighWaterMark) {
        _progressHighWaterMark = rawFraction;
      }
    }

    if (_phase == TimerPhase.running && _elapsed >= _total) {
      _phase = TimerPhase.done;
      _ticker?.cancel();
      _ticker = null;
      _progressHighWaterMark = 1.0;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
