import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../data/clues.dart';
import '../data/music.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/notation.dart';
import 'clue_runner.dart';
import 'section_page.dart';
import 'shared.dart';

final beatsSection = SectionInfo(
  title: 'Beat maths',
  emoji: '🧮',
  minutes: 7,
  color: Lab.orange,
  goal: 'Every note lasts for some beats. Add them up!',
  keyWords: const ['Beats', 'Rhythm', 'Whole note', 'Half note', 'Quarter note', 'Eighth note'],
  sentence: 'How many beats is it?',
  steps: const [
    IntroStep('👀', 'Look at the notes.'),
    IntroStep('🧮', 'Add up the beats with your team.'),
    IntroStep('🔐', 'At Clue time, write the answers on your code card!'),
  ],
  introVisual: (context) => const _BeatChart(),
  introNotes: const TeacherNotes(
    say: [
      'A beat is the steady pulse in music – like a clock: tick, tick, tick. ⏱️',
      'Each note lasts for a number of beats. Tap a note to hear it with the beat clicks.',
      'Example: a quarter note (1) + a half note (2) = 3 beats.',
    ],
    ask: ['How many beats is a whole note?', 'Which note is the shortest?'],
    watch: [
      'An eighth note is half a beat – two eighth notes make one beat.',
      'Hollow notes are longer. Filled notes are shorter.',
    ],
  ),
  game: (context) => const _BeatsGame(),
  gameNotes: const TeacherNotes(
    say: [
      'Practice: teams race to answer – give the point to the first correct team.',
      'Clue time: clues 4, 5 and 6. Students write their answer – no talking!',
    ],
    ask: ['How many beats is it?'],
    watch: [
      'Level 3 adds eighth notes (½ beat), so answers can be like "2½".',
      'Do not show answers at Clue time – they are unveiled at the end.',
    ],
  ),
);

class _BeatChart extends StatefulWidget {
  const _BeatChart();
  @override
  State<_BeatChart> createState() => _BeatChartState();
}

class _BeatChartState extends State<_BeatChart> {
  static const _lengths = [NoteLength.whole, NoteLength.half, NoteLength.quarter, NoteLength.eighth];
  int? _playing;
  PlayToken _token = PlayToken();

  @override
  void dispose() {
    _token.cancel();
    super.dispose();
  }

  Future<void> _hear(int i) async {
    _token.cancel();
    final token = _token = PlayToken();
    setState(() => _playing = i);
    final len = _lengths[i];
    await playRhythm(len == NoteLength.eighth ? [NoteLength.eighthPair] : [len], token);
    if (mounted && _playing == i) setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('🔊 Tap a note to hear how long it is',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      Row(children: [
        for (var i = 0; i < _lengths.length; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _hear(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _playing == i ? Lab.orange.withValues(alpha: 0.2) : Colors.white,
                  border: Border.all(color: Lab.orange, width: 3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(children: [
                  RhythmNoteView(_lengths[i], size: 100, color: Lab.ink),
                  const SizedBox(height: 8),
                  Text(_lengths[i].label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(
                      '${beatsText(_lengths[i].beats)} ${_lengths[i].beats == 1 ? 'beat' : 'beats'}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Lab.orange)),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 24),
      const Text('🧪 Example', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(children: [
          RhythmNoteView(NoteLength.quarter, size: 90, color: Lab.ink),
          Text('  +  ', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
          RhythmNoteView(NoteLength.half, size: 90, color: Lab.ink),
          Text('  =  3 beats', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Lab.orange)),
        ]),
      ),
    ]);
  }
}

class _BeatsGame extends StatefulWidget {
  const _BeatsGame();
  @override
  State<_BeatsGame> createState() => _BeatsGameState();
}

class _BeatsGameState extends State<_BeatsGame> {
  static const _rounds = ['2 notes', '3 notes', '3–4 notes with eighth notes', 'Listen only – count the clicks!'];
  final _rng = Random();
  bool _clueMode = false;
  int _round = 1;
  List<NoteLength> _notes = [];
  bool _revealed = false;
  int? _lit;
  bool _playing = false;
  PlayToken _token = PlayToken();

  @override
  void initState() {
    super.initState();
    _notes = _make();
  }

  @override
  void dispose() {
    _token.cancel();
    super.dispose();
  }

  List<NoteLength> _make() {
    const basic = [NoteLength.whole, NoteLength.half, NoteLength.quarter];
    const withEighth = [NoteLength.whole, NoteLength.half, NoteLength.quarter, NoteLength.eighth];
    final count = switch (_round) {
      1 => 2,
      2 => 3,
      3 => 3 + _rng.nextInt(2),
      _ => 2 + _rng.nextInt(2),
    };
    final pool = _round == 3 ? withEighth : basic;
    List<NoteLength> list;
    do {
      list = [for (var i = 0; i < count; i++) pool[_rng.nextInt(pool.length)]];
    } while (_round == 3 && !list.contains(NoteLength.eighth));
    return list;
  }

  void _next() {
    _token.cancel();
    setState(() {
      _notes = _make();
      _revealed = false;
      _lit = null;
      _playing = false;
    });
  }

  Future<void> _play() async {
    _token.cancel();
    final token = _token = PlayToken();
    setState(() => _playing = true);
    await playRhythm(_notes, token, onIndex: (i) {
      if (mounted) setState(() => _lit = i < 0 ? null : i);
    });
    if (mounted && !token.cancelled) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ModeSwitch(
          clues: _clueMode,
          color: Lab.orange,
          onChanged: (v) {
            _token.cancel();
            setState(() => _clueMode = v);
          },
        ),
      ),
      Expanded(
        child: _clueMode
            ? const ClueRunner(numbers: ClueBank.beatNumbers, color: Lab.orange)
            : _practice(),
      ),
    ]);
  }

  Widget _practice() {
    final total = _notes.fold<double>(0, (a, b) => a + b.beats);
    final hideNotes = _round == 4 && !_revealed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(children: [
        RoundPicker(
          round: _round,
          descriptions: _rounds,
          color: Lab.orange,
          onChanged: (r) {
            _round = r;
            _next();
          },
        ),
        const SizedBox(height: 12),
        const SentenceBanner('How many beats is it?', color: Lab.orange, fontSize: 30, emoji: '🧮'),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                for (var i = 0; i < _notes.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('+', style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900)),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lit == i ? Lab.orange.withValues(alpha: 0.25) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black12, width: 2),
                    ),
                    child: Column(children: [
                      hideNotes
                          ? const SizedBox(
                              width: 120,
                              height: 200,
                              child: Center(child: Text('👂', style: TextStyle(fontSize: 80))))
                          : RhythmNoteView(_notes[i], size: 200, color: Lab.ink),
                      SizedBox(
                        height: 50,
                        child: _revealed
                            ? Text(
                                '${beatsText(_notes[i].beats)} ${_notes[i].beats == 1 ? 'beat' : 'beats'}',
                                style: const TextStyle(
                                    fontSize: 34, fontWeight: FontWeight.w900, color: Lab.orange))
                            : null,
                      ),
                    ]),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('=', style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 220,
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _revealed ? Lab.orange : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Lab.orange, width: 6),
                  ),
                  child: Text(
                    _revealed ? beatsText(total) : '?',
                    style: TextStyle(
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                        color: _revealed ? Colors.white : Lab.orange),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          BigButton('Play it', emoji: '🔊', color: Colors.blueGrey, onPressed: _playing ? null : _play),
          const SizedBox(width: 18),
          BigButton('Show answer', emoji: '👀', color: Lab.teal,
              onPressed: _revealed
                  ? null
                  : () {
                      setState(() => _revealed = true);
                      Sound.instance.correct();
                    }),
          const SizedBox(width: 18),
          BigButton('Next', emoji: '➡️', color: Lab.orange, onPressed: _next),
        ]),
      ]),
    );
  }
}
