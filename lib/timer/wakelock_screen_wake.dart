import 'package:wakelock_plus/wakelock_plus.dart';

import 'screen_wake.dart';

/// [ScreenWake] adapter backed by the wakelock_plus plugin.
///
/// This is the only file in `lib/timer/` that touches the plugin, so the
/// domain-layer controller and its tests never load a platform plugin.
class WakelockScreenWake implements ScreenWake {
  const WakelockScreenWake();

  @override
  Future<void> enable() => WakelockPlus.enable().catchError((_) {});

  @override
  Future<void> disable() => WakelockPlus.disable().catchError((_) {});
}
