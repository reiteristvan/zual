import 'dart:async';

import 'package:flutter/widgets.dart';

/// A button that fires [onStep] once per tap, and repeats -- accelerating
/// the longer it is held -- while held past the platform long-press
/// threshold (~500ms).
///
/// Ownership split: this widget owns only the tap/hold gesture recognition
/// and the repeat [Timer]'s lifecycle (create -> cancel-on-every-exit-path
/// -> cancel-in-dispose, mirroring `TimerController`'s own Timer
/// discipline). It knows nothing about any value range -- the parent
/// supplies [enabled] (already reflecting whatever range/clamp rule
/// applies, e.g. `customMin > 1`) and an [onStep] callback that is itself
/// expected to clamp on the caller's side.
///
/// The repeat Timer is cancelled on long-press end, long-press cancel, AND
/// in [dispose] -- never relying on exactly one of those paths, since this
/// widget can be unmounted mid-hold (e.g. a preset is tapped while the
/// Custom stepper's -/+ button is still being held), which fires neither
/// long-press end nor long-press cancel. A single-shot, self-rescheduling
/// [Timer] is used (not `Timer.periodic`) so the interval can change every
/// tick as the hold accelerates.
class HoldRepeatButton extends StatefulWidget {
  const HoldRepeatButton({
    super.key,
    required this.onStep,
    required this.enabled,
    required this.child,
  });

  /// Invoked once per discrete step: once for a tap, and once per repeat
  /// tick while held. The caller owns clamping/range semantics.
  final VoidCallback onStep;

  /// When false, neither tap nor hold produce any [onStep] calls, and any
  /// in-flight repeat stops before its next tick.
  final bool enabled;

  final Widget child;

  @override
  State<HoldRepeatButton> createState() => _HoldRepeatButtonState();
}

class _HoldRepeatButtonState extends State<HoldRepeatButton> {
  Timer? _repeatTimer;

  /// Total time held so far, tracked as the sum of already-elapsed repeat
  /// intervals rather than read from a wall clock (e.g. `DateTime.now()`).
  /// A wall-clock read would desync from Flutter's test-time `Timer`
  /// scheduling under `tester.pump(duration)` (widget tests advance a fake
  /// timer clock, not real wall-clock time), making acceleration
  /// untestable; accumulating scheduled durations is deterministic under
  /// both real and fake time.
  Duration _heldDuration = Duration.zero;

  static const _initialInterval = Duration(milliseconds: 350); // held > ~500ms
  static const _midInterval = Duration(milliseconds: 150); // held > ~2s
  static const _fastInterval = Duration(milliseconds: 60); // held > ~4s

  /// Recomputed on every tick (not fixed at hold-start) so the repeat rate
  /// can accelerate mid-hold rather than being locked to whatever interval
  /// applied when the hold began.
  Duration _nextInterval() {
    if (_heldDuration >= const Duration(seconds: 4)) return _fastInterval;
    if (_heldDuration >= const Duration(seconds: 2)) return _midInterval;
    return _initialInterval;
  }

  void _scheduleNextTick() {
    _repeatTimer?.cancel();
    final interval = _nextInterval();
    _repeatTimer = Timer(interval, () {
      if (!widget.enabled) {
        _stopRepeating();
        return;
      }
      _heldDuration += interval;
      widget.onStep();
      _scheduleNextTick();
    });
  }

  void _startRepeating() {
    _heldDuration = Duration.zero;
    widget.onStep(); // the step coinciding with onLongPressStart (~500ms mark)
    _scheduleNextTick();
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _heldDuration = Duration.zero;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel(); // safety net independent of end/cancel handlers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onStep : null,
      onLongPressStart: widget.enabled ? (_) => _startRepeating() : null,
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: widget.child,
    );
  }
}
