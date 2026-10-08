import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/mic.dart';
import '../audio/sound.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'section_page.dart';

final microscopeSection = SectionInfo(
  title: 'Sound microscope',
  emoji: '🔬',
  minutes: 5,
  color: Lab.teal,
  showScores: false,
  goal: 'Sound is a wave! Let’s look at it.',
  keyWords: const ['Sound', 'Pitch', 'High', 'Low', 'Beats'],
  sentence: 'Is the pitch high or low?',
  steps: const [
    IntroStep('🎤', 'Make a sound near the microphone.'),
    IntroStep('🔬', 'Watch your sound wave on the screen.'),
    IntroStep('🤔', 'High sounds = tight, squiggly waves. Low sounds = big, slow waves.'),
  ],
  introVisual: (context) => const _WaveExamples(),
  introNotes: const TeacherNotes(
    say: [
      'Today we are sound scientists! 🔬',
      'Every sound is a wave. Our microscope lets us SEE sound.',
      'A high pitch makes a tight, squiggly wave. A low pitch makes a big, slow wave.',
      'A clap makes a big spike – one beat!',
    ],
    ask: ['Which wave is the bird? Which is the elephant?', 'What do you think a clap looks like?'],
    watch: [
      'Students may think "high" means "loud". Show that loud = tall wave, high = squiggly wave.',
    ],
  ),
  game: (context) => const _Microscope(),
  gameNotes: const TeacherNotes(
    say: [
      'Press "Turn on microscope" and allow the microphone.',
      'Call students up one at a time to try a challenge card.',
    ],
    ask: [
      'Can you make the wave tiny? HUGE?',
      'Is the pitch high or low?',
      'How many spikes did we make? (claps = beats)',
    ],
    watch: [
      'Press "Freeze" to stop the wave and talk about it.',
      'If claps are not counted, move the slider in Rhythm scanner later – this screen just shows them.',
    ],
  ),
);

/// Paints a wave: a sine wave, or a clap spike.
class WavePainter extends CustomPainter {
  final double cycles;
  final double amplitude; // 0..1
  final Color color;
  final bool spike;
  WavePainter({required this.cycles, required this.amplitude, required this.color, this.spike = false});

  @override
  void paint(Canvas canvas, Size s) {
    final mid = s.height / 2;
    final p = Path();
    const n = 400;
    for (var i = 0; i <= n; i++) {
      final x = s.width * i / n;
      double y;
      if (spike) {
        final t = (i / n - 0.4).abs();
        y = (i / n >= 0.4 ? math.exp(-t * 18) * math.sin(i * 1.7) : 0.0) * amplitude;
      } else {
        y = math.sin(i / n * cycles * 2 * math.pi) * amplitude;
      }
      final py = mid - y * mid * 0.9;
      if (i == 0) {
        p.moveTo(x, py);
      } else {
        p.lineTo(x, py);
      }
    }
    canvas.drawLine(Offset(0, mid), Offset(s.width, mid),
        Paint()..color = color.withValues(alpha: 0.25)..strokeWidth = 2);
    canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant WavePainter old) => true;
}

class _WaveExamples extends StatefulWidget {
  const _WaveExamples();
  @override
  State<_WaveExamples> createState() => _WaveExamplesState();
}

class _WaveExamplesState extends State<_WaveExamples> {
  String? _playing;
  int _playId = 0;

  void _hear(String sound) {
    final id = ++_playId;
    Sound.instance.example(sound);
    setState(() => _playing = sound);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted && id == _playId) setState(() => _playing = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String sound, String emoji, String label, Color c, Widget wave) {
      final on = _playing == sound;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: on ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _hear(sound),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(children: [
                SizedBox(
                  width: 150,
                  child: Column(children: [
                    AnimatedScale(
                      scale: on ? 1.25 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Text(emoji, style: const TextStyle(fontSize: 54)),
                    ),
                    Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
                  ]),
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: on ? Lab.gold : Colors.transparent, width: 4),
                      boxShadow: on ? [BoxShadow(color: Lab.lime.withValues(alpha: 0.5), blurRadius: 20)] : const [],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: wave,
                  ),
                ),
                const SizedBox(width: 10),
                Text(on ? '🔊' : '🔈', style: const TextStyle(fontSize: 34)),
              ]),
            ),
          ),
        ),
      );
    }

    return Column(children: [
      const Text('What sounds look like 👀  (tap to hear!)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      row('high', '🐦', 'HIGH pitch', Lab.purple,
          CustomPaint(painter: WavePainter(cycles: 18, amplitude: 0.6, color: Lab.lime))),
      row('low', '🐘', 'LOW pitch', Colors.brown,
          CustomPaint(painter: WavePainter(cycles: 3, amplitude: 0.6, color: Lab.lime))),
      row('loud', '📢', 'LOUD', Lab.orange,
          CustomPaint(painter: WavePainter(cycles: 6, amplitude: 1, color: Lab.lime))),
      row('quiet', '🤫', 'quiet', Colors.blueGrey,
          CustomPaint(painter: WavePainter(cycles: 6, amplitude: 0.15, color: Lab.lime))),
      row('clap', '👏', 'CLAP = beat', Lab.blue,
          CustomPaint(painter: WavePainter(cycles: 0, amplitude: 1, color: Lab.lime, spike: true))),
    ]);
  }
}

class _Microscope extends StatefulWidget {
  const _Microscope();
  @override
  State<_Microscope> createState() => _MicroscopeState();
}

class _MicroscopeState extends State<_Microscope> {
  final mic = Mic.instance;
  List<double>? _frozen;
  int _zoom = 1; // 0 = wide, 1 = medium, 2 = close
  int _claps = 0;
  int _flashUntil = 0;
  int? _challenge;

  static const _challenges = [
    ('🤫', 'Make the wave tiny'),
    ('📢', 'Make the wave HUGE'),
    ('🐦', 'Make a HIGH pitch'),
    ('🐘', 'Make a LOW pitch'),
    ('👏', 'Make 4 spikes (4 beats)'),
  ];

  @override
  void initState() {
    super.initState();
    mic.addOnsetListener(_onClap);
  }

  @override
  void dispose() {
    mic.removeOnsetListener(_onClap);
    mic.stop();
    super.dispose();
  }

  void _onClap(int ms) {
    if (!mounted || _frozen != null) return;
    setState(() {
      _claps++;
      _flashUntil = LabClock.ms + 300;
    });
  }

  int get _samples => const [2048, 1024, 384][_zoom];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListenableBuilder(
        listenable: mic,
        builder: (context, _) {
          final data = _frozen ?? mic.latest(_samples);
          final pitch = _frozen == null ? mic.roughPitch() : null;
          final flash = LabClock.ms < _flashUntil;
          return Column(children: [
            // Challenge cards
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < _challenges.length; i++)
                ChoiceChip(
                  label: Text('${_challenges[i].$1} ${_challenges[i].$2}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _challenge == i ? Colors.white : Lab.ink)),
                  selected: _challenge == i,
                  selectedColor: Lab.teal,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Lab.teal, width: 2),
                  showCheckmark: false,
                  onSelected: (s) => setState(() => _challenge = s ? i : null),
                ),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Loud-o-meter
                _Meter(level: _frozen == null ? mic.level : 0),
                const SizedBox(width: 14),
                // Scope screen
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: flash ? Lab.gold : Lab.teal, width: flash ? 8 : 5),
                      boxShadow: [BoxShadow(color: Lab.teal.withValues(alpha: 0.3), blurRadius: 30)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(children: [
                        Positioned.fill(child: CustomPaint(painter: _ScopePainter(data))),
                        if (!mic.running && _frozen == null)
                          Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('🔬', style: TextStyle(fontSize: 90)),
                              const SizedBox(height: 10),
                              BigButton('Turn on microscope', emoji: '🎤', color: Lab.teal,
                                  onPressed: () => mic.start()),
                              if (mic.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text('${mic.error}\nCheck that the microphone is allowed.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white70, fontSize: 18)),
                                ),
                            ]),
                          ),
                        if (_frozen != null)
                          const Positioned(
                            top: 14,
                            left: 18,
                            child: Text('❄️ FROZEN',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          ),
                        if (flash)
                          const Positioned(
                            top: 14,
                            right: 18,
                            child: Text('👏 SPIKE!',
                                style: TextStyle(
                                    color: Lab.gold, fontSize: 34, fontWeight: FontWeight.w900)),
                          ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Pitch-o-meter + clap counter
                SizedBox(
                  width: 170,
                  child: Column(children: [
                    Expanded(child: _PitchMeter(hz: pitch)),
                    const SizedBox(height: 12),
                    LabPanel(
                      border: Lab.blue,
                      padding: const EdgeInsets.all(10),
                      child: Column(children: [
                        const Text('👏 Spikes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('$_claps',
                            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Lab.blue)),
                        TextButton(
                            onPressed: () => setState(() => _claps = 0), child: const Text('Reset')),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              BigButton(mic.running ? 'Turn off' : 'Turn on', emoji: mic.running ? '⏹️' : '🎤',
                  color: mic.running ? Colors.blueGrey : Lab.teal,
                  onPressed: () => mic.running ? mic.stop() : mic.start()),
              const SizedBox(width: 16),
              BigButton(_frozen == null ? 'Freeze' : 'Unfreeze', emoji: '❄️', color: Lab.blue,
                  onPressed: () => setState(() =>
                      _frozen = _frozen == null ? List.of(mic.latest(_samples)) : null)),
              const SizedBox(width: 24),
              const Text('🔍 Zoom', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Far')),
                  ButtonSegment(value: 1, label: Text('Mid')),
                  ButtonSegment(value: 2, label: Text('Close')),
                ],
                selected: {_zoom},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _zoom = s.first;
                  _frozen = null;
                }),
              ),
            ]),
          ]);
        },
      ),
    );
  }
}

class _ScopePainter extends CustomPainter {
  final List<double> data;
  _ScopePainter(this.data);

  @override
  void paint(Canvas canvas, Size s) {
    final grid = Paint()
      ..color = Lab.teal.withValues(alpha: 0.18)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 10; i++) {
      final x = s.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (var i = 1; i < 6; i++) {
      final y = s.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    final mid = s.height / 2;
    canvas.drawLine(Offset(0, mid), Offset(s.width, mid),
        Paint()..color = Lab.teal.withValues(alpha: 0.45)..strokeWidth = 2);
    if (data.isEmpty) return;

    // Gentle auto-gain so quiet sounds are still visible, but loud stays loud.
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = s.width * i / (data.length - 1);
      final y = mid - (data[i] * 2.2).clamp(-1.0, 1.0) * mid * 0.92;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = Lab.lime.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(
        path,
        Paint()
          ..color = Lab.lime
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _ScopePainter old) => true;
}

class _Meter extends StatelessWidget {
  final double level;
  const _Meter({required this.level});

  @override
  Widget build(BuildContext context) {
    final v = level.clamp(0.0, 1.0);
    final c = v > 0.6 ? Lab.red : (v > 0.25 ? Lab.orange : Lab.green);
    return SizedBox(
      width: 90,
      child: Column(children: [
        const Text('📢', style: TextStyle(fontSize: 34)),
        const Text('Loud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.black12, width: 3),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(4),
            child: FractionallySizedBox(
              heightFactor: math.max(0.04, v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text('🤫', style: TextStyle(fontSize: 30)),
      ]),
    );
  }
}

/// Shows roughly how high or low the sound is, from 🐘 to 🐦.
class _PitchMeter extends StatelessWidget {
  final double? hz;
  const _PitchMeter({required this.hz});

  @override
  Widget build(BuildContext context) {
    // Map 80 Hz .. 2000 Hz (log scale) to 0..1.
    double? t;
    if (hz != null && hz! > 40) {
      t = ((math.log(hz!) - math.log(80)) / (math.log(2000) - math.log(80))).clamp(0.0, 1.0);
    }
    return LabPanel(
      border: Lab.purple,
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        const Text('Pitch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Text('🐦', style: TextStyle(fontSize: 36)),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            return SizedBox.expand(
                child: Stack(alignment: Alignment.topCenter, children: [
              Container(
                width: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Lab.purple, Colors.brown],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              if (t != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  top: (1 - t) * (c.maxHeight - 40),
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Lab.gold,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🎵', style: TextStyle(fontSize: 20)),
                  ),
                ),
            ]));
          }),
        ),
        const Text('🐘', style: TextStyle(fontSize: 36)),
      ]),
    );
  }
}
