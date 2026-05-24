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

  Future<Box<SudokuRecord>> get _box async => Hive.isBoxOpen(_boxName)
      ? Hive.box<SudokuRecord>(_boxName)
      : await Hive.openBox<SudokuRecord>(_boxName);

  @override
  Future<void> save(SudokuRecord record) async {
    final box = await _box;
    await box.put(record.id, record);
  }

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
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
