// Scoring for Fretboard Spectrum.
//
// Ports the answer checking in SUB answerscreen (and the letter half-point
// awarded in SUB questionscreen's graphics-off branch).
//
// Real Guitar Mode (fretboard visible): the player names the note.
//   Correct letter -> +1 point.
//
// Air Guitar Mode (no fretboard, audio only): a two-part question —
// letter name plus octave number — each half worth 0.5 with true partial
// credit:
//
//   letter correct, octave correct -> 1.0
//   letter correct, octave wrong   -> 0.5   ("Wrong Octave (note correct)!")
//   letter wrong,   octave correct -> 0.5   ("Octave Correct (note wrong)!")
//   letter wrong,   octave wrong   -> 0.0   ("You Got Both of Them Wrong!")

/// Points for one question in Real Guitar Mode.
double scoreRealGuitar({required bool letterCorrect}) =>
    letterCorrect ? 1.0 : 0.0;

/// Points for one question in Air Guitar Mode (letter half + octave half).
double scoreAirGuitar({
  required bool letterCorrect,
  required bool octaveCorrect,
}) =>
    (letterCorrect ? 0.5 : 0.0) + (octaveCorrect ? 0.5 : 0.0);
