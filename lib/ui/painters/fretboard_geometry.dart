// Logical-space geometry for the Fretboard Spectrum fretboard painter.
//
// Pure Dart — no Flutter imports — so the coordinate math is unit-testable.
//
// The logical space ports the QB64 program's coordinates 1:1:
// strings live at x = 390..450 (SUB drawfretboard), the nut at y = 13,
// the board end at y = 327, and each fret marker sits at the
// (xlite, ylite) position computed by SUB highlitenoteonfretboard.

/// A point in logical fretboard space.
typedef LPoint = ({double x, double y});

class FretboardGeometry {
  // Logical bounds, with margin for the open-string marker (y = 8, above
  // the nut) and the marker radius.
  static const double minX = 380.0;
  static const double maxX = 460.0;
  static const double minY = -5.0;
  static const double maxY = 335.0;

  /// Y of the nut (fret-0 wire). Ports y1 / the c = 13 init in
  /// SUB drawfretboard.
  static const double nutY = 13.0;

  /// Y of the board end (y2 in SUB drawfretboard).
  static const double endY = 327.0;

  /// Per-fret spacing increments for d = 2..26 in SUB drawfretboard.
  /// "AS YOU TRAVEL DOWN THE NECK, THE DISTANCE BECOMES LESS AND LESS"
  static const List<double> fretSpacings = [
    20, 20, // d = 2, 3
    18, 18, 18, // d = 4, 5, 6
    16, 16, 16, // d = 7, 8, 9
    15, 15, 15, // d = 10, 11, 12
    13, 13, 13, // d = 13, 14, 15
    10, 10, // d = 16, 17
    9, 9, // d = 18, 19
    8, 8, 8, 8, // d = 20, 21, 22, 23
    7, 7, // d = 24, 25
    4, // d = 26 (board end line)
  ];

  /// Y positions of the 26 wires: the nut, frets 1..24, then the board end.
  /// fretWireY[0] is the nut; fretWireY[i] (i >= 1) is the fret-i wire.
  /// Fret f's marker (f = 1..24) sits between fretWireY[f - 1] and
  /// fretWireY[f]; the open-string marker sits above the nut at y = 8.
  static List<double> get fretWireY {
    final wires = <double>[nutY];
    var c = nutY;
    for (final s in fretSpacings) {
      c += s;
      wires.add(c);
    }
    return wires;
  }

  /// Marker Y per fret — the ylite table from SUB highlitenoteonfretboard.
  /// This is the ground truth for where note dots sit (fret 0 is the open
  /// string, drawn above the nut).
  static const List<double> fretMarkerY = [
    8, // open string
    23, 43, 62, 80, 98, 115, 131, 147, 163, 178, 193, 207,
    220, 233, 244, 254, 264, 272, 281, 289, 297, 305, 313, 320,
  ];

  /// X of a string column. Ports the xlite SELECT CASEs in SUB
  /// highlitenoteonfretboard: right-handed runs 450 (string 1) down to 390;
  /// left-handed mirrors (400..450 on 6-string, 390..450 on 7-string).
  static double stringX(
    int string, {
    required bool sevenString,
    required bool leftHanded,
  }) {
    assert(string >= 1 && string <= (sevenString ? 7 : 6));
    if (leftHanded) {
      final xMin = sevenString ? 390.0 : 400.0;
      return xMin + (string - 1) * 10.0;
    }
    return 450.0 - (string - 1) * 10.0;
  }

  /// Logical position of a note ID's marker: xlite from the string,
  /// ylite from the fret.
  static LPoint markerLogical(
    int noteId, {
    required bool sevenString,
    required bool leftHanded,
  }) {
    final string = noteId ~/ 25 + 1;
    final fret = noteId % 25;
    return (
      x: stringX(string, sevenString: sevenString, leftHanded: leftHanded),
      y: fretMarkerY[fret],
    );
  }

  /// Inverse of [markerLogical]: the nearest note ID for a logical tap
  /// position, or null when the tap is outside the board.
  ///
  /// Nearest zone wins — there are no dead areas, so every tap on the
  /// board resolves to the closest string column and fret marker. This
  /// makes finger taps meaningful despite the small logical zones.
  static int? noteIdAtLogical(
    double x,
    double y, {
    required bool sevenString,
    required bool leftHanded,
  }) {
    if (x < minX || x > maxX || y < minY || y > maxY) return null;
    final nStrings = sevenString ? 7 : 6;
    var bestString = 1;
    var bestDx = double.infinity;
    for (var s = 1; s <= nStrings; s++) {
      final dx =
          (x - stringX(s, sevenString: sevenString, leftHanded: leftHanded))
              .abs();
      if (dx < bestDx) {
        bestDx = dx;
        bestString = s;
      }
    }
    var bestFret = 0;
    var bestDy = double.infinity;
    for (var f = 0; f < 25; f++) {
      final dy = (y - fretMarkerY[f]).abs();
      if (dy < bestDy) {
        bestDy = dy;
        bestFret = f;
      }
    }
    return (bestString - 1) * 25 + bestFret;
  }

  /// Single-dot inlay Y positions from SUB drawinlays
  /// (frets 3, 5, 7, 9, 15, 17, 19, 21).
  static const List<double> inlayY = [62, 98, 131, 163, 244, 264, 281, 297];

  /// Double-dot inlay rows (12th and 24th frets).
  static const double inlayFret12Y = 207.0;
  static const double inlayFret24Y = 319.0;
}
