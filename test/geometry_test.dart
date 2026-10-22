// Widget tests for the fretboard painter's coordinate math.
//
// Verifies the full chain the tap-to-answer quiz relies on:
//   note ID -> marker position -> screen position -> back to note ID
// for every ID, in all four board configurations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fretboard_spectrum/ui/painters/fretboard_geometry.dart';
import 'package:fretboard_spectrum/ui/painters/fretboard_painter.dart';

void main() {
  group('fret wire math (ports SUB drawfretboard)', () {
    test('26 wires from nut (13) to board end (327)', () {
      final wires = FretboardGeometry.fretWireY;
      expect(wires.length, 26);
      expect(wires.first, 13.0);
      expect(wires.last, 327.0);
    });

    test('first fret wire lands at 33 (13 + 20)', () {
      expect(FretboardGeometry.fretWireY[1], 33.0);
    });
  });

  group('marker table (ports SUB highlitenoteonfretboard ylite)', () {
    test('25 entries, open string above the nut', () {
      expect(FretboardGeometry.fretMarkerY.length, 25);
      expect(FretboardGeometry.fretMarkerY[0], 8.0);
    });

    test('markers sit between their fret wires (within 1.0)', () {
      final wires = FretboardGeometry.fretWireY;
      // Fret f's marker sits between wire[f-1] and wire[f]
      // (wire[0] is the nut, wire[i>=1] is the fret-i wire).
      for (var f = 1; f < 25; f++) {
        final mid = (wires[f - 1] + wires[f]) / 2;
        expect(
          (FretboardGeometry.fretMarkerY[f] - mid).abs(),
          lessThan(1.0),
          reason: 'fret $f marker ${FretboardGeometry.fretMarkerY[f]} '
              'vs wire midpoint $mid',
        );
      }
    });

    test('12th fret marker matches the inlay row', () {
      expect(FretboardGeometry.fretMarkerY[12],
          FretboardGeometry.inlayFret12Y);
    });
  });

  group('string columns (ports the xlite SELECT CASEs)', () {
    test('right-handed: string 1 at x=450 down to string 7 at x=390', () {
      expect(
          FretboardGeometry.stringX(1,
              sevenString: true, leftHanded: false),
          450.0);
      expect(
          FretboardGeometry.stringX(7,
              sevenString: true, leftHanded: false),
          390.0);
    });

    test('left-handed mirrors: 6-string 400..450, 7-string 390..450', () {
      expect(
          FretboardGeometry.stringX(1,
              sevenString: false, leftHanded: true),
          400.0);
      expect(
          FretboardGeometry.stringX(6,
              sevenString: false, leftHanded: true),
          450.0);
      expect(
          FretboardGeometry.stringX(1,
              sevenString: true, leftHanded: true),
          390.0);
    });
  });

  group('screen transform', () {
    test('toScreen/toLogical invert each other', () {
      const size = Size(200, 850);
      const logical = (x: 425.0, y: 207.0);
      final back =
          FretboardPainter.toLogical(FretboardPainter.toScreen(logical, size), size);
      expect((back.x - logical.x).abs(), lessThan(1e-9));
      expect((back.y - logical.y).abs(), lessThan(1e-9));
    });
  });

  group('note ID round-trips', () {
    void checkAll({required bool sevenString, required bool leftHanded}) {
      const size = Size(200, 850);
      final maxId = sevenString ? 174 : 149;
      for (var id = 0; id <= maxId; id++) {
        final logical = FretboardGeometry.markerLogical(
          id,
          sevenString: sevenString,
          leftHanded: leftHanded,
        );
        final screen = FretboardPainter.toScreen(logical, size);
        final back =
            FretboardPainter.toLogical(screen, size);
        final roundTripped = FretboardGeometry.noteIdAtLogical(
          back.x,
          back.y,
          sevenString: sevenString,
          leftHanded: leftHanded,
        );
        expect(roundTripped, id,
            reason:
                'id $id (7-string: $sevenString, left: $leftHanded)');
      }
    }

    test('6-string right-handed', () {
      checkAll(sevenString: false, leftHanded: false);
    });
    test('6-string left-handed', () {
      checkAll(sevenString: false, leftHanded: true);
    });
    test('7-string right-handed', () {
      checkAll(sevenString: true, leftHanded: false);
    });
    test('7-string left-handed', () {
      checkAll(sevenString: true, leftHanded: true);
    });

    test('out-of-board taps return null', () {
      expect(
          FretboardGeometry.noteIdAtLogical(100, 100,
              sevenString: false, leftHanded: false),
          isNull);
      expect(
          FretboardGeometry.noteIdAtLogical(420, 999,
              sevenString: false, leftHanded: false),
          isNull);
    });
  });
}
