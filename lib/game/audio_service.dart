import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';

enum SoundEvent { slide, merge, spawn, win, over }

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  static const int _sr = 22050;

  // players per event (reused across profiles)
  final Map<SoundEvent, AudioPlayer> _players = {};
  // cache[profile][event] = WAV bytes
  final Map<SoundProfile, Map<SoundEvent, Uint8List>> _cache = {};

  bool _ready = false;
  bool _muted = false;
  SoundProfile _profile = SoundProfile.neonCircuit;

  bool get muted => _muted;
  void toggleMute() => _muted = !_muted;

  void setProfile(SoundProfile profile) => _profile = profile;

  Future<void> init() async {
    // 전체 프로파일의 WAV를 Isolate에서 한 번에 생성
    final allWavs = await Isolate.run(_generateAllWavs);

    for (final event in SoundEvent.values) {
      final p = AudioPlayer();
      await p.setVolume(1.0);
      _players[event] = p;
    }

    for (final profile in SoundProfile.values) {
      _cache[profile] = {};
      final wavs = allWavs[profile.index];
      for (int i = 0; i < SoundEvent.values.length; i++) {
        _cache[profile]![SoundEvent.values[i]] = wavs[i];
      }
    }

    _ready = true;
  }

  void play(SoundEvent event) {
    if (!_ready || _muted) return;
    final bytes = _cache[_profile]?[event];
    final player = _players[event];
    if (bytes == null || player == null) return;
    player.play(BytesSource(bytes)).ignore();
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
  }

  // ─── Isolate entry ────────────────────────────────────────────────────────

  /// Returns List of 3 profiles × 5 events
  static List<List<Uint8List>> _generateAllWavs() {
    return [
      // Neon Circuit
      [
        _wav(_neonSlide()),
        _wav(_neonMerge()),
        _wav(_neonSpawn()),
        _wav(_neonWin()),
        _wav(_neonOver()),
      ],
      // Cherry Bloom
      [
        _wav(_cherrySlide()),
        _wav(_cherryMerge()),
        _wav(_cherrySpawn()),
        _wav(_cherryWin()),
        _wav(_cherryOver()),
      ],
      // Pastel Dream
      [
        _wav(_pastelSlide()),
        _wav(_pastelMerge()),
        _wav(_pastelSpawn()),
        _wav(_pastelWin()),
        _wav(_pastelOver()),
      ],
    ];
  }

  // ─── Neon Circuit sounds (original electronic feel) ───────────────────────

  static List<double> _neonSlide() {
    final n = (_sr * 0.075).round();
    final rng = Random(7);
    return List.generate(n, (i) {
      final t = i / _sr;
      final click = (rng.nextDouble() * 2 - 1) * exp(-t * 180) * 0.55;
      final freq = 700.0 * exp(-t * 12);
      final sweep = sin(2 * pi * freq * t) * exp(-t * 20) * 0.45;
      return (click + sweep).clamp(-1.0, 1.0);
    });
  }

  static List<double> _neonMerge() {
    final n = (_sr * 0.22).round();
    final rng = Random(42);
    return List.generate(n, (i) {
      final t = i / _sr;
      final attack = (rng.nextDouble() * 2 - 1) * exp(-t * 90) * 0.6;
      final freq = 260.0 + 1400.0 * exp(-t * 28);
      final h1 = sin(2 * pi * freq * t);
      final h2 = sin(4 * pi * freq * t) * 0.55;
      final h3 = sin(6 * pi * freq * t) * 0.28;
      final h4 = sin(8 * pi * freq * t) * 0.12;
      final harmonics = (h1 + h2 + h3 + h4) * exp(-t * 11) * 0.85;
      return (attack + harmonics).clamp(-1.0, 1.0);
    });
  }

  static List<double> _neonSpawn() {
    final n = (_sr * 0.030).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      return sin(2 * pi * 1200.0 * t) * exp(-t * 55) * 0.32;
    });
  }

  static List<double> _neonWin() {
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

  static List<double> _neonOver() {
    final n = (_sr * 0.35).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final freq = 380.0 * exp(-t * 3.5);
      final env = (1.0 - t / 0.35).clamp(0.0, 1.0) * 0.4;
      return (sin(2 * pi * freq * t) + sin(4 * pi * freq * t) * 0.25) * env;
    });
  }

  // ─── Cherry Bloom sounds (bell / melodic) ─────────────────────────────────

  static List<double> _cherrySlide() {
    // 부드러운 고음→저음 스윕 (whoosh)
    final n = (_sr * 0.10).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final freq = 520.0 * exp(-t * 9);
      final env = exp(-t * 16) * 0.35;
      return sin(2 * pi * freq * t) * env;
    });
  }

  static List<double> _cherryMerge() {
    // 맑은 벨 차임 — A5(880Hz) 중심 하모닉
    final n = (_sr * 0.30).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      const freq = 880.0;
      final env = exp(-t * 7) * 0.48;
      final h1 = sin(2 * pi * freq * t);
      final h2 = sin(4 * pi * freq * t) * 0.28;
      final h3 = sin(6 * pi * freq * t) * 0.10;
      return (h1 + h2 + h3) * env;
    });
  }

  static List<double> _cherrySpawn() {
    // 짧고 밝은 벨 딩
    final n = (_sr * 0.07).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      return sin(2 * pi * 1400.0 * t) * exp(-t * 45) * 0.28;
    });
  }

  static List<double> _cherryWin() {
    // 오름차순 5음계 (C D E G A) — 꽃이 피는 느낌
    const freqs = [261.63, 293.66, 329.63, 392.0, 440.0];
    final noteSamples = (_sr * 0.14).toInt();
    final samples = <double>[];
    for (final freq in freqs) {
      for (int i = 0; i < noteSamples; i++) {
        final t = i / _sr;
        final attack = (noteSamples * 0.05).round();
        final env = i < attack
            ? i / attack.toDouble()
            : exp(-(i - attack) / (noteSamples * 0.45));
        final wave = sin(2 * pi * freq * t) + sin(4 * pi * freq * t) * 0.18;
        samples.add(wave * env.clamp(0.0, 1.0) * 0.40);
      }
    }
    return samples;
  }

  static List<double> _cherryOver() {
    // 내려가는 3음 (E D C) — 꽃잎 지는 느낌
    const freqs = [329.63, 293.66, 261.63];
    final noteSamples = (_sr * 0.13).toInt();
    final samples = <double>[];
    for (final freq in freqs) {
      for (int i = 0; i < noteSamples; i++) {
        final t = i / _sr;
        final env = exp(-t * 7) * 0.32;
        samples.add(sin(2 * pi * freq * t) * env);
      }
    }
    return samples;
  }

  // ─── Pastel Dream sounds (soft / bubbly / airy) ───────────────────────────

  static List<double> _pastelSlide() {
    // 가볍고 부드러운 버블 팝
    final n = (_sr * 0.065).round();
    final rng = Random(13);
    return List.generate(n, (i) {
      final t = i / _sr;
      final noise = (rng.nextDouble() * 2 - 1) * exp(-t * 180) * 0.10;
      final tone =
          sin(2 * pi * 580.0 * exp(-t * 25) * t) * exp(-t * 38) * 0.22;
      return (noise + tone).clamp(-1.0, 1.0);
    });
  }

  static List<double> _pastelMerge() {
    // 반짝이는 하이 코드 차임 (C6 E6 G6)
    final n = (_sr * 0.22).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      const f1 = 1046.5;
      const f2 = 1318.5;
      const f3 = 1567.98;
      final env = exp(-t * 10) * 0.38;
      return (sin(2 * pi * f1 * t) * 0.5 +
              sin(2 * pi * f2 * t) * 0.3 +
              sin(2 * pi * f3 * t) * 0.2) *
          env;
    });
  }

  static List<double> _pastelSpawn() {
    // 아주 짧고 밝은 반짝임
    final n = (_sr * 0.040).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      return sin(2 * pi * 1900.0 * t) * exp(-t * 75) * 0.20;
    });
  }

  static List<double> _pastelWin() {
    // 몽환적인 메이저7 아르페지오 (C5 E5 G5 B5 C6)
    const freqs = [523.25, 659.25, 783.99, 987.77, 1046.5];
    final noteSamples = (_sr * 0.13).toInt();
    final samples = <double>[];
    for (final freq in freqs) {
      for (int i = 0; i < noteSamples; i++) {
        final t = i / _sr;
        final attack = (noteSamples * 0.07).round();
        final env = i < attack
            ? i / attack.toDouble()
            : exp(-(i - attack) / (noteSamples * 0.55));
        samples.add(sin(2 * pi * freq * t) * env.clamp(0.0, 1.0) * 0.32);
      }
    }
    return samples;
  }

  static List<double> _pastelOver() {
    // A4 단순 페이드아웃 — 잔잔한 끝맺음
    final n = (_sr * 0.40).round();
    return List.generate(n, (i) {
      final t = i / _sr;
      final env = (1.0 - t / 0.40).clamp(0.0, 1.0) * exp(-t * 2.5) * 0.28;
      return sin(2 * pi * 440.0 * t) * env;
    });
  }

  // ─── WAV 인코딩 ──────────────────────────────────────────────────────────

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
    buf.setUint32(o, 36 + dataSize, Endian.little);
    o += 4;
    str('WAVE');
    str('fmt ');
    buf.setUint32(o, 16, Endian.little);
    o += 4;
    buf.setUint16(o, 1, Endian.little);
    o += 2;
    buf.setUint16(o, 1, Endian.little);
    o += 2;
    buf.setUint32(o, _sr, Endian.little);
    o += 4;
    buf.setUint32(o, _sr * 2, Endian.little);
    o += 4;
    buf.setUint16(o, 2, Endian.little);
    o += 2;
    buf.setUint16(o, 16, Endian.little);
    o += 2;
    str('data');
    buf.setUint32(o, dataSize, Endian.little);
    o += 4;

    for (final s in samples) {
      buf.setInt16(o, (s.clamp(-1.0, 1.0) * 32767).round(), Endian.little);
      o += 2;
    }
    return buf.buffer.asUint8List();
  }
}
