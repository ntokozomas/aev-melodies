import 'package:flutter/material.dart';

import '../data/music.dart';

/// Shows a hand-sign picture for a note.
///
/// Drop your own photos into assets/handsigns (do.png, re.png, mi.png, fa.png,
/// sol.png, la.png, ti.png, do_high.png). Until then a simple stand-in
/// (emoji + description) is shown.
class HandSignCard extends StatelessWidget {
  final Solfege note;
  final double size;
  final bool showName;
  final bool showDescription;
  final bool colored;
  const HandSignCard(
    this.note, {
    super.key,
    this.size = 200,
    this.showName = false,
    this.showDescription = true,
    this.colored = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = colored ? note.color.withValues(alpha: 0.15) : Colors.grey.shade100;
    final border = colored ? note.color : Colors.grey.shade400;
    return Container(
      width: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.1),
        border: Border.all(color: border, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size * 0.8,
            height: size * 0.8,
            child: Image.asset(
              note.imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => _Fallback(note, size, showDescription),
            ),
          ),
          if (showName) ...[
            SizedBox(height: size * 0.03),
            Text(
              note.name,
              style: TextStyle(
                fontSize: size * 0.18,
                fontWeight: FontWeight.w900,
                color: note.color == miNote.color ? const Color(0xFFB59A00) : note.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final Solfege note;
  final double size;
  final bool showDescription;
  const _Fallback(this.note, this.size, this.showDescription);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(note.emoji, style: TextStyle(fontSize: size * 0.38)),
        if (showDescription)
          Padding(
            padding: EdgeInsets.only(top: size * 0.03),
            child: Text(
              note.handSign,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: TextStyle(fontSize: size * 0.075, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}
