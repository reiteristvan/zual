import 'dart:typed_data';

/// Abstraction over playing the completion chime.
///
/// Kept as a pure interface with no Flutter plugin imports, so
/// [RunningScreen][] can trigger playback without depending on a platform
/// plugin directly, keeping it trivially unit-testable with a fake
/// implementation (mirrors [ScreenWake][]'s interface-wraps-a-plugin shape).
///
/// [RunningScreen]: package:zual/screens/running_screen.dart
/// [ScreenWake]: package:zual/timer/screen_wake.dart
abstract interface class ChimePlayer {
  /// Plays the given WAV byte buffer once.
  Future<void> play(Uint8List wavBytes);
}

/// A [ChimePlayer] that does nothing.
///
/// The default for widget tests, so they never touch a real platform
/// channel (Common Pitfall 5, `04-RESEARCH.md`).
class NoopChimePlayer implements ChimePlayer {
  const NoopChimePlayer();

  @override
  Future<void> play(Uint8List wavBytes) async {}
}
