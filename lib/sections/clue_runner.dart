import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../data/clues.dart';
import '../state/class_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hand_sign.dart';
import '../widgets/notation.dart';
import 'shared.dart';

/// Shows the code-card clues for one section, one at a time.
/// Answers are NOT shown here – they are unveiled at the end of the lesson.
class ClueRunner extends StatefulWidget {
  final List<int> numbers;
  final Color color;
  const ClueRunner({super.key, required this.numbers, required this.color});

  @override
  State<ClueRunner> createState() => _ClueRunnerState();
}

class _ClueRunnerState extends State<ClueRunner> {
  int _i = 0;
  int? _lit;
  PlayToken _token = PlayToken();

  Clue get clue => ClassState.instance.clues.byNumber(widget.numbers[_i]);

  @override
  void dispose() {
    _token.cancel();
    super.dispose();
  }

  void _go(int i) {
    _token.cancel();
    setState(() {
      _i = i;
      _lit = null;
    });
  }

  Future<void> _play() async {
    _token.cancel();
    final token = _token = PlayToken();
    final c = clue;
    switch (c.type) {
      case ClueType.pitch:
        for (final (i, m) in [(0, c.midi1!), (1, c.midi2!)]) {
          if (token.cancelled || !mounted) return;
          setState(() => _lit = i);
          Sound.instance.note(m, beats: 1.1);
          if (!await Sound.wait(1100, token)) return;
          if (mounted) setState(() => _lit = null);
          if (!await Sound.wait(300, token)) return;
        }
      case ClueType.beats:
        await playRhythm(c.rhythm, token, onIndex: (i) {
          if (mounted) setState(() => _lit = i < 0 ? null : i);
        });
      case ClueType.note:
        Sound.instance.note(c.note!.midi, beats: 1.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = clue;
    final color = widget.color;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Clue tabs
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < widget.numbers.length; k++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text('🔐 Clue ${widget.numbers[k]}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: k == _i ? Colors.white : color)),
                selected: k == _i,
                selectedColor: color,
                backgroundColor: Colors.white,
                side: BorderSide(color: color, width: 2),
                showCheckmark: false,
                onSelected: (_) => _go(k),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        SentenceBanner(c.question, color: color, fontSize: 30, emoji: c.emoji),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(padding: const EdgeInsets.all(24), child: _body(c)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: Lab.gold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Lab.gold, width: 3),
          ),
          child: Text('✏️ Write your answer in square ${c.number} of your code card!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          BigButton('Back', emoji: '⬅️', color: Colors.blueGrey,
              onPressed: _i == 0 ? null : () => _go(_i - 1)),
          const SizedBox(width: 18),
          BigButton(c.type == ClueType.note ? 'Hear it' : 'Play', emoji: '🔊', color: color,
              onPressed: _play),
          const SizedBox(width: 18),
          BigButton('Next clue', emoji: '➡️', color: Colors.blueGrey,
              onPressed: _i == widget.numbers.length - 1 ? null : () => _go(_i + 1)),
        ]),
      ]),
    );
  }

  Widget _body(Clue c) {
    switch (c.type) {
      case ClueType.pitch:
        return Row(children: [
          _bubble(0, 'Note 1'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text('➜', style: TextStyle(fontSize: 70, color: Colors.black26)),
          ),
          _bubble(1, 'Note 2'),
          const SizedBox(width: 40),
          const Column(children: [
            Text('🐦 High?', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
            SizedBox(height: 20),
            Text('🐘 Low?', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
          ]),
        ]);
      case ClueType.beats:
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          for (var i = 0; i < c.rhythm.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('+', style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900)),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lit == i ? widget.color.withValues(alpha: 0.25) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12, width: 2),
              ),
              child: RhythmNoteView(c.rhythm[i], size: 200),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('= ?', style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900)),
          ),
        ]);
      case ClueType.note:
        if (c.showAsHandSign) {
          return HandSignCard(c.note!, size: 340, colored: false);
        }
        return Container(
          width: 700,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: StaffView(
            notes: [StaffNote(c.note!.copyGrey())],
            showNames: false,
            height: 300,
            minSlots: 1,
          ),
        );
    }
  }

  Widget _bubble(int i, String label) {
    final lit = _lit == i;
    final color = widget.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? color : Colors.white,
        border: Border.all(color: color, width: 6),
        boxShadow: lit ? [BoxShadow(color: color, blurRadius: 40, spreadRadius: 6)] : const [],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎵', style: TextStyle(fontSize: 60)),
        Text(label,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: lit ? Colors.white : color)),
      ]),
    );
  }
}
