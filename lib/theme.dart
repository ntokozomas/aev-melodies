import 'dart:math';

import 'package:flutter/material.dart';

/// Melodies Sound Lab colours – bright, friendly and easy to read on a projector.
class Lab {
  static const ink = Color(0xFF1E1B4B); // deep indigo text
  static const paper = Color(0xFFF5F9FF); // soft lab-white background
  static const card = Colors.white;

  static const teal = Color(0xFF14B8A6); // Sound microscope
  static const purple = Color(0xFF8B5CF6); // Pitch on Click
  static const orange = Color(0xFFF97316); // Beat maths
  static const pink = Color(0xFFEC4899); // Notes
  static const blue = Color(0xFF3B82F6); // Rhythm scanner
  static const gold = Color(0xFFF59E0B); // Code unveil
  static const green = Color(0xFF22C55E); // correct / hit
  static const red = Color(0xFFEF4444); // miss / false alarm
  static const lime = Color(0xFFA3E635); // oscilloscope glow

  static const teamA = Color(0xFFFF5D73); // Team Red
  static const teamB = Color(0xFF3D8BFF); // Team Blue

  static const science = ['🔬', '🧪', '⚗️', '🧬', '🔭', '🎧', '📡', '🧲', '💡', '🎵', '🎶', '⚡'];
}

/// A soft background with floating science and music emojis.
class LabBackground extends StatelessWidget {
  final Widget child;
  final Color tint;
  final int seed;
  final double opacity;
  const LabBackground({
    super.key,
    required this.child,
    this.tint = Lab.purple,
    this.seed = 7,
    this.opacity = 0.13,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Lab.paper, Color.lerp(Lab.paper, tint, 0.10)!],
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(builder: (context, c) {
            final rng = Random(seed);
            const count = 18;
            return Stack(children: [
              for (var i = 0; i < count; i++)
                Positioned(
                  left: rng.nextDouble() * (c.maxWidth - 60),
                  top: rng.nextDouble() * (c.maxHeight - 60),
                  child: Transform.rotate(
                    angle: (rng.nextDouble() - 0.5) * 0.8,
                    child: Opacity(
                      opacity: opacity,
                      child: Text(Lab.science[rng.nextInt(Lab.science.length)],
                          style: TextStyle(fontSize: 34 + rng.nextDouble() * 30)),
                    ),
                  ),
                ),
            ]);
          }),
        ),
      ),
      Positioned.fill(child: child),
    ]);
  }
}

/// A rounded white panel used across the app.
class LabPanel extends StatelessWidget {
  final Widget child;
  final Color? border;
  final EdgeInsets padding;
  const LabPanel({super.key, required this.child, this.border, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Lab.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: (border ?? Lab.purple).withValues(alpha: 0.35), width: 3),
        boxShadow: [
          BoxShadow(
              color: (border ?? Lab.purple).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

ThemeData labTheme() {
  final base = ThemeData(
    colorSchemeSeed: Lab.purple,
    useMaterial3: true,
    scaffoldBackgroundColor: Lab.paper,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Lab.ink, displayColor: Lab.ink),
  );
}
