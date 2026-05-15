import '../models/sudoku_board.dart';

class SudokuValidator {
  bool isValidMove(SudokuBoard board, int row, int col, int value) {
    if (value == 0) return true;

    for (int c = 0; c < 9; c++) {
      if (c != col && board.grid[row][c] == value) return false;
    }

    for (int r = 0; r < 9; r++) {
      if (r != row && board.grid[r][col] == value) return false;
    }

    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if ((r != row || c != col) && board.grid[r][c] == value) return false;
      }
    }

    return true;
  }
}
