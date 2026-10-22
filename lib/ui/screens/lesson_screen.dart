// Lesson plan screen for Fretboard Spectrum.
//
// Ports SUB lessonplan from Fretspc9_LARGE.BAS. In the original, the
// lesson plan was the pre-session confirmation: it restated the full
// configuration (handedness, strings, scope, modifier, range,
// footprints, reps) and asked "Press Y to continue / N to go back".
// Here it becomes a guided path: the 17 string scopes are grouped into
// four stages — single strings, pairs, triples, full neck — which is
// the progression the BASIC menus were already steering players
// through. The summary card keeps the original's confirmation lines.

import 'package:flutter/material.dart';

import '../../engine/quiz_engine.dart';
import 'quiz_screen.dart';

/// One pedagogical stage: a group of string scopes in rising difficulty.
class _Stage {
  final String title;
  final List<StringScope> scopes;

  const _Stage(this.title, this.scopes);
}

List<_Stage> _stagesFor(bool sevenString) => [
      _Stage('Stage 1 · Single strings', [
        StringScope.string1,
        StringScope.string2,
        StringScope.string3,
        StringScope.string4,
        StringScope.string5,
        StringScope.string6,
        if (sevenString) StringScope.string7,
      ]),
      _Stage('Stage 2 · String pairs', [
        StringScope.strings1And2,
        StringScope.strings3And4,
        StringScope.strings5And6,
        if (sevenString) StringScope.strings6And7,
      ]),
      _Stage('Stage 3 · String triples', [
        StringScope.strings1To3,
        StringScope.strings2To4,
        StringScope.strings3To5,
        StringScope.strings4To6,
        if (sevenString) StringScope.strings5To7,
      ]),
      const _Stage('Stage 4 · Full neck', [StringScope.allStrings]),
    ];

String _modifierLabel(AccidentalFilter f) => switch (f) {
      AccidentalFilter.naturalsOnly => 'No Sharps / No Flats',
      AccidentalFilter.accidentalsOnly => 'Sharps / Flats Only',
      AccidentalFilter.all => 'All Notes Available',
    };

class LessonScreen extends StatefulWidget {
  final bool leftHanded;
  final bool sevenString;

  const LessonScreen({
    super.key,
    required this.leftHanded,
    required this.sevenString,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _stageIndex = 0;
  late StringScope _scope;
  QuizMode _mode = QuizMode.realGuitar;
  AccidentalFilter _filter = AccidentalFilter.all;
  bool _sharps = false;
  int _reps = 20;

  @override
  void initState() {
    super.initState();
    _scope = _stagesFor(widget.sevenString)[0].scopes.first;
  }

  void _pickStage(int i) {
    final stages = _stagesFor(widget.sevenString);
    setState(() {
      _stageIndex = i;
      _scope = stages[i].scopes.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stagesFor(widget.sevenString);
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Work the neck in stages — single strings, then pairs, '
            'then triples, then the whole thing.',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // Stage picker.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < stages.length; i++)
                ChoiceChip(
                  label: Text(stages[i].title),
                  selected: i == _stageIndex,
                  onSelected: (_) => _pickStage(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Scopes within the stage.
          RadioGroup<StringScope>(
            groupValue: _scope,
            onChanged: (v) =>
                setState(() => _scope = v ?? _scope),
            child: Column(
              children: stages[_stageIndex].scopes
                  .map(
                    (s) => RadioListTile<StringScope>(
                      title: Text(stringScopeLabel(s)),
                      value: s,
                      dense: true,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 32),
          _row('Mode',
              SegmentedButton<QuizMode>(
                segments: const [
                  ButtonSegment(
                      value: QuizMode.realGuitar, label: Text('Real Guitar')),
                  ButtonSegment(
                      value: QuizMode.airGuitar, label: Text('Air Guitar')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) =>
                    setState(() => _mode = s.first),
              )),
          _row('Notes',
              SegmentedButton<AccidentalFilter>(
                segments: const [
                  ButtonSegment(
                      value: AccidentalFilter.naturalsOnly,
                      label: Text('Naturals')),
                  ButtonSegment(
                      value: AccidentalFilter.all, label: Text('Mixed')),
                  ButtonSegment(
                      value: AccidentalFilter.accidentalsOnly,
                      label: Text('Accidentals')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) =>
                    setState(() => _filter = s.first),
              )),
          if (_filter != AccidentalFilter.naturalsOnly)
            _row('Spelling',
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Flats')),
                    ButtonSegment(value: true, label: Text('Sharps')),
                  ],
                  selected: {_sharps},
                  onSelectionChanged: (s) =>
                      setState(() => _sharps = s.first),
                )),
          _row('Reps',
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 10, label: Text('10')),
                  ButtonSegment(value: 20, label: Text('20')),
                  ButtonSegment(value: 50, label: Text('50')),
                ],
                selected: {_reps},
                onSelectionChanged: (s) =>
                    setState(() => _reps = s.first),
              )),
          const SizedBox(height: 16),
          // The lessonplan confirmation card.
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your lesson',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('You are playing a '
                      '${widget.leftHanded ? 'left-handed' : 'right-handed'}, '
                      '${widget.sevenString ? '7' : '6'} string guitar.'),
                  const SizedBox(height: 4),
                  Text('You have chosen to study '
                      '${stringScopeLabel(_scope)}.'),
                  const SizedBox(height: 4),
                  Text('Modifier = ${_modifierLabel(_filter)}'),
                  if (_filter != AccidentalFilter.naturalsOnly) ...[
                    const SizedBox(height: 4),
                    Text('Answers will be expressed using '
                        '${_sharps ? 'Sharps (#)' : 'FLATS (b)'}'),
                  ],
                  const SizedBox(height: 4),
                  Text('Reps = $_reps'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  config: QuizConfig(
                    leftHanded: widget.leftHanded,
                    sevenString: widget.sevenString,
                    mode: _mode,
                    accidentalFilter: _filter,
                    sharps: _sharps,
                    reps: _reps,
                    scope: _scope,
                  ),
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Start Lesson',
                style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(String label, Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
                width: 64,
                child:
                    Text(label, style: const TextStyle(fontSize: 15))),
            Expanded(child: child),
          ],
        ),
      );
}
