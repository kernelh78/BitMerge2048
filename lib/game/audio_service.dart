import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

enum SoundEvent { slide, merge, spawn, win, over }

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  static const int _sr = 22050;

  final Map<SoundEvent, AudioPlayer> _players = {};
  final Map<SoundEvent, Uint8List> _cache = {};
  bool _ready = false;
  bool _muted = false;

  bool get muted => _muted;
  void toggleMute() => _muted = !_muted;

  Future<void> init() async {
    // WAV 생성 (Isolate — 메인 스레드 차단 없음)
    final wavList = await Isolate.run(_generateAllWavs);
    final events = SoundEvent.values;
    for (int i = 0; i < events.length; i++) {
      final p = AudioPlayer();
      await p.setVolume(1.0);
      _players[events[i]] = p;
      _cache[events[i]] = wavList[i];
    }
    _ready = true;
  }

  /// stop() 없이 바로 play — 이전 stop() 대기가 없어 딜레이 최소화
  void play(SoundEvent event) {
    if (!_ready || _muted) return;
    final bytes = _cache[event];
    final player = _players[event];
    if (bytes == null || player == null) return;

    player.play(BytesSource(bytes)).ignore();
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
  }

  // ─────────────────────────────────────
  // Isolate에서 실행되는 최상위 함수
  // ─────────────────────────────────────

  static List<Uint8List> _generateAllWavs() {
    return [
      _wav(_slideWave()),
      _wav(_mergeWave()),
      _wav(_spawnWave()),
      _wav(_winWave()),
      _wav(_overWave()),
    ];
  }

  // ─────────────────────────────────────
  // 파형 생성 (static — Isolate 사용 가능)
  // ─────────────────────────────────────

  static List<double> _slideWave() {
    // 경쾌한 "틱-슉" 효과: 짧은 클릭 + 주파수 스윕
    final n = (_sr * 0.075).round();
    final rng = Random(7);
    return List.generate(n, (i) {
      final t = i / _sr;
      // 앞부분 노이즈 클릭
      final click = (rng.nextDouble() * 2 - 1) * exp(-t * 180) * 0.55;
      // 주파수 스윕: 700Hz → 220Hz
      final freq = 700.0 * exp(-t * 12);
      final sweep = sin(2 * pi * freq * t) * exp(-t * 20) * 0.45;
      return (click + sweep).clamp(-1.0, 1.0);
    });
  }

  static List<double> _mergeWave() {
    // 강력한 전자 "팡!" 사운드
    final n = (_sr * 0.22).round();
    final rng = Random(42);
    return List.generate(n, (i) {
      final t = i / _sr;
      // 임팩트 노이즈 어택 (처음 10ms)
      final attack = (rng.nextDouble() * 2 - 1) * exp(-t * 90) * 0.6;
      // 풍부한 하모닉 스윕
      final freq = 260.0 + 1400.0 * exp(-t * 28);
      final h1 = sin(2 * pi * freq * t);
      final h2 = sin(4 * pi * freq * t) * 0.55;
      final h3 = sin(6 * pi * freq * t) * 0.28;
      final h4 = sin(8 * pi * freq * t) * 0.12;
      final harmonics = (h1 + h2 + h3 + h4) * exp(-t * 11) * 0.85;
      return (attack + harmonics).clamp(-1.0, 1.0);
    });
  }

  static List<double> _spawnWave() {
    final n = (_sr * 0.030).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final env = exp(-t * 55) * 0.32;
      return sin(2 * pi * 1200.0 * t) * env;
    });
  }

  static List<double> _winWave() {
    const freqs = [261.63, 329.63, 392.0, 523.25];
    final noteSamples = (_sr * 0.17).toInt();
    final samples = <double>[];
    for (final freq in freqs) {
      for (int i = 0; i < noteSamples; i++) {
        final t = i / _sr;
        final attack = (noteSamples * 0.1).round();
        final env = i < attack
            ? i / attack.toDouble()
            : (noteSamples - i) / (noteSamples * 0.9);
        final wave = sin(2 * pi * freq * t) + sin(4 * pi * freq * t) * 0.3;
        samples.add(wave * env.clamp(0.0, 1.0) * 0.45);
      }
    }
    return samples;
  }

  static List<double> _overWave() {
    final n = (_sr * 0.35).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final freq = 380.0 * exp(-t * 3.5);
      final env = (1.0 - t / 0.35).clamp(0.0, 1.0) * 0.4;
      return (sin(2 * pi * freq * t) + sin(4 * pi * freq * t) * 0.25) * env;
    });
  }

  // ─────────────────────────────────────
  // WAV 인코딩
  // ─────────────────────────────────────

  static Uint8List _wav(List<double> samples) {
    final dataSize = samples.length * 2;
    final buf = ByteData(44 + dataSize);
    int o = 0;

    void str(String s) {
      for (int i = 0; i < s.length; i++) {
        buf.setUint8(o + i, s.codeUnitAt(i));
      }
      o += s.length;
    }

    str('RIFF');
    buf.setUint32(o, 36 + dataSize, Endian.little); o += 4;
    str('WAVE');
    str('fmt ');
    buf.setUint32(o, 16, Endian.little); o += 4;
    buf.setUint16(o, 1, Endian.little); o += 2;
    buf.setUint16(o, 1, Endian.little); o += 2;
    buf.setUint32(o, _sr, Endian.little); o += 4;
    buf.setUint32(o, _sr * 2, Endian.little); o += 4;
    buf.setUint16(o, 2, Endian.little); o += 2;
    buf.setUint16(o, 16, Endian.little); o += 2;
    str('data');
    buf.setUint32(o, dataSize, Endian.little); o += 4;

    for (final s in samples) {
      buf.setInt16(o, (s.clamp(-1.0, 1.0) * 32767).round(), Endian.little);
      o += 2;
    }
    return buf.buffer.asUint8List();
  }
}
