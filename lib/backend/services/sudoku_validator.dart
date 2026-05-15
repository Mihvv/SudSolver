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
      for (int c = 0; c < 9; c++) {
        final val = board.grid[r][c];
        if (val != 0 && !isValidMove(board, r, c, val)) return false;
      }
    }
    return true;
  }
}
