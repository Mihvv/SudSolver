import '../models/sudoku_board.dart';

class SudokuValidator {
  static bool isValidMove(SudokuBoard board, int row, int col, int val) {
    if (val == 0) return true;

    for (int i = 0; i < 9; i++) {
      if (i != col && board.grid[row][i] == val) return false;
      if (i != row && board.grid[i][col] == val) return false;
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if ((r != row || c != col) && board.grid[r][c] == val) return false;
      }
    }
    return true;
  }

  static bool isBoardValid(SudokuBoard board) {
    for (int r = 0; r < 9; r++) {
      if (!_isUniqueNonZero(board.grid[r])) return false;
    }

    for (int c = 0; c < 9; c++) {
      final col = List.generate(9, (r) => board.grid[r][c]);
      if (!_isUniqueNonZero(col)) return false;
    }

    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        final box = <int>[];
        for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
          for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
            box.add(board.grid[r][c]);
          }
        }
        if (!_isUniqueNonZero(box)) return false;
      }
    }

    return true;
  }

  static bool isBoardComplete(SudokuBoard board) {
    final hasBlanks = board.grid.any((row) => row.any((val) => val == 0));
    if (hasBlanks) return false;
    return isBoardValid(board);
  }

  static bool _isUniqueNonZero(List<int> values) {
    final seen = <int>{};
    for (final val in values) {
      if (val != 0 && !seen.add(val)) return false;
    }
    return true;
  }
}
