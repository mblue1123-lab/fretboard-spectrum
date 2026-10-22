// Final statistics screen for Fretboard Spectrum.
//
// Ports SUB statistics: Final Points, Total Reps, Percent Correct,
// with Repeat / Menu / Quit options.

import 'package:flutter/material.dart';

import '../../engine/session.dart';

class ResultsScreen extends StatelessWidget {
  final Session session;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  const ResultsScreen({
    super.key,
    required this.session,
    required this.onReplay,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Complete')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Final Points = ${session.points}',
                style:
                    const TextStyle(fontSize: 24, color: Colors.lightGreen)),
            const SizedBox(height: 12),
            Text('Total Reps = ${session.reps}',
                style:
                    const TextStyle(fontSize: 24, color: Colors.lightBlue)),
            const SizedBox(height: 12),
            Text('Percent Correct = ${session.percentCorrect}%',
                style:
                    const TextStyle(fontSize: 24, color: Colors.lightGreen)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onReplay,
              child: const Text('Repeat exercise'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onHome,
              child: const Text('Back to menu'),
            ),
          ],
        ),
      ),
    );
  }
}
