import 'package:flutter/material.dart';

import '../data/clues.dart';
import '../theme.dart';

class Team {
  final String name;
  final String emoji;
  final Color color;
  int score = 0;
  Team(this.name, this.emoji, this.color);
}

/// Result of one blindfolded hearing test (Pitch on Click).
class HearingResult {
  final int team;
  final int hits;
  final int misses;
  final int falseAlarms;
  final int points;
  final int? avgReactionMs;
  const HearingResult(
      this.team, this.hits, this.misses, this.falseAlarms, this.points, this.avgReactionMs);
}

/// Best rhythm-scan result for a team.
class RhythmResult {
  final int accuracy; // 0..100
  final bool passed;
  const RhythmResult(this.accuracy, this.passed);
}

/// Shared classroom state: teams, scores, the secret code and results.
class ClassState extends ChangeNotifier {
  ClassState._();
  static final ClassState instance = ClassState._();

  final List<Team> teams = [
    Team('Red Lab', '🧪', Lab.teamA),
    Team('Blue Lab', '🔬', Lab.teamB),
  ];

  bool teacherNotes = false;

  ClueBank clues = ClueBank.random();
  final List<HearingResult> hearing = [];
  final Map<int, RhythmResult> rhythm = {};

  void toggleTeacherNotes() {
    teacherNotes = !teacherNotes;
    notifyListeners();
  }

  void addPoint(int team, [int amount = 1]) {
    final t = teams[team];
    t.score = (t.score + amount).clamp(-99, 999);
    notifyListeners();
  }

  void addHearing(HearingResult r) {
    hearing.add(r);
    addPoint(r.team, r.points);
  }

  void setRhythm(int team, RhythmResult r) {
    final old = rhythm[team];
    if (old == null || r.accuracy > old.accuracy) rhythm[team] = r;
    notifyListeners();
  }

  /// Fresh code, scores and results for a new class.
  void newLesson() {
    for (final t in teams) {
      t.score = 0;
    }
    clues = ClueBank.random();
    hearing.clear();
    rhythm.clear();
    notifyListeners();
  }
}
