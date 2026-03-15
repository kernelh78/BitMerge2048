import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/spark_theme.dart';
import 'ui/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 상태바 다크 스타일
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const BitMergeApp());
}

class BitMergeApp extends StatelessWidget {
  const BitMergeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BitMerge: 2048 Spark',
      theme: SparkTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}
