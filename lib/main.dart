import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sound.dart';
import 'sections/s1_microscope.dart';
import 'sections/s2_pitch_click.dart';
import 'sections/s3_beats.dart';
import 'sections/s4_notes.dart';
import 'sections/s5_rhythm_scan.dart';
import 'sections/s6_unveil.dart';
import 'sections/section_page.dart';
import 'state/class_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Sound.instance.init();
  runApp(const MelodiesApp());
}

/// The lesson, in order.
final List<SectionInfo> lessonSections = [
  microscopeSection,
  pitchClickSection,
  beatsSection,
  notesSection,
  rhythmScanSection,
  unveilSection,
];

class MelodiesApp extends StatelessWidget {
  const MelodiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melodies Sound Lab',
      debugShowCheckedModeBanner: false,
      theme: labTheme(),
      // Press T anywhere to show or hide the teacher notes.
      builder: (context, child) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyT): ClassState.instance.toggleTeacherNotes,
        },
        child: Focus(autofocus: true, child: child ?? const SizedBox.shrink()),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    final total = lessonSections.fold<int>(0, (a, s) => a + s.minutes);
    return Scaffold(
      body: LabBackground(
        tint: Lab.purple,
        seed: 3,
        opacity: 0.18,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Lab.purple, Lab.pink]),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Text('🔬🎵', style: TextStyle(fontSize: 44)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShaderMask(
                      shaderCallback: (r) =>
                          const LinearGradient(colors: [Lab.purple, Lab.pink, Lab.orange]).createShader(r),
                      child: const Text('Melodies Sound Lab',
                          style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                    ),
                    const SizedBox(height: 6),
                    Text('🧑‍🔬 Scientists wanted!  Crack the secret code of sound.  •  $total minutes',
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.black54)),
                  ]),
                ),
              ]),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 1100 ? 3 : 2;
                  final rows = (lessonSections.length / cols).ceil();
                  final w = (c.maxWidth - 20 * (cols - 1)) / cols;
                  final h = (c.maxHeight - 20 * (rows - 1)) / rows;
                  return Wrap(spacing: 20, runSpacing: 20, children: [
                    for (var i = 0; i < lessonSections.length; i++)
                      SizedBox(width: w, height: h, child: _SectionCard(index: i)),
                  ]);
                }),
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: cs,
                builder: (context, _) => Row(children: [
                  for (final t in cs.teams)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.color,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('${t.emoji} ${t.name}: ${t.score}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _confirmNewLesson(context),
                    icon: const Text('🔄', style: TextStyle(fontSize: 20)),
                    label: const Text('New lesson',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  const Text('🖨️ Cards: print/code_cards.pdf',
                      style: TextStyle(fontSize: 15, color: Colors.black54)),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: cs.toggleTeacherNotes,
                    icon: const Text('📋', style: TextStyle(fontSize: 20)),
                    label: Text(cs.teacherNotes ? 'Teacher notes: ON (T)' : 'Teacher notes: off (T)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmNewLesson(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Start a new lesson?'),
        content: const Text('This makes a new secret code and resets both team scores.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('New lesson')),
        ],
      ),
    );
    if (yes == true) ClassState.instance.newLesson();
  }
}

class _SectionCard extends StatelessWidget {
  final int index;
  const _SectionCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final s = lessonSections[index];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: s.color.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SectionPage(sections: lessonSections, index: index),
        )),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: s.color, width: 4),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: s.color, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(s.emoji, style: const TextStyle(fontSize: 50)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(12)),
                    child: Text('Step ${index + 1}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  Text(s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  Text('⏱️ ${s.minutes} min',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black54)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
