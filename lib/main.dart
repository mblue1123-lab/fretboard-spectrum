import 'package:flutter/material.dart';

import 'ui/screens/home_screen.dart';

void main() {
  runApp(const FretboardApp());
}

/// Fretboard Spectrum — Flutter port of Mike's QB64 fretboard trainer.
/// Dark theme nods to the black SCREEN 9 the original ran on.
class FretboardApp extends StatelessWidget {
  const FretboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fretboard Spectrum',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
