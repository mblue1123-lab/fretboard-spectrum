// Unit tests for the Fretboard Spectrum Phase 1 engine.
// The oracle for every expectation is Fretspc9_LARGE.BAS, via
// Fretboard-Spectrum-Note-Mapping-and-Scoring.md.

import 'dart:math';

import 'package:test/test.dart';

import 'package:fretboard_spectrum/engine/answer_normalizer.dart';
import 'package:fretboard_spectrum/engine/note_mapper.dart';
import 'package:fretboard_spectrum/engine/note_tables.dart';
import 'package:fretboard_spectrum/engine/quiz_engine.dart';
import 'package:fretboard_spectrum/engine/scorer.dart';
import 'package:fretboard_spectrum/engine/session.dart';

void main() {
  group('note tables (generated from BASIC source)', () {
    test('all 175 IDs resolve to a letter and octave in both tables', () {
      for (var id = 0; id < 175; id++) {
        expect(letterByIdFlats[id], isNotNull, reason: 'flats id $id');
        expect(letterByIdSharps[id], isNotNull, reason: 'sharps id $id');
        expect(octaveById[id], isNotNull, reason: 'octave id $id');
        expect(fsById[id], isNotNull, reason: 'fs id $id');
      }
    });

    test('accidental-ness is consistent across both spelling tables', () {
      for (var id = 0; id < 175; id++) {
        final flat = letterByIdFlats[id]!;
        final sharp = letterByIdSharps[id]!;
        if (fsById[id] != 0) {
          // Same pitch, two spellings.
          expect(flat.endsWith('b'), isTrue, reason: 'id $id');
          expect(sharp.endsWith('#'), isTrue, reason: 'id $id');
        } else {
          expect(flat, sharp, reason: 'natural id $id');
        }
      }
    });

    test('octave distribution on 6-string matches printoctavestatistics', () {
      // Doc: -1:0, 0:11, 1:40, 2:59, 3:35, 4:5 (150 notes).
      final counts = <int, int>{for (var o = -1; o <= 4; o++) o: 0};
      for (var id = 0; id < 150; id++) {
        counts[octaveById[id]!] = counts[octaveById[id]!]! + 1;
      }
      expect(counts, {-1: 0, 0: 11, 1: 40, 2: 59, 3: 35, 4: 5});
    });

    test('octave distribution on 7-string matches printoctavestatistics', () {
      // Doc: -1:1, 0:23, 1:52, 2:59, 3:35, 4:5 (175 notes).
      final counts = <int, int>{for (var o = -1; o <= 4; o++) o: 0};
      for (var id = 0; id < 175; id++) {
        counts[octaveById[id]!] = counts[octaveById[id]!]! + 1;
      }
      expect(counts, {-1: 1, 0: 23, 1: 52, 2: 59, 3: 35, 4: 5});
    });
  });

  group('note mapper', () {
    test('spot checks from the doc', () {
      // id 0: open high E, octave 2.
      expect(letterOf(0), 'E');
      expect(stringOf(0), 1);
      expect(fretOf(0), 0);
      expect(octaveOf(0), 2);
      // id 150: open low B on the 7-string, octave -1.
      expect(octaveOf(150), -1);
      expect(stringOf(150), 7);
      // id 24: 24th fret high E, octave 4.
      expect(letterOf(24), 'E');
      expect(octaveOf(24), 4);
      expect(fretOf(24), 24);
      // id 8: C, octave 3.
      expect(letterOf(8), 'C');
      expect(octaveOf(8), 3);
    });

    test('string and fret arithmetic across all IDs', () {
      for (var id = 0; id < 175; id++) {
        expect(stringOf(id), id ~/ 25 + 1);
        expect(fretOf(id), id % 25);
      }
    });

    test('sharps spelling differs from flats only on accidentals', () {
      for (var id = 0; id < 175; id++) {
        if (isAccidental(id)) {
          expect(letterOf(id, sharps: true).endsWith('#'), isTrue);
          expect(letterOf(id).endsWith('b'), isTrue);
        } else {
          expect(letterOf(id, sharps: true), letterOf(id));
        }
      }
    });

    test('octave colors cover octaves -1..4', () {
      for (var o = -1; o <= 4; o++) {
        expect(colorOfOctave(o), isNotNull);
      }
      // Spot-check the palette mapping from assignoctave.
      expect(paletteOfOctave(-1), 7);
      expect(paletteOfOctave(0), 12);
      expect(paletteOfOctave(1), 14);
      expect(paletteOfOctave(2), 10);
      expect(paletteOfOctave(3), 11);
      expect(paletteOfOctave(4), 13);
    });
  });

  group('answer normalizer', () {
    test('typo variants resolve to canonical names', () {
      expect(normalizeAnswer('asharp'), 'A#');
      expect(normalizeAnswer('a sharp'), 'A#');
      expect(normalizeAnswer('A#'), 'A#');
      expect(normalizeAnswer('db'), 'Db');
      expect(normalizeAnswer('d flat'), 'Db');
      expect(normalizeAnswer('g'), 'G');
      expect(normalizeAnswer('  G  '), 'G');
      expect(normalizeAnswer('Bb'), 'Bb');
    });

    test('unknown input returns null', () {
      expect(normalizeAnswer('nonsense'), isNull);
      expect(normalizeAnswer(''), isNull);
      expect(normalizeAnswer('h#'), isNull);
    });

    test('accidental helpers', () {
      expect(isSharpName('A#'), isTrue);
      expect(isSharpName('Bb'), isFalse);
      expect(isFlatName('Bb'), isTrue);
      expect(isFlatName('B'), isFalse); // natural B is not a flat
      expect(isFlatName('A#'), isFalse);
      expect(isNaturalName('G'), isTrue);
      expect(isNaturalName('Db'), isFalse);
    });
  });

  group('scorer', () {
    test('air guitar partial-credit matrix', () {
      expect(scoreAirGuitar(letterCorrect: true, octaveCorrect: true), 1.0);
      expect(scoreAirGuitar(letterCorrect: true, octaveCorrect: false), 0.5);
      expect(scoreAirGuitar(letterCorrect: false, octaveCorrect: true), 0.5);
      expect(scoreAirGuitar(letterCorrect: false, octaveCorrect: false), 0.0);
    });

    test('real guitar scoring', () {
      expect(scoreRealGuitar(letterCorrect: true), 1.0);
      expect(scoreRealGuitar(letterCorrect: false), 0.0);
    });
  });

  group('quiz engine', () {
    test('naturalsOnly filter never returns accidentals (500 picks)', () {
      final engine = QuizEngine(rng: Random(42));
      for (var i = 0; i < 500; i++) {
        final id = engine.pickNext(
          scope: StringScope.allStrings,
          filter: AccidentalFilter.naturalsOnly,
          sevenString: true,
        );
        expect(isAccidental(id), isFalse, reason: 'id $id');
      }
    });

    test('accidentalsOnly filter never returns naturals (500 picks)', () {
      final engine = QuizEngine(rng: Random(7));
      for (var i = 0; i < 500; i++) {
        final id = engine.pickNext(
          scope: StringScope.allStrings,
          filter: AccidentalFilter.accidentalsOnly,
          sevenString: true,
        );
        expect(isAccidental(id), isTrue, reason: 'id $id');
      }
    });

    test('picks stay within the scope range', () {
      final engine = QuizEngine(rng: Random(1));
      final cases = {
        StringScope.string1: (0, 24),
        StringScope.string7: (150, 174),
        StringScope.strings1And2: (0, 49),
        StringScope.strings3To5: (50, 124),
      };
      cases.forEach((scope, bounds) {
        for (var i = 0; i < 100; i++) {
          final id = engine.pickNext(
            scope: scope,
            filter: AccidentalFilter.all,
            sevenString: true,
          );
          expect(id, inInclusiveRange(bounds.$1, bounds.$2));
        }
      });
    });

    test('allStrings respects the 6/7-string guitar setting', () {
      final engine = QuizEngine(rng: Random(3));
      for (var i = 0; i < 200; i++) {
        final id = engine.pickNext(
          scope: StringScope.allStrings,
          filter: AccidentalFilter.all,
          sevenString: false,
        );
        expect(id, inInclusiveRange(0, 149));
      }
    });

    test('no immediate ID or name repeats across 200 picks', () {
      final engine = QuizEngine(rng: Random(99));
      int? prev1;
      int? prev2;
      String? prevName;
      for (var i = 0; i < 200; i++) {
        final id = engine.pickNext(
          scope: StringScope.allStrings,
          filter: AccidentalFilter.all,
          sevenString: true,
        );
        expect(id, isNot(equals(prev1)), reason: 'id repeated');
        expect(id, isNot(equals(prev2)), reason: 'id repeated 2-deep');
        // Name guard uses the sharp spelling (name$ in BASIC).
        expect(playNameOf(id), isNot(equals(prevName)),
            reason: 'name repeated');
        prev2 = prev1;
        prev1 = id;
        prevName = playNameOf(id);
      }
    });
  });

  group('session', () {
    test('percent math on a known answer sequence', () {
      final session = Session(10);
      // 7 right, 3 wrong in Real Guitar Mode.
      for (var i = 0; i < 7; i++) {
        session.recordAnswer(scoreRealGuitar(letterCorrect: true));
      }
      for (var i = 0; i < 3; i++) {
        session.recordAnswer(scoreRealGuitar(letterCorrect: false));
      }
      expect(session.points, 7.0);
      expect(session.theoscore, 10);
      expect(session.repsLeft, 0);
      expect(session.isComplete, isTrue);
      expect(session.percentCorrect, 70);
    });

    test('partial credit flows into the percent', () {
      final session = Session(4);
      session.recordAnswer(
          scoreAirGuitar(letterCorrect: true, octaveCorrect: true)); // 1.0
      session.recordAnswer(
          scoreAirGuitar(letterCorrect: true, octaveCorrect: false)); // 0.5
      session.recordAnswer(
          scoreAirGuitar(letterCorrect: false, octaveCorrect: true)); // 0.5
      session.recordAnswer(
          scoreAirGuitar(letterCorrect: false, octaveCorrect: false)); // 0.0
      expect(session.points, 2.0);
      expect(session.percentCorrect, 50);
      expect(session.repsLeft, 0);
    });
  });
}
