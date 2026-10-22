// Session record for Fretboard Spectrum's history feature.
//
// Pure Dart — no Flutter imports — so serialization is unit-testable.
// The BASIC program never persisted anything; every run started from
// zero. This is the new capability from the Phase 3 plan: after each
// quiz session we keep the date, score, mode, and the missed note IDs
// that feed the lifetime weak-spot map.

/// Which quiz mode a session used.
enum SessionMode { realGuitar, airGuitar }

/// One completed practice session.
class SessionRecord {
  /// When the session finished.
  final DateTime date;

  /// Questions in the session (the BASIC `reps`).
  final int reps;

  /// Points earned (the BASIC `points`; halves possible in Air Guitar).
  final double points;

  /// Percent correct, INT(points / reps * 100) like SUB statistics.
  int get percent => (points / reps * 100).toInt();

  final SessionMode mode;

  /// Target note IDs the player missed — the persistent Footprints.
  final List<int> missedIds;

  /// Whether the session used a 7-string guitar (ids up to 174).
  final bool sevenString;

  const SessionRecord({
    required this.date,
    required this.reps,
    required this.points,
    required this.mode,
    required this.missedIds,
    required this.sevenString,
  });

  Map<String, dynamic> toJson() => {
        'v': 1,
        'date': date.toIso8601String(),
        'reps': reps,
        'points': points,
        'mode': mode.name,
        'missedIds': missedIds,
        'sevenString': sevenString,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      date: DateTime.parse(json['date'] as String),
      reps: (json['reps'] as num).toInt(),
      points: (json['points'] as num).toDouble(),
      mode: SessionMode.values.byName(json['mode'] as String),
      missedIds:
          (json['missedIds'] as List).map((e) => (e as num).toInt()).toList(),
      sevenString: json['sevenString'] as bool? ?? false,
    );
  }
}
