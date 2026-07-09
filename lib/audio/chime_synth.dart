import 'dart:math' as math;
import 'dart:typed_data';

/// Synthesizes the calm completion chime as a well-formed WAV byte buffer.
///
/// Pure Dart -- imports only `dart:math` and `dart:typed_data`, no Flutter
/// or plugin dependency -- so it is fully unit-testable without a platform
/// channel (`test/audio/chime_synth_test.dart`).
///
/// Produces two soft sine tones, D5 (587.33 Hz) then G5 (783.99 Hz), with
/// tone starts ~0.3s apart. Each tone's gain envelope ramps to ~0.16 over
/// 60ms then exponentially decays toward ~0 over ~1.1s, per
/// `design/README.md`'s End chime spec (D-05: real-time synthesized tone,
/// not a bundled audio asset). The exact decay time-constant below is a
/// tunable approximation of that description (04-RESEARCH.md Open
/// Question 1), not a locked formula.
Uint8List synthesizeChimeWav({int sampleRate = 44100}) {
  const toneOffsetsSec = <double>[0.0, 0.3];
  const toneFrequenciesHz = <double>[587.33, 783.99];
  const envelopeDurationSec = 1.1;
  const rampSec = 0.06;
  const peakGain = 0.16;
  // Tuned so the exponential decay reaches ~0 by envelopeDurationSec.
  const decayTimeConstantSec = 0.22;

  var totalDurationSec = 0.0;
  for (final offset in toneOffsetsSec) {
    final toneEnd = offset + envelopeDurationSec;
    if (toneEnd > totalDurationSec) totalDurationSec = toneEnd;
  }
  final totalSampleCount = (sampleRate * totalDurationSec).round();

  // Accumulate overlapping tones in a wider-than-16-bit buffer before
  // clamping down to 16-bit signed samples.
  final mixed = Int32List(totalSampleCount);

  for (var toneIndex = 0; toneIndex < toneFrequenciesHz.length; toneIndex++) {
    final freqHz = toneFrequenciesHz[toneIndex];
    final startSample = (toneOffsetsSec[toneIndex] * sampleRate).round();
    final toneSampleCount = (envelopeDurationSec * sampleRate).round();

    for (var i = 0; i < toneSampleCount; i++) {
      final sampleIndex = startSample + i;
      if (sampleIndex >= totalSampleCount) break;

      final t = i / sampleRate;
      final gain = t < rampSec
          ? peakGain * (t / rampSec)
          : peakGain * math.exp(-(t - rampSec) / decayTimeConstantSec);
      final sample = gain * math.sin(2 * math.pi * freqHz * t);
      final intSample = (sample * 32767).round();
      mixed[sampleIndex] += intSample;
    }
  }

  final pcmBytes = Uint8List(totalSampleCount * 2);
  final pcmView = ByteData.sublistView(pcmBytes);
  for (var i = 0; i < totalSampleCount; i++) {
    final clamped = mixed[i].clamp(-32768, 32767);
    pcmView.setInt16(i * 2, clamped, Endian.little);
  }

  return _wrapPcmAsWav(
    pcmBytes,
    sampleRate: sampleRate,
    channels: 1,
    bitsPerSample: 16,
  );
}

/// Prepends a minimal canonical RIFF/WAVE header to raw PCM [pcmBytes].
Uint8List _wrapPcmAsWav(
  Uint8List pcmBytes, {
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
}) {
  final blockAlign = channels * bitsPerSample ~/ 8;
  final byteRate = sampleRate * blockAlign;
  final dataSize = pcmBytes.length;
  final riffSize = 36 + dataSize;

  final header = Uint8List(44);
  final headerView = ByteData.sublistView(header);

  header.setRange(0, 4, 'RIFF'.codeUnits);
  headerView.setUint32(4, riffSize, Endian.little);
  header.setRange(8, 12, 'WAVE'.codeUnits);

  header.setRange(12, 16, 'fmt '.codeUnits);
  headerView.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  headerView.setUint16(20, 1, Endian.little); // audio format: PCM
  headerView.setUint16(22, channels, Endian.little);
  headerView.setUint32(24, sampleRate, Endian.little);
  headerView.setUint32(28, byteRate, Endian.little);
  headerView.setUint16(32, blockAlign, Endian.little);
  headerView.setUint16(34, bitsPerSample, Endian.little);

  header.setRange(36, 40, 'data'.codeUnits);
  headerView.setUint32(40, dataSize, Endian.little);

  final result = Uint8List(header.length + pcmBytes.length);
  result.setRange(0, header.length, header);
  result.setRange(header.length, result.length, pcmBytes);
  return result;
}
