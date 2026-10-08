import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/class_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class IntroStep {
  final String emoji;
  final String text;
  const IntroStep(this.emoji, this.text);
}

/// Everything that describes one lesson section.
class SectionInfo {
  final String title;
  final String emoji;
  final int minutes;
  final Color color;
  final bool showScores;

  // Intro screen
  final String goal;
  final List<String> keyWords;
  final String? sentence;
  final List<IntroStep> steps;
  final WidgetBuilder introVisual;
  final TeacherNotes introNotes;

  // Game screen
  final WidgetBuilder game;
  final TeacherNotes gameNotes;

  const SectionInfo({
    required this.title,
    required this.emoji,
    required this.minutes,
    required this.color,
    this.showScores = true,
    required this.goal,
    required this.keyWords,
    this.sentence,
    required this.steps,
    required this.introVisual,
    required this.introNotes,
    required this.game,
    required this.gameNotes,
  });
}

/// Shows a section: first its intro screen, then the game.
class SectionPage extends StatefulWidget {
  final List<SectionInfo> sections;
  final int index;
  const SectionPage({super.key, required this.sections, required this.index});

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  bool _intro = true;

  SectionInfo get info => widget.sections[widget.index];

  @override
  void dispose() {
    Sound.instance.stopAll();
    super.dispose();
  }

  void _setIntro(bool v) {
    Sound.instance.stopAll();
    setState(() => _intro = v);
  }

  void _goTo(int i) {
    Sound.instance.stopAll();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => SectionPage(sections: widget.sections, index: i),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    final hasNext = widget.index < widget.sections.length - 1;
    return Scaffold(
      body: Column(
        children: [
          // Top bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                info.color,
                Color.lerp(info.color, Colors.white, 0.25)!,
              ]),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              bottom: false,
              child: Row(children: [
                IconButton(
                  tooltip: 'All sections',
                  icon: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Text(info.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text('${widget.index + 1}. ${info.title}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('📖 Intro')),
                    ButtonSegment(value: false, label: Text('🚀 Play')),
                  ],
                  selected: {_intro},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => _setIntro(s.first),
                  style: ButtonStyle(
                    textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    backgroundColor: WidgetStateProperty.resolveWith((st) =>
                        st.contains(WidgetState.selected) ? Colors.white : Colors.white24),
                    foregroundColor: WidgetStateProperty.resolveWith((st) =>
                        st.contains(WidgetState.selected) ? info.color : Colors.white),
                  ),
                ),
                const Spacer(),
                SectionTimer(minutes: info.minutes),
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: cs,
                  builder: (context, _) => IconButton(
                    tooltip: 'Teacher notes (T)',
                    icon: Icon(Icons.sticky_note_2,
                        color: Colors.white.withValues(alpha: cs.teacherNotes ? 1 : 0.4)),
                    onPressed: cs.toggleTeacherNotes,
                  ),
                ),
                if (hasNext)
                  TextButton(
                    onPressed: () => _goTo(widget.index + 1),
                    child: const Text('Next ➜',
                        style: TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: cs,
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LabBackground(
                      tint: info.color,
                      seed: widget.index * 13 + (_intro ? 1 : 2),
                      child: _intro
                          ? _IntroView(info: info, onStart: () => _setIntro(false))
                          : Column(children: [
                              Expanded(child: Builder(builder: info.game)),
                              if (info.showScores) const ScoreBar(),
                            ]),
                    ),
                  ),
                  if (cs.teacherNotes)
                    TeacherNotesPanel(
                      _intro ? info.introNotes : info.gameNotes,
                      heading: _intro ? 'Teacher notes – intro' : 'Teacher notes – game',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  final SectionInfo info;
  final VoidCallback onStart;
  const _IntroView({required this.info, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.goal,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: info.color, height: 1.1)),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final w in info.keyWords)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: info.color, width: 3),
              ),
              child: Text(w, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
        ]),
        if (info.sentence != null) ...[
          const SizedBox(height: 22),
          SentenceBanner(info.sentence!, color: info.color, fontSize: 26),
        ],
        const SizedBox(height: 26),
        const Text('🧑‍🔬 How it works', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (var i = 0; i < info.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: info.color,
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Text(info.steps[i].emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(info.steps[i].text,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        const SizedBox(height: 16),
        BigButton("Let's go!", emoji: '🚀', color: info.color, onPressed: onStart),
      ],
    );

    final visual = LabPanel(border: info.color, child: Builder(builder: info.introVisual));

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 1000;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 5, child: left),
                const SizedBox(width: 28),
                Expanded(flex: 6, child: visual),
              ])
            : Column(children: [left, const SizedBox(height: 24), visual]),
      );
    });
  }
}
