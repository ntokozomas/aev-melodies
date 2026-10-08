import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// One shared clock so mic claps and app events use the same timeline.
class LabClock {
  static final Stopwatch _sw = Stopwatch()..start();
  static int get ms => _sw.elapsedMilliseconds;
}

/// Listens to the microphone and provides:
/// * the latest samples (for the oscilloscope),
/// * a loudness level,
/// * clap detection (onsets) with timestamps on [LabClock].
class Mic extends ChangeNotifier {
  Mic._();
  static final Mic instance = Mic._();

  static const int configRate = 44100;
  static const int window = 256; // samples per analysis window

  AudioRecorder? _rec;
  StreamSubscription<Uint8List>? _sub;
  bool running = false;
  String? error;

  /// Latest samples, -1..1 (oldest first).
  final List<double> scope = List.filled(2048, 0);
  int _scopePos = 0;

  /// Loudness 0..1 (smoothed peak).
  double level = 0;

  /// Clap sensitivity: the minimum peak (0..1) that counts as a clap.
  double clapThreshold = 0.22;

  final List<void Function(int ms)> _onsetListeners = [];
  int _lastOnsetMs = -10000;
  double _noise = 0.02;
  bool _above = false;

  // For estimating the real sample rate (browsers may ignore the requested one).
  int _samplesTotal = 0;
  int? _firstChunkMs;
  double rate = configRate.toDouble();

  int _lastNotify = 0;

  void addOnsetListener(void Function(int ms) f) => _onsetListeners.add(f);
  void removeOnsetListener(void Function(int ms) f) => _onsetListeners.remove(f);

  Future<bool> start() async {
    if (running) return true;
    error = null;
    try {
      final rec = _rec ??= AudioRecorder();
      if (!await rec.hasPermission()) {
        error = 'Microphone permission was not given.';
        notifyListeners();
        return false;
      }
      final stream = await rec.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: configRate,
        numChannels: 1,
        echoCancel: false,
        noiseSuppress: false,
        autoGain: false,
      ));
      _samplesTotal = 0;
      _firstChunkMs = null;
      _sub = stream.listen(_onData, onError: (Object e) {
        error = 'Microphone error: $e';
        notifyListeners();
      });
      running = true;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Could not start the microphone: $e';
      running = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _rec?.stop();
    } catch (_) {}
    running = false;
    level = 0;
    for (var i = 0; i < scope.length; i++) {
      scope[i] = 0;
    }
    notifyListeners();
  }

  void _onData(Uint8List data) {
    final now = LabClock.ms;
    _firstChunkMs ??= now;
    final bd = ByteData.sublistView(data);
    final n = data.length ~/ 2;
    if (n == 0) return;
    _samplesTotal += n;
    final elapsed = now - _firstChunkMs!;
    if (elapsed > 1500) {
      final r = _samplesTotal * 1000 / elapsed;
      if (r > 7000 && r < 100000) rate = rate * 0.9 + r * 0.1;
    }

    var peakAll = 0.0;
    var winPeak = 0.0;
    var winCount = 0;
    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little) / 32768.0;
      scope[_scopePos] = s;
      _scopePos = (_scopePos + 1) % scope.length;
      final a = s.abs();
      if (a > winPeak) winPeak = a;
      if (a > peakAll) peakAll = a;
      winCount++;
      if (winCount == window || i == n - 1) {
        // Time at the end of this window, measured back from "now".
        final msAgo = ((n - 1 - i) * 1000 / rate).round();
        _analyseWindow(winPeak, now - msAgo);
        winPeak = 0;
        winCount = 0;
      }
    }

    level = max(peakAll, level * 0.85);
    if (now - _lastNotify > 33) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  void _analyseWindow(double peak, int ms) {
    final trigger = max(clapThreshold, _noise * 5);
    if (!_above && peak > trigger && ms - _lastOnsetMs > 120) {
      _above = true;
      _lastOnsetMs = ms;
      for (final f in List.of(_onsetListeners)) {
        f(ms);
      }
    } else if (_above && peak < trigger * 0.5) {
      _above = false;
    }
    if (!_above) _noise = _noise * 0.97 + peak * 0.03;
  }

  /// Latest samples in order (oldest first).
  List<double> latest(int count) {
    count = min(count, scope.length);
    final out = List<double>.filled(count, 0);
    var p = (_scopePos - count) % scope.length;
    if (p < 0) p += scope.length;
    for (var i = 0; i < count; i++) {
      out[i] = scope[(p + i) % scope.length];
    }
    return out;
  }

  /// Rough pitch of the current sound in Hz (null when too quiet).
  double? roughPitch() {
    if (level < 0.06) return null;
    final s = latest(2048);
    var crossings = 0;
    for (var i = 1; i < s.length; i++) {
      if ((s[i - 1] < 0) != (s[i] < 0)) crossings++;
    }
    final seconds = s.length / rate;
    return crossings / 2 / seconds;
  }
}
