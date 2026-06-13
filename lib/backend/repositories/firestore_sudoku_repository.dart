import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sudoku_record.dart';
import 'sudoku_repository.dart';

class FirestoreSudokuRepository implements ISudokuRepository {
  final FirebaseFirestore _db;
  final String uid;

  FirestoreSudokuRepository({required this.uid, FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('sudoku_records');

  static Map<String, dynamic> _toMap(SudokuRecord r) => {
    'id': r.id,
    'scannedAt': r.scannedAt.toIso8601String(),
    'initialGrid': r.initialGrid,
    'solvedGrid': r.solvedGrid,
    'solveMode': r.solveMode.index,
    'solveTimeMicros': r.solveTime?.inMicroseconds,
    'hintsUsed': r.hintsUsed,
    'userId': r.userId,
  };

  static SudokuRecord _fromMap(Map<String, dynamic> m) => SudokuRecord(
    id: m['id'] as String,
    scannedAt: DateTime.parse(m['scannedAt'] as String),
    initialGrid: (m['initialGrid'] as List)
        .map((row) => (row as List).map((v) => v as int).toList())
        .toList(),
    solvedGrid: m['solvedGrid'] == null
        ? null
        : (m['solvedGrid'] as List)
              .map((row) => (row as List).map((v) => v as int).toList())
              .toList(),
    solveMode: SolveModeRecord.values[m['solveMode'] as int],
    solveTime: m['solveTimeMicros'] == null
        ? null
        : Duration(microseconds: m['solveTimeMicros'] as int),
    hintsUsed: m['hintsUsed'] as int? ?? 0,
    userId: m['userId'] as String?,
  );

  @override
  Future<void> save(SudokuRecord record) =>
      _col.doc(record.id).set(_toMap(record));

  @override
  Future<List<SudokuRecord>> getAll() async {
    final snap = await _col.orderBy('scannedAt', descending: true).get();
    return snap.docs.map((d) => _fromMap(d.data())).toList();
  }

  @override
  Future<SudokuRecord?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromMap(doc.data()!);
  }

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> uploadBatch(List<SudokuRecord> records) async {
    if (records.isEmpty) return;

    const chunkSize = 400;
    for (var i = 0; i < records.length; i += chunkSize) {
      final chunk = records.sublist(
        i,
        i + chunkSize > records.length ? records.length : i + chunkSize,
      );
      final batch = _db.batch();
      for (final r in chunk) {
        batch.set(_col.doc(r.id), _toMap(r), SetOptions(merge: true));
      }
      await batch.commit();
    }
  }
}
