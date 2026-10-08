import 'package:flutter_test/flutter_test.dart';
import 'package:melodies/data/clues.dart';
import 'package:melodies/data/music.dart';

void main() {
  test('note lengths have the right beats', () {
    expect(NoteLength.whole.beats, 4);
    expect(NoteLength.eighth.beats, 0.5);
    expect(beatsText(2.5), '2½');
    expect(beatsText(3), '3');
  });

  test('a new code has 8 clues with answers', () {
    final bank = ClueBank.random();
    expect(bank.clues.length, 8);
    for (var n = 1; n <= 8; n++) {
      expect(bank.byNumber(n).answer, isNotEmpty);
    }
    expect(['High', 'Low'], contains(bank.byNumber(1).answer));
  });
}
