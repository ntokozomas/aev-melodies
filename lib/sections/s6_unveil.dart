import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../data/clues.dart';
import '../state/class_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'section_page.dart';

final unveilSection = SectionInfo(
  title: 'Crack the code',
  emoji: '🔐',
  minutes: 7,
  color: Lab.gold,
  goal: 'Time to unveil the secret code! 🔐',
  keyWords: const ['Code', 'Stamps', 'Bingo'],
  steps: const [
    IntroStep('🔓', 'The vault opens one square at a time.'),
    IntroStep('✅', 'Find that number on YOUR card. Right answer? Tick it!'),
    IntroStep('🌟', 'A line of 3 ticks = a stamp. A full card = 🏆 3 stamps!'),
  ],
  introVisual: (context) => const _RulesCard(),
  introNotes: const TeacherNotes(
    say: [
      'Everyone has a code card. The squares are in a different order on each card!',
      'When a number is unveiled, find that number on your own card.',
      'Lines can go across, down or corner to corner (diagonal).',
    ],
    ask: ['Which number are you looking for?', 'How many lines do you have?'],
    watch: [
      'The middle ⭐ square is the team rhythm scan – everyone in a team that passed ticks it.',
      'Stamps: 1 line = 1 stamp, 2+ lines = 2 stamps, full card = 3 stamps.',
    ],
  ),
  game: (context) => const _Unveil(),
  gameNotes: const TeacherNotes(
    say: [
      'Press "Open the vault", then "Unveil next" for each square. Build the suspense! 🥁',
      'Give students a few seconds to tick before the next one.',
    ],
    ask: ['Who got it right?', 'Who has a line already?'],
    watch: [
      'Check lines quickly by asking students to hold up their cards.',
      'Press "New lesson" on the home screen to make a new code for the next class.',
    ],
  ),
);

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    // A sample card with the top row ticked.
    const sample = ['3', '7', '1', '5', '⭐', '8', '2', '6', '4'];
    const ticked = {0, 1, 2, 4};
    return Column(children: [
      const Text('🎫 Your code card', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      SizedBox(
        width: 330,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < 9; i++)
              Container(
                decoration: BoxDecoration(
                  color: ticked.contains(i) ? Lab.green.withValues(alpha: 0.18) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: i < 3 ? Lab.gold : Colors.black26, width: i < 3 ? 5 : 2),
                ),
                alignment: Alignment.center,
                child: Stack(alignment: Alignment.center, children: [
                  Text(sample[i], style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  if (ticked.contains(i))
                    const Positioned(
                        right: 6, bottom: 2, child: Text('✅', style: TextStyle(fontSize: 22))),
                ]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _rule('🌟', '1 line', '1 stamp'),
      _rule('🌟🌟', '2 lines or more', '2 stamps'),
      _rule('🏆', 'Full card', '3 stamps'),
    ]);
  }

  Widget _rule(String e, String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 70, child: Text(e, style: const TextStyle(fontSize: 28))),
          Expanded(child: Text(a, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          Text(b, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Lab.gold)),
        ]),
      );
}

class _Unveil extends StatefulWidget {
  const _Unveil();
  @override
  State<_Unveil> createState() => _UnveilState();
}

class _UnveilState extends State<_Unveil> with SingleTickerProviderStateMixin {
  // Order the tiles are unveiled: 1..8 then the rhythm star (0).
  static const _order = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  bool _open = false;
  int _shown = 0;
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  bool get _done => _shown >= _order.length;

  void _openVault() {
    Sound.instance.sfx(Sfx.vault);
    setState(() => _open = true);
  }

  void _next() {
    if (_done) return;
    setState(() => _shown++);
    if (_done) {
      Sound.instance.sfx(Sfx.tada);
      _confetti.forward(from: 0);
    } else {
      Sound.instance.sfx(Sfx.reveal);
    }
  }

  void _all() {
    setState(() => _shown = _order.length);
    Sound.instance.sfx(Sfx.tada);
    _confetti.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
          child: _open ? _board() : _vault(),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _confetti,
            builder: (context, _) => _confetti.isAnimating
                ? CustomPaint(painter: _ConfettiPainter(_confetti.value))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ]);
  }

  Widget _vault() {
    return Center(
      key: const ValueKey('vault'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 340,
          height: 340,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFFCBD5E1), Color(0xFF64748B)]),
            border: Border.all(color: Lab.gold, width: 14),
            boxShadow: [BoxShadow(color: Lab.gold.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 6)],
          ),
          alignment: Alignment.center,
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🔒', style: TextStyle(fontSize: 120)),
            Text('SECRET CODE', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 30),
        BigButton('Open the vault', emoji: '🔓', color: Lab.gold, fontSize: 30, onPressed: _openVault),
      ]),
    );
  }

  Widget _board() {
    final cs = ClassState.instance;
    return Column(
      key: const ValueKey('board'),
      children: [
        Text(
            _done ? '🎉 Count your lines and collect your stamps! 🎉' : '🔍 Find the number on YOUR card!',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            const cols = 5;
            const rows = 2;
            final w = (c.maxWidth - 16 * (cols - 1)) / cols;
            final h = (c.maxHeight - 16 * (rows - 1)) / rows;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              for (var k = 0; k < _order.length; k++)
                SizedBox(
                  width: w,
                  height: h,
                  child: _Tile(
                    number: _order[k],
                    revealed: k < _shown,
                    clues: cs.clues,
                    isNext: k == _shown,
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!_done) ...[
            BigButton('Unveil next', emoji: '✨', color: Lab.gold, fontSize: 26, onPressed: _next),
            const SizedBox(width: 18),
            BigButton('Show all', emoji: '⏩', color: Colors.blueGrey, onPressed: _all),
          ] else
            _winner(cs),
        ]),
      ],
    );
  }

  Widget _winner(ClassState cs) {
    final a = cs.teams[0], b = cs.teams[1];
    final text = a.score == b.score
        ? '🤝 It’s a tie! ${a.score} – ${b.score}'
        : '🏆 ${(a.score > b.score ? a : b).name} wins!  ${a.emoji} ${a.score} – ${b.score} ${b.emoji}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Lab.gold, width: 5),
      ),
      child: Text(text, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
    );
  }
}

class _Tile extends StatelessWidget {
  final int number; // 0 = rhythm star
  final bool revealed;
  final bool isNext;
  final ClueBank clues;
  const _Tile({required this.number, required this.revealed, required this.clues, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final clue = number == 0 ? null : clues.byNumber(number);
    final color = clue == null
        ? Lab.blue
        : switch (clue.type) {
            ClueType.pitch => Lab.purple,
            ClueType.beats => Lab.orange,
            ClueType.note => Lab.pink,
          };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, a) => RotationTransition(
        turns: Tween(begin: 0.5, end: 1.0).animate(a),
        child: ScaleTransition(scale: a, child: child),
      ),
      child: revealed ? _front(clue, color) : _back(color),
    );
  }

  Widget _back(Color color) {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isNext ? 0.35 : 0.15),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color, width: isNext ? 6 : 3),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔐', style: TextStyle(fontSize: 44)),
            Text(number == 0 ? '⭐' : '$number',
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _front(Clue? clue, Color color) {
    final cs = ClassState.instance;
    return Container(
      key: const ValueKey('front'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color, width: 5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18)],
      ),
      padding: const EdgeInsets.all(10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: clue == null
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('⭐ Rhythm scan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                for (var t = 0; t < cs.teams.length; t++)
                  Text(
                    '${cs.teams[t].emoji} ${cs.teams[t].name}: '
                    '${cs.rhythm[t]?.passed == true ? 'PASS ✅' : 'no ✗'}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.teams[t].color),
                  ),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${clue.emoji} Square ${clue.number}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
                Text(clue.answer, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Lab.ink)),
              ]),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);
  static const _bits = ['🎉', '⭐', '🎵', '🎶', '🧪', '🌟', '🎊', '🔬'];

  @override
  void paint(Canvas canvas, Size s) {
    final rng = Random(42);
    for (var i = 0; i < 46; i++) {
      final x = rng.nextDouble() * s.width;
      final speed = 0.6 + rng.nextDouble() * 0.8;
      final delay = rng.nextDouble() * 0.4;
      final p = ((t - delay) * speed).clamp(0.0, 1.2);
      if (p <= 0) continue;
      final y = -60 + p * (s.height + 120);
      final wobble = sin((t * 6 + i) * 1.3) * 20;
      final tp = TextPainter(
        text: TextSpan(text: _bits[i % _bits.length], style: TextStyle(fontSize: 26 + rng.nextDouble() * 22)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + wobble, y));
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
