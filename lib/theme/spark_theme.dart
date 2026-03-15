import 'package:flutter/material.dart';

class SparkTheme {
  // 배경
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color boardBg = Color(0xFF0D1117);
  static const Color cellBg = Color(0xFF1A2235);

  // 네온 강조
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonPurple = Color(0xFF9B59FF);
  static const Color neonCyan = Color(0xFF00FFEA);
  static const Color neonPink = Color(0xFFFF2D78);
  static const Color neonGold = Color(0xFFFFD700);

  // 텍스트
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF6B7A99);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: neonBlue,
          secondary: neonPurple,
          surface: surface,
        ),
      );

  /// 타일 값에 따른 색상 반환
  static Color tileColor(int value) {
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

  /// 타일 글로우(발광) 색상
  static Color tileGlow(int value) {
    if (value <= 4) return neonBlue.withValues(alpha: 0.3);
    if (value <= 16) return neonCyan.withValues(alpha: 0.4);
    if (value <= 64) return neonPurple.withValues(alpha: 0.5);
    if (value <= 256) return neonPurple.withValues(alpha: 0.6);
    if (value <= 1024) return neonPink.withValues(alpha: 0.6);
    if (value == 2048) return neonGold.withValues(alpha: 0.9);
    return neonGold.withValues(alpha: 1.0);
  }

  /// 타일 테두리 색상
  static Color tileBorder(int value) {
    if (value <= 4) return neonBlue.withValues(alpha: 0.5);
    if (value <= 16) return neonCyan.withValues(alpha: 0.6);
    if (value <= 64) return neonPurple.withValues(alpha: 0.7);
    if (value <= 256) return neonPurple.withValues(alpha: 0.8);
    if (value <= 1024) return neonPink.withValues(alpha: 0.8);
    if (value == 2048) return neonGold;
    return neonGold;
  }

  /// 타일 텍스트 색상
  static Color tileTextColor(int value) {
    if (value <= 4) return neonBlue;
    if (value <= 16) return neonCyan;
    if (value <= 64) return neonPurple;
    if (value <= 256) return const Color(0xFFBB8FFF);
    if (value <= 1024) return neonPink;
    if (value == 2048) return neonGold;
    return neonGold;
  }

  /// 타일 폰트 크기
  static double tileFontSize(int value) {
    final digits = value.toString().length;
    if (digits <= 2) return 32;
    if (digits == 3) return 26;
    if (digits == 4) return 20;
    return 16;
  }
}
