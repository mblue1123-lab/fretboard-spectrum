// Session history store for Fretboard Spectrum.
//
// Persists completed practice sessions as a JSON list in
// SharedPreferences — simple, offline, no database needed for this
// volume of data. The store is constructed with the prefs instance so
// tests can inject fakes.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_record.dart';

class SessionHistory {
  static const storageKey = 'fretboard_spectrum_sessions_v1';

  final SharedPreferences _prefs;

  SessionHistory(this._prefs);

  /// Loads all sessions, newest first. Corrupt entries are skipped
  /// rather than wiping the whole history.
  static Future<SessionHistory> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionHistory(prefs);
  }

  List<SessionRecord> get sessions {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final records = <SessionRecord>[];
      for (final e in list) {
        try {
          records.add(SessionRecord.fromJson(e as Map<String, dynamic>));
        } catch (_) {
          // Skip one bad entry; keep the rest.
        }
      }
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (_) {
      return [];
    }
  }

  Future<void> add(SessionRecord record) async {
    final all = [...sessions, record];
    all.sort((a, b) => b.date.compareTo(a.date));
    await _prefs.setString(
      storageKey,
      jsonEncode(all.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> clear() async => _prefs.remove(storageKey);

  /// Every missed note ID across all sessions, deduplicated — the
  /// lifetime weak-spot map, drawn as footprints on a fretboard.
  List<int> get weakSpotIds {
    final ids = <int>{};
    for (final s in sessions) {
      ids.addAll(s.missedIds);
    }
    return ids.toList()..sort();
  }
}
