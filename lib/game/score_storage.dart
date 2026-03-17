import 'package:shared_preferences/shared_preferences.dart';

class ScoreStorage {
  static const _key = 'best_score';

  static Future<int> loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> saveBest(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, score);
  }
}
