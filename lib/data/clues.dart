import 'dart:math';

import 'music.dart';

enum ClueType { pitch, beats, note }

/// One square on the students' code card.
class Clue {
  final int number; // 1..8 (the middle square is the rhythm scan)
  final ClueType type;

  // pitch: is note 2 higher or lower than note 1?
  final int? midi1, midi2;
  // beats: add up these notes
  final List<NoteLength> rhythm;
  // note: which solfege note is this?
  final Solfege? note;
  final bool showAsHandSign;

  const Clue._(this.number, this.type,
      {this.midi1, this.midi2, this.rhythm = const [], this.note, this.showAsHandSign = false});

  String get answer => switch (type) {
        ClueType.pitch => midi2! > midi1! ? 'High' : 'Low',
        ClueType.beats => beatsText(rhythm.fold<double>(0, (a, b) => a + b.beats)),
        ClueType.note => note!.name,
      };

  String get emoji => switch (type) {
        ClueType.pitch => '🎧',
        ClueType.beats => '🧮',
        ClueType.note => '🎵',
      };

  String get question => switch (type) {
        ClueType.pitch => 'Is the pitch high or low?',
        ClueType.beats => 'How many beats is it?',
        ClueType.note => showAsHandSign ? 'Which note is this hand sign?' : 'Which note is this?',
      };
}

/// The secret code for one lesson: 8 clues + the rhythm scan in the middle.
class ClueBank {
  final List<Clue> clues;
  ClueBank._(this.clues);

  static const pitchNumbers = [1, 2, 3];
  static const beatNumbers = [4, 5, 6];
  static const noteNumbers = [7, 8];

  Clue byNumber(int n) => clues.firstWhere((c) => c.number == n);

  factory ClueBank.random([Random? rng]) {
    final r = rng ?? Random();
    final list = <Clue>[];

    // Pitch clues: mix of high and low, never the same answer three times.
    final dirs = [true, false, r.nextBool()]..shuffle(r);
    for (var i = 0; i < 3; i++) {
      final gap = 4 + r.nextInt(9); // 4..12 semitones
      final up = dirs[i];
      final start = up ? 52 + r.nextInt(14) : 64 + r.nextInt(14);
      list.add(Clue._(pitchNumbers[i], ClueType.pitch,
          midi1: start, midi2: up ? start + gap : start - gap));
    }

    // Beat clues: 2–4 notes, the last one may use an eighth note.
    const basic = [NoteLength.whole, NoteLength.half, NoteLength.quarter];
    final usedTotals = <String>{};
    for (var i = 0; i < 3; i++) {
      List<NoteLength> rhythm;
      String total;
      do {
        final count = 2 + i;
        rhythm = [for (var k = 0; k < count; k++) basic[r.nextInt(basic.length)]];
        if (i == 2 && r.nextBool()) rhythm[r.nextInt(count)] = NoteLength.eighth;
        total = beatsText(rhythm.fold<double>(0, (a, b) => a + b.beats));
      } while (usedTotals.contains(total));
      usedTotals.add(total);
      list.add(Clue._(beatNumbers[i], ClueType.beats, rhythm: rhythm));
    }

    // Note clues: one hand sign, one note on the staff.
    const pool = [doNote, reNote, miNote, faNote, solNote, laNote, tiNote];
    final a = pool[r.nextInt(pool.length)];
    Solfege b;
    do {
      b = pool[r.nextInt(pool.length)];
    } while (b.midi == a.midi);
    list.add(Clue._(noteNumbers[0], ClueType.note, note: a, showAsHandSign: true));
    list.add(Clue._(noteNumbers[1], ClueType.note, note: b));

    return ClueBank._(list);
  }
}
