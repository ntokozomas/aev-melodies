import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Lets a running sequence be stopped (e.g. when the teacher presses
/// another button or leaves the screen).
class PlayToken {
  bool cancelled = false;
  void cancel() => cancelled = true;
}

enum BeepLevel { loud, mid, quiet, faint }

enum Sfx { hit, buzz, reveal, tada, vault }

/// Plays the generated sounds in assets/audio.
class Sound {
  Sound._();
  static final Sound instance = Sound._();

  static const int minMidi = 48;
  static const int maxMidi = 84;

  /// Hearing-test pitches (Hz), like a real audiogram.
  static const beepFrequencies = [125, 250, 500, 750, 1000, 1500, 2000, 3000, 4000, 6000, 8000, 12000];

  /// Length of one beat in milliseconds (75 beats per minute).
  static const int beatMs = 800;

  final List<AudioPlayer> _pool = [];
  final List<int> _owner = [];
  int _next = 0;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    AudioCache.instance = AudioCache(prefix: 'assets/');
    for (var i = 0; i < 10; i++) {
      final p = AudioPlayer();
      try {
        await p.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      _pool.add(p);
      _owner.add(0);
    }
    try {
      await AudioCache.instance.loadAll([
        for (var m = minMidi; m <= maxMidi; m++) 'audio/n$m.wav',
        'audio/tick.wav',
        'audio/tick_accent.wav',
        for (final f in beepFrequencies)
          for (final l in BeepLevel.values)
            for (final suffix in ['', '_short']) 'audio/beep_${f}_${l.name}$suffix.wav',
        for (final s in Sfx.values) 'audio/sfx_${s.name}.wav',
        for (final e in ['high', 'low', 'loud', 'quiet', 'clap']) 'audio/ex_$e.wav',
      ]);
    } catch (_) {
      // Sounds will load on first play instead.
    }
  }

  int _claim() {
    final i = _next;
    _next = (_next + 1) % _pool.length;
    _owner[i]++;
    return i;
  }

  Future<void> _play(String asset, {Duration? length}) async {
    if (_pool.isEmpty) return;
    final i = _claim();
    final mine = _owner[i];
    final p = _pool[i];
    try {
      await p.stop();
      await p.play(AssetSource(asset));
    } catch (_) {
      return;
    }
    if (length != null) {
      Timer(length, () {
        if (_owner[i] == mine) p.stop();
      });
    }
  }

  /// Plays a note. [beats] limits how long it sounds (null = natural fade).
  Future<void> note(int midi, {double? beats}) {
    final m = midi.clamp(minMidi, maxMidi);
    return _play('audio/n$m.wav',
        length: beats == null ? null : Duration(milliseconds: (beats * beatMs).round() - 40));
  }

  /// A hearing-test beep (0.9 s).
  Future<void> beep(int frequency, BeepLevel level, {bool short = false}) =>
      _play('audio/beep_${frequency}_${level.name}${short ? '_short' : ''}.wav');

  Future<void> sfx(Sfx s) => _play('audio/sfx_${s.name}.wav');

  /// Example sounds for the microscope intro: high, low, loud, quiet, clap.
  Future<void> example(String name) => _play('audio/ex_$name.wav');

  Future<void> tick({bool accent = false}) =>
      _play(accent ? 'audio/tick_accent.wav' : 'audio/tick.wav');

  Future<void> correct() => sfx(Sfx.tada);
  Future<void> wrong() => sfx(Sfx.buzz);

  Future<void> stopAll() async {
    for (var i = 0; i < _pool.length; i++) {
      _owner[i]++;
      try {
        await _pool[i].stop();
      } catch (_) {}
    }
  }

  /// Waits [ms] milliseconds unless the token is cancelled first.
  static Future<bool> wait(int ms, PlayToken token) async {
    const step = 20;
    var waited = 0;
    while (waited < ms) {
      if (token.cancelled) return false;
      final d = (ms - waited) < step ? ms - waited : step;
      await Future.delayed(Duration(milliseconds: d));
      waited += d;
    }
    return !token.cancelled;
  }
}
