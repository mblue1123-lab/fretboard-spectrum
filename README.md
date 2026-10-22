# Fretboard Spectrum — Flutter App

Flutter port of Mike's QB64 fretboard trainer (`Fretspc9_LARGE.BAS`).
Phase 1: pure-Dart quiz engine. Phase 2: fretboard renderer, quiz screen
with touch input, audio layer. Design docs:
`~/workspace/your_files/Fretboard-Spectrum-Flutter-Architecture.md`.

## Layout

| File | Ports (BASIC routine) |
|---|---|
| `lib/engine/` | Phase 1 — pure Dart, zero Flutter imports (see below) |
| `lib/ui/painters/fretboard_geometry.dart` | Pure-Dart logical coordinate math: fret-wire Y positions (the spacing table in `drawfretboard`), the `ylite` marker table and `xlite` string columns (`highlitenoteonfretboard`), inlay positions (`drawinlays`), and the tap→note-ID inverse |
| `lib/ui/painters/fretboard_painter.dart` | `FretboardPainter` (CustomPainter): strings, frets, inlays, Footprints, octave-colored highlight; plus the touch-sensitive `FretboardBoard` widget. Logical space == the QB64 coordinates 1:1, scaled to fit |
| `lib/ui/screens/home_screen.dart` | `homepage`: handedness, 6/7-string, mode, accidentals, spelling, reps; rainbow title echoing `printrainbow`; launches Practice Session, Lesson Plan, Spectrum Viewer, Session History |
| `lib/ui/screens/quiz_screen.dart` | `questionscreen` + `answerscreen` merged. Real Guitar Mode: note name + octave color chip + pitch are given, player taps the fretboard (any position with the target's pitch class scores). Air Guitar Mode: audio only, letter buttons + rainbow octave picker, 0.5 + 0.5 partial credit |
| `lib/ui/screens/results_screen.dart` | `statistics`: final points, total reps, percent correct |
| `lib/ui/screens/lesson_screen.dart` | Phase 3 — ports `lessonplan`: the 17 string scopes grouped into 4 pedagogical stages, options, and the original's confirmation summary card ("You have chosen to study ...") |
| `lib/ui/screens/viewer_screen.dart` | Phase 3 — ports the rainbow-reference mode (`rainbowgraphics`, `drawkeyboard`): octave picker in rainbow colors, every note of the octave glowing on the fretboard, tap-to-hear, piano strip mirror |
| `lib/ui/screens/history_screen.dart` | Phase 3 — session history list + lifetime weak-spot map (all missed note IDs drawn as footprints) |
| `lib/data/session_record.dart` | Phase 3 — pure-Dart session record (date, reps, points, mode, missed IDs) with JSON serialization |
| `lib/data/session_history.dart` | Phase 3 — SharedPreferences-backed history store (offline JSON list) |
| `lib/audio/tone_synth.dart` | Pure-Dart pitch math (program octave → MIDI → Hz, A4 = 440) and in-memory WAV synthesis with attack/decay envelope |
| `lib/audio/note_player.dart` | Replaces every `PLAY`: quiz pitch, right/wrong blips, via `audioplayers` (`BytesSource`) |
| `lib/main.dart` | App entry, dark theme |

### Phase 1 engine (unchanged by Phase 2)

| File | Ports |
|---|---|
| `lib/engine/note_tables.dart` | **Generated** from the BASIC source: 175-entry flats/sharps letter tables (`assignletter`), 175-entry octave table (`assignoctave`), typo-variant map (`questionscreen`), octave→color maps |
| `lib/engine/note_mapper.dart` | `assignstrngnumber`, `assignfretnumber`, letter/octave lookups |
| `lib/engine/quiz_engine.dart` | `pickanote`: 17 string scopes, accidental filter, anti-repeat guards |
| `lib/engine/answer_normalizer.dart` | TYPO FILTER + sharp/flat/natural helpers |
| `lib/engine/scorer.dart` | Real Guitar +1, Air Guitar 0.5+0.5 partial credit |
| `lib/engine/session.dart` | Rep counting, `theoscore`, percent math |

## Fidelity notes

- The painter uses the QB64 program's own coordinates (strings at
  x = 390..450, nut y = 13, board end y = 327); the fret-spacing
  increments and the hardcoded `ylite` marker table are ported verbatim.
  Left-handed mode mirrors the string columns exactly like the BASIC
  `CASE 2` branch.
- Tap scoring in Real Guitar Mode accepts any tapped position whose
  pitch class matches the target (via the sharp-spelled `playNameOf`) —
  the same note lives in several places on the neck, and all of them are
  musically correct answers to "tap the Db".
- The `PLAY "On"` octave-cue side effect from `assignoctave` is dropped:
  the octave's cue is now the rainbow color, as the method intends.
- Air Guitar Mode asks letter + octave together on one screen (the BASIC
  asked them sequentially); the 0.5 + 0.5 partial-credit scoring is
  identical.

## Tests

- `test/engine_test.dart` — 20 engine tests (Phase 1, oracle = the BASIC source)
- `test/geometry_test.dart` — wire/marker/string math; note-ID round-trips
  (ID → marker → screen → ID) for all 175 IDs × 4 board configs
- `test/audio_test.dart` — pitch math (E4 = 329.63 Hz, B1 = 61.74 Hz),
  WAV header validity
- `test/board_tap_test.dart` — widget taps resolve to the right note IDs

`flutter analyze`: clean. `flutter test`: all passing.

## Toolchain

Flutter SDK 3.47.7 (Dart 3.13.5) at `~/workspace/.sdks/flutter`
(on PATH as `$HOME/workspace/.sdks/flutter/bin`).
Android SDK (cmdline-tools, platform android-36, build-tools 35.0.0,
platform-tools, licenses) at `~/workspace/.sdks/android`; JDK 17 at
`~/workspace/.sdks/jdk-17.0.20.1+1`; Gradle 9.3.1 dist at
`~/workspace/.sdks/gradle-9.3.1-all.zip`.

APK status (2026-10-21): `flutter build apk` is blocked in this sandbox —
Gradle's daemon starts and listens fine, but the sandbox tampers with
loopback TCP (a Java loopback repro received corrupted bytes), so the
daemon handshake fails. Not a code problem: `flutter analyze` is clean
and all 42 tests pass. On a normal machine (or this VM if the network
filtering changes), the toolchain above should build the APK as-is.
Note: `android/gradle/wrapper/gradle-wrapper.properties` points
`distributionUrl` at the local Gradle zip and `android/gradle.properties`
sets `-Xmx2g` — sandbox-specific tweaks; harmless elsewhere, but the
`file://` URL only resolves on this VM.

## Phase 3 (done 2026-10-21)

Spectrum Viewer, lesson plan, persistence. `flutter analyze` clean,
`flutter test` 54/54 passing (42 prior + 12 new in `test/phase3_test.dart`).
