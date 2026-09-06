import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../../models/user_model.dart';
import 'firestore_service.dart';

/// Loads user profiles from Firestore, caches to local SQLite.
/// Falls back to SQLite cache when offline.
class FirebaseUserRepository {
  static final FirebaseUserRepository instance = FirebaseUserRepository._();
  FirebaseUserRepository._();

  final FirestoreService _firestore = FirestoreService.instance;
  final AppDatabase _db = AppDatabase.instance;

  /// Load profile: Firestore first, SQLite cache fallback.
  Future<UserModel?> loadProfile(String uid) async {
    try {
      final remote = await _firestore.getUserProfile(uid);
      if (remote != null) {
        await _cacheProfile(remote);
        return remote;
      }
    } catch (_) {
      // Offline – fall through to local cache
    }
    return _loadCachedProfile(uid);
  }

  Future<void> saveProfile(UserModel user) async {
    await _firestore.createOrUpdateUserProfile(user.id, user.toFirestoreMap());
    await _cacheProfile(user);
  }

  Future<void> _cacheProfile(UserModel user) async {
    final db = await _db.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> _loadCachedProfile(String uid) async {
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }
}
