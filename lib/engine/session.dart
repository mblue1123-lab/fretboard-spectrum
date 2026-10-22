// Practice-session bookkeeping for Fretboard Spectrum.
//
// Ports the rep counting and final statistics in SUB statistics and the
// main exercise loop: the player chooses 10-100 reps, each answered
// question increments theoscore (possible points), and the session ends
// with Final Points, Total Reps, and Percent Correct.

/// One practice session of [reps] questions.
class Session {
  /// Total questions in the session (10-100 in the BASIC program).
  final int reps;

  /// Points earned so far.
  double points = 0;

  /// Questions answered so far ("possible points" in the BASIC program;
  /// incremented once per question in answerscreen).
  int theoscore = 0;

  Session(this.reps) : assert(reps > 0, 'reps must be positive');

  /// Records one answered question worth [earned] points.
  void recordAnswer(double earned) {
    points += earned;
    theoscore++;
  }

  /// Questions remaining. Mirrors the "Reps Left" readout (repdisplay).
  int get repsLeft => reps - theoscore;

  /// Session complete once every rep has been answered.
  bool get isComplete => theoscore >= reps;

  /// Percent Correct as shown on the statistics screen:
  /// INT(points / reps * 100).
  int get percentCorrect => (points / reps * 100).toInt();
}
