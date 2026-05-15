import '../models/sudoku_board.dart';
import 'sudoku_validator.dart';

class SudokuSolver {
  final SudokuValidator _validator;

  SudokuSolver(this._validator);

  bool solve(SudokuBoard board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board.grid[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (_validator.isValidMove(board, row, col, num)) {
              board.grid[row][col] = num;

              if (solve(board)) {
                return true;
              } else {
                board.grid[row][col] = 0;
              }
            }
          }
          return false;
        }
      }
    }
    return true;
  }
}
