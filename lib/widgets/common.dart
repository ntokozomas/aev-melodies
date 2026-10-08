import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../state/class_state.dart';
import '../theme.dart';

/// Notes for teachers, shown in a side panel only when teacher notes are on
/// (press T, or tap the small notes icon in the top bar).
class TeacherNotes {
  final List<String> say;
  final List<String> ask;
  final List<String> watch;
  const TeacherNotes({this.say = const [], this.ask = const [], this.watch = const []});
}

class TeacherNotesPanel extends StatelessWidget {
  final TeacherNotes notes;
  final String heading;
  const TeacherNotesPanel(this.notes, {super.key, this.heading = 'Teacher notes'});

  @override
  Widget build(BuildContext context) {
    Widget group(String title, String emoji, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$emoji  $title',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: Colors.brown.shade800)),
            const SizedBox(height: 6),
            for (final s in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text('• $s', style: const TextStyle(fontSize: 15, height: 1.3)),
              ),
          ],
        ),
      );
    }

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border(left: BorderSide(color: Colors.amber.shade300, width: 3)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(children: [
            const Text('📋', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(heading,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            IconButton(
              tooltip: 'Hide notes (T)',
              icon: const Icon(Icons.close),
              onPressed: ClassState.instance.toggleTeacherNotes,
            ),
          ]),
          const SizedBox(height: 10),
          group('Say', '🗣️', notes.say),
          group('Ask the class', '❓', notes.ask),
          group('Watch for', '👀', notes.watch),
        ],
      ),
    );
  }
}

/// A large rounded button that reads well on a projector.
class BigButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double fontSize;
  const BigButton(this.label,
      {super.key, this.emoji, this.icon, this.onPressed, this.color, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Lab.purple;
    final lead = emoji != null
        ? Text(emoji!, style: TextStyle(fontSize: fontSize * 1.1))
        : (icon != null ? Icon(icon, size: fontSize * 1.2) : null);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c,
        foregroundColor: Colors.white,
        disabledBackgroundColor: c.withValues(alpha: 0.25),
        disabledForegroundColor: Colors.white70,
        padding: EdgeInsets.symmetric(horizontal: fontSize * 1.1, vertical: fontSize * 0.7),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fontSize * 1.2)),
        elevation: 3,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (lead != null) ...[lead, SizedBox(width: fontSize * 0.45)],
        Text(label),
      ]),
    );
  }
}

/// "Round 1 2 3 4" picker. The teacher decides when to move up.
class RoundPicker extends StatelessWidget {
  final int round; // 1-based
  final List<String> descriptions;
  final ValueChanged<int> onChanged;
  final Color color;
  const RoundPicker({
    super.key,
    required this.round,
    required this.descriptions,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        for (var i = 1; i <= descriptions.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Tooltip(
              message: descriptions[i - 1],
              child: ChoiceChip(
                label: Text('$i',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: i == round ? Colors.white : color)),
                selected: i == round,
                selectedColor: color,
                backgroundColor: Colors.white,
                side: BorderSide(color: color, width: 2),
                showCheckmark: false,
                onSelected: (_) => onChanged(i),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(descriptions[round - 1],
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ),
      ],
    );
  }
}

/// Team scores with +1 / −1 buttons, shown along the bottom of each game.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    return ListenableBuilder(
      listenable: cs,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white.withValues(alpha: 0.92),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cs.teams.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text('⚡', style: TextStyle(fontSize: 28)),
                ),
              _TeamScore(index: i),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final int index;
  const _TeamScore({required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = ClassState.instance;
    final t = cs.teams[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: t.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: t.color, width: 3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Take a point away',
          onPressed: () => cs.addPoint(index, -1),
          icon: const Icon(Icons.remove_circle_outline),
          color: t.color,
        ),
        Text('${t.emoji} ${t.name}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: t.color)),
        const SizedBox(width: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.4, end: 1),
          key: ValueKey(t.score),
          duration: const Duration(milliseconds: 350),
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: Text('${t.score}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Lab.ink)),
        ),
        IconButton(
          tooltip: 'Give a point',
          onPressed: () => cs.addPoint(index, 1),
          icon: const Icon(Icons.add_circle, size: 32),
          color: t.color,
        ),
      ]),
    );
  }
}

/// Countdown timer chip for the section. Tap to pause/play, long-press to reset.
class SectionTimer extends StatefulWidget {
  final int minutes;
  const SectionTimer({super.key, required this.minutes});

  @override
  State<SectionTimer> createState() => _SectionTimerState();
}

class _SectionTimerState extends State<SectionTimer> {
  late int _left = widget.minutes * 60;
  bool _running = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running && _left > 0) setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _left ~/ 60, s = _left % 60;
    final done = _left == 0;
    return Tooltip(
      message: 'Tap: pause / play   •   Long-press: reset',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _running = !_running),
        onLongPress: () => setState(() {
          _left = widget.minutes * 60;
          _running = true;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: done ? Colors.red.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_running ? '⏱️' : '⏸️', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('$m:${s.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: done ? Colors.red : Lab.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      ),
    );
  }
}

/// A big centred speech bubble like "Is the pitch high or low?".
class SentenceBanner extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final String emoji;
  const SentenceBanner(this.text,
      {super.key, required this.color, this.fontSize = 34, this.emoji = '💬'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fontSize),
        border: Border.all(color: color, width: 4),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: TextStyle(fontSize: fontSize)),
        SizedBox(width: fontSize * 0.4),
        Flexible(
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
}

/// Switch between "Practice" and "Clue time" inside a section.
class ModeSwitch extends StatelessWidget {
  final bool clues;
  final ValueChanged<bool> onChanged;
  final Color color;
  const ModeSwitch({super.key, required this.clues, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    Widget chip(bool value, String text) {
      final sel = clues == value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(text,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: sel ? Colors.white : color)),
          selected: sel,
          selectedColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(color: color, width: 2),
          showCheckmark: false,
          onSelected: (_) => onChanged(value),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      chip(false, '🧪 Practice'),
      chip(true, '🔐 Clue time'),
    ]);
  }
}
