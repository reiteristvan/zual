import 'dart:async';

import 'package:flutter/foundation.dart';

import 'screen_wake.dart';
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
  TimerController({
    DateTime Function()? clock,
    Duration? tickInterval,
    ScreenWake? screenWake,
  }) : _clock = clock ?? DateTime.now,
       _tickInterval = tickInterval ?? const Duration(milliseconds: 200),
       _screenWake = screenWake ?? const NoopScreenWake();

  final DateTime Function() _clock;
  final Duration _tickInterval;
  final ScreenWake _screenWake;

  TimerPhase _phase = TimerPhase.setup;
  Duration _total = Duration.zero;
  DateTime? _startTime;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pausedAt;
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
  ///
  /// While [_phase] is [TimerPhase.paused], elapsed is measured up to the
  /// frozen [_pausedAt] instant rather than the live clock, so progress does
  /// not advance while paused. While running, elapsed is measured against the
  /// live injected clock, which is what makes backgrounding "just work" —
  /// elapsed is always derived from real timestamps, never from a running
  /// Stopwatch that the OS could throttle.
  Duration get _elapsed {
    final start = _startTime;
    if (start == null) return Duration.zero;
    final now = _phase == TimerPhase.paused ? (_pausedAt ?? _clock()) : _clock();
    final delta = now.difference(start) - _pausedTotal;
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
    _screenWake.enable();
    notifyListeners();
  }

  /// Freezes the countdown: no-op unless [phase] is [TimerPhase.running].
  /// Records the paused-at instant from the injected clock so [_elapsed]
  /// stops advancing while paused. Per locked decision D-01, pause() is only
  /// ever an explicit parent action — backgrounding must never call this.
  void pause() {
    if (_phase != TimerPhase.running) return;
    _pausedAt = _clock();
    _phase = TimerPhase.paused;
    _ticker?.cancel();
    _ticker = null;
    _screenWake.disable();
    notifyListeners();
  }

  /// Resumes the countdown: no-op unless [phase] is [TimerPhase.paused].
  /// Adds the just-elapsed paused interval to [_pausedTotal] so it is
  /// permanently excluded from elapsed time, then restarts the periodic
  /// reconcile ticker.
  void resume() {
    if (_phase != TimerPhase.paused) return;
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      _pausedTotal += _clock().difference(pausedAt);
    }
    _pausedAt = null;
    _phase = TimerPhase.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) => syncToWallClock());
    _screenWake.enable();
    notifyListeners();
  }

  /// Ends the current timer from any phase, returning the controller to
  /// [TimerPhase.setup] with progress reset to zero. Does not persist
  /// anything (D-03) — an ended or killed timer leaves no at-rest state.
  void endTimer() {
    _ticker?.cancel();
    _ticker = null;
    _total = Duration.zero;
    _startTime = null;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    _progressHighWaterMark = 0.0;
    _phase = TimerPhase.setup;
    _screenWake.disable();
    notifyListeners();
  }

  /// The single reconcile path: recomputes progress from elapsed wall-clock
  /// time and transitions to [TimerPhase.done] once elapsed time reaches the
  /// total duration. Completion is a pure function of elapsed time, so this
  /// method produces the correct result whether it is invoked by the
  /// periodic ticker or by a foreground-return lifecycle hook
  /// (`TimerLifecycleBinder`), which realizes done-while-backgrounded.
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
      _screenWake.disable();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
