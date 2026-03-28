import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'ui/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final savedTheme = await ThemeNotifier.loadSaved();
  final notifier = ThemeNotifier(savedTheme);

  runApp(BitMergeApp(notifier: notifier));
}

class BitMergeApp extends StatelessWidget {
  final ThemeNotifier notifier;
  const BitMergeApp({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      notifier: notifier,
      child: ValueListenableBuilder<AppTheme>(
        valueListenable: notifier,
        builder: (context, theme, _) {
          // 상태바 스타일: 밝은 배경이면 아이콘 어둡게, 어두운 배경이면 밝게
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.statusBrightness,
            statusBarBrightness:
                theme.isDark ? Brightness.dark : Brightness.light,
          ));

          return MaterialApp(
            title: 'BitMerge: 2048',
            theme: theme.flutterTheme,
            debugShowCheckedModeBanner: false,
            home: const GameScreen(),
          );
        },
      ),
    );
  }
}
