// Fretboard renderer for Fretboard Spectrum.
//
// Ports SUB drawfretboard, SUB drawinlays, SUB highlitenoteonfretboard and
// the footprint half of SUB erasehighlitednote from Fretspc9_LARGE.BAS.
//
// The painter draws in the logical coordinate space defined by
// FretboardGeometry (the QB64 program's coordinates 1:1) and scales it to
// fit the widget width, preserving aspect ratio. Screen <-> logical
// conversion is exposed as static helpers so taps can be mapped back to
// note IDs and the whole transform stays unit-testable.

import 'package:flutter/material.dart';

import '../../engine/note_mapper.dart';
import 'fretboard_geometry.dart';

/// Draws the fretboard: strings, frets, inlays, footprints, highlight.
class FretboardPainter extends CustomPainter {
  final bool sevenString;
  final bool leftHanded;

  /// Note ID to highlight in its octave color (the quiz target, shown only
  /// in feedback — never while the player is answering in tap mode).
  final int? highlightedId;

  /// Missed note IDs, drawn as persistent brown markers (Footprints).
  final List<int> footprintIds;
  final bool showFootprints;

  /// Note IDs drawn filled in their own octave colors — the Spectrum
  /// Viewer mode (ports the rainbow octave lines of SUB rainbowgraphics).
  /// Independent of [highlightedId]; both may be set at once.
  final List<int> spectrumIds;

  const FretboardPainter({
    required this.sevenString,
    required this.leftHanded,
    this.highlightedId,
    this.footprintIds = const [],
    this.showFootprints = true,
    this.spectrumIds = const [],
  });

  // -- Screen transform -------------------------------------------------

  static double _scaleFor(Size size) =>
      size.width / (FretboardGeometry.maxX - FretboardGeometry.minX);

  /// Logical -> screen for a widget of [size].
  static Offset toScreen(LPoint logical, Size size) {
    final s = _scaleFor(size);
    return Offset(
      (logical.x - FretboardGeometry.minX) * s,
      (logical.y - FretboardGeometry.minY) * s,
    );
  }

  /// Screen -> logical for a widget of [size].
  static LPoint toLogical(Offset screen, Size size) {
    final s = _scaleFor(size);
    return (
      x: screen.dx / s + FretboardGeometry.minX,
      y: screen.dy / s + FretboardGeometry.minY,
    );
  }

  /// Widget height for a given width (aspect preserved).
  static double boardHeightFor(double width) =>
      (FretboardGeometry.maxY - FretboardGeometry.minY) *
      (width / (FretboardGeometry.maxX - FretboardGeometry.minX));

  // -- Paint ------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final s = _scaleFor(size);
    canvas.save();
    canvas.translate(-FretboardGeometry.minX * s, -FretboardGeometry.minY * s);
    canvas.scale(s);
    _paintBoard(canvas);
    canvas.restore();
  }

  void _paintBoard(Canvas canvas) {
    final nStrings = sevenString ? 7 : 6;
    final xStart = sevenString ? 390.0 : 400.0;

    // Background (the QB64 program ran on a black screen).
    canvas.drawRect(
      const Rect.fromLTRB(
        FretboardGeometry.minX,
        FretboardGeometry.minY,
        FretboardGeometry.maxX,
        FretboardGeometry.maxY,
      ),
      Paint()..color = Colors.black,
    );

    // Footprints first so strings/frets draw over their edges, matching
    // the BASIC look where the marker sits on the board.
    if (showFootprints) {
      final brown = Paint()..color = const Color(0xFFAA5500); // COLOR 6
      for (final id in footprintIds) {
        final p = FretboardGeometry.markerLogical(
          id,
          sevenString: sevenString,
          leftHanded: leftHanded,
        );
        canvas.drawCircle(Offset(p.x, p.y), 4.0, brown);
      }
    }

    // Strings: vertical lines, ports FOR x = 400 TO 450 STEP 10
    // (plus x = 390 for the 7th string).
    final stringPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.4;
    for (var st = 1; st <= nStrings; st++) {
      final x = FretboardGeometry.stringX(
        st,
        sevenString: sevenString,
        leftHanded: leftHanded,
      );
      canvas.drawLine(
        Offset(x, FretboardGeometry.nutY),
        Offset(x, FretboardGeometry.endY),
        stringPaint,
      );
    }

    // Frets: horizontal lines at the accumulated wire positions.
    // The nut (first wire) draws thicker, like a real nut.
    final wires = FretboardGeometry.fretWireY;
    for (var i = 0; i < wires.length; i++) {
      canvas.drawLine(
        Offset(xStart, wires[i]),
        Offset(450.0, wires[i]),
        Paint()
          ..color = Colors.white70
          ..strokeWidth = i == 0 ? 2.6 : 1.1,
      );
    }

    // Inlays: single dots + double dots at the 12th and 24th frets.
    // Ports SUB drawinlays (white fill, red edge in the original).
    final inlayX = sevenString ? 420.0 : 425.0;
    final dotFill = Paint()..color = Colors.white;
    final dotEdge = Paint()
      ..color = const Color(0xFFFF5555)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    void dot(double x, double y) {
      canvas.drawCircle(Offset(x, y), 3.6, dotFill);
      canvas.drawCircle(Offset(x, y), 3.6, dotEdge);
    }

    for (final y in FretboardGeometry.inlayY) {
      dot(inlayX, y);
    }
    final pairX2 = sevenString ? 435.0 : 444.0;
    dot(406.0, FretboardGeometry.inlayFret12Y);
    dot(pairX2, FretboardGeometry.inlayFret12Y);
    dot(406.0, FretboardGeometry.inlayFret24Y);
    dot(pairX2, FretboardGeometry.inlayFret24Y);

    // Highlighted note: filled circle in its octave color.
    // Ports CIRCLE (xlite, ylite), 5, octcolor + PAINT.
    final hid = highlightedId;
    if (hid != null) {
      final p = FretboardGeometry.markerLogical(
        hid,
        sevenString: sevenString,
        leftHanded: leftHanded,
      );
      canvas.drawCircle(
        Offset(p.x, p.y),
        5.0,
        Paint()..color = Color(colorOfOctave(octaveOf(hid))),
      );
    }

    // Spectrum set: every ID filled in its own octave color.
    // Ports the rainbow octave lines of SUB rainbowgraphics, but as
    // per-note dots so the board stays readable at phone scale.
    for (final id in spectrumIds) {
      final p = FretboardGeometry.markerLogical(
        id,
        sevenString: sevenString,
        leftHanded: leftHanded,
      );
      canvas.drawCircle(
        Offset(p.x, p.y),
        4.2,
        Paint()..color = Color(colorOfOctave(octaveOf(id))),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FretboardPainter old) =>
      old.sevenString != sevenString ||
      old.leftHanded != leftHanded ||
      old.highlightedId != highlightedId ||
      old.showFootprints != showFootprints ||
      !_sameIds(old.footprintIds, footprintIds) ||
      !_sameIds(old.spectrumIds, spectrumIds);

  bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Touch-sensitive fretboard widget. Taps are converted back to note IDs
/// through the inverse of the painter's transform and reported via
/// [onNoteTapped]; taps outside the board are ignored.
class FretboardBoard extends StatelessWidget {
  final bool sevenString;
  final bool leftHanded;
  final int? highlightedId;
  final List<int> footprintIds;
  final bool showFootprints;

  /// Note IDs drawn in their octave colors (Spectrum Viewer).
  final List<int> spectrumIds;
  final ValueChanged<int>? onNoteTapped;

  const FretboardBoard({
    super.key,
    required this.sevenString,
    required this.leftHanded,
    this.highlightedId,
    this.footprintIds = const [],
    this.showFootprints = true,
    this.spectrumIds = const [],
    this.onNoteTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = FretboardPainter.boardHeightFor(width);
        final size = Size(width, height);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final cb = onNoteTapped;
            if (cb == null) return;
            final logical =
                FretboardPainter.toLogical(details.localPosition, size);
            final id = FretboardGeometry.noteIdAtLogical(
              logical.x,
              logical.y,
              sevenString: sevenString,
              leftHanded: leftHanded,
            );
            if (id != null) cb(id);
          },
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: FretboardPainter(
                sevenString: sevenString,
                leftHanded: leftHanded,
                highlightedId: highlightedId,
                footprintIds: footprintIds,
                showFootprints: showFootprints,
                spectrumIds: spectrumIds,
              ),
            ),
          ),
        );
      },
    );
  }
}
