import 'dart:math';
import 'package:flutter/material.dart';

enum ThemeId { neonCircuit, cherryBloom, pastelDream }

enum SoundProfile { neonCircuit, cherryBloom, pastelDream }

enum TileOverlayStyle { circuit, floral, dots }

class AppTheme {
  final ThemeId id;
  final String displayName;
  final String emoji;
  final String subtitle;

  // Backgrounds
  final Color background;
  final Color surface;
  final Color boardBg;
  final Color cellBg;

  // Text
  final Color textPrimary;
  final Color textMuted;

  // Accents
  final Color accent;
  final Color accentAlt;
  final Color accentPop;
  final Color accentWarm;

  // Board UI
  final double boardRadius;
  final double tileRadius;

  // Animations
  final Curve slideCurve;
  final Duration slideDuration;
  final double mergeScalePeak;
  final double mergeScaleDip;
  final double mergeScaleBounce;
  final Duration mergeDuration;
  final Curve spawnCurve;
  final Duration spawnDuration;

  // Sound profile
  final SoundProfile soundProfile;

  // Status bar brightness (light = dark icons, dark = light icons)
  final Brightness statusBrightness;

  // Tile overlay
  final TileOverlayStyle tileOverlayStyle;
  final double tileOverlayAlpha; // 패턴 오버레이 투명도
  final double tileMargin;       // 타일 간 여백 (값 작을수록 타일 커 보임)

  // Overlay / UI texts
  final String winTitle;
  final String winSubtitle;
  final String gameOverTitle;
  final String continueLabel;
  final String newGameLabel;
  final String restartLabel;
  final String hintText;
  final String logoLabel;
  final IconData logoIcon;

  // Particle colors for win overlay
  final List<Color> particleColors;

  const AppTheme({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.subtitle,
    required this.background,
    required this.surface,
    required this.boardBg,
    required this.cellBg,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.accentPop,
    required this.accentWarm,
    required this.boardRadius,
    required this.tileRadius,
    required this.slideCurve,
    required this.slideDuration,
    required this.mergeScalePeak,
    required this.mergeScaleDip,
    required this.mergeScaleBounce,
    required this.mergeDuration,
    required this.spawnCurve,
    required this.spawnDuration,
    required this.soundProfile,
    required this.statusBrightness,
    required this.tileOverlayStyle,
    required this.tileOverlayAlpha,
    required this.tileMargin,
    required this.winTitle,
    required this.winSubtitle,
    required this.gameOverTitle,
    required this.continueLabel,
    required this.newGameLabel,
    required this.restartLabel,
    required this.hintText,
    required this.logoLabel,
    required this.logoIcon,
    required this.particleColors,
  });

  static AppTheme fromIdString(String id) {
    switch (id) {
      case 'cherry_bloom':
        return cherryBloom;
      case 'pastel_dream':
        return pastelDream;
      default:
        return neonCircuit;
    }
  }

  String get idString {
    switch (id) {
      case ThemeId.neonCircuit:
        return 'neon_circuit';
      case ThemeId.cherryBloom:
        return 'cherry_bloom';
      case ThemeId.pastelDream:
        return 'pastel_dream';
    }
  }

  bool get isDark => statusBrightness == Brightness.light;

  double tileFontSize(int value) {
    final digits = value.toString().length;
    if (digits <= 2) return 32;
    if (digits == 3) return 26;
    if (digits == 4) return 20;
    return 16;
  }

  Color tileColor(int value) => _tileColorFn(id, value);
  Color tileGlow(int value) => _tileGlowFn(id, value);
  Color tileBorder(int value) => _tileBorderFn(id, value);
  Color tileTextColor(int value) => _tileTextColorFn(id, value);

  /// 타일 배경 그라디언트 — null이면 단색(tileColor) 사용
  Gradient? tileGradient(int value) {
    final base = tileColor(value);
    final border = tileBorder(value);
    switch (id) {
      case ThemeId.neonCircuit:
        // 왼쪽 위에 약한 청색 하이라이트 → 오른쪽 아래 어두운 면
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, border, 0.20)!,
            base,
            Color.lerp(base, Colors.black, 0.18)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        );
      case ThemeId.cherryBloom:
        // 왼쪽 위: 밝은 핑크 하이라이트 → 오른쪽 아래: 깊은 로즈
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.32)!,
            base,
            Color.lerp(base, Colors.black, 0.22)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        );
      case ThemeId.pastelDream:
        // 왼쪽 위: 거의 흰색 → 오른쪽 아래: 파스텔 원색
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.50)!,
            base,
          ],
        );
    }
  }

  ThemeData get flutterTheme {
    if (isDark) {
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        fontFamily: id == ThemeId.neonCircuit ? 'monospace' : null,
        colorScheme: ColorScheme.dark(
          primary: accent,
          secondary: accentAlt,
          surface: surface,
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.light(
          primary: accent,
          secondary: accentAlt,
          surface: surface,
        ),
      );
    }
  }

  // ─── Tile color dispatch ───────────────────────────────────────────────────

  static Color _tileColorFn(ThemeId id, int value) {
    switch (id) {
      case ThemeId.neonCircuit:
        return _neonTileColor(value);
      case ThemeId.cherryBloom:
        return _cherryTileColor(value);
      case ThemeId.pastelDream:
        return _pastelTileColor(value);
    }
  }

  static Color _tileGlowFn(ThemeId id, int value) {
    switch (id) {
      case ThemeId.neonCircuit:
        return _neonTileGlow(value);
      case ThemeId.cherryBloom:
        return _cherryTileGlow(value);
      case ThemeId.pastelDream:
        return _pastelTileGlow(value);
    }
  }

  static Color _tileBorderFn(ThemeId id, int value) {
    switch (id) {
      case ThemeId.neonCircuit:
        return _neonTileBorder(value);
      case ThemeId.cherryBloom:
        return _cherryTileBorder(value);
      case ThemeId.pastelDream:
        return _pastelTileBorder(value);
    }
  }

  static Color _tileTextColorFn(ThemeId id, int value) {
    switch (id) {
      case ThemeId.neonCircuit:
        return _neonTileText(value);
      case ThemeId.cherryBloom:
        return _cherryTileText(value);
      case ThemeId.pastelDream:
        return _pastelTileText(value);
    }
  }

  // ─── Neon Circuit ──────────────────────────────────────────────────────────

  static Color _neonTileColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFF1B2A3B);
      case 4:
        return const Color(0xFF1B2E4A);
      case 8:
        return const Color(0xFF0D2B4A);
      case 16:
        return const Color(0xFF0A2240);
      case 32:
        return const Color(0xFF1A1B4B);
      case 64:
        return const Color(0xFF2D1B6B);
      case 128:
        return const Color(0xFF3D1B7A);
      case 256:
        return const Color(0xFF1B3D7A);
      case 512:
        return const Color(0xFF0A3D6B);
      case 1024:
        return const Color(0xFF0A4D5A);
      case 2048:
        return const Color(0xFF1A0A3D);
      default:
        return const Color(0xFF2A0A4D);
    }
  }

  static const _neonBlue = Color(0xFF00D4FF);
  static const _neonCyan = Color(0xFF00FFEA);
  static const _neonPurple = Color(0xFF9B59FF);
  static const _neonPink = Color(0xFFFF2D78);
  static const _neonGold = Color(0xFFFFD700);

  static Color _neonTileGlow(int value) {
    if (value <= 4) return _neonBlue.withValues(alpha: 0.3);
    if (value <= 16) return _neonCyan.withValues(alpha: 0.4);
    if (value <= 64) return _neonPurple.withValues(alpha: 0.5);
    if (value <= 256) return _neonPurple.withValues(alpha: 0.6);
    if (value <= 1024) return _neonPink.withValues(alpha: 0.6);
    if (value == 2048) return _neonGold.withValues(alpha: 0.9);
    return _neonGold.withValues(alpha: 1.0);
  }

  static Color _neonTileBorder(int value) {
    if (value <= 4) return _neonBlue.withValues(alpha: 0.5);
    if (value <= 16) return _neonCyan.withValues(alpha: 0.6);
    if (value <= 64) return _neonPurple.withValues(alpha: 0.7);
    if (value <= 256) return _neonPurple.withValues(alpha: 0.8);
    if (value <= 1024) return _neonPink.withValues(alpha: 0.8);
    return _neonGold;
  }

  static Color _neonTileText(int value) {
    if (value <= 4) return _neonBlue;
    if (value <= 16) return _neonCyan;
    if (value <= 64) return _neonPurple;
    if (value <= 256) return const Color(0xFFBB8FFF);
    if (value <= 1024) return _neonPink;
    return _neonGold;
  }

  // ─── Cherry Bloom ──────────────────────────────────────────────────────────

  static Color _cherryTileColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFF2D1020);
      case 4:
        return const Color(0xFF3A1228);
      case 8:
        return const Color(0xFF481432);
      case 16:
        return const Color(0xFF56163C);
      case 32:
        return const Color(0xFF641840);
      case 64:
        return const Color(0xFF721B44);
      case 128:
        return const Color(0xFF7E1E48);
      case 256:
        return const Color(0xFF8A2048);
      case 512:
        return const Color(0xFF962244);
      case 1024:
        return const Color(0xFFA0243C);
      case 2048:
        return const Color(0xFFAA2830);
      default:
        return const Color(0xFFB43022);
    }
  }

  static const _cherryPink = Color(0xFFFF4EA3);
  static const _cherryRose = Color(0xFFFF2D78);
  static const _cherryLight = Color(0xFFFFB3D1);
  static const _cherryPeach = Color(0xFFFFD6A0);
  static const _cherryMagenta = Color(0xFFFF69B4);

  static Color _cherryTileGlow(int value) {
    if (value <= 4) return _cherryPink.withValues(alpha: 0.3);
    if (value <= 16) return _cherryMagenta.withValues(alpha: 0.4);
    if (value <= 64) return _cherryRose.withValues(alpha: 0.5);
    if (value <= 256) return _cherryRose.withValues(alpha: 0.6);
    if (value <= 1024) return _cherryLight.withValues(alpha: 0.6);
    return _cherryPeach.withValues(alpha: 0.9);
  }

  static Color _cherryTileBorder(int value) {
    if (value <= 4) return _cherryPink.withValues(alpha: 0.5);
    if (value <= 16) return _cherryMagenta.withValues(alpha: 0.6);
    if (value <= 64) return _cherryRose.withValues(alpha: 0.7);
    if (value <= 256) return _cherryRose.withValues(alpha: 0.8);
    if (value <= 1024) return _cherryLight.withValues(alpha: 0.8);
    return _cherryPeach;
  }

  static Color _cherryTileText(int value) {
    if (value <= 4) return _cherryPink;
    if (value <= 16) return _cherryMagenta;
    if (value <= 64) return _cherryRose;
    if (value <= 256) return _cherryLight;
    if (value <= 1024) return const Color(0xFFFFC8E0);
    return _cherryPeach;
  }

  // ─── Pastel Dream ──────────────────────────────────────────────────────────

  static Color _pastelTileColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFFE8DCFF);
      case 4:
        return const Color(0xFFDDD0FF);
      case 8:
        return const Color(0xFFD1C4FF);
      case 16:
        return const Color(0xFFC4B4FF);
      case 32:
        return const Color(0xFFC8E8FF);
      case 64:
        return const Color(0xFFB8F0E8);
      case 128:
        return const Color(0xFFFFD0E0);
      case 256:
        return const Color(0xFFFFDCB8);
      case 512:
        return const Color(0xFFFFF0B8);
      case 1024:
        return const Color(0xFFFFD0F0);
      case 2048:
        return const Color(0xFFFFE8FF);
      default:
        return const Color(0xFFF0C8FF);
    }
  }

  static const _pastelLavender = Color(0xFF9B7FD4);
  static const _pastelMint = Color(0xFF5CC8A0);
  static const _pastelPeach = Color(0xFFF0A0B0);
  static const _pastelButter = Color(0xFFD4A855);
  static const _pastelBlue = Color(0xFF7EB8F0);

  static Color _pastelTileGlow(int value) {
    if (value <= 4) return _pastelLavender.withValues(alpha: 0.35);
    if (value <= 16) return _pastelBlue.withValues(alpha: 0.35);
    if (value <= 64) return _pastelMint.withValues(alpha: 0.35);
    if (value <= 256) return _pastelPeach.withValues(alpha: 0.35);
    if (value <= 1024) return _pastelButter.withValues(alpha: 0.45);
    return _pastelButter.withValues(alpha: 0.65);
  }

  static Color _pastelTileBorder(int value) {
    if (value <= 4) return _pastelLavender.withValues(alpha: 0.55);
    if (value <= 16) return _pastelBlue.withValues(alpha: 0.55);
    if (value <= 64) return _pastelMint.withValues(alpha: 0.55);
    if (value <= 256) return _pastelPeach.withValues(alpha: 0.55);
    if (value <= 1024) return _pastelButter.withValues(alpha: 0.65);
    return _pastelButter;
  }

  static Color _pastelTileText(int value) {
    if (value <= 4) return const Color(0xFF6B50A8);
    if (value <= 16) return const Color(0xFF4878C0);
    if (value <= 64) return const Color(0xFF3A9870);
    if (value <= 256) return const Color(0xFFC05080);
    if (value <= 1024) return const Color(0xFFA07020);
    return const Color(0xFF8030A0);
  }

  // ─── Static theme instances ────────────────────────────────────────────────

  static const AppTheme neonCircuit = AppTheme(
    id: ThemeId.neonCircuit,
    displayName: 'Neon Circuit',
    emoji: '⚡',
    subtitle: 'Cyberpunk electric',
    background: Color(0xFF0A0E1A),
    surface: Color(0xFF111827),
    boardBg: Color(0xFF0D1117),
    cellBg: Color(0xFF1A2235),
    textPrimary: Color(0xFFE8F4FD),
    textMuted: Color(0xFF6B7A99),
    accent: Color(0xFF00D4FF),
    accentAlt: Color(0xFF00FFEA),
    accentPop: Color(0xFF9B59FF),
    accentWarm: Color(0xFFFFD700),
    boardRadius: 10,
    tileRadius: 6,
    slideCurve: _ExpoOut(),
    slideDuration: Duration(milliseconds: 105),
    mergeScalePeak: 1.65,
    mergeScaleDip: 0.82,
    mergeScaleBounce: 1.10,
    mergeDuration: Duration(milliseconds: 180),
    spawnCurve: Curves.elasticOut,
    spawnDuration: Duration(milliseconds: 160),
    soundProfile: SoundProfile.neonCircuit,
    statusBrightness: Brightness.light,
    tileOverlayStyle: TileOverlayStyle.circuit,
    tileOverlayAlpha: 0.15,
    tileMargin: 3,
    winTitle: '⚡ Spark Ignited! ⚡',
    winSubtitle: 'You reached 2048!',
    gameOverTitle: 'SYSTEM HALT',
    continueLabel: 'KEEP GOING',
    newGameLabel: 'NEW GAME',
    restartLabel: 'REBOOT',
    hintText: 'SWIPE TO MERGE  •  REACH 2048',
    logoLabel: 'Spark',
    logoIcon: Icons.bolt,
    particleColors: [
      Color(0xFFFFD700),
      Color(0xFF00D4FF),
      Color(0xFF9B59FF),
      Color(0xFF00FFEA),
    ],
  );

  static const AppTheme cherryBloom = AppTheme(
    id: ThemeId.cherryBloom,
    displayName: 'Cherry Bloom',
    emoji: '🌸',
    subtitle: 'Vibrant pink bloom',
    background: Color(0xFF1A0B12),
    surface: Color(0xFF2D1422),
    boardBg: Color(0xFF140910),
    cellBg: Color(0xFF241220),
    textPrimary: Color(0xFFFFE8F0),
    textMuted: Color(0xFF9E6B82),
    accent: Color(0xFFFF4EA3),
    accentAlt: Color(0xFFFF2D78),
    accentPop: Color(0xFFFFB3D1),
    accentWarm: Color(0xFFFFD6A0),
    boardRadius: 14,
    tileRadius: 8,
    slideCurve: _ExpoOut(),
    slideDuration: Duration(milliseconds: 105),
    mergeScalePeak: 1.50,
    mergeScaleDip: 0.88,
    mergeScaleBounce: 1.08,
    mergeDuration: Duration(milliseconds: 185),
    spawnCurve: Curves.elasticOut,
    spawnDuration: Duration(milliseconds: 160),
    soundProfile: SoundProfile.cherryBloom,
    statusBrightness: Brightness.light,
    tileOverlayStyle: TileOverlayStyle.floral,
    tileOverlayAlpha: 0.24,
    tileMargin: 2,
    winTitle: '🌸 Cherry Bloom! 🌸',
    winSubtitle: 'You reached 2048!',
    gameOverTitle: 'PETALS FALL',
    continueLabel: 'KEEP GOING',
    newGameLabel: 'NEW GAME',
    restartLabel: 'TRY AGAIN',
    hintText: 'SWIPE TO MERGE  •  REACH 2048',
    logoLabel: 'Bloom',
    logoIcon: Icons.local_florist,
    particleColors: [
      Color(0xFFFF4EA3),
      Color(0xFFFFB3D1),
      Color(0xFFFF2D78),
      Color(0xFFFFD6A0),
    ],
  );

  static const AppTheme pastelDream = AppTheme(
    id: ThemeId.pastelDream,
    displayName: 'Pastel Dream',
    emoji: '✨',
    subtitle: 'Soft & dreamy pastels',
    background: Color(0xFFF5F0FF),
    surface: Color(0xFFEDE5FF),
    boardBg: Color(0xFFE2D8FF),
    cellBg: Color(0xFFD8CCFF),
    textPrimary: Color(0xFF2D2040),
    textMuted: Color(0xFF8A7FAE),
    accent: Color(0xFF9B7FD4),
    accentAlt: Color(0xFF5CC8A0),
    accentPop: Color(0xFFF0A0B0),
    accentWarm: Color(0xFFD4A855),
    boardRadius: 18,
    tileRadius: 12,
    slideCurve: _ExpoOut(),
    slideDuration: Duration(milliseconds: 110),
    mergeScalePeak: 1.35,
    mergeScaleDip: 0.92,
    mergeScaleBounce: 1.04,
    mergeDuration: Duration(milliseconds: 200),
    spawnCurve: Curves.easeOut,
    spawnDuration: Duration(milliseconds: 160),
    soundProfile: SoundProfile.pastelDream,
    statusBrightness: Brightness.dark,
    tileOverlayStyle: TileOverlayStyle.dots,
    tileOverlayAlpha: 0.32,
    tileMargin: 4,
    winTitle: '✨ Dream Achieved! ✨',
    winSubtitle: 'You reached 2048!',
    gameOverTitle: 'DREAM PAUSED',
    continueLabel: 'KEEP GOING',
    newGameLabel: 'NEW GAME',
    restartLabel: 'TRY AGAIN',
    hintText: 'SWIPE TO MERGE  •  REACH 2048',
    logoLabel: 'Dream',
    logoIcon: Icons.auto_awesome,
    particleColors: [
      Color(0xFF9B7FD4),
      Color(0xFF5CC8A0),
      Color(0xFFF0A0B0),
      Color(0xFFD4A855),
    ],
  );

  static const List<AppTheme> all = [neonCircuit, cherryBloom, pastelDream];
}

/// 지수 감속 커브: 빠르게 출발해 정확하게 멈춤 (Neon Circuit)
class _ExpoOut extends Curve {
  const _ExpoOut();
  @override
  double transformInternal(double t) {
    if (t == 1.0) return 1.0;
    return 1 - pow(2, -10 * t).toDouble();
  }
}

/// 사인 감속 커브: 부드럽게 가속 후 감속 (Cherry Bloom)
class _SineOut extends Curve {
  const _SineOut();
  @override
  double transformInternal(double t) => sin(t * pi / 2);
}
