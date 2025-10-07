import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../models/game_history_model.dart';

class CloudGameHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Get user's games collection reference
  CollectionReference? get _userGamesCollection {
    if (_userId == null) return null;
    return _firestore
        .collection(AppConfig.usersCollection)
        .doc(_userId)
        .collection(AppConfig.gamesCollection);
  }

  /// Get all games for the current user, sorted by timestamp (newest first)
  Future<List<GameHistory>> getHistory() async {
    try {
      if (_userGamesCollection == null) {
        print('No user logged in');
        return [];
      }

      // Try server first with a timeout, then fall back to cache to avoid hanging UI
      QuerySnapshot querySnapshot;
      try {
        // Allow more time for slow networks but still fall back to cache if it takes too long
        querySnapshot = await _userGamesCollection!
            .limit(50)
            .get()
            .timeout(const Duration(seconds: 10));
      } on Exception catch (e) {
        print(
            'History server fetch failed or timed out, falling back to cache: $e');
        querySnapshot = await _userGamesCollection!
            .limit(50)
            .get(const GetOptions(source: Source.cache));
      }

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return GameHistory.fromJson(data);
      }).toList();
      // Sort client-side: prefer clientTimestamp, then timestamp
      items.sort((a, b) {
        final at = a.clientTimestamp ?? a.timestamp.millisecondsSinceEpoch;
        final bt = b.clientTimestamp ?? b.timestamp.millisecondsSinceEpoch;
        return bt.compareTo(at);
      });
      return items;
    } catch (e) {
      print('Error loading history from Firestore: $e');
      return [];
    }
  }

  /// Save a new game to Firestore
  Future<void> saveGame(GameHistory game) async {
    try {
      if (_userGamesCollection == null) {
        print('No user logged in, cannot save game');
        return;
      }
      if (AppConfig.requireEmailVerifiedToSave &&
          (_auth.currentUser?.emailVerified != true)) {
        print('User email not verified; skipping save by configuration');
        return;
      }

      final gameData = game.toJson();
      gameData['userId'] = _userId;
      // Keep server timestamp for authoritative time
      gameData['timestamp'] = FieldValue.serverTimestamp();
      // Add client timestamp (ms since epoch) so UI can order immediately
      gameData['clientTimestamp'] = DateTime.now().millisecondsSinceEpoch;

      // Do not aggressively timeout writes; allow Firestore offline queueing and slow networks.
      try {
        await _userGamesCollection!.add(gameData);
      } on Exception catch (e) {
        // One quick retry for transient failures
        print('Save failed once, retrying: $e');
        await Future.delayed(const Duration(milliseconds: 500));
        await _userGamesCollection!.add(gameData);
      }
      print('Game saved to Firestore successfully');
    } catch (e) {
      print('Error saving game to Firestore (continuing without crash): $e');
      // Intentionally swallow to avoid blocking UI at game over when offline
    }
  }

  /// Delete a specific game by document ID
  Future<void> deleteGame(String documentId) async {
    try {
      if (_userGamesCollection == null) {
        print('No user logged in');
        return;
      }

      await _userGamesCollection!.doc(documentId).delete();
      print('Game deleted from Firestore successfully');
    } catch (e) {
      print('Error deleting game from Firestore: $e');
      rethrow;
    }
  }

  /// Clear all game history for the current user
  Future<void> clearHistory() async {
    try {
      if (_userGamesCollection == null) {
        print('No user logged in');
        return;
      }

      final querySnapshot = await _userGamesCollection!.get();
      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All games cleared from Firestore successfully');
    } catch (e) {
      print('Error clearing history from Firestore: $e');
      rethrow;
    }
  }

  /// Get statistics for the current user
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (_userGamesCollection == null) {
        return {
          'totalGames': 0,
          'totalWins': 0,
          'winRate': 0.0,
        };
      }

      final games = await getHistory();
      final userEmail = _auth.currentUser?.email ?? '';

      int totalGames = games.length;
      int totalWins = 0;

      for (var game in games) {
        // Check if current user won this game
        final winningPlayer = game.playerScores.firstWhere(
          (player) => player.isWinner,
          orElse: () => game.playerScores.first,
        );

        // Check if winner's name matches user email or contains user email
        if (winningPlayer.name.contains(userEmail) ||
            winningPlayer.name == userEmail) {
          totalWins++;
        }
      }

      return {
        'totalGames': totalGames,
        'totalWins': totalWins,
        'winRate': totalGames > 0 ? (totalWins / totalGames * 100) : 0.0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalGames': 0,
        'totalWins': 0,
        'winRate': 0.0,
      };
    }
  }

  /// Stream of game history (real-time updates)
  Stream<List<GameHistory>> getHistoryStream() {
    if (_userGamesCollection == null) {
      return Stream.value([]);
    }

    // Using includeMetadataChanges allows cached data to arrive immediately
    // followed by server updates when available.
    return _userGamesCollection!
        .limit(50)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return GameHistory.fromJson(data);
      }).toList();
      items.sort((a, b) {
        final at = a.clientTimestamp ?? a.timestamp.millisecondsSinceEpoch;
        final bt = b.clientTimestamp ?? b.timestamp.millisecondsSinceEpoch;
        return bt.compareTo(at);
      });
      return items;
    });
  }
}
