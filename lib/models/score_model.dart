class ScoreModel {
  final String? id;
  final String userId;
  final String gameId;
  final int score;
  final String playerName;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ScoreModel({
    this.id,
    required this.userId,
    required this.gameId,
    required this.score,
    required this.playerName,
    required this.createdAt,
    this.metadata,
  });

  factory ScoreModel.fromMap(Map<String, dynamic> map, String id) {
    return ScoreModel(
      id: id,
      userId: map['userId'] ?? '',
      gameId: map['gameId'] ?? '',
      score: map['score'] ?? 0,
      playerName: map['playerName'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameId': gameId,
      'score': score,
      'playerName': playerName,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }
}
