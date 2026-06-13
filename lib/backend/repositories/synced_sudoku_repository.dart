import '../models/sudoku_record.dart';
import 'sudoku_repository.dart';
import 'firestore_sudoku_repository.dart';

class SyncedSudokuRepository implements ISudokuRepository {
  final ISudokuRepository _local;
  final FirestoreSudokuRepository _remote;

  SyncedSudokuRepository({
    required ISudokuRepository local,
    required FirestoreSudokuRepository remote,
  }) : _local = local,
       _remote = remote;

  @override
  Future<void> save(SudokuRecord record) async {
    await _local.save(record);
    _remote.save(record).catchError((_) {}); // fire-and-forget
  }

  @override
  Future<List<SudokuRecord>> getAll() => _local.getAll();

  @override
  Future<SudokuRecord?> getById(String id) => _local.getById(id);

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    _remote.delete(id).catchError((_) {});
  }

  Future<SyncResult> syncFromCloud() async {
    try {
      final remoteRecords = await _remote.getAll();
      final localRecords = await _local.getAll();

      final localMap = {for (final r in localRecords) r.id: r};
      final remoteMap = {for (final r in remoteRecords) r.id: r};

      int added = 0;
      int updated = 0;

      for (final remote in remoteRecords) {
        final local = localMap[remote.id];
        if (local == null) {
          await _local.save(remote);
          added++;
        } else if (remote.scannedAt.isAfter(local.scannedAt)) {
          await _local.save(remote);
          updated++;
        }
      }

      final onlyLocal = localRecords
          .where((r) => !remoteMap.containsKey(r.id))
          .toList();
      if (onlyLocal.isNotEmpty) {
        await _remote.uploadBatch(onlyLocal);
      }

      return SyncResult(
        added: added,
        updated: updated,
        uploaded: onlyLocal.length,
      );
    } catch (e) {
      return SyncResult.failed(e.toString());
    }
  }
}

class SyncResult {
  final int added;
  final int updated;
  final int uploaded;
  final String? error;

  const SyncResult({
    this.added = 0,
    this.updated = 0,
    this.uploaded = 0,
    this.error,
  });

  const SyncResult.failed(this.error) : added = 0, updated = 0, uploaded = 0;

  bool get isSuccess => error == null;

  @override
  String toString() => isSuccess
      ? 'Sync OK (+$added added, ~$updated updated, ↑$uploaded uploaded)'
      : 'Sync FAIL: $error';
}
