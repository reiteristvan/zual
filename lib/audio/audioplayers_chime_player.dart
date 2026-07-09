import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'chime_player.dart';

/// [ChimePlayer] adapter backed by the `audioplayers` plugin.
///
/// This is the only file in `lib/audio/` that touches the plugin, so the
/// rest of the app and all widget tests never load a platform channel.
/// Plays the in-memory synthesized chime bytes directly via [BytesSource]
/// -- no temp file, no bundled audio asset (D-05).
///
/// [AudioContextAndroid] is left at its default (`USAGE_MEDIA` /
/// `STREAM_MUSIC`), so the chime follows the device's media-volume slider
/// (D-06); `respectSilence` is intentionally left unset since its
/// iOS-oriented semantics don't map to Android's ringer-silent concept
/// (04-RESEARCH.md Pitfall 4).
class AudioplayersChimePlayer implements ChimePlayer {
  AudioplayersChimePlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(Uint8List wavBytes) =>
      _player.play(BytesSource(wavBytes)).catchError((_) {});
}
