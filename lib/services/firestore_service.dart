import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get users => _db.collection(AppConfig.usersCollection);
  CollectionReference get scores => _db.collection('scores');
  CollectionReference get games => _db.collection(AppConfig.gamesCollection);

  // User operations
  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).set(data);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await users.doc(uid).get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).update(data);
  }

  // Score operations
  Future<String> createScore(Map<String, dynamic> scoreData) async {
    final docRef = await scores.add(scoreData);
    return docRef.id;
  }

  Future<QuerySnapshot> getUserScores(String userId) async {
    return await scores
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> updateScore(String scoreId, Map<String, dynamic> data) async {
    await scores.doc(scoreId).update(data);
  }

  Future<void> deleteScore(String scoreId) async {
    await scores.doc(scoreId).delete();
  }

  // Game operations
  Future<String> createGame(Map<String, dynamic> gameData) async {
    final docRef = await games.add(gameData);
    return docRef.id;
  }

  Future<QuerySnapshot> getAllGames() async {
    return await games.orderBy('createdAt', descending: true).get();
  }

  Stream<QuerySnapshot> getGamesStream() {
    return games.orderBy('createdAt', descending: true).snapshots();
  }
}
