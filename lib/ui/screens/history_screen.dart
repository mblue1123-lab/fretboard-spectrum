// Session history for Fretboard Spectrum.
//
// New capability the BASIC program never had: every finished practice
// session is persisted (see lib/data/), and this screen shows the list
// plus the lifetime weak-spot map — every missed note ID across all
// sessions, drawn as footprints on a fretboard.

import 'package:flutter/material.dart';

import '../../data/session_history.dart';
import '../../data/session_record.dart';
import '../painters/fretboard_painter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  SessionHistory? _history;
  bool _sevenStringBoard = false;

  @override
  void initState() {
    super.initState();
    SessionHistory.load().then((h) {
      if (!mounted) return;
      setState(() {
        _history = h;
        // A 7-string board fits every recorded ID; a 6-string board
        // would drop the low-B misses.
        _sevenStringBoard = h.sessions.any((s) => s.sevenString);
      });
    });
  }

  Future<void> _clear() async {
    final h = _history;
    if (h == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This deletes all saved sessions and the weak-spot map.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await h.clear();
      if (mounted) setState(() {});
    }
  }

  String _dateLabel(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.month}/${d.day}  $h12:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final h = _history;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          if (h != null && h.sessions.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            ),
        ],
      ),
      body: h == null
          ? const Center(child: CircularProgressIndicator())
          : h.sessions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No sessions yet. Finish a practice session and '
                      'it will show up here — along with a map of every '
                      'note you have ever missed.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _weakSpotMap(h),
                    const SizedBox(height: 16),
                    const Text('Sessions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...h.sessions.map(_sessionTile),
                  ],
                ),
    );
  }

  Widget _weakSpotMap(SessionHistory h) {
    final ids = h.weakSpotIds;
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weak-spot map · ${ids.length} note${ids.length == 1 ? '' : 's'} missed all-time',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Every brown footprint is a note you missed in some '
              'session. Drill these.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
                child: FretboardBoard(
                  sevenString: _sevenStringBoard,
                  leftHanded: false,
                  footprintIds: ids,
                  showFootprints: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionTile(SessionRecord s) {
    final pct = s.percent;
    final pctColor = pct >= 80
        ? Colors.lightGreen
        : pct >= 60
            ? Colors.amber
            : Colors.redAccent;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pctColor.withValues(alpha: 0.2),
          child: Text('$pct%',
              style: TextStyle(
                  color: pctColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        title: Text(_dateLabel(s.date)),
        subtitle: Text(
          '${s.mode == SessionMode.realGuitar ? 'Real Guitar' : 'Air Guitar'}'
          ' · ${s.reps} reps'
          ' · ${s.points.toStringAsFixed(s.points % 1 == 0 ? 0 : 1)} pts'
          ' · ${s.missedIds.length} missed'
          '${s.sevenString ? ' · 7-string' : ''}',
        ),
      ),
    );
  }
}
