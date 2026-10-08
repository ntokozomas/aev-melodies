import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/mic.dart';
import '../audio/sound.dart';
import '../data/clues.dart';
import '../state/class_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'clue_runner.dart';
import 'section_page.dart';

final pitchClickSection = SectionInfo(
  title: 'Pitch on Click',
  emoji: '🎧',
  minutes: 12,
  color: Lab.purple,
  goal: 'Can you hear every beep? 🎧',
  keyWords: const ['Pitch', 'High', 'Low', 'Hearing test'],
  sentence: 'Is the pitch high or low?',
  steps: const [
    IntroStep('🙈', 'One scientist sits at the front with headphones and a blindfold.'),
    IntroStep('⌨️', 'Every time you hear a beep – press SPACE!'),
    IntroStep('🐦', 'Everyone else: silent signals! Hand UP for a high beep, hand DOWN for a low beep.'),
  ],
  introVisual: (context) => const _Audiogram(),
  introNotes: const TeacherNotes(
    say: [
      'Doctors test our ears with a hearing test called an audiogram.',
      'The machine plays beeps – low and high, long and short, loud and super quiet.',
      'Today YOU are the doctors and the patients!',
      'Tap the dots to hear low and high beeps (through the speakers).',
    ],
    ask: ['Is this beep high or low?', 'Which animal would make this sound?'],
    watch: [
      'Explain the points: hit +1, quiet hit +2, false alarm −1.',
      'Plug the headphones in BEFORE starting the first test.',
    ],
  ),
  game: (context) => const _PitchClickGame(),
  gameNotes: const TeacherNotes(
    say: [
      'Pick the team, blindfold the tester, put on the headphones, press Start.',
      'Each test has 12 beeps: 12 different pitches, 4 volumes, long or short, with random gaps.',
      'Audience: silent signals only – hand up for high, hand down for low.',
    ],
    ask: ['Was that beep high or low?'],
    watch: [
      'The teams take turns automatically after each test.',
      'A test never goes below 0 points.',
      'Before "Clue time", unplug the headphones so the whole class can hear!',
    ],
  ),
);

String _hzLabel(int hz) => hz < 1000
    ? '$hz'
    : '${hz % 1000 == 0 ? hz ~/ 1000 : (hz / 1000).toStringAsFixed(1)}k';

double _pitchPos(int hz) =>
    (math.log(hz) - math.log(125)) / (math.log(12000) - math.log(125)); // 0 low → 1 high

/// Intro visual: the six test pitches as dots, low to high.
class _Audiogram extends StatelessWidget {
  const _Audiogram();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('🩺 The hearing test pitches – tap to hear',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      SizedBox(
        height: 260,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('🐦\nHIGH', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text('🐘\nLOW', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              return Stack(children: [
                for (var i = 0; i < Sound.beepFrequencies.length; i++)
                  Positioned(
                    left: (c.maxWidth - 56) * i / (Sound.beepFrequencies.length - 1),
                    top: (1 - _pitchPos(Sound.beepFrequencies[i])) * (c.maxHeight - 56),
                    child: _Dot(hz: Sound.beepFrequencies[i]),
                  ),
              ]);
            }),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      const _PointsTable(),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final int hz;
  const _Dot({required this.hz});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Sound.instance.beep(hz, BeepLevel.mid),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(Colors.brown, Lab.purple, _pitchPos(hz)),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        alignment: Alignment.center,
        child: Text(_hzLabel(hz),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _PointsTable extends StatelessWidget {
  const _PointsTable();

  @override
  Widget build(BuildContext context) {
    Widget row(String e, String t, String p, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text(e, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            Text(p, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c)),
          ]),
        );
    return Column(children: [
      row('✅', 'Hit – you heard the beep', '+1', Lab.green),
      row('🌟', 'Hit on a quiet beep', '+2', Lab.gold),
      row('💎', 'Hit on a super-quiet beep', '+3', Lab.blue),
      row('❌', 'Miss', '0', Colors.blueGrey),
      row('🚨', 'False alarm – pressed with no beep', '−1', Lab.red),
    ]);
  }
}

enum _BeepState { waiting, playing, hit, miss }

class _Beep {
  final int hz;
  final BeepLevel level;
  final int gapMs;
  final bool short;
  _BeepState state = _BeepState.waiting;
  int? reactionMs;
  int startMs = 0;
  _Beep(this.hz, this.level, this.gapMs, this.short);
}

class _PitchClickGame extends StatefulWidget {
  const _PitchClickGame();
  @override
  State<_PitchClickGame> createState() => _PitchClickGameState();
}

class _PitchClickGameState extends State<_PitchClickGame> {
  static const _windowMs = 1500;
  final _rng = math.Random();
  final _keys = FocusNode(debugLabel: 'pitch-on-click');

  bool _clueMode = false;
  int _team = 0;
  List<_Beep> _beeps = [];
  bool _running = false;
  bool _finished = false;
  String _status = 'Ready when you are!';
  int _falseAlarms = 0;
  int _flashFalseUntil = 0;
  int _flashHitUntil = 0;
  PlayToken _token = PlayToken();

  @override
  void dispose() {
    _token.cancel();
    _keys.dispose();
    super.dispose();
  }

  int get _points {
    var p = 0;
    for (final b in _beeps) {
      if (b.state == _BeepState.hit) {
        p += switch (b.level) {
          BeepLevel.faint => 3,
          BeepLevel.quiet => 2,
          _ => 1,
        };
      }
    }
    return math.max(0, p - _falseAlarms);
  }

  void _newTest() {
    final freqs = List.of(Sound.beepFrequencies)..shuffle(_rng);
    // 12 beeps: every pitch once, mostly quiet ones, half of them short.
    final levels = [
      BeepLevel.loud, BeepLevel.loud,
      BeepLevel.mid, BeepLevel.mid, BeepLevel.mid,
      BeepLevel.quiet, BeepLevel.quiet, BeepLevel.quiet, BeepLevel.quiet,
      BeepLevel.faint, BeepLevel.faint, BeepLevel.faint,
    ]..shuffle(_rng);
    _beeps = [
      for (var i = 0; i < freqs.length; i++)
        _Beep(freqs[i], levels[i], 1000 + _rng.nextInt(3800), _rng.nextBool()),
    ];
    _falseAlarms = 0;
    _finished = false;
  }

  Future<void> _start() async {
    _token.cancel();
    final token = _token = PlayToken();
    setState(() {
      _newTest();
      _running = true;
      _status = 'Get ready… 🤫';
    });
    _keys.requestFocus();
    if (!await Sound.wait(1500, token)) return;
    for (final b in _beeps) {
      if (!mounted || token.cancelled) return;
      setState(() => _status = 'Listening… 👂');
      if (!await Sound.wait(b.gapMs, token)) return;
      b.startMs = LabClock.ms;
      setState(() => b.state = _BeepState.playing);
      Sound.instance.beep(b.hz, b.level, short: b.short);
      if (!await Sound.wait(_windowMs, token)) return;
      if (b.state == _BeepState.playing) setState(() => b.state = _BeepState.miss);
    }
    if (!await Sound.wait(600, token)) return;
    _finish();
  }

  void _finish() {
    final hits = _beeps.where((b) => b.state == _BeepState.hit).toList();
    final reactions = [for (final b in hits) b.reactionMs!];
    final avg = reactions.isEmpty ? null : reactions.reduce((a, b) => a + b) ~/ reactions.length;
    ClassState.instance.addHearing(HearingResult(
      _team,
      hits.length,
      _beeps.where((b) => b.state == _BeepState.miss).length,
      _falseAlarms,
      _points,
      avg,
    ));
    Sound.instance.sfx(Sfx.tada);
    setState(() {
      _running = false;
      _finished = true;
      _status = 'Test complete! 🎉';
    });
  }

  void _stop() {
    _token.cancel();
    setState(() {
      _running = false;
      _beeps = [];
      _status = 'Test stopped.';
    });
  }

  void _press() {
    if (!_running) return;
    final now = LabClock.ms;
    _Beep? active;
    for (final b in _beeps) {
      if (b.state == _BeepState.playing) active = b;
    }
    setState(() {
      if (active != null) {
        active.state = _BeepState.hit;
        active.reactionMs = now - active.startMs;
        _flashHitUntil = now + 500;
      } else {
        _falseAlarms++;
        _flashFalseUntil = now + 900;
      }
    });
    // Clear the flashes later.
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() {});
    });
  }

  void _nextTester() {
    setState(() {
      _team = (_team + 1) % ClassState.instance.teams.length;
      _beeps = [];
      _finished = false;
      _status = 'Ready when you are!';
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e.logicalKey == LogicalKeyboardKey.space) {
      if (e is KeyDownEvent) _press();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ModeSwitch(
          clues: _clueMode,
          color: Lab.purple,
          onChanged: (v) {
            if (v) _stop();
            setState(() => _clueMode = v);
          },
        ),
      ),
      Expanded(
        child: _clueMode
            ? Column(children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                      color: Lab.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Text('🎧➡️🔈 Unplug the headphones so everyone can hear!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                const Expanded(
                    child: ClueRunner(numbers: ClueBank.pitchNumbers, color: Lab.purple)),
              ])
            : Focus(
                focusNode: _keys,
                autofocus: true,
                onKeyEvent: _onKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _keys.requestFocus(),
                  child: _testView(cs),
                ),
              ),
      ),
    ]);
  }

  Widget _testView(ClassState cs) {
    final team = cs.teams[_team];
    final now = LabClock.ms;
    final falseFlash = now < _flashFalseUntil;
    final hitFlash = now < _flashHitUntil;
    final playing = _beeps.any((b) => b.state == _BeepState.playing);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          flex: 7,
          child: Column(children: [
            // Who is being tested
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🧑‍🔬 Tester from:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              for (var i = 0; i < cs.teams.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${cs.teams[i].emoji} ${cs.teams[i].name}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: i == _team ? Colors.white : cs.teams[i].color)),
                    selected: i == _team,
                    selectedColor: cs.teams[i].color,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: cs.teams[i].color, width: 2),
                    showCheckmark: false,
                    onSelected: _running ? null : (_) => setState(() => _team = i),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            // Big status light
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 110,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: falseFlash
                    ? Lab.red
                    : hitFlash
                        ? Lab.green
                        : playing
                            ? Lab.gold
                            : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: team.color, width: 4),
              ),
              child: Text(
                falseFlash
                    ? '🚨 FALSE ALARM  −1'
                    : hitFlash
                        ? '✅ HIT!'
                        : playing
                            ? '🔊 BEEP NOW!'
                            : _status,
                style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: (falseFlash || hitFlash) ? Colors.white : Lab.ink),
              ),
            ),
            const SizedBox(height: 14),
            // The beep track
            Expanded(
              child: LabPanel(
                border: Lab.purple,
                padding: const EdgeInsets.all(14),
                child: _beeps.isEmpty
                    ? const Center(
                        child: Text('🙈 Blindfold on?  🎧 Headphones on?  ⌨️ Finger on SPACE?',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                      )
                    : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('🐦', style: TextStyle(fontSize: 34)),
                          Text('🐘', style: TextStyle(fontSize: 34)),
                        ]),
                        const SizedBox(width: 8),
                        for (var i = 0; i < _beeps.length; i++)
                          Expanded(child: _BeepSlot(index: i, beep: _beeps[i])),
                      ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!_running && !_finished)
                BigButton('Start test', emoji: '▶️', color: team.color, onPressed: _start),
              if (_running) ...[
                BigButton('PRESS (space)', emoji: '👆', color: Lab.purple, onPressed: _press),
                const SizedBox(width: 18),
                BigButton('Stop', emoji: '⏹️', color: Colors.blueGrey, onPressed: _stop),
              ],
              if (_finished) ...[
                BigButton('Next tester', emoji: '🔁', color: cs.teams[(_team + 1) % cs.teams.length].color,
                    onPressed: _nextTester),
                const SizedBox(width: 18),
                BigButton('Test again', emoji: '▶️', color: Colors.blueGrey, onPressed: _start),
              ],
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        // Side: live points / report / leaderboard
        SizedBox(
          width: 300,
          child: Column(children: [
            LabPanel(
              border: team.color,
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Text(_finished ? '📋 Hearing report' : '⭐ This test',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('$_points',
                    style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: team.color)),
                Text('points for ${team.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (_beeps.isNotEmpty) ...[
                  const Divider(height: 20),
                  _stat('✅ Hits', '${_beeps.where((b) => b.state == _BeepState.hit).length}'),
                  _stat('❌ Misses', '${_beeps.where((b) => b.state == _BeepState.miss).length}'),
                  _stat('🚨 False alarms', '$_falseAlarms'),
                  if (_finished) _stat('⚡ Reaction', _avgText()),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            Expanded(child: _Leaderboard()),
          ]),
        ),
      ]),
    );
  }

  String _avgText() {
    final r = [
      for (final b in _beeps)
        if (b.reactionMs != null) b.reactionMs!
    ];
    if (r.isEmpty) return '–';
    final avg = r.reduce((a, b) => a + b) / r.length;
    return '${(avg / 1000).toStringAsFixed(2)} s';
  }

  Widget _stat(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(a, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          Text(b, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _BeepSlot extends StatelessWidget {
  final int index;
  final _Beep beep;
  const _BeepSlot({required this.index, required this.beep});

  @override
  Widget build(BuildContext context) {
    final shown = beep.state != _BeepState.waiting;
    final playing = beep.state == _BeepState.playing;
    final size = switch (beep.level) {
      BeepLevel.loud => 52.0,
      BeepLevel.mid => 42.0,
      BeepLevel.quiet => 32.0,
      BeepLevel.faint => 24.0,
    };
    final color = switch (beep.state) {
      _BeepState.hit => Lab.green,
      _BeepState.miss => Lab.red,
      _BeepState.playing => Lab.gold,
      _BeepState.waiting => Colors.grey.shade300,
    };
    return Column(children: [
      Text('${index + 1}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final top = (1 - _pitchPos(beep.hz)) * (c.maxHeight - size);
          return Stack(alignment: Alignment.topCenter, children: [
            Center(
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (shown)
              Positioned(
                top: top,
                child: AnimatedScale(
                  scale: playing ? 1.25 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: playing
                          ? [BoxShadow(color: Lab.gold, blurRadius: 30, spreadRadius: 6)]
                          : const [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      playing ? '🔊' : (beep.state == _BeepState.hit ? '✓' : '✗'),
                      style: TextStyle(
                          fontSize: size * 0.45, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
          ]);
        }),
      ),
      SizedBox(
        height: 46,
        child: Column(children: [
          Text('${_hzLabel(beep.hz)} Hz',
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          if (beep.reactionMs != null)
            Text('${(beep.reactionMs! / 1000).toStringAsFixed(2)} s',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Lab.green)),
          if (beep.state == _BeepState.waiting)
            const Text('…', style: TextStyle(fontSize: 16, color: Colors.black38)),
        ]),
      ),
    ]);
  }
}

class _Leaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    final list = cs.hearing.reversed.toList();
    String fastest(int team) {
      final r = [
        for (final h in cs.hearing)
          if (h.team == team && h.avgReactionMs != null) h.avgReactionMs!
      ];
      if (r.isEmpty) return '–';
      return '${(r.reduce(math.min) / 1000).toStringAsFixed(2)} s';
    }

    return LabPanel(
      border: Lab.gold,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('⚡ Fastest ears', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        for (var t = 0; t < cs.teams.length; t++)
          Text('${cs.teams[t].emoji} ${cs.teams[t].name}: ${fastest(t)}',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.teams[t].color)),
        const Divider(),
        Text('Tests done: ${cs.hearing.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Expanded(
          child: ListView(children: [
            for (final h in list)
              Text(
                  '${cs.teams[h.team].emoji} ${h.points} pts • ✅${h.hits} ❌${h.misses} 🚨${h.falseAlarms}',
                  style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ]),
    );
  }
}
