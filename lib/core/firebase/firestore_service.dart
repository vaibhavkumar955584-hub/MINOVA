import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

/// Central Firestore access layer.
/// Screens NEVER call FirebaseFirestore.instance directly.
/// All Firestore access passes through this service or the per-entity datasources.
class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Collections ────────────────────────────────────────────────
  CollectionReference get usersCol => _db.collection('users');
  CollectionReference get minesCol => _db.collection('mines');
  CollectionReference get inspectionsCol => _db.collection('inspections');
  CollectionReference get incidentsCol => _db.collection('incidents');
  CollectionReference get attendanceCol => _db.collection('attendance');
  CollectionReference get grievancesCol => _db.collection('grievances');
  CollectionReference get observationsCol => _db.collection('grievances');
  CollectionReference get documentsCol => _db.collection('documents');
  CollectionReference get correctionRequestsCol =>
      _db.collection('correctionRequests');
  CollectionReference get auditEventsCol => _db.collection('auditEvents');

  // ── User Profile ───────────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await usersCol.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()! as Map<String, dynamic>;
      return UserModel.fromFirestore(uid, data);
    } catch (_) {
      return null;
    }
  }

  Future<void> createOrUpdateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await usersCol.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> setReport({
    required String collection,
    required String reportId,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection(collection)
        .doc(reportId)
        .set(_withFirestoreTimestamps(data), SetOptions(merge: true));
  }

  Map<String, dynamic> _withFirestoreTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      // Keep date_time, check_in_time, check_out_time, captured_at as strings for desktop portal compatibility
      if (key == 'date_time' || key == 'check_in_time' || key == 'check_out_time' || key == 'captured_at') {
        return MapEntry(key, value.toString());
      }
      if (value is DateTime) {
        return MapEntry(key, Timestamp.fromDate(value));
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _withFirestoreTimestamps(value));
      }
      if (value is List) {
        return MapEntry(
          key,
          value.map((item) {
            if (item is DateTime) {
              return Timestamp.fromDate(item);
            }
            if (item is Map<String, dynamic>) {
              return _withFirestoreTimestamps(item);
            }
            return item;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }

  // ── Mine ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getMine(String mineId) async {
    try {
      final doc = await minesCol.doc(mineId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  // ── Generic document write (used by datasources) ───────────────
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _db
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      final doc = await _db.collection(collection).doc(docId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> queryDocuments(
    String collection, {
    String? whereField,
    dynamic whereValue,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _db.collection(collection);
      if (whereField != null) {
        query = query.where(whereField, isEqualTo: whereValue);
      }
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();
    } catch (_) {
      return [];
    }
  }
}
