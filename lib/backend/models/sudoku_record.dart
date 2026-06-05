import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'sudoku_record.g.dart';

enum SolveModeRecord { manual, auto, unsolved, inProgress }

@HiveType(typeId: 0)
@immutable
class SudokuRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime scannedAt;

  @HiveField(2)
  final List<List<int>> initialGrid;

  @HiveField(3)
  final List<List<int>>? solvedGrid;

  @HiveField(4)
  final SolveModeRecord solveMode;

  @HiveField(5)
  final Duration? solveTime;

  @HiveField(6)
  final int hintsUsed;

  const SudokuRecord({
    required this.id,
    required this.scannedAt,
    required this.initialGrid,
    this.solvedGrid,
    required this.solveMode,
    this.solveTime,
    this.hintsUsed = 0,
  });
}
