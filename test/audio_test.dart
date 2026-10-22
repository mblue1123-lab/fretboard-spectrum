// Tests for the audio pitch math and WAV rendering.
// Pure Dart (tone_synth has no plugin imports), so this runs under dart test.

import 'dart:typed_data';

import 'package:fretboard_spectrum/audio/tone_synth.dart';
import 'package:fretboard_spectrum/engine/note_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('pitch math', () {
    test('semitone indices', () {
      expect(ToneSynth.semitoneIndex('C'), 0);
      expect(ToneSynth.semitoneIndex('A#'), 10);
      expect(ToneSynth.semitoneIndex('Bb'), 10);
      expect(ToneSynth.semitoneIndex('Gb'), 6);
      expect(ToneSynth.semitoneIndex('F#'), 6);
    });

    test('program octave mapping: high-E open (id 0) is E4 = 329.63 Hz', () {
      // letterByIdSharps[0] == 'E', octaveById[0] == 2
      final f = ToneSynth.frequency(playNameOf(0), octaveOf(0));
      expect(f, closeTo(329.63, 0.01));
    });

    test('program octave mapping: 7-string low B (id 150) is B1 = 61.74 Hz',
        () {
      // octaveById[150] == -1, the sub-bass B
      final f = ToneSynth.frequency(playNameOf(150), octaveOf(150));
      expect(f, closeTo(61.74, 0.01));
    });

    test('A4 reference is exactly 440 Hz', () {
      expect(ToneSynth.frequency('A', 2), closeTo(440.0, 0.001));
    });
  });

  group('WAV rendering', () {
    test('valid RIFF header and expected data size', () {
      final wav = ToneSynth.renderSequence(const [
        (freq: 440.0, seconds: 0.1),
      ]);
      final bytes = wav.buffer.asByteData();
      String tag(int o) => String.fromCharCodes(wav.sublist(o, o + 4));
      expect(tag(0), 'RIFF');
      expect(tag(8), 'WAVE');
      expect(tag(36), 'data');
      final expectedSamples = (0.1 * ToneSynth.sampleRate).round();
      expect(bytes.getUint32(40, Endian.little), expectedSamples * 2);
      expect(wav.length, 44 + expectedSamples * 2);
    });

    test('sequence concatenates tones', () {
      final one = ToneSynth.renderSequence(const [
        (freq: 440.0, seconds: 0.1),
      ]);
      final two = ToneSynth.renderSequence(const [
        (freq: 440.0, seconds: 0.1),
        (freq: 880.0, seconds: 0.1),
      ]);
      expect(two.length, one.length * 2 - 44);
    });
  });
}
