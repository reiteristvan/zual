/// Abstraction over keeping the device screen awake while a timer runs.
///
/// Kept as a pure interface with no Material, Widgets, or wakelock_plus
/// imports, so the domain-layer [TimerController][] can enable/disable
/// screen wake without depending on a platform plugin, keeping it trivially
/// unit-testable with a fake implementation.
///
/// [TimerController]: package:zual/timer/timer_controller.dart
abstract interface class ScreenWake {
  /// Prevents the device from sleeping.
  Future<void> enable();

  /// Allows the device to sleep normally again.
  Future<void> disable();
}

/// A [ScreenWake] that does nothing.
///
/// The default for [TimerController][], so the domain layer never has to
/// import a wakelock plugin.
///
/// [TimerController]: package:zual/timer/timer_controller.dart
class NoopScreenWake implements ScreenWake {
  const NoopScreenWake();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}
