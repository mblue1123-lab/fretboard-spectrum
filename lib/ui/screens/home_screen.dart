// Home screen for Fretboard Spectrum.
//
// Ports SUB homepage: guitar options (handedness, 6/7 string), then
// Practice Session or Spectrum Viewer. The rainbow title echoes SUB
// printrainbow, which rendered the title letter-by-letter in rainbow
// colors.

import 'package:flutter/material.dart';

import '../../engine/note_mapper.dart';
import '../../engine/quiz_engine.dart';
import 'history_screen.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';
import 'viewer_screen.dart';

/// Rainbow colors for the title, drawn from the octave color map.
List<Color> _rainbowColors() =>
    [-1, 0, 1, 2, 3, 4].map((o) => Color(colorOfOctave(o))).toList();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _leftHanded = false;
  bool _sevenString = false;
  QuizMode _mode = QuizMode.realGuitar;
  int _accidentals = 1; // 0 = naturals only, 1 = mixed in, 2 = only accidentals
  bool _sharps = false; // display spelling when accidentals are on
  int _reps = 20;

  QuizConfig _config() => QuizConfig(
        leftHanded: _leftHanded,
        sevenString: _sevenString,
        mode: _mode,
        accidentalFilter: switch (_accidentals) {
          0 => AccidentalFilter.naturalsOnly,
          2 => AccidentalFilter.accidentalsOnly,
          _ => AccidentalFilter.all,
        },
        sharps: _sharps,
        reps: _reps,
      );

  @override
  Widget build(BuildContext context) {
    final colors = _rainbowColors();
    const title = 'Fretboard Spectrum';
    return Scaffold(
      appBar: AppBar(title: const Text('Fretboard Spectrum')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  for (var i = 0; i < title.length; i++)
                    TextSpan(
                      text: title[i],
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: colors[i % colors.length],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SettingRow(
            label: 'Hand',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Right')),
                ButtonSegment(value: true, label: Text('Left')),
              ],
              selected: {_leftHanded},
              onSelectionChanged: (s) =>
                  setState(() => _leftHanded = s.first),
            ),
          ),
          _SettingRow(
            label: 'Strings',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('6')),
                ButtonSegment(value: true, label: Text('7')),
              ],
              selected: {_sevenString},
              onSelectionChanged: (s) =>
                  setState(() => _sevenString = s.first),
            ),
          ),
          _SettingRow(
            label: 'Mode',
            child: SegmentedButton<QuizMode>(
              segments: const [
                ButtonSegment(
                    value: QuizMode.realGuitar, label: Text('Real Guitar')),
                ButtonSegment(
                    value: QuizMode.airGuitar, label: Text('Air Guitar')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          _SettingRow(
            label: 'Notes',
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Naturals')),
                ButtonSegment(value: 1, label: Text('Mixed')),
                ButtonSegment(value: 2, label: Text('Accidentals')),
              ],
              selected: {_accidentals},
              onSelectionChanged: (s) =>
                  setState(() => _accidentals = s.first),
            ),
          ),
          if (_accidentals != 0)
            _SettingRow(
              label: 'Spelling',
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Flats')),
                  ButtonSegment(value: true, label: Text('Sharps')),
                ],
                selected: {_sharps},
                onSelectionChanged: (s) =>
                    setState(() => _sharps = s.first),
              ),
            ),
          _SettingRow(
            label: 'Reps',
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 50, label: Text('50')),
              ],
              selected: {_reps},
              onSelectionChanged: (s) => setState(() => _reps = s.first),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => QuizScreen(config: _config())),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Start Practice Session',
                style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => LessonScreen(
                        leftHanded: _leftHanded,
                        sevenString: _sevenString,
                      )),
            ),
            child: const Text('Guided Lesson Plan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ViewerScreen(
                        leftHanded: _leftHanded,
                        sevenString: _sevenString,
                        sharps: _sharps,
                      )),
            ),
            child: const Text('Spectrum Viewer'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const HistoryScreen()),
            ),
            child: const Text('Session History'),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 72,
              child: Text(label,
                  style: const TextStyle(fontSize: 16))),
          Expanded(child: child),
        ],
      ),
    );
  }
}
