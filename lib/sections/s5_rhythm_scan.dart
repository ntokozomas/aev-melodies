import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/mic.dart';
import '../audio/sound.dart';
import '../data/music.dart';
import '../state/class_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/notation.dart';
import 'section_page.dart';
import 'shared.dart';

final rhythmScanSection = SectionInfo(
  title: 'Rhythm scanner',
  emoji: '📡',
  minutes: 8,
  color: Lab.blue,
  goal: 'Clap the rhythm – the scanner is watching! 📡',
  keyWords: const ['Rhythm', 'Beats', 'Rest'],
  steps: const [
    IntroStep('👀', 'Read the rhythm with your team.'),
    IntroStep('👏', 'After the count-in, clap it together. Long notes: clap, then HOLD.'),
    IntroStep('📡', 'The scanner checks every clap. Pass = ⭐ the middle square of your code card!'),
  ],
  introVisual: (context) => const _ClapChart(),
  introNotes: const TeacherNotes(
    say: [
      'Long notes: clap once, then hold your hands together while you count.',
      'Whole note: clap – 2 – 3 – 4. Half note: clap – 2. Quarter note: one clap.',
      'Two eighth notes: two quick claps in one beat. A rest: no clap!',
      'The scanner listens with the microphone and catches every extra clap.',
    ],
    ask: ['How do we clap a half note?', 'What do we do for a rest?'],
    watch: [
      'Counting out loud ("clap-2-3-4") helps the team stay together.',
      'Tap each note to practise once with the class.',
    ],
  ),
  game: (context) => const _ScannerGame(),
  gameNotes: const TeacherNotes(
    say: [
      'Choose the team. They stand together near the microphone.',
      'Press "Start scan": 1-2-3-4 count-in, then they clap while the notes light up.',
      'Each team can try more than once – the best score counts.',
    ],
    ask: ['Where did the scanner find an extra clap?', 'How many beats is it?'],
    watch: [
      'Test the mic first: one clap should flash "CLAP!". If not, raise the sensitivity.',
      'If the room is noisy, lower the sensitivity so talking is not counted.',
      'A pass (80% or more) gives the team +2 points and the ⭐ square.',
    ],
  ),
);

class _ClapChart extends StatefulWidget {
  const _ClapChart();
  @override
  State<_ClapChart> createState() => _ClapChartState();
}

class _ClapChartState extends State<_ClapChart> {
  static const _items = [
    NoteLength.whole,
    NoteLength.half,
    NoteLength.quarter,
    NoteLength.eighthPair,
    NoteLength.rest,
  ];
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
    await playRhythm([_items[i]], token, sound: _items[i] != NoteLength.rest);
    if (mounted && _playing == i) setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('👏 How to clap each note – tap to practise',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      for (var i = 0; i < _items.length; i++)
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _hear(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _playing == i ? Lab.blue.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Lab.blue.withValues(alpha: 0.5), width: 2),
            ),
            child: Row(children: [
              SizedBox(width: 90, child: Center(child: RhythmNoteView(_items[i], size: 70, color: Lab.ink))),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(_items[i].label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                flex: 4,
                child: Text(_items[i].clapHint,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Lab.blue)),
              ),
              Text(
                  _items[i] == NoteLength.rest
                      ? '1 beat (silent)'
                      : '${beatsText(_items[i].beats)} ${_items[i].beats == 1 ? 'beat' : 'beats'}',
                  style: const TextStyle(fontSize: 18, color: Colors.black54)),
            ]),
          ),
        ),
    ]);
  }
}

enum _Phase { idle, countIn, scanning, result }

class _ScanResult {
  final List<int> expected; // ms from bar start
  final List<int> detected; // ms from bar start (shift-corrected)
  final Set<int> matchedDetected; // indexes into detected
  final int matched;
  final int extras;
  final int accuracy;
  bool get passed => accuracy >= 80;
  const _ScanResult(this.expected, this.detected, this.matchedDetected, this.matched, this.extras, this.accuracy);
}

class _ScannerGame extends StatefulWidget {
  const _ScannerGame();
  @override
  State<_ScannerGame> createState() => _ScannerGameState();
}

class _ScannerGameState extends State<_ScannerGame> {
  static const _levels = ['Quarter + half notes', 'Add whole notes and rests', 'Add eighth notes'];
  static const _tolerance = 170;
  final _rng = Random();
  final mic = Mic.instance;

  int _team = 0;
  int _level = 1;
  List<NoteLength> _bar = [NoteLength.quarter, NoteLength.quarter, NoteLength.half];
  _Phase _phase = _Phase.idle;
  String? _countIn;
  int? _lit;
  int _barStart = 0;
  final List<int> _onsets = [];
  _ScanResult? _result;
  int _clapFlashUntil = 0;
  Timer? _ticker;
  PlayToken _token = PlayToken();

  @override
  void initState() {
    super.initState();
    mic.addOnsetListener(_onClap);
    _bar = _randomBar();
  }

  @override
  void dispose() {
    _token.cancel();
    _ticker?.cancel();
    mic.removeOnsetListener(_onClap);
    mic.stop();
    super.dispose();
  }

  List<NoteLength> get _pool => switch (_level) {
        1 => const [NoteLength.quarter, NoteLength.half],
        2 => const [NoteLength.whole, NoteLength.half, NoteLength.quarter, NoteLength.rest],
        _ => const [NoteLength.half, NoteLength.quarter, NoteLength.eighthPair, NoteLength.rest],
      };

  List<NoteLength> _randomBar() {
    List<NoteLength> bar;
    do {
      bar = [];
      var left = 4.0;
      while (left > 0) {
        final fits = _pool.where((n) => n.beats <= left).toList();
        final n = fits[_rng.nextInt(fits.length)];
        bar.add(n);
        left -= n.beats;
      }
      // Avoid boring bars: need at least 2 claps, and not only rests.
    } while (bar.where((n) => n != NoteLength.rest).length < 2);
    return bar;
  }

  void _onClap(int ms) {
    if (!mounted) return;
    if (_phase == _Phase.scanning) _onsets.add(ms);
    setState(() => _clapFlashUntil = LabClock.ms + 250);
  }

  List<int> _expected() {
    final out = <int>[];
    var t = 0.0;
    for (final n in _bar) {
      if (n == NoteLength.eighthPair) {
        out.add((t * Sound.beatMs).round());
        out.add(((t + 0.5) * Sound.beatMs).round());
      } else if (n != NoteLength.rest) {
        out.add((t * Sound.beatMs).round());
      }
      t += n.beats;
    }
    return out;
  }

  Future<void> _scan() async {
    if (!mic.running) {
      final ok = await mic.start();
      if (!ok) {
        if (mounted) setState(() {});
        return;
      }
    }
    _token.cancel();
    final token = _token = PlayToken();
    setState(() {
      _phase = _Phase.countIn;
      _result = null;
      _lit = null;
      _onsets.clear();
    });
    final startCount = LabClock.ms;
    for (var i = 1; i <= 4; i++) {
      if (!mounted || token.cancelled) return;
      setState(() => _countIn = '$i');
      Sound.instance.tick(accent: i == 1);
      final target = startCount + i * Sound.beatMs;
      while (LabClock.ms < target) {
        if (!await Sound.wait(10, token)) return;
      }
    }
    if (!mounted) return;
    _barStart = startCount + 4 * Sound.beatMs;
    setState(() {
      _countIn = null;
      _phase = _Phase.scanning;
    });
    // Light up each note as time passes.
    final starts = <double>[];
    var t = 0.0;
    for (final n in _bar) {
      starts.add(t);
      t += n.beats;
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final beat = (LabClock.ms - _barStart) / Sound.beatMs;
      var idx = -1;
      for (var i = 0; i < starts.length; i++) {
        if (beat >= starts[i]) idx = i;
      }
      if (beat >= 4) idx = -1;
      if (mounted && idx != (_lit ?? -1)) setState(() => _lit = idx < 0 ? null : idx);
    });
    final end = _barStart + 4 * Sound.beatMs + 500;
    while (LabClock.ms < end) {
      if (!await Sound.wait(20, token)) {
        _ticker?.cancel();
        return;
      }
    }
    _ticker?.cancel();
    _finish();
  }

  void _finish() {
    final expected = _expected();
    final raw = [for (final o in _onsets) o - _barStart]
        .where((d) => d > -400 && d < 4 * Sound.beatMs + 450)
        .toList();

    // Try small time shifts to allow for microphone delay; keep the best fit.
    var bestMatched = -1;
    var bestErr = 1 << 30;
    var bestShift = 0;
    for (var shift = -100; shift <= 400; shift += 10) {
      final (m, err, _) = _match(expected, [for (final d in raw) d - shift]);
      if (m > bestMatched || (m == bestMatched && err < bestErr)) {
        bestMatched = m;
        bestErr = err;
        bestShift = shift;
      }
    }
    final detected = [for (final d in raw) d - bestShift];
    final (matched, _, used) = _match(expected, detected);
    final extras = detected.length - matched;
    final total = expected.length + extras;
    final accuracy = total == 0 ? 0 : (100 * matched / total).round();
    final r = _ScanResult(expected, detected, used, matched, extras, accuracy);

    final cs = ClassState.instance;
    cs.setRhythm(_team, RhythmResult(accuracy, r.passed));
    if (r.passed) {
      cs.addPoint(_team, 2);
      Sound.instance.correct();
    } else {
      Sound.instance.wrong();
    }
    setState(() {
      _result = r;
      _phase = _Phase.result;
      _lit = null;
    });
  }

  /// Greedy matching: returns (matched count, total error, used detected indexes).
  (int, int, Set<int>) _match(List<int> expected, List<int> detected) {
    final used = <int>{};
    var matched = 0;
    var err = 0;
    for (final e in expected) {
      var best = -1;
      var bestD = _tolerance + 1;
      for (var i = 0; i < detected.length; i++) {
        if (used.contains(i)) continue;
        final d = (detected[i] - e).abs();
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
      if (best >= 0) {
        used.add(best);
        matched++;
        err += bestD;
      }
    }
    return (matched, err, used);
  }

  void _newRhythm() {
    _token.cancel();
    setState(() {
      _bar = _randomBar();
      _phase = _Phase.idle;
      _result = null;
      _lit = null;
    });
  }

  Future<void> _hearIt() async {
    _token.cancel();
    final token = _token = PlayToken();
    await playRhythm(_bar, token, onIndex: (i) {
      if (mounted) setState(() => _lit = i < 0 ? null : i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    final team = cs.teams[_team];
    final busy = _phase == _Phase.countIn || _phase == _Phase.scanning;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Column(children: [
            Row(children: [
              const Text('👥 Scanning:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                    onSelected: busy
                        ? null
                        : (_) => setState(() {
                              _team = i;
                              _result = null;
                              _phase = _Phase.idle;
                            }),
                  ),
                ),
              const SizedBox(width: 24),
              Expanded(
                child: RoundPicker(
                  round: _level,
                  descriptions: _levels,
                  color: Lab.blue,
                  onChanged: (r) {
                    if (busy) return;
                    _level = r;
                    _newRhythm();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 14),
            // Rhythm to clap
            Expanded(
              flex: 5,
              child: Stack(alignment: Alignment.center, children: [
                LabPanel(
                  border: team.color,
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, c) => RhythmBar(_bar,
                        highlight: _lit,
                        height: min(c.maxHeight * 0.62, 230.0),
                        color: Lab.blue,
                        showClaps: _phase == _Phase.idle || _phase == _Phase.result),
                  ),
                ),
                if (_countIn != null)
                  Container(
                    width: 210,
                    height: 210,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: team.color.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: team.color, blurRadius: 30)],
                    ),
                    child: Text(_countIn!,
                        style: const TextStyle(fontSize: 120, color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                if (_phase == _Phase.scanning)
                  const Positioned(
                    top: 10,
                    right: 20,
                    child: Text('📡 SCANNING…',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Lab.red)),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            // Seismograph result
            Expanded(
              flex: 4,
              child: LabPanel(
                border: Lab.blue,
                padding: const EdgeInsets.all(12),
                child: _result == null
                    ? Center(
                        child: Text(
                            busy ? '👏 Clap now!' : '📈 The scan results will appear here.',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black45)),
                      )
                    : _ResultView(result: _result!, bar: _bar),
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              BigButton('Hear it', emoji: '🔊', color: Colors.blueGrey, onPressed: busy ? null : _hearIt),
              const SizedBox(width: 16),
              BigButton(_result == null ? 'Start scan' : 'Scan again', emoji: '📡', color: team.color,
                  onPressed: busy ? null : _scan),
              const SizedBox(width: 16),
              BigButton('New rhythm', emoji: '🔀', color: Lab.blue, onPressed: busy ? null : _newRhythm),
            ]),
          ]),
        ),
        const SizedBox(width: 18),
        SizedBox(width: 260, child: _sidePanel(cs)),
      ]),
    );
  }

  Widget _sidePanel(ClassState cs) {
    return ListenableBuilder(
      listenable: mic,
      builder: (context, _) {
        final flash = LabClock.ms < _clapFlashUntil;
        return Column(children: [
          LabPanel(
            border: Lab.teal,
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              const Text('🎤 Microphone', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (!mic.running)
                FilledButton(
                    onPressed: () => mic.start(),
                    style: FilledButton.styleFrom(backgroundColor: Lab.teal),
                    child: const Text('Turn on'))
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: mic.level.clamp(0.0, 1.0),
                    minHeight: 16,
                    color: mic.level > mic.clapThreshold ? Lab.orange : Lab.teal,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: flash ? Lab.gold : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(flash ? '👏 CLAP!' : 'Clap to test',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ],
              if (mic.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(mic.error!, style: const TextStyle(color: Lab.red, fontSize: 13)),
                ),
              const SizedBox(height: 8),
              const Text('Sensitivity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Slider(
                // Higher slider = more sensitive = lower threshold.
                value: (0.6 - mic.clapThreshold).clamp(0.0, 0.55),
                min: 0,
                max: 0.55,
                activeColor: Lab.teal,
                onChanged: (v) => setState(() => mic.clapThreshold = 0.6 - v),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LabPanel(
              border: Lab.gold,
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('⭐ Best scans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                for (var t = 0; t < cs.teams.length; t++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${cs.teams[t].emoji} ${cs.teams[t].name}: '
                      '${cs.rhythm[t] == null ? '–' : '${cs.rhythm[t]!.accuracy}% ${cs.rhythm[t]!.passed ? '⭐' : ''}'}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.teams[t].color),
                    ),
                  ),
                const Spacer(),
                const Text('80% or more = PASS ⭐',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black54)),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}

class _ResultView extends StatelessWidget {
  final _ScanResult result;
  final List<NoteLength> bar;
  const _ResultView({required this.result, required this.bar});

  @override
  Widget build(BuildContext context) {
    final r = result;
    // Find extra claps that landed inside a held note.
    var heldExtra = false;
    var t = 0.0;
    for (final n in bar) {
      if (n == NoteLength.half || n == NoteLength.whole || n == NoteLength.rest) {
        final from = (t * Sound.beatMs) + (n == NoteLength.rest ? -80 : 200);
        final to = (t + n.beats) * Sound.beatMs - 150;
        for (var i = 0; i < r.detected.length; i++) {
          if (!r.matchedDetected.contains(i) && r.detected[i] > from && r.detected[i] < to) {
            heldExtra = true;
          }
        }
      }
      t += n.beats;
    }
    return Row(children: [
      SizedBox(
        width: 210,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${r.accuracy}%',
              style: TextStyle(
                  fontSize: 64, fontWeight: FontWeight.w900, color: r.passed ? Lab.green : Lab.red)),
          Text(r.passed ? '⭐ PASSED!' : '🔁 Try again',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('✅ ${r.matched}/${r.expected.length} claps   🚨 ${r.extras} extra',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (heldExtra)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Someone clapped during a hold or rest! ✋',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Lab.red)),
            ),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(child: CustomPaint(size: Size.infinite, painter: _SeismoPainter(r))),
    ]);
  }
}

/// Timeline: grey circles = where claps should be, spikes = real claps.
class _SeismoPainter extends CustomPainter {
  final _ScanResult r;
  _SeismoPainter(this.r);

  @override
  void paint(Canvas canvas, Size s) {
    const startMs = -400.0;
    final endMs = 4.0 * Sound.beatMs + 400;
    double x(num ms) => (ms - startMs) / (endMs - startMs) * s.width;
    final base = s.height * 0.72;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16)),
        Paint()..color = const Color(0xFF0B1220));
    final grid = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    for (var b = 0; b <= 4; b++) {
      final bx = x(b * Sound.beatMs);
      canvas.drawLine(Offset(bx, 10), Offset(bx, s.height - 10), grid);
      if (b < 4) {
        final tp = TextPainter(
          text: TextSpan(
              text: '${b + 1}',
              style: const TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(bx + 6, 8));
      }
    }
    canvas.drawLine(Offset(0, base), Offset(s.width, base), Paint()..color = Colors.white38..strokeWidth = 2);

    // Expected claps
    for (final e in r.expected) {
      canvas.drawCircle(
          Offset(x(e), base),
          14,
          Paint()
            ..color = Colors.white70
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    // Detected claps
    for (var i = 0; i < r.detected.length; i++) {
      final ok = r.matchedDetected.contains(i);
      final c = ok ? Lab.lime : Lab.red;
      final dx = x(r.detected[i]);
      canvas.drawLine(Offset(dx, base), Offset(dx, base - s.height * 0.55),
          Paint()
            ..color = c
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(dx, base), 7, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant _SeismoPainter old) => old.r != r;
}
