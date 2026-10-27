// Widget tests for the corrected Real Guitar flow and the Spectrum
// Viewer "All octaves" mode.
//
// Real Guitar (per the QB64 original): the engine's note is highlighted
// on the fretboard in its octave color and its pitch is played; the
// player NAMES the note with letter buttons (A-G) plus a
// sharp/flat/natural toggle. Correct letter -> +1. Tapping the
// fretboard is not an answer input.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fretboard_spectrum/engine/note_mapper.dart';
import 'package:fretboard_spectrum/engine/quiz_engine.dart';
import 'package:fretboard_spectrum/ui/painters/fretboard_painter.dart';
import 'package:fretboard_spectrum/ui/screens/quiz_screen.dart';
import 'package:fretboard_spectrum/ui/screens/viewer_screen.dart';

const _seed = 20261022;

QuizConfig _realGuitarConfig({
  AccidentalFilter filter = AccidentalFilter.naturalsOnly,
}) =>
    QuizConfig(
      leftHanded: false,
      sevenString: false,
      mode: QuizMode.realGuitar,
      accidentalFilter: filter,
      sharps: false,
      reps: 3,
    );

/// The target the seeded engine picks first, mirroring what QuizScreen's
/// own engine will pick in initState.
int _expectedTarget(AccidentalFilter filter) =>
    QuizEngine(rng: Random(_seed)).pickNext(
      scope: StringScope.allStrings,
      filter: filter,
      sevenString: false,
    );

Future<void> _pumpRealGuitar(
  WidgetTester tester, {
  AccidentalFilter filter = AccidentalFilter.naturalsOnly,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: QuizScreen(
        config: _realGuitarConfig(filter: filter),
        engine: QuizEngine(rng: Random(_seed)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'real guitar: the target is highlighted while answering, '
      'and the fretboard is not a tap input', (tester) async {
    await _pumpRealGuitar(tester);
    final targetId = _expectedTarget(AccidentalFilter.naturalsOnly);

    final board =
        tester.widget<FretboardBoard>(find.byType(FretboardBoard));
    // The highlight IS the question: visible before any answer.
    expect(board.highlightedId, targetId);
    // Naming replaced tapping: no tap handler is wired.
    expect(board.onNoteTapped, isNull);
  });

  testWidgets('real guitar: correct letter scores +1', (tester) async {
    await _pumpRealGuitar(tester);
    final targetId = _expectedTarget(AccidentalFilter.naturalsOnly);
    final targetLetter = letterOf(targetId, sharps: false);

    await tester.tap(find.text(targetLetter));
    await tester.pump();
    await tester.tap(find.text('Check answer'));
    await tester.pump();

    expect(find.textContaining('Correct!'), findsOneWidget);
    expect(find.textContaining('(+1.0)'), findsOneWidget);
  });

  testWidgets(
      'real guitar: wrong letter scores 0 and leaves a footprint',
      (tester) async {
    await _pumpRealGuitar(tester);
    final targetId = _expectedTarget(AccidentalFilter.naturalsOnly);
    final targetLetter = letterOf(targetId, sharps: false);
    final wrongLetter =
        ['A', 'B', 'C', 'D', 'E', 'F', 'G'].firstWhere(
      (l) => l != targetLetter,
    );

    await tester.tap(find.text(wrongLetter));
    await tester.pump();
    await tester.tap(find.text('Check answer'));
    await tester.pump();

    expect(find.textContaining('Not quite'), findsOneWidget);
    expect(find.textContaining('(+0.0)'), findsOneWidget);
    final board =
        tester.widget<FretboardBoard>(find.byType(FretboardBoard));
    expect(board.footprintIds, contains(targetId));
  });

  testWidgets('real guitar: sharp answer via the toggle scores',
      (tester) async {
    await _pumpRealGuitar(tester, filter: AccidentalFilter.all);
    final targetId = _expectedTarget(AccidentalFilter.all);
    // Sharp-spelled canonical pitch class, e.g. 'A#' or 'G'.
    final pitchClass = playNameOf(targetId);
    final letter = pitchClass[0];
    final needsSharp = pitchClass.length > 1;

    await tester.tap(find.text(letter));
    await tester.pump();
    if (needsSharp) {
      await tester.tap(find.text('♯ Sharp'));
      await tester.pump();
    }
    await tester.tap(find.text('Check answer'));
    await tester.pump();

    expect(find.textContaining('Correct!'), findsOneWidget);
    expect(find.textContaining('(+1.0)'), findsOneWidget);
  });

  testWidgets(
      'viewer: All option highlights every octave in its own color '
      'and keeps tap-to-hear', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ViewerScreen(
          leftHanded: false,
          sevenString: false,
          sharps: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sanity: single-octave mode shows a strict subset.
    var board =
        tester.widget<FretboardBoard>(find.byType(FretboardBoard));
    final singleCount = board.spectrumIds.length;
    expect(singleCount, greaterThan(0));

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    board = tester.widget<FretboardBoard>(find.byType(FretboardBoard));
    final expected = [
      for (var o = -1; o <= 4; o++)
        ...idsInOctave(o, sevenString: false),
    ];
    expect(board.spectrumIds.length, expected.length);
    expect(board.spectrumIds.length, greaterThan(singleCount));
    expect(board.spectrumIds.toSet(), expected.toSet());
    // Tap-to-hear stays wired in All mode.
    expect(board.onNoteTapped, isNotNull);
    // The per-octave piano strip is hidden when no single octave
    // is selected.
    expect(find.text('C'), findsNothing);
  });
}
