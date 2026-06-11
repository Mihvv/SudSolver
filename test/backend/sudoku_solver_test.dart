import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';
import 'package:sudsolver/backend/logic/sudoku_solver.dart';
import 'package:sudsolver/backend/logic/sudoku_validator.dart';

SudokuBoard _boardFromGrid(List<List<int>> grid) =>
    SudokuBoard(grid, List.generate(9, (_) => List.filled(9, false)));

void main() {
  final solver = SudokuSolver();

  final _puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  group('SudokuSolver.solve', () {
    test('solves a valid puzzle and returns a complete, valid board', () {
      final board = _boardFromGrid(
        _puzzle.map((r) => List<int>.from(r)).toList(),
      );
      final solution = solver.solve(board);
      expect(solution, isNotNull);
      final solvedBoard = _boardFromGrid(solution!);
      expect(SudokuValidator.isBoardComplete(solvedBoard), isTrue);
    });

    test('preserves all originally given (non-zero) digits', () {
      final board = _boardFromGrid(
        _puzzle.map((r) => List<int>.from(r)).toList(),
      );
      final solution = solver.solve(board);
      expect(solution, isNotNull);
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (_puzzle[r][c] != 0) {
            expect(solution![r][c], _puzzle[r][c]);
          }
        }
      }
    });

    test('returns the same grid when board is already complete', () {
      final solvedGrid = [
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
      final board = _boardFromGrid(solvedGrid);
      final solution = solver.solve(board);
      expect(solution, isNotNull);
      expect(solution, solvedGrid);
    });

    test('does not mutate the original board grid', () {
      final original = _puzzle.map((r) => List<int>.from(r)).toList();
      final board = _boardFromGrid(
        _puzzle.map((r) => List<int>.from(r)).toList(),
      );
      solver.solve(board);
      for (int r = 0; r < 9; r++) {
        expect(board.grid[r], original[r]);
      }
    });
  });
}
