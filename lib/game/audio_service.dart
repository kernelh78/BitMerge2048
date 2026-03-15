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
    // 플레이어 초기화 — lowLatency는 BytesSource 미지원이므로 기본 모드 사용
    for (final event in SoundEvent.values) {
      final p = AudioPlayer();
      await p.setVolume(0.7);
      _players[event] = p;
    }

    // WAV 생성은 별도 Isolate에서 — 메인 스레드 차단 없음
    final wavList = await Isolate.run(_generateAllWavs);
    _cache[SoundEvent.slide] = wavList[0];
    _cache[SoundEvent.merge] = wavList[1];
    _cache[SoundEvent.spawn] = wavList[2];
    _cache[SoundEvent.win]   = wavList[3];
    _cache[SoundEvent.over]  = wavList[4];
    _ready = true;
  }

  /// fire-and-forget: 사운드 재생이 UI 스레드를 절대 막지 않음
  void play(SoundEvent event) {
    if (!_ready || _muted) return;
    final bytes = _cache[event];
    final player = _players[event];
    if (bytes == null || player == null) return;

    player.stop().then((_) => player.play(BytesSource(bytes))).ignore();
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
    final n = (_sr * 0.055).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final freq = 520.0 * exp(-t * 14);
      final env = (1.0 - i / n) * 0.25;
      return sin(2 * pi * freq * t) * env;
    });
  }

  static List<double> _mergeWave() {
    final n = (_sr * 0.11).round();
    final rng = Random(42);
    return List.generate(n, (i) {
      final t = i / _sr;
      final freq = 180.0 + 700.0 * exp(-t * 20);
      final harmonics = sin(2 * pi * freq * t)
          + sin(4 * pi * freq * t) * 0.45
          + sin(6 * pi * freq * t) * 0.2;
      final noise = (rng.nextDouble() * 2 - 1) * 0.15;
      final env = exp(-t * 14) * 0.55;
      return (harmonics + noise) * env;
    });
  }

  static List<double> _spawnWave() {
    final n = (_sr * 0.025).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final env = exp(-t * 60) * 0.2;
      return sin(2 * pi * 1100.0 * t) * env;
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
