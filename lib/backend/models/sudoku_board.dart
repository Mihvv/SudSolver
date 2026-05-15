import 'package:flutter/foundation.dart';

@immutable
class SudokuBoard {
  final List<List<int>> grid;
  final List<List<bool>> isFixed;

  const SudokuBoard(this.grid, this.isFixed);

  factory SudokuBoard.empty() => SudokuBoard(
    List.generate(9, (_) => List.filled(9, 0)),
    List.generate(9, (_) => List.filled(9, false)),
  );

  SudokuBoard copyWithCell(int row, int col, int value) {
    final newGrid = grid.map((r) => List<int>.from(r)).toList();
    newGrid[row][col] = value;
    return SudokuBoard(newGrid, isFixed);
  }

  SudokuBoard lock() {
    final newIsFixed = grid
        .map((row) => row.map((val) => val != 0).toList())
        .toList();
    return SudokuBoard(grid, newIsFixed);
  }
}
