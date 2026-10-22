// Quiz question picker for Fretboard Spectrum.
//
// Ports SUB pickanote from Fretspc9_LARGE.BAS, including the strngstudy
// string scopes (1-17), the modifier accidental filter, and both
// anti-repeat guards (lastnote1/lastnote2 for IDs, lastname1$ for names).

import 'dart:math';

import 'note_mapper.dart';

/// Which strings a question may come from. Mirrors pickanote's strngstudy.
enum StringScope {
  string1,
  string2,
  string3,
  string4,
  string5,
  string6,
  string7,
  allStrings,
  strings1And2,
  strings3And4,
  strings5And6,
  strings6And7,
  strings1To3,
  strings2To4,
  strings3To5,
  strings4To6,
  strings5To7,
}

/// Accidental filter. Mirrors pickanote's modifier:
/// 1 = naturals only, 2 = sharps/flats only, 3 = everything.
enum AccidentalFilter { naturalsOnly, accidentalsOnly, all }

/// Inclusive note-ID range for a scope. The BASIC `-2` offset plus
/// reject-if-negative trick is exactly uniform over 0..N, so the range
/// is expressed directly.
({int start, int end}) _rangeFor(StringScope scope, bool sevenString) {
  switch (scope) {
    case StringScope.string1:
      return (start: 0, end: 24);
    case StringScope.string2:
      return (start: 25, end: 49);
    case StringScope.string3:
      return (start: 50, end: 74);
    case StringScope.string4:
      return (start: 75, end: 99);
    case StringScope.string5:
      return (start: 100, end: 124);
    case StringScope.string6:
      return (start: 125, end: 149);
    case StringScope.string7:
      return (start: 150, end: 174);
    case StringScope.allStrings:
      // BASIC CASE 8: 0..174 on 7-string, 0..149 on 6-string.
      return sevenString ? (start: 0, end: 174) : (start: 0, end: 149);
    case StringScope.strings1And2:
      return (start: 0, end: 49);
    case StringScope.strings3And4:
      return (start: 50, end: 99);
    case StringScope.strings5And6:
      return (start: 100, end: 149);
    case StringScope.strings6And7:
      return (start: 125, end: 174);
    case StringScope.strings1To3:
      return (start: 0, end: 74);
    case StringScope.strings2To4:
      return (start: 25, end: 99);
    case StringScope.strings3To5:
      return (start: 50, end: 124);
    case StringScope.strings4To6:
      return (start: 75, end: 149);
    case StringScope.strings5To7:
      return (start: 100, end: 174);
  }
}

/// Friendly display name for a string scope, taken from the
/// "You have chosen to study ..." lines in SUB lessonplan.
String stringScopeLabel(StringScope scope) => switch (scope) {
      StringScope.string1 => 'High E string (#1)',
      StringScope.string2 => 'String B (#2)',
      StringScope.string3 => 'String G (#3)',
      StringScope.string4 => 'String D (#4)',
      StringScope.string5 => 'String A (#5)',
      StringScope.string6 => 'Low E string (#6)',
      StringScope.string7 => 'Low B string (#7)',
      StringScope.allStrings => 'ALL strings',
      StringScope.strings1And2 => 'Strings 1 and 2 (E and B)',
      StringScope.strings3And4 => 'Strings 3 and 4 (G and D)',
      StringScope.strings5And6 => 'Strings 5 and 6 (A and Low E)',
      StringScope.strings6And7 => 'Strings 6 and 7 (Low E and Low B)',
      StringScope.strings1To3 => 'Strings 1, 2, and 3 (High E, B, G)',
      StringScope.strings2To4 => 'Strings 2, 3, and 4 (B, G, D)',
      StringScope.strings3To5 => 'Strings 3, 4, and 5 (G, D, A)',
      StringScope.strings4To6 => 'Strings 4, 5, and 6 (D, A, Low E)',
      StringScope.strings5To7 => 'Strings 5, 6, and 7 (A, E, Low B)',
    };

/// Picks random note IDs for quiz questions, mirroring pickanote.
///
/// Holds the anti-repeat state the BASIC program keeps in
/// lastnote1/lastnote2 (note IDs, two levels deep) and lastname1$
/// (note name, one level deep — always the sharp spelling, i.e. name$).
class QuizEngine {
  final Random _rng;
  int? _lastId1;
  int? _lastId2;
  String? _lastName;

  QuizEngine({Random? rng}) : _rng = rng ?? Random();

  /// Returns the next note ID. Re-picks internally until the ID is in
  /// scope, passes the accidental filter, and clears both repeat guards —
  /// exactly the GOTO-based rejection sampling in pickanote.
  int pickNext({
    required StringScope scope,
    required AccidentalFilter filter,
    required bool sevenString,
  }) {
    final range = _rangeFor(scope, sevenString);
    final span = range.end - range.start + 1;
    while (true) {
      final id = range.start + _rng.nextInt(span);
      if (filter == AccidentalFilter.naturalsOnly && isAccidental(id)) {
        continue;
      }
      if (filter == AccidentalFilter.accidentalsOnly && !isAccidental(id)) {
        continue;
      }
      if (id == _lastId1 || id == _lastId2) continue;
      // name$ guard: sharp spelling regardless of display setting.
      final name = playNameOf(id);
      if (name == _lastName) continue;
      _lastId2 = _lastId1;
      _lastId1 = id;
      _lastName = name;
      return id;
    }
  }

  /// Exposes the scope range for tests and UI (e.g. fretboard highlighting).
  ({int start, int end}) rangeFor(StringScope scope, bool sevenString) =>
      _rangeFor(scope, sevenString);
}
