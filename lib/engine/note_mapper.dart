// Pure-Dart note mapping for Fretboard Spectrum.
//
// Ports SUB assignstrngnumber, assignfretnumber, assignletter and
// assignoctave from Fretspc9_LARGE.BAS. All data lives in the generated
// note_tables.dart; this file is the arithmetic + lookup layer.
//
// Note ID space: 0-174. Each string owns 25 consecutive IDs
// (open string + 24 frets):
//   string 1 (high E): 0-24, 2 (B): 25-49, 3 (G): 50-74, 4 (D): 75-99,
//   5 (A): 100-124, 6 (low E): 125-149, 7 (low B): 150-174.

import 'note_tables.dart';

/// String number (1-7) for a note ID. Mirrors assignstrngnumber.
int stringOf(int id) {
  assert(id >= 0 && id < 175, 'note id out of range: $id');
  return id ~/ 25 + 1;
}

/// Fret number (0-24) for a note ID. Mirrors assignfretnumber
/// (id 0 of each string block is the open string).
int fretOf(int id) {
  assert(id >= 0 && id < 175, 'note id out of range: $id');
  return id % 25;
}

/// Display/answer name for a note ID. Mirrors assignletter's letter$.
/// [sharps]=false uses the flats spelling (flatsharp 0/1), true uses the
/// sharps spelling (flatsharp 2).
String letterOf(int id, {bool sharps = false}) {
  assert(id >= 0 && id < 175, 'note id out of range: $id');
  return sharps ? letterByIdSharps[id]! : letterByIdFlats[id]!;
}

/// The name handed to PLAY in the BASIC program (name$).
/// In assignletter, name$ is always the sharp spelling regardless of the
/// flats/sharps display setting, so this is just the sharps table.
String playNameOf(int id) {
  assert(id >= 0 && id < 175, 'note id out of range: $id');
  return letterByIdSharps[id]!;
}

/// Octave (-1..4) for a note ID. Mirrors assignoctave.
int octaveOf(int id) {
  assert(id >= 0 && id < 175, 'note id out of range: $id');
  return octaveById[id]!;
}

/// True when the note is a sharp/flat (fs != 0 in assignletter).
/// Mirrors the `modifier` filter in pickanote.
bool isAccidental(int id) {
  assert(id >= 0 && id < 175, 'note id out of range: $id');
  return fsById[id]! != 0;
}

/// Display color for an octave as 0xAARRGGBB.
/// Mirrors assignoctave's octcolor mapping.
int colorOfOctave(int octave) => octaveColorArgb[octave]!;

/// Original SCREEN 9 palette number for an octave.
int paletteOfOctave(int octave) => octaveColorPalette[octave]!;

/// All note IDs in [octave] (-1..4), ascending. Mirrors the octave
/// distribution table in SUB printoctavestatistics: a 6-string guitar
/// holds 150 notes (ids 0-149), a 7-string 175 (ids 0-174).
List<int> idsInOctave(int octave, {required bool sevenString}) {
  final max = sevenString ? 174 : 149;
  final ids = <int>[];
  for (var id = 0; id <= max; id++) {
    if (octaveOf(id) == octave) ids.add(id);
  }
  return ids;
}

/// Register name for an octave, from SUB printoctavestatistics
/// ("Low Bass" .. "High Treble").
String octaveRegisterName(int octave) => switch (octave) {
      -1 => 'Low Bass',
      0 => 'Bass',
      1 => 'Middle Range',
      2 => 'Upper Middle',
      3 => 'Treble',
      4 => 'High Treble',
      _ => throw ArgumentError('octave out of range: $octave'),
    };
