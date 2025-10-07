import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history_model.dart';

class GameHistoryService {
  static const String _historyKey = 'game_history';

  Future<List<GameHistory>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null) {
        return [];
      }

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .map((json) => GameHistory.fromJson(json))
          .toList()
          .reversed
          .toList(); // Most recent first
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  Future<void> saveGame(GameHistory game) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Add new game to history
      history.insert(0, game); // Add at beginning

      // Keep only last 50 games
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      // Save to shared preferences
      final historyJson = jsonEncode(
        history.map((g) => g.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  Future<void> deleteGame(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      if (index >= 0 && index < history.length) {
        history.removeAt(index);

        // Save updated history
        final historyJson = jsonEncode(
          history.map((g) => g.toJson()).toList(),
        );
        await prefs.setString(_historyKey, historyJson);
      }
    } catch (e) {
      print('Error deleting game: $e');
    }
  }
}
