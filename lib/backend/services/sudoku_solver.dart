import '../models/sudoku_board.dart';
import 'sudoku_validator.dart';

class SudokuSolver {
  bool solve(SudokuBoard board) {
    final emptyCell = _findEmpty(board);
    if (emptyCell == null) return true;

    final (row, col) = emptyCell;

    for (int num = 1; num <= 9; num++) {
      if (SudokuValidator.isValidMove(board, row, col, num)) {
        board.grid[row][col] = num;

        if (solve(board)) return true;

        board.grid[row][col] = 0;
      }
    }
    return false;
  }

  (int, int)? _findEmpty(SudokuBoard board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board.grid[r][c] == 0) return (r, c);
      }
    }
    return null;
  }
}
