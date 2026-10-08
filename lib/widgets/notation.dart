import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/music.dart';

/// Draws a single rhythm symbol (whole, half, quarter, eighth, eighth pair, rest).
class RhythmNoteView extends StatelessWidget {
  final NoteLength length;
  final double size;
  final Color color;
  final Color? fill;
  const RhythmNoteView(this.length,
      {super.key, this.size = 80, this.color = Colors.black87, this.fill});

  @override
  Widget build(BuildContext context) {
    final w = length == NoteLength.eighthPair ? size * 0.95 : size * 0.6;
    return SizedBox(
      width: w,
      height: size,
      child: CustomPaint(painter: _RhythmPainter(length, color, fill ?? color)),
    );
  }
}

class _RhythmPainter extends CustomPainter {
  final NoteLength length;
  final Color color;
  final Color fill;
  _RhythmPainter(this.length, this.color, this.fill);

  @override
  void paint(Canvas canvas, Size s) {
    final h = s.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.035
      ..strokeCap = StrokeCap.round;
    final solid = Paint()..color = fill;
    final headY = h * 0.8;
    final rx = h * 0.13, ry = h * 0.095;

    void head(double cx, {required bool hollow}) {
      canvas.save();
      canvas.translate(cx, headY);
      canvas.rotate(-0.35);
      final r = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
      if (hollow) {
        canvas.drawOval(r, stroke..strokeWidth = h * 0.04);
      } else {
        canvas.drawOval(r, solid);
        canvas.drawOval(r, stroke..strokeWidth = h * 0.015);
      }
      canvas.restore();
      stroke.strokeWidth = h * 0.035;
    }

    double stem(double cx) {
      final x = cx + rx * 0.9;
      canvas.drawLine(Offset(x, headY - ry * 0.4), Offset(x, h * 0.08), stroke);
      return x;
    }

    switch (length) {
      case NoteLength.whole:
        canvas.save();
        canvas.translate(s.width / 2, headY);
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: rx * 2.4, height: ry * 2.1),
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = h * 0.05);
        canvas.restore();
      case NoteLength.half:
        final cx = s.width / 2 - rx * 0.4;
        head(cx, hollow: true);
        stem(cx);
      case NoteLength.quarter:
        final cx = s.width / 2 - rx * 0.4;
        head(cx, hollow: false);
        stem(cx);
      case NoteLength.eighth:
        final cx = s.width / 2 - rx * 0.8;
        head(cx, hollow: false);
        final x = stem(cx);
        final flag = Path()
          ..moveTo(x, h * 0.08)
          ..cubicTo(x + h * 0.02, h * 0.22, x + h * 0.25, h * 0.27, x + h * 0.17, h * 0.5);
        canvas.drawPath(flag, stroke..strokeWidth = h * 0.045);
      case NoteLength.eighthPair:
        final c1 = s.width * 0.25, c2 = s.width * 0.7;
        head(c1, hollow: false);
        head(c2, hollow: false);
        final x1 = stem(c1), x2 = stem(c2);
        canvas.drawLine(Offset(x1, h * 0.1), Offset(x2, h * 0.1),
            Paint()
              ..color = color
              ..strokeWidth = h * 0.08);
      case NoteLength.rest:
        // Quarter rest: a zig-zag with a hook at the bottom.
        final cx = s.width / 2;
        final p = Path()
          ..moveTo(cx - h * 0.06, h * 0.15)
          ..lineTo(cx + h * 0.08, h * 0.33)
          ..lineTo(cx - h * 0.06, h * 0.48)
          ..lineTo(cx + h * 0.08, h * 0.64)
          ..quadraticBezierTo(cx - h * 0.12, h * 0.62, cx - h * 0.02, h * 0.86);
        canvas.drawPath(
            p,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = h * 0.06
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter old) =>
      old.length != length || old.color != color || old.fill != fill;
}

/// A pitched note placed on the staff.
class StaffNote {
  final Solfege note;
  final NoteLength length;
  const StaffNote(this.note, [this.length = NoteLength.quarter]);
}

/// A five-line staff showing notes in colour, with solfege names underneath.
class StaffView extends StatelessWidget {
  final List<StaffNote> notes;
  final int? highlight;
  final bool showNames;
  final bool showLetters;
  final double height;
  final int minSlots;
  const StaffView({
    super.key,
    required this.notes,
    this.highlight,
    this.showNames = true,
    this.showLetters = false,
    this.height = 220,
    this.minSlots = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _StaffPainter(notes, highlight, showNames, showLetters, minSlots,
            Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _StaffPainter extends CustomPainter {
  final List<StaffNote> notes;
  final int? highlight;
  final bool showNames;
  final bool showLetters;
  final int minSlots;
  final Color ink;
  _StaffPainter(this.notes, this.highlight, this.showNames, this.showLetters,
      this.minSlots, this.ink);

  @override
  void paint(Canvas canvas, Size s) {
    final gap = s.height * 0.1; // distance between staff lines
    final top = s.height * 0.12;
    final bottomLine = top + gap * 4;
    final line = Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    const left = 20.0;
    final right = s.width - 20;
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(Offset(left, top + gap * i), Offset(right, top + gap * i), line);
    }
    // Start bar line and end bar line.
    canvas.drawLine(Offset(left, top), Offset(left, bottomLine), line);
    canvas.drawLine(Offset(right, top), Offset(right, bottomLine), line);

    final slots = math.max(notes.length, minSlots);
    final slotW = (right - left - 40) / slots;
    final rx = gap * 0.68, ry = gap * 0.5;

    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      final cx = left + 40 + slotW * (i + 0.5);
      final cy = bottomLine - (n.note.staffStep - 2) * gap / 2;
      final isHi = highlight == i;

      if (isHi) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(cx, s.height / 2), width: slotW * 0.9, height: s.height * 0.98),
                const Radius.circular(16)),
            Paint()..color = n.note.color.withValues(alpha: 0.25));
      }

      // Ledger line for middle C.
      if (n.note.staffStep == 0) {
        canvas.drawLine(Offset(cx - rx * 1.7, cy), Offset(cx + rx * 1.7, cy), line);
      }

      final hollow = n.length == NoteLength.whole || n.length == NoteLength.half;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-0.3);
      final r = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
      canvas.drawOval(r, Paint()..color = hollow ? n.note.color.withValues(alpha: 0.35) : n.note.color);
      canvas.drawOval(
          r,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = hollow ? 4 : 2);
      canvas.restore();

      if (n.length != NoteLength.whole) {
        final up = n.note.staffStep < 6;
        final stem = Paint()
          ..color = ink
          ..strokeWidth = 3;
        if (up) {
          canvas.drawLine(Offset(cx + rx * 0.95, cy), Offset(cx + rx * 0.95, cy - gap * 3.4), stem);
        } else {
          canvas.drawLine(Offset(cx - rx * 0.95, cy), Offset(cx - rx * 0.95, cy + gap * 3.4), stem);
        }
      }

      if (showNames || showLetters) {
        final label = [
          if (showNames) n.note.name,
          if (showLetters) n.note.letter,
        ].join('\n');
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: gap * 1.25,
              fontWeight: FontWeight.w800,
              color: n.note.color == const Color(0xFFFDD835) ? const Color(0xFFB59A00) : n.note.color,
              height: 1.05,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, bottomLine + gap * 2.2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaffPainter old) => true;
}
