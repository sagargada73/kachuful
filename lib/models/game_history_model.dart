class GameHistory {
  final String? id; // Firestore document ID
  final DateTime timestamp;
  final int? clientTimestamp; // ms since epoch (client-side), optional
  final int numberOfPlayers;
  final int startingCards;
  final int scoreMode;
  final List<PlayerScore> playerScores;
  final String winnerId;

  GameHistory({
    this.id,
    required this.timestamp,
    this.clientTimestamp,
    required this.numberOfPlayers,
    required this.startingCards,
    required this.scoreMode,
    required this.playerScores,
    required this.winnerId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      if (clientTimestamp != null) 'clientTimestamp': clientTimestamp,
      'numberOfPlayers': numberOfPlayers,
      'startingCards': startingCards,
      'scoreMode': scoreMode,
      'playerScores': playerScores.map((p) => p.toJson()).toList(),
      'winnerId': winnerId,
    };
  }

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'];
    DateTime parsedTimestamp;
    try {
      if (ts == null) {
        parsedTimestamp = DateTime.now();
      } else if (ts is String) {
        parsedTimestamp = DateTime.parse(ts);
      } else if (ts is DateTime) {
        parsedTimestamp = ts;
      } else {
        // Try Firestore Timestamp-like object with toDate()
        parsedTimestamp = (ts as dynamic).toDate();
      }
    } catch (_) {
      parsedTimestamp = DateTime.now();
    }

    return GameHistory(
      id: json['id'],
      timestamp: parsedTimestamp,
      clientTimestamp: json['clientTimestamp'] is int
          ? json['clientTimestamp'] as int
          : (json['clientTimestamp'] is String
              ? int.tryParse(json['clientTimestamp'])
              : null),
      numberOfPlayers: json['numberOfPlayers'],
      startingCards: json['startingCards'],
      scoreMode: json['scoreMode'],
      playerScores: (json['playerScores'] as List)
          .map((p) => PlayerScore.fromJson(p))
          .toList(),
      winnerId: json['winnerId'],
    );
  }
}

class PlayerScore {
  final String id;
  final String name;
  final int totalScore;
  final bool isWinner;

  PlayerScore({
    required this.id,
    required this.name,
    required this.totalScore,
    required this.isWinner,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalScore': totalScore,
      'isWinner': isWinner,
    };
  }

  factory PlayerScore.fromJson(Map<String, dynamic> json) {
    return PlayerScore(
      id: json['id'],
      name: json['name'],
      totalScore: json['totalScore'],
      isWinner: json['isWinner'],
    );
  }
}
