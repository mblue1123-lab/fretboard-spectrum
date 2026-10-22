// Answer input normalization for Fretboard Spectrum.
//
// Ports the TYPO FILTER in SUB questionscreen: the program lowercases the
// player's typed answer, then maps dozens of spelling variants
// ("a sharp", "asharp", "a#", "a3", "a s" ...) to canonical note names.
// The variant table is machine-extracted from the BASIC source
// (see note_tables.dart).

import 'note_tables.dart';

/// Normalizes raw player input to a canonical note name ("A#", "Db", "G",
/// ...), or null when the input matches nothing.
///
/// Mirrors questionscreen: input is trimmed and lowercased before lookup.
String? normalizeAnswer(String rawInput) {
  final key = rawInput.trim().toLowerCase();
  if (key.isEmpty) return null;
  return typoVariants[key];
}

/// True for sharp-spelled names ("A#", "C#"...).
/// Used for the flatsharp consistency check: in flats mode a sharp-spelled
/// answer is re-asked, not marked wrong.
bool isSharpName(String name) => name.endsWith('#');

/// True for flat-spelled names ("Bb", "Db"...).
/// Used for the flatsharp consistency check: in sharps mode a flat-spelled
/// answer is re-asked, not marked wrong.
bool isFlatName(String name) => name.length > 1 && name.endsWith('b');

/// True for natural names ("A".."G").
bool isNaturalName(String name) => !isSharpName(name) && !isFlatName(name);
