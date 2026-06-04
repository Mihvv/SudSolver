import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sudoku_record.dart';

// Provider
final sudokuRepositoryProvider = Provider<ISudokuRepository>(
  (ref) => HiveSudokuRepository(),
);

// Interfejs
abstract class ISudokuRepository {
  Future<void> save(SudokuRecord record);
  Future<List<SudokuRecord>> getAll();
  Future<SudokuRecord?> getById(String id);
  Future<void> delete(String id);
}

// Implementacja Hive
class HiveSudokuRepository implements ISudokuRepository {
  static const _boxName = 'sudoku_records';
  static Future<Box<SudokuRecord>>? _openFuture;
  Future<void> _writeLock = Future.value();

  Future<Box<SudokuRecord>> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<SudokuRecord>(_boxName);
    }
    _openFuture ??= Hive.openBox<SudokuRecord>(_boxName).whenComplete(() {
      _openFuture = null;
    });
    return _openFuture!;
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final next = _writeLock.then((_) => action());
    _writeLock = next.then((_) {}, onError: (_) {});
    return next;
  }

  @override
  Future<void> save(SudokuRecord record) => _synchronized(() async {
    final box = await _box;
    await box.put(record.id, record);
  });

  @override
  Future<List<SudokuRecord>> getAll() async {
    final box = await _box;
    final records = box.values.toList();
    records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return records;
  }

  @override
  Future<SudokuRecord?> getById(String id) async {
    final box = await _box;
    return box.get(id);
  }

  @override
  Future<void> delete(String id) => _synchronized(() async {
    final box = await _box;
    await box.delete(id);
  });
}
