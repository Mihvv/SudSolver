import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';
import 'package:sudsolver/backend/services/sudoku_validator.dart';

SudokuBoard _boardFromGrid(List<List<int>> grid) =>
    SudokuBoard(grid, List.generate(9, (_) => List.filled(9, false)));

final _solvedGrid = [
  [5, 3, 4, 6, 7, 8, 9, 1, 2],
  [6, 7, 2, 1, 9, 5, 3, 4, 8],
  [1, 9, 8, 3, 4, 2, 5, 6, 7],
  [8, 5, 9, 7, 6, 1, 4, 2, 3],
  [4, 2, 6, 8, 5, 3, 7, 9, 1],
  [7, 1, 3, 9, 2, 4, 8, 5, 6],
  [9, 6, 1, 5, 3, 7, 2, 8, 4],
  [2, 8, 7, 4, 1, 9, 6, 3, 5],
  [3, 4, 5, 2, 8, 6, 1, 7, 9],
];

void main() {
  group('SudokuValidator.isValidMove', () {
    test('returns true for 0 (erase)', () {
      final board = _boardFromGrid(
        _solvedGrid.map((r) => List<int>.from(r)).toList(),
      );
      expect(SudokuValidator.isValidMove(board, 0, 0, 0), isTrue);
    });

    test('returns true when no conflict exists', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.isValidMove(board, 0, 0, 5), isTrue);
    });

    test('returns false when value conflicts in the same row', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][3] = 5;
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.isValidMove(board, 0, 0, 5), isFalse);
    });

    test('returns false when value conflicts in the same column', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[4][0] = 5;
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.isValidMove(board, 0, 0, 5), isFalse);
    });

    test('returns false when value conflicts in the same 3x3 box', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[1][1] = 5;
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.isValidMove(board, 0, 0, 5), isFalse);
    });

    test('does not count the cell itself as a conflict', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.isValidMove(board, 0, 0, 5), isTrue);
    });
  });

  group('SudokuValidator.isBoardValid', () {
    test('returns true for an empty board', () {
      expect(SudokuValidator.isBoardValid(SudokuBoard.empty()), isTrue);
    });

    test('returns true for a partially filled valid board', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[0][1] = 3;
      expect(SudokuValidator.isBoardValid(_boardFromGrid(grid)), isTrue);
    });

    test('returns false when a row has duplicates', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[0][1] = 5;
      expect(SudokuValidator.isBoardValid(_boardFromGrid(grid)), isFalse);
    });

    test('returns false when a column has duplicates', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[1][0] = 5;
      expect(SudokuValidator.isBoardValid(_boardFromGrid(grid)), isFalse);
    });

    test('returns false when a 3x3 box has duplicates', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[2][2] = 5;
      expect(SudokuValidator.isBoardValid(_boardFromGrid(grid)), isFalse);
    });
  });

  group('SudokuValidator.isBoardComplete', () {
    test('returns true for a fully solved valid board', () {
      expect(
        SudokuValidator.isBoardComplete(_boardFromGrid(_solvedGrid)),
        isTrue,
      );
    });

    test('returns false when board has empty cells', () {
      final grid = _solvedGrid.map((r) => List<int>.from(r)).toList();
      grid[0][0] = 0;
      expect(SudokuValidator.isBoardComplete(_boardFromGrid(grid)), isFalse);
    });

    test('returns false for a fully filled but invalid board', () {
      final grid = _solvedGrid.map((r) => List<int>.from(r)).toList();
      final tmp = grid[0][0];
      grid[0][0] = grid[0][1];
      grid[0][1] = tmp;
      expect(SudokuValidator.isBoardComplete(_boardFromGrid(grid)), isFalse);
    });
  });
}
