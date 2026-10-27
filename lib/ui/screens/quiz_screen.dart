// Quiz screen for Fretboard Spectrum.
//
// Merges SUB questionscreen and SUB answerscreen from Fretspc9_LARGE.BAS
// into one screen with two modes:
//
//  Real Guitar Mode: the engine picks a note; its fretboard position is
//    highlighted in the octave's rainbow color and its pitch is played.
//    The player NAMES the note with letter buttons (A-G) plus a
//    sharp/flat/natural toggle. Correct letter -> +1.
//  Air Guitar Mode: audio only; the player picks the letter name with
//    buttons and the octave with the rainbow octave picker. Each half is
//    worth 0.5, exactly the partial-credit matrix in SUB answerscreen.

import 'package:flutter/material.dart';

import '../../audio/note_player.dart';
import '../../data/session_history.dart';
import '../../data/session_record.dart';
import '../../engine/note_mapper.dart';
import '../../engine/quiz_engine.dart';
import '../../engine/scorer.dart';
import '../../engine/session.dart';
import '../painters/fretboard_geometry.dart';
import '../painters/fretboard_painter.dart';
import 'results_screen.dart';

enum QuizMode { realGuitar, airGuitar }

class QuizConfig {
  final bool leftHanded;
  final bool sevenString;
  final QuizMode mode;
  final AccidentalFilter accidentalFilter;
  final bool sharps; // display spelling (flatsharp setting)
  final int reps;

  /// Which strings questions come from (strngstudy in the BASIC program).
  final StringScope scope;

  const QuizConfig({
    required this.leftHanded,
    required this.sevenString,
    required this.mode,
    required this.accidentalFilter,
    required this.sharps,
    required this.reps,
    this.scope = StringScope.allStrings,
  });
}

/// Flat spelling -> sharp spelling, for comparing a tapped/picked answer
/// against the target's canonical pitch class (playNameOf is sharp-spelled).
String _toSharp(String name) {
  const flatToSharp = {
    'Bb': 'A#',
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
  };
  return flatToSharp[name] ?? name;
}

class QuizScreen extends StatefulWidget {
  final QuizConfig config;

  /// Optional engine override — tests pass a seeded engine so the picked
  /// note is deterministic.
  final QuizEngine? engine;

  const QuizScreen({super.key, required this.config, this.engine});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late QuizEngine _engine;
  late Session _session;
  late final NotePlayer _player;

  int? _targetId;

  // Real-guitar answer state: the player names the highlighted note with
  // letter buttons plus a sharp/flat/natural toggle.
  String? _pickedLetter;
  String _pickedAccidental = '';
  bool? _letterCorrect;

  // Air-guitar answer state.
  int? _pickedOctave;
  bool? _octaveCorrect;

  double _lastEarned = 0;
  final List<int> _footprints = [];

  /// Every missed target ID, regardless of the Footprints toggle — this
  /// is what gets persisted for the lifetime weak-spot map.
  final List<int> _missedIds = [];
  bool _footprintsOn = true;
  bool _sessionSaved = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _scrollKey = GlobalKey();

  QuizConfig get _c => widget.config;
  bool get _answered => _letterCorrect != null;

  String get _targetLetter => letterOf(_targetId!, sharps: _c.sharps);
  int get _targetOctave => octaveOf(_targetId!);
  String get _targetPitchClass => playNameOf(_targetId!);

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? QuizEngine();
    _session = Session(_c.reps);
    _player = NotePlayer();
    _nextQuestion();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    final id = _engine.pickNext(
      scope: _c.scope,
      filter: _c.accidentalFilter,
      sevenString: _c.sevenString,
    );
    setState(() {
      _targetId = id;
      _pickedLetter = null;
      _pickedAccidental = '';
      _pickedOctave = null;
      _letterCorrect = null;
      _octaveCorrect = null;
    });
    _player.playNoteId(id);
    // The highlight IS the question now: bring it into view.
    _scrollToTarget();
  }

  void _replay() {
    final id = _targetId;
    if (id != null) _player.playNoteId(id);
  }

  // -- Real guitar: name the highlighted note ----------------------------

  void _answerReal() {
    if (_targetId == null || _answered) return;
    final letter = _pickedLetter;
    if (letter == null) return;
    // Letter + accidental against the target's canonical pitch class
    // (sharp-spelled, like the BASIC name$).
    final answer = '$letter$_pickedAccidental';
    final correct = _toSharp(answer) == _targetPitchClass;
    final earned = scoreRealGuitar(letterCorrect: correct);
    _session.recordAnswer(earned);
    if (!correct) {
      _missedIds.add(_targetId!);
      if (_footprintsOn) _footprints.add(_targetId!);
    }
    setState(() {
      _letterCorrect = correct;
      _lastEarned = earned;
    });
    if (correct) {
      _player.playRight();
    } else {
      _player.playWrong();
    }
  }

  void _scrollToTarget() {
    final target = _targetId;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box =
          _boardKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final size = box.size;
      final logical = FretboardGeometry.markerLogical(
        target,
        sevenString: _c.sevenString,
        leftHanded: _c.leftHanded,
      );
      final y = FretboardPainter.toScreen(logical, size).dy;
      final viewBox =
          _scrollKey.currentContext?.findRenderObject() as RenderBox?;
      final viewH = viewBox?.size.height ?? 400.0;
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        (y - viewH / 2).clamp(0.0, max),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  // -- Air guitar: buttons ----------------------------------------------

  void _answerAir() {
    if (_pickedLetter == null || _pickedOctave == null || _answered) return;
    final lc = _toSharp(_pickedLetter!) == _targetPitchClass;
    final oc = _pickedOctave == _targetOctave;
    final earned = scoreAirGuitar(letterCorrect: lc, octaveCorrect: oc);
    _session.recordAnswer(earned);
    if (!(lc && oc)) {
      _missedIds.add(_targetId!);
      if (_footprintsOn) _footprints.add(_targetId!);
    }
    setState(() {
      _letterCorrect = lc;
      _octaveCorrect = oc;
      _lastEarned = earned;
    });
    if (lc && oc) {
      _player.playRight();
    } else {
      _player.playWrong();
    }
  }

  void _replaySession() {
    setState(() {
      _engine = QuizEngine();
      _session = Session(_c.reps);
      _footprints.clear();
      _missedIds.clear();
      _sessionSaved = false;
    });
    _nextQuestion();
  }

  /// Persists the finished session for the history view and the lifetime
  /// weak-spot map. Fire-and-forget: history must never block results.
  void _maybeSaveSession() {
    if (_sessionSaved || !_session.isComplete) return;
    _sessionSaved = true;
    final record = SessionRecord(
      date: DateTime.now(),
      reps: _session.reps,
      points: _session.points,
      mode: _c.mode == QuizMode.realGuitar
          ? SessionMode.realGuitar
          : SessionMode.airGuitar,
      missedIds: List.of(_missedIds),
      sevenString: _c.sevenString,
    );
    SessionHistory.load()
        .then((h) => h.add(record))
        .catchError((Object _, StackTrace __) {});
  }

  // -- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_session.isComplete) {
      _maybeSaveSession();
      return ResultsScreen(
        session: _session,
        onReplay: _replaySession,
        onHome: () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Session'),
        actions: [
          IconButton(
            tooltip: 'Replay note',
            icon: const Icon(Icons.replay),
            onPressed: _replay,
          ),
          IconButton(
            tooltip: _footprintsOn ? 'Footprints on' : 'Footprints off',
            icon: Icon(
              Icons.fingerprint,
              color: _footprintsOn ? Colors.brown[300] : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _footprintsOn = !_footprintsOn),
          ),
        ],
      ),
      body: Column(
        children: [
          _ScoreBar(session: _session),
          if (_c.mode == QuizMode.realGuitar)
            _buildRealGuitar()
          else
            _buildAirGuitar(),
        ],
      ),
    );
  }

  Widget _buildRealGuitar() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Name the highlighted note',
                    style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                _OctaveChip(octave: _targetOctave),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: _scrollKey,
              controller: _scrollController,
              child: FretboardBoard(
                key: _boardKey,
                sevenString: _c.sevenString,
                leftHanded: _c.leftHanded,
                // The highlight IS the question: always visible, in the
                // target's octave color. No tap handler — the player
                // answers with the letter buttons below.
                highlightedId: _targetId,
                footprintIds: _footprints,
                showFootprints: _footprintsOn,
              ),
            ),
          ),
          _buildRealAnswerPanel(),
          _FeedbackBar(
            answered: _answered,
            earned: _lastEarned,
            message: _answered
                ? (_letterCorrect!
                    ? 'Correct! $_targetLetter'
                    : 'Not quite — $_targetLetter, '
                        'string ${stringOf(_targetId!)}, '
                        'fret ${fretOf(_targetId!)} '
                        '(you answered ${_pickedLetter ?? '?'}'
                        '$_pickedAccidental)')
                : null,
            onNext: _nextQuestion,
          ),
        ],
      ),
    );
  }

  /// Letter buttons (A-G) plus a sharp/flat/natural toggle for Real
  /// Guitar Mode. The accidental toggle only appears when the session
  /// includes accidentals.
  Widget _buildRealAnswerPanel() {
    const naturals = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final showAccidentals =
        _c.accidentalFilter != AccidentalFilter.naturalsOnly;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[900],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in naturals)
                _ChoiceChip(
                  label: n,
                  selected: _pickedLetter == n,
                  enabled: !_answered,
                  onTap: () => setState(() => _pickedLetter = n),
                ),
            ],
          ),
          if (showAccidentals) ...[
            const SizedBox(height: 8),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: '', label: Text('♮ Natural')),
                ButtonSegment(value: '#', label: Text('♯ Sharp')),
                ButtonSegment(value: 'b', label: Text('♭ Flat')),
              ],
              selected: {_pickedAccidental},
              onSelectionChanged: _answered
                  ? null
                  : (s) => setState(() => _pickedAccidental = s.first),
            ),
          ],
          const SizedBox(height: 8),
          if (!_answered)
            ElevatedButton(
              onPressed:
                  _pickedLetter != null ? _answerReal : null,
              child: const Text('Check answer'),
            ),
        ],
      ),
    );
  }

  Widget _buildAirGuitar() {
    final showAccidentals =
        _c.accidentalFilter != AccidentalFilter.naturalsOnly;
    const naturals = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final accidentalNames = _c.sharps
        ? ['A#', 'C#', 'D#', 'F#', 'G#']
        : ['Bb', 'Db', 'Eb', 'Gb', 'Ab'];

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: Text(
              'What note do you hear?',
              style: TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: _replay,
              icon: const Icon(Icons.volume_up),
              label: const Text('Replay'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Letter', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in naturals)
                _ChoiceChip(
                  label: n,
                  selected: _pickedLetter == n,
                  enabled: !_answered,
                  onTap: () => setState(() => _pickedLetter = n),
                ),
              if (showAccidentals)
                for (final n in accidentalNames)
                  _ChoiceChip(
                    label: n,
                    selected: _pickedLetter == n,
                    enabled: !_answered,
                    onTap: () => setState(() => _pickedLetter = n),
                  ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Octave', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var o = -1; o <= 4; o++)
                _OctavePickChip(
                  octave: o,
                  selected: _pickedOctave == o,
                  enabled: !_answered,
                  onTap: () => setState(() => _pickedOctave = o),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_answered)
            ElevatedButton(
              onPressed: (_pickedLetter != null && _pickedOctave != null)
                  ? _answerAir
                  : null,
              child: const Text('Check'),
            ),
          if (_answered) _airFeedback(),
        ],
      ),
    );
  }

  Widget _airFeedback() {
    String half(String label, bool? ok, String picked, String answer) {
      final mark = ok! ? '✓' : '✗';
      return '$label: $picked $mark  (was $answer)';
    }

    return Column(
      children: [
        Text(
          half('Letter', _letterCorrect, _pickedLetter!, _targetLetter),
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          half('Octave', _octaveCorrect, '$_pickedOctave!',
              '$_targetOctave'),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          '+$_lastEarned points',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _nextQuestion,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final Session session;

  const _ScoreBar({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Points: ${session.points}',
              style: const TextStyle(fontSize: 16)),
          Text('Reps left: ${session.repsLeft}',
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _OctaveChip extends StatelessWidget {
  final int octave;

  const _OctaveChip({required this.octave});

  @override
  Widget build(BuildContext context) {
    final bg = Color(colorOfOctave(octave));
    // Dark text on the light octave colors, white on the saturated ones.
    final fg = (octave == 0 || octave == 4) ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('oct $octave',
          style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.lightBlue : Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? Colors.lightBlueAccent : Colors.grey),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _OctavePickChip extends StatelessWidget {
  final int octave;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OctavePickChip({
    required this.octave,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Color(colorOfOctave(octave));
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: Text(
          '$octave',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  final bool answered;
  final double earned;
  final String? message;
  final VoidCallback onNext;

  const _FeedbackBar({
    required this.answered,
    required this.earned,
    required this.message,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (!answered) {
      return const SizedBox(
        height: 72,
        child: Center(
          child: Text('Name the highlighted note',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${message!}  (+$earned)',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
