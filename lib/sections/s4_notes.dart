import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../data/clues.dart';
import '../data/music.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hand_sign.dart';
import '../widgets/notation.dart';
import 'clue_runner.dart';
import 'section_page.dart';

final notesSection = SectionInfo(
  title: 'Note detectives',
  emoji: '🕵️',
  minutes: 6,
  color: Lab.pink,
  goal: 'Every note has a name and a hand sign!',
  keyWords: const ['Notes', 'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Ti'],
  sentence: 'What note is it?',
  steps: const [
    IntroStep('✋', 'Look at the hand sign or the note on the lines.'),
    IntroStep('🗣️', 'Say the note name: Do, Re, Mi…'),
    IntroStep('🔐', 'At Clue time, write the answers on your code card!'),
  ],
  introVisual: (context) => const _Ladder(),
  introNotes: const TeacherNotes(
    say: [
      'Notes go up like a ladder: Do, Re, Mi, Fa, Sol, La, Ti, Do.',
      'Each note has a hand sign. When the note goes up, the hand goes up too.',
      'Notes also live on the five lines of the staff – higher on the staff = higher pitch.',
    ],
    ask: ['Which sign is the highest?', 'Which note sits on the bottom line? (Mi)'],
    watch: [
      'Students mixing up Mi (flat, palm down) and Sol (palm facing you).',
      'Fa is the thumb pointing down – it "falls" to Mi.',
    ],
  ),
  game: (context) => const _NotesGame(),
  gameNotes: const TeacherNotes(
    say: [
      'Practice: show the sign or note, teams answer – first correct team gets a point.',
      'Clue time: clues 7 and 8. Students write the note name on their card.',
    ],
    ask: ['What note is it?'],
    watch: ['Level 4 shows notes on the staff instead of hand signs.'],
  ),
);

class _Ladder extends StatelessWidget {
  const _Ladder();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('🪜 The note ladder – tap to hear', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < allSolfege.length; i++)
              Padding(
                padding: EdgeInsets.only(top: (allSolfege.length - 1 - i) * 34.0, left: 5, right: 5),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Sound.instance.note(allSolfege[i].midi, beats: 1.2),
                  child: HandSignCard(allSolfege[i], size: 120, showName: true, showDescription: false),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      StaffView(
        notes: [for (final n in allSolfege) StaffNote(n)],
        height: 210,
        minSlots: 8,
      ),
    ]);
  }
}

class _NotesGame extends StatefulWidget {
  const _NotesGame();
  @override
  State<_NotesGame> createState() => _NotesGameState();
}

class _NotesGameState extends State<_NotesGame> {
  static const _rounds = [
    'Hand signs: Do, Mi, Sol',
    'Hand signs: Do to Sol',
    'Hand signs: all the notes',
    'Notes on the staff',
  ];
  final _rng = Random();
  bool _clueMode = false;
  int _round = 1;
  Solfege _current = doNote;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _current = _pick();
  }

  List<Solfege> get _pool => switch (_round) {
        1 => const [doNote, miNote, solNote],
        2 => const [doNote, reNote, miNote, faNote, solNote],
        _ => allSolfege,
      };

  Solfege _pick() {
    final pool = _pool;
    Solfege n;
    do {
      n = pool[_rng.nextInt(pool.length)];
    } while (pool.length > 1 && n.midi == _current.midi);
    return n;
  }

  void _next() => setState(() {
        _current = _pick();
        _revealed = false;
      });

  void _reveal() {
    setState(() => _revealed = true);
    Sound.instance.note(_current.midi, beats: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ModeSwitch(
          clues: _clueMode,
          color: Lab.pink,
          onChanged: (v) => setState(() => _clueMode = v),
        ),
      ),
      Expanded(
        child: _clueMode
            ? const ClueRunner(numbers: ClueBank.noteNumbers, color: Lab.pink)
            : _practice(),
      ),
    ]);
  }

  Widget _practice() {
    final staff = _round == 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(children: [
        RoundPicker(
          round: _round,
          descriptions: _rounds,
          color: Lab.pink,
          onChanged: (r) {
            _round = r;
            _next();
          },
        ),
        const SizedBox(height: 12),
        const SentenceBanner('What note is it?', color: Lab.pink, fontSize: 30, emoji: '🕵️'),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: staff
                  ? Container(
                      width: 760,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: StaffView(
                        notes: [StaffNote(_revealed ? _current : _current.copyGrey())],
                        showNames: _revealed,
                        height: 320,
                        minSlots: 1,
                      ),
                    )
                  : HandSignCard(_current, size: 340, showName: _revealed, colored: _revealed),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          BigButton(_revealed ? 'Hear it again' : 'Show answer', emoji: '👀', color: Lab.teal,
              onPressed: _reveal),
          const SizedBox(width: 18),
          BigButton('Next', emoji: '➡️', color: Lab.pink, onPressed: _next),
        ]),
      ]),
    );
  }
}
