import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeNotifier extends ValueNotifier<AppTheme> {
  ThemeNotifier(super.initial);

  Future<void> setTheme(AppTheme theme) async {
    value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_id', theme.idString);
  }

  static Future<AppTheme> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('theme_id') ?? 'neon_circuit';
    return AppTheme.fromIdString(id);
  }
}

/// InheritedNotifier — 모든 위젯이 context로 현재 테마에 접근 가능
class ThemeScope extends InheritedNotifier<ThemeNotifier> {
  const ThemeScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope?.notifier?.value ?? AppTheme.neonCircuit;
  }

  static ThemeNotifier notifierOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope!.notifier!;
  }
}
