// Audio playback for Fretboard Spectrum.
//
// Replaces every PLAY statement in the QB64 program:
//  - quiz pitch (PLAY name$)  -> synthesized tone at the note's frequency
//  - right/wrong sounds       -> short synthesized blips
// The old `PLAY "On"` octave-cue side effect from SUB assignoctave is
// dropped on purpose: the octave is just data now, and its cue lives on
// as the rainbow color.

import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../engine/note_mapper.dart';
import 'tone_synth.dart';

class NotePlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;

  /// Frequency of a note ID, using the sharp spelling (name$) and the
  /// program's octave numbering, exactly as PLAY name$ heard it.
  static double frequencyOfId(int noteId) =>
      ToneSynth.frequency(playNameOf(noteId), octaveOf(noteId));

  /// Plays the quiz pitch for a note ID (the PLAY name$ moment).
  Future<void> playNoteId(int noteId, {double seconds = 0.9}) {
    return _play(ToneSynth.renderSequence(
        [(freq: frequencyOfId(noteId), seconds: seconds)]));
  }

  /// Plays a named pitch in a program octave (-1..4), for the Spectrum
  /// Viewer's piano strip. [letter] accepts sharp or flat spelling.
  Future<void> playPitch(String letter, int programOctave,
      {double seconds = 0.9}) {
    return _play(ToneSynth.renderSequence([
      (freq: ToneSynth.frequency(letter, programOctave), seconds: seconds)
    ]));
  }

  /// Right-answer blip (ports rightanswersound): quick ascending two-tone.
  Future<void> playRight() {
    return _play(ToneSynth.renderSequence(const [
      (freq: 659.25, seconds: 0.12), // E5
      (freq: 880.0, seconds: 0.22), // A5
    ]));
  }

  /// Wrong-answer blip (ports wronganswersound): low single tone.
  Future<void> playWrong() {
    return _play(ToneSynth.renderSequence(const [
      (freq: 196.0, seconds: 0.32), // G3
    ]));
  }

  Future<void> _play(Uint8List wav) async {
    if (_disposed) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(wav));
    } catch (_) {
      // Audio is enhancement, never fatal: a quiz must survive a
      // missing audio route.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _player.dispose();
  }
}
