// Phase 3 tests: viewer logic, lesson labels, persistence.
//
// Covers the pure-Dart additions behind the Spectrum Viewer, lesson
// plan, and session history. Widget/painter code is exercised through
// these units; the screens themselves follow the patterns already
// tested in board_tap_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:fretboard_spectrum/data/session_history.dart';
import 'package:fretboard_spectrum/data/session_record.dart';
import 'package:fretboard_spectrum/engine/note_mapper.dart';
import 'package:fretboard_spectrum/engine/quiz_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('viewer logic', () {
    test('octave note distribution matches the BASIC statistics table', () {
      // SUB printoctavestatistics, 6-string: -1:0, 0:11, 1:40, 2:59, 3:35, 4:5
      const expected = {-1: 0, 0: 11, 1: 40, 2: 59, 3: 35, 4: 5};
      for (final e in expected.entries) {
        expect(
          idsInOctave(e.key, sevenString: false),
          hasLength(e.value),
          reason: 'octave ${e.key}',
        );
      }
    });

    test('7-string adds the sub-bass B to octave -1', () {
      final ids = idsInOctave(-1, sevenString: true);
      expect(ids, [150]);
    });

    test('octave ids are ascending and within the guitar range', () {
      for (var o = -1; o <= 4; o++) {
        final ids = idsInOctave(o, sevenString: true);
        expect(ids, orderedEquals(ids..sort()));
        for (final id in ids) {
          expect(octaveOf(id), o);
          expect(id, inInclusiveRange(0, 174));
        }
      }
    });

    test('register names cover all octaves', () {
      expect(octaveRegisterName(-1), 'Low Bass');
      expect(octaveRegisterName(0), 'Bass');
      expect(octaveRegisterName(1), 'Middle Range');
      expect(octaveRegisterName(2), 'Upper Middle');
      expect(octaveRegisterName(3), 'Treble');
      expect(octaveRegisterName(4), 'High Treble');
    });
  });

  group('lesson labels', () {
    test('all 17 scopes have a non-empty label', () {
      for (final s in StringScope.values) {
        expect(stringScopeLabel(s), isNotEmpty, reason: '$s');
      }
    });

    test('labels match the BASIC lessonplan wording', () {
      expect(stringScopeLabel(StringScope.string1), 'High E string (#1)');
      expect(stringScopeLabel(StringScope.allStrings), 'ALL strings');
      expect(stringScopeLabel(StringScope.strings1To3),
          'Strings 1, 2, and 3 (High E, B, G)');
      expect(stringScopeLabel(StringScope.strings5To7),
          'Strings 5, 6, and 7 (A, E, Low B)');
    });
  });

  group('session record', () {
    test('json round-trip preserves every field', () {
      final r = SessionRecord(
        date: DateTime.utc(2026, 10, 21, 17, 30),
        reps: 20,
        points: 17.5,
        mode: SessionMode.airGuitar,
        missedIds: [3, 42, 150],
        sevenString: true,
      );
      final back = SessionRecord.fromJson(r.toJson());
      expect(back.date, r.date);
      expect(back.reps, 20);
      expect(back.points, 17.5);
      expect(back.percent, 87); // INT(17.5 / 20 * 100), like SUB statistics
      expect(back.mode, SessionMode.airGuitar);
      expect(back.missedIds, [3, 42, 150]);
      expect(back.sevenString, isTrue);
    });

    test('missing sevenString defaults to false', () {
      final json = {
        'date': '2026-10-21T17:30:00.000Z',
        'reps': 10,
        'points': 8.0,
        'mode': 'realGuitar',
        'missedIds': <int>[],
      };
      expect(SessionRecord.fromJson(json).sevenString, isFalse);
    });
  });

  group('session history', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    SessionRecord rec(DateTime d, List<int> missed, {double points = 10}) =>
        SessionRecord(
          date: d,
          reps: 20,
          points: points,
          mode: SessionMode.realGuitar,
          missedIds: missed,
          sevenString: false,
        );

    test('add then load returns newest-first', () async {
      final h = await SessionHistory.load();
      await h.add(rec(DateTime.utc(2026, 10, 20), [1]));
      await h.add(rec(DateTime.utc(2026, 10, 21), [2]));
      final sessions = (await SessionHistory.load()).sessions;
      expect(sessions, hasLength(2));
      expect(sessions.first.date.day, 21);
      expect(sessions.last.date.day, 20);
    });

    test('weakSpotIds aggregates and dedupes misses', () async {
      final h = await SessionHistory.load();
      await h.add(rec(DateTime.utc(2026, 10, 20), [1, 5, 9]));
      await h.add(rec(DateTime.utc(2026, 10, 21), [5, 42]));
      final fresh = await SessionHistory.load();
      expect(fresh.weakSpotIds, [1, 5, 9, 42]);
    });

    test('corrupt entries are skipped, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        SessionHistory.storageKey: '["not a record object"]',
      });
      final h = await SessionHistory.load();
      expect(h.sessions, isEmpty);
    });

    test('clear wipes the history', () async {
      final h = await SessionHistory.load();
      await h.add(rec(DateTime.utc(2026, 10, 21), [1]));
      await h.clear();
      expect((await SessionHistory.load()).sessions, isEmpty);
    });
  });
}
