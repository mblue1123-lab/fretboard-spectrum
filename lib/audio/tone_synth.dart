// Tone synthesis for Fretboard Spectrum.
//
// Pure Dart — no Flutter or plugin imports — so the pitch math and WAV
// rendering are unit-testable. Replaces the QB64 PLAY statement: instead
// of the PC speaker, we synthesize a warm sine-based tone in memory and
// hand the bytes to the audio plugin (see note_player.dart).

import 'dart:math';
import 'dart:typed_data';

class ToneSynth {
  static const int sampleRate = 22050;

  /// Semitone index from C for a note name in sharp or flat spelling.
  /// ('C' -> 0 ... 'B' -> 11; '#' adds one, 'b' subtracts one.)
  static int semitoneIndex(String name) {
    final base = switch (name[0]) {
      'C' => 0,
      'D' => 2,
      'E' => 4,
      'F' => 5,
      'G' => 7,
      'A' => 9,
      'B' => 11,
      _ => throw ArgumentError('bad note name: $name'),
    };
    var idx = base;
    if (name.endsWith('#')) {
      idx += 1;
    } else if (name.length > 1 && name.endsWith('b')) {
      idx -= 1;
    }
    return idx % 12;
  }

  /// MIDI number for a note name in the program's octave numbering.
  /// Program octaves run C..B; program octave 2, E is the high-E open
  /// string (scientific E4, MIDI 64), so midi = 12 * (octave + 3) + index.
  /// (Check: 7-string low B is program octave -1 -> 12 * 2 + 11 = 35.)
  static int midiNumber(String letter, int programOctave) =>
      12 * (programOctave + 3) + semitoneIndex(letter);

  /// Equal-temperament frequency, A4 = 440 Hz.
  static double frequency(String letter, int programOctave) =>
      440.0 * pow(2, (midiNumber(letter, programOctave) - 69) / 12);

  /// Renders a mono 16-bit WAV (in memory) for a sequence of
  /// (frequency, seconds) tones. Each tone gets a short attack and an
  /// exponential decay plus a soft second harmonic, so it sounds like a
  /// plucked note rather than a PC-speaker beep.
  static Uint8List renderSequence(List<({double freq, double seconds})> tones) {
    final samples = <int>[];
    for (final tone in tones) {
      final n = (tone.seconds * sampleRate).round();
      final attack = min((0.012 * sampleRate).round(), n ~/ 5);
      for (var i = 0; i < n; i++) {
        final t = i / sampleRate;
        final envAttack = attack == 0 ? 1.0 : min(1.0, i / attack);
        final envDecay = exp(-2.8 * (i / n));
        final env = envAttack * envDecay;
        final v = sin(2 * pi * tone.freq * t) * 0.72 +
            sin(4 * pi * tone.freq * t) * 0.20 +
            sin(6 * pi * tone.freq * t) * 0.08;
        samples.add((v * env * 32767).round().clamp(-32768, 32767));
      }
    }
    return _wavBytes(samples);
  }

  /// Packs 16-bit mono samples into a WAV container.
  static Uint8List _wavBytes(List<int> samples) {
    final dataSize = samples.length * 2;
    final out = ByteData(44 + dataSize);
    void writeString(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        out.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    out.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    out.setUint32(16, 16, Endian.little); // PCM header size
    out.setUint16(20, 1, Endian.little); // PCM format
    out.setUint16(22, 1, Endian.little); // mono
    out.setUint32(24, sampleRate, Endian.little);
    out.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    out.setUint16(32, 2, Endian.little); // block align
    out.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    out.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      out.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return out.buffer.asUint8List();
  }
}
