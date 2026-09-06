import '../firestore_service.dart';

/// Firestore data source for document records.
/// Use through the repository layer only — never call from screens directly.
class FirestoreDocumentDatasource {
  FirestoreDocumentDatasource({FirestoreService? firestoreService})
      : _fs = firestoreService ?? FirestoreService.instance;

  final FirestoreService _fs;

  static const _collection = 'documents';

  Future<void> create(String docId, Map<String, dynamic> data) =>
      _fs.setDocument(_collection, docId, data);

  Future<void> update(String docId, Map<String, dynamic> data) =>
      _fs.updateDocument(_collection, docId, data);

  Future<Map<String, dynamic>?> getById(String docId) =>
      _fs.getDocument(_collection, docId);

  Future<List<Map<String, dynamic>>> getByUserId(String userId) =>
      _fs.queryDocuments(
        _collection,
        whereField: 'inspectorId',
        whereValue: userId,
        orderBy: 'createdAt',
        descending: true,
      );

  Future<List<Map<String, dynamic>>> getByMineId(String mineId) =>
      _fs.queryDocuments(
        _collection,
        whereField: 'mineId',
        whereValue: mineId,
        orderBy: 'createdAt',
        descending: true,
      );
}
