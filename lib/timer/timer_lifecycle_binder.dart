import 'package:flutter/widgets.dart';

import 'timer_controller.dart';

/// App-layer glue that reconciles a [TimerController] to real wall-clock
/// time whenever the app returns to the foreground.
///
/// This is the one hook that realizes done-while-backgrounded (locked
/// decision D-02): the OS may throttle or suspend the app's timers while
/// backgrounded, so [TimerController.syncToWallClock] must be re-run on
/// resume to catch up. Per D-01, no other lifecycle state pauses or
/// otherwise mutates the timer — backgrounding must never call `pause()`.
///
/// Allowed to import `package:flutter/widgets.dart` because this is
/// app-layer wiring, not the domain layer; [TimerController] itself must
/// never import Widgets.
class TimerLifecycleBinder with WidgetsBindingObserver {
  TimerLifecycleBinder(this.controller);

  final TimerController controller;

  /// Registers this binder as an observer of app lifecycle changes.
  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Unregisters this binder. Safe to call once; must be called when the
  /// binder is no longer needed to avoid leaking the observer registration.
  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        controller.syncToWallClock();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // No action: per D-01, backgrounding must not pause the timer —
        // the wall-clock model keeps advancing on its own and is
        // reconciled the next time the app resumes.
        break;
    }
  }
}
