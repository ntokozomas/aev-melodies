import 'package:flutter/material.dart';

/// One solfege note in C major (Do = C).
class Solfege {
  final String name; // Do, Re, Mi...
  final String letter; // C, D, E...
  final int midi; // 60 = middle C
  final Color color;

  /// Staff step: 0 = middle C (ledger line), 1 = D (below bottom line),
  /// 2 = E (bottom line) ... 7 = high C.
  final int staffStep;

  /// Short description of the Curwen hand sign, used for teacher notes and
  /// as a fallback when no hand-sign picture has been added.
  final String handSign;

  /// Rough emoji stand-in shown when there is no picture.
  final String emoji;

  const Solfege(this.name, this.letter, this.midi, this.color, this.staffStep,
      this.handSign, this.emoji);

  /// Same note drawn in grey, so the colour doesn't give the answer away.
  Solfege copyGrey() =>
      Solfege(name, letter, midi, const Color(0xFF475569), staffStep, handSign, emoji);

  String get imageAsset => 'assets/handsigns/${name.toLowerCase()}${midi == 72 ? '_high' : ''}.png';
}

const doNote = Solfege('Do', 'C', 60, Color(0xFFE53935), 0,
    'Closed fist, at waist height', '✊');
const reNote = Solfege('Re', 'D', 62, Color(0xFFFB8C00), 1,
    'Flat hand slanting upward', '🫸');
const miNote = Solfege('Mi', 'E', 64, Color(0xFFFDD835), 2,
    'Flat hand, palm down, level', '🫳');
const faNote = Solfege('Fa', 'F', 65, Color(0xFF43A047), 3,
    'Fist with thumb pointing down', '👎');
const solNote = Solfege('Sol', 'G', 67, Color(0xFF29B6F6), 4,
    'Flat hand, palm facing you', '✋');
const laNote = Solfege('La', 'A', 69, Color(0xFF5E35B1), 5,
    'Relaxed hand, fingers hanging down', '🫴');
const tiNote = Solfege('Ti', 'B', 71, Color(0xFFD81B60), 6,
    'Index finger pointing up and out', '☝️');
const highDoNote = Solfege('Do', 'C', 72, Color(0xFFE53935), 7,
    'Closed fist, held up high', '✊');

const allSolfege = [doNote, reNote, miNote, faNote, solNote, laNote, tiNote, highDoNote];

/// Note lengths used for rhythm activities.
enum NoteLength {
  whole(4, 'whole note'),
  half(2, 'half note'),
  quarter(1, 'quarter note'),
  eighth(0.5, 'eighth note'),
  eighthPair(1, 'two eighth notes'),
  rest(1, 'rest');

  final double beats;
  final String label;
  const NoteLength(this.beats, this.label);

  /// How the class claps it (clap-and-hold style).
  String get clapHint => switch (this) {
        NoteLength.whole => 'clap – 2 – 3 – 4',
        NoteLength.half => 'clap – 2',
        NoteLength.quarter => 'clap',
        NoteLength.eighth => 'quick clap',
        NoteLength.eighthPair => 'clap-clap (quick)',
        NoteLength.rest => 'no clap',
      };
}

String beatsText(double b) {
  final whole = b.floor();
  final hasHalf = (b - whole) > 0.25;
  if (!hasHalf) return '$whole';
  return whole == 0 ? '½' : '$whole½';
}
