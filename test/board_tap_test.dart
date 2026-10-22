// Widget test: taps on the fretboard resolve to the right note IDs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fretboard_spectrum/ui/painters/fretboard_geometry.dart';
import 'package:fretboard_spectrum/ui/painters/fretboard_painter.dart';

void main() {
  testWidgets('tapping a marker reports its note ID', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 850,
            child: FretboardBoard(
              sevenString: false,
              leftHanded: false,
              onNoteTapped: (id) => tapped = id,
            ),
          ),
        ),
      ),
    );

    // Tap the marker for note id 60 (string 3, fret 10).
    const size = Size(200, 850);
    final logical = FretboardGeometry.markerLogical(
      60,
      sevenString: false,
      leftHanded: false,
    );
    final local = FretboardPainter.toScreen(logical, size);
    final topLeft = tester.getTopLeft(find.byType(FretboardBoard));
    await tester.tapAt(topLeft + local);
    await tester.pump();
    expect(tapped, 60);
  });

  testWidgets('tapping between zones snaps to the nearest note ID',
      (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 850,
            child: FretboardBoard(
              sevenString: true,
              leftHanded: true,
              onNoteTapped: (id) => tapped = id,
            ),
          ),
        ),
      ),
    );

    // A point 2 logical units right of string 1's column (x=390) still
    // belongs to string 1 (columns are 10 apart).
    const size = Size(200, 850);
    final local = FretboardPainter.toScreen(
        (x: 392.0, y: 207.0), size); // near 12th-fret marker row
    final topLeft = tester.getTopLeft(find.byType(FretboardBoard));
    await tester.tapAt(topLeft + local);
    await tester.pump();
    // string 1, fret 12 -> id 12 on a 7-string board.
    expect(tapped, 12);
  });

  testWidgets('board without a tap handler does not crash on tap',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 850,
            child: FretboardBoard(
              sevenString: false,
              leftHanded: false,
              highlightedId: 42,
              footprintIds: [7, 100],
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(100, 400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
