import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:zual/audio/chime_synth.dart';

void main() {
  group('synthesizeChimeWav', () {
    test('produces a well-formed RIFF/WAVE header', () {
      final bytes = synthesizeChimeWav();

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    });

    test(
      'contains a PCM fmt chunk (1 channel, 16-bit) and a non-empty data chunk',
      () {
        final bytes = synthesizeChimeWav();
        final byteData = ByteData.sublistView(bytes);

        expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
        final audioFormat = byteData.getUint16(20, Endian.little);
        final numChannels = byteData.getUint16(22, Endian.little);
        final bitsPerSample = byteData.getUint16(34, Endian.little);
        expect(audioFormat, 1); // PCM
        expect(numChannels, 1);
        expect(bitsPerSample, 16);

        expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
        final dataSize = byteData.getUint32(40, Endian.little);
        expect(dataSize, greaterThan(0));
        expect(bytes.length, 44 + dataSize);
      },
    );

    test(
      'total buffer covers well over one second of 44100Hz 16-bit mono PCM',
      () {
        final bytes = synthesizeChimeWav();
        final byteData = ByteData.sublistView(bytes);
        final dataSize = byteData.getUint32(40, Endian.little);

        // 44100 samples/sec * 2 bytes/sample = 88200 bytes/sec.
        expect(dataSize, greaterThan(88200));
      },
    );

    test('the PCM payload is not all zero (tones are synthesized, not silence)', () {
      final bytes = synthesizeChimeWav();
      final pcm = bytes.sublist(44);

      expect(pcm.any((byte) => byte != 0), isTrue);
    });
  });
}
