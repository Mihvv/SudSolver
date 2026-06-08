import '../models/sudoku_board.dart';
import 'sudoku_validator.dart';

class SudokuSolver {
  List<List<int>>? solve(SudokuBoard board) {
    final grid = board.grid.map((r) => List<int>.from(r)).toList();
    return _solve(grid) ? grid : null;
  }

  bool _solve(List<List<int>> grid) {
    final emptyCell = _findEmpty(grid);
    if (emptyCell == null) return true;

    final (row, col) = emptyCell;

    for (int num = 1; num <= 9; num++) {
      if (_isValidInGrid(grid, row, col, num)) {
        grid[row][col] = num;
        if (_solve(grid)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  (int, int)? _findEmpty(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return (r, c);
      }
    }
    return null;
  }

  bool _isValidInGrid(List<List<int>> grid, int row, int col, int val) {
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == val) return false;
      if (grid[i][col] == val) return false;
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (grid[r][c] == val) return false;
      }
    }
    return true;
  }
}
