import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../data/music.dart';
import '../widgets/hand_sign.dart';
import '../widgets/notation.dart';

/// Plays pitched notes one after another, calling [onIndex] as each starts
/// (and with -1 at the end). Returns false if it was cancelled.
Future<bool> playMelody(List<StaffNote> notes, PlayToken token,
    {ValueChanged<int>? onIndex, double tempo = 1}) async {
  for (var i = 0; i < notes.length; i++) {
    if (token.cancelled) return false;
    onIndex?.call(i);
    final beats = notes[i].length.beats;
    Sound.instance.note(notes[i].note.midi, beats: beats * tempo);
    if (!await Sound.wait((beats * tempo * Sound.beatMs).round(), token)) return false;
  }
  onIndex?.call(-1);
  return true;
}

/// Plays a rhythm with a tick on every beat. [sound] adds a note for each
/// symbol (rests stay silent). [onIndex] is called as each symbol starts.
Future<bool> playRhythm(List<NoteLength> rhythm, PlayToken token,
    {ValueChanged<int>? onIndex, bool ticks = true, bool sound = true, int midi = 67}) async {
  // Work out when each beat tick falls.
  final total = rhythm.fold<double>(0, (a, b) => a + b.beats);
  final beatCount = total.ceil();
  var t = 0.0; // in beats
  var nextTick = 0;
  for (var i = 0; i < rhythm.length; i++) {
    if (token.cancelled) return false;
    onIndex?.call(i);
    final len = rhythm[i];
    final parts = len == NoteLength.eighthPair ? [0.5, 0.5] : [len.beats];
    for (final p in parts) {
      if (ticks) {
        while (nextTick < beatCount && nextTick <= t + 0.01) {
          Sound.instance.tick(accent: nextTick % 4 == 0);
          nextTick++;
        }
      }
      if (sound && len != NoteLength.rest) Sound.instance.note(midi, beats: p * 0.92);
      // Wait in half-beat steps so ticks inside long notes still sound.
      var waited = 0.0;
      while (waited < p - 0.01) {
        final step = (p - waited) >= 1 ? 1.0 : (p - waited);
        if (!await Sound.wait((step * Sound.beatMs).round(), token)) return false;
        waited += step;
        t += step;
        if (ticks && waited < p - 0.01) {
          while (nextTick < beatCount && nextTick <= t + 0.01) {
            Sound.instance.tick(accent: nextTick % 4 == 0);
            nextTick++;
          }
        }
      }
    }
  }
  onIndex?.call(-1);
  return true;
}

/// A big coloured note button with its hand sign, which lights up.
class NotePad extends StatelessWidget {
  final Solfege note;
  final bool lit;
  final VoidCallback? onTap;
  final double size;
  final bool showName;
  const NotePad(this.note,
      {super.key, this.lit = false, this.onTap, this.size = 200, this.showName = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: lit ? 1.08 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.12),
          boxShadow: lit
              ? [BoxShadow(color: note.color, blurRadius: 40, spreadRadius: 8)]
              : [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: lit ? note.color : Colors.white,
          borderRadius: BorderRadius.circular(size * 0.12),
          child: InkWell(
            borderRadius: BorderRadius.circular(size * 0.12),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(size * 0.06),
              child: HandSignCard(note,
                  size: size * 0.88, showName: showName, showDescription: false),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rhythm shown as a row of symbols, each box sized by its beats.
class RhythmBar extends StatelessWidget {
  final List<NoteLength> rhythm;
  final int? highlight;
  final double height;
  final Color color;
  final bool showBeats;
  final bool showClaps;
  const RhythmBar(
    this.rhythm, {
    super.key,
    this.highlight,
    this.height = 140,
    this.color = Colors.indigo,
    this.showBeats = false,
    this.showClaps = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade700, width: 3)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < rhythm.length; i++)
            Expanded(
              flex: (rhythm[i].beats * 4).round(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: highlight == i ? color.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RhythmNoteView(rhythm[i], size: height, color: Colors.black87),
                  ),
                  if (showBeats)
                    Text('${beatsText(rhythm[i].beats)} ${rhythm[i].beats == 1 ? 'beat' : 'beats'}',
                        style: TextStyle(
                            fontSize: height * 0.16, fontWeight: FontWeight.w800, color: color)),
                  if (showClaps)
                    Text(rhythm[i].clapHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: height * 0.13, color: Colors.grey.shade800)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
