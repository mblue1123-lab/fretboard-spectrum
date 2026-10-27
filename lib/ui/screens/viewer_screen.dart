// Spectrum Viewer for Fretboard Spectrum.
//
// Ports the rainbow-reference mode of the QB64 program (SUB
// rainbowgraphics / rainbowgraphics2 drew the whole fretboard with every
// position colored by octave; SUB drawkeyboard showed the piano mirror).
// This is an explorable reference, not a quiz: pick an octave — or All —
// see every one of its notes light up in the octave's rainbow color, tap
// any of them — or the piano keys — to hear its pitch.

import 'package:flutter/material.dart';

import '../../audio/note_player.dart';
import '../../engine/note_mapper.dart';
import '../painters/fretboard_painter.dart';

class ViewerScreen extends StatefulWidget {
  final bool leftHanded;
  final bool sevenString;
  final bool sharps;

  const ViewerScreen({
    super.key,
    required this.leftHanded,
    required this.sevenString,
    required this.sharps,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final NotePlayer _player;
  int _octave = 2;
  bool _showAll = false;
  late bool _sharps;

  @override
  void initState() {
    super.initState();
    _player = NotePlayer();
    _sharps = widget.sharps;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  List<int> get _ids => _showAll
      ? [
          for (var o = -1; o <= 4; o++)
            ...idsInOctave(o, sevenString: widget.sevenString),
        ]
      : idsInOctave(_octave, sevenString: widget.sevenString);

  @override
  Widget build(BuildContext context) {
    final octaveColor = Color(colorOfOctave(_octave));
    final ids = _ids;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spectrum Viewer'),
        actions: [
          IconButton(
            tooltip: _sharps ? 'Sharps' : 'Flats',
            icon: Text(_sharps ? '#' : 'b',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _sharps = !_sharps),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Octave selector: the rainbow itself, plus All.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (var o = -1; o <= 4; o++)
                _OctaveChip(
                  octave: o,
                  selected: o == _octave && !_showAll,
                  onTap: () {
                    setState(() {
                      _octave = o;
                      _showAll = false;
                    });
                  },
                ),
              _AllChip(
                selected: _showAll,
                onTap: () => setState(() => _showAll = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_showAll)
            Text(
              'All octaves · ${ids.length} notes',
              style: const TextStyle(fontSize: 16),
            )
          else
            Text(
              'Octave $_octave · ${octaveRegisterName(_octave)}'
              '${ids.isEmpty ? ' · no notes on a 6-string' : ' · ${ids.length} notes'}',
              style: TextStyle(fontSize: 16, color: octaveColor),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FretboardBoard(
                    sevenString: widget.sevenString,
                    leftHanded: widget.leftHanded,
                    spectrumIds: ids,
                    showFootprints: false,
                    onNoteTapped: (id) => _player.playNoteId(id),
                  ),
                  const SizedBox(height: 12),
                  if (_showAll)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Every octave at once, each in its own rainbow color. Tap any glowing note to hear it.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Tap any glowing note — or a piano key — to hear it.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: _pianoStrip(),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Piano mirror of the chosen octave (ports SUB drawkeyboard):
  /// 12 chromatic keys, white/black layout, each playing its pitch.
  Widget _pianoStrip() {
    const whiteLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    // (letter, index of the white key to its left)
    final blackLetters = [
      (_sharps ? 'C#' : 'Db', 0),
      (_sharps ? 'D#' : 'Eb', 1),
      (_sharps ? 'F#' : 'Gb', 3),
      (_sharps ? 'G#' : 'Ab', 4),
      (_sharps ? 'A#' : 'Bb', 5),
    ];
    const stripH = 120.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final whiteW = constraints.maxWidth / 7;
        final blackW = whiteW * 0.62;
        Widget whiteKey(String letter) => Expanded(
              child: GestureDetector(
                onTap: () => _player.playPitch(letter, _octave),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black54),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(letter,
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 13)),
                ),
              ),
            );
        return SizedBox(
          height: stripH,
          child: Stack(
            children: [
              Row(children: [for (final l in whiteLetters) whiteKey(l)]),
              for (final (letter, i) in blackLetters)
                Positioned(
                  left: whiteW * (i + 1) - blackW / 2,
                  top: 0,
                  width: blackW,
                  height: stripH * 0.62,
                  child: GestureDetector(
                    onTap: () => _player.playPitch(letter, _octave),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(color: Colors.black),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(letter,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "All" chip for the Spectrum Viewer: a rainbow-gradient pill that
/// selects every octave at once.
class _AllChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AllChip({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          gradient: LinearGradient(
            colors: [
              for (var o = -1; o <= 4; o++) Color(colorOfOctave(o)),
            ],
          ),
        ),
        child: const Text(
          'All',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _OctaveChip extends StatelessWidget {
  final int octave;
  final bool selected;
  final VoidCallback onTap;

  const _OctaveChip({
    required this.octave,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Color(colorOfOctave(octave)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: Text(
          '$octave',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
