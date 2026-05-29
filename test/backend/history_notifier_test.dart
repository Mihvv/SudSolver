import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_record.dart';
import 'package:sudsolver/backend/repositories/sudoku_repository.dart';
import 'package:sudsolver/backend/services/history_notifier.dart';

class FakeRepository implements ISudokuRepository {
  final List<SudokuRecord> _store;
  bool throwOnGetAll = false;

  FakeRepository([List<SudokuRecord>? initial]) : _store = initial ?? [];

  @override
  Future<void> save(SudokuRecord r) async => _store.add(r);
  @override
  Future<List<SudokuRecord>> getAll() async {
    if (throwOnGetAll) throw Exception('db error');
    return List.from(_store);
  }

  @override
  Future<SudokuRecord?> getById(String id) async =>
      _store.where((r) => r.id == id).firstOrNull;
  @override
  Future<void> delete(String id) async => _store.removeWhere((r) => r.id == id);
}

SudokuRecord _record(String id) => SudokuRecord(
  id: id,
  scannedAt: DateTime(2024, 1, 1),
  initialGrid: List.generate(9, (_) => List.filled(9, 0)),
  solveMode: SolveModeRecord.manual,
);

void main() {
  group('HistoryNotifier.loadHistory', () {
    test('sets status to loaded and populates records on success', () async {
      final repo = FakeRepository([_record('1'), _record('2')]);
      final notifier = HistoryNotifier(repo);
      await notifier.loadHistory();
      expect(notifier.state.status, HistoryLoadStatus.loaded);
      expect(notifier.state.records, hasLength(2));
    });

    test('initially has idle status', () {
      final notifier = HistoryNotifier(FakeRepository());
      expect(notifier.state.status, HistoryLoadStatus.idle);
    });

    test('sets status to error and stores message on failure', () async {
      final repo = FakeRepository()..throwOnGetAll = true;
      final notifier = HistoryNotifier(repo);
      await notifier.loadHistory();
      expect(notifier.state.status, HistoryLoadStatus.error);
      expect(notifier.state.errorMessage, isNotNull);
    });
  });

  group('HistoryNotifier.deleteRecord', () {
    test('removes the record from state', () async {
      final repo = FakeRepository([_record('1'), _record('2')]);
      final notifier = HistoryNotifier(repo);
      await notifier.loadHistory();
      await notifier.deleteRecord('1');
      expect(notifier.state.records.any((r) => r.id == '1'), isFalse);
      expect(notifier.state.records, hasLength(1));
    });

    test('also deletes from the repository', () async {
      final repo = FakeRepository([_record('1')]);
      final notifier = HistoryNotifier(repo);
      await notifier.loadHistory();
      await notifier.deleteRecord('1');
      expect(await repo.getAll(), isEmpty);
    });
  });
}
