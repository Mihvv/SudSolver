class SudokuBoard {
  List<List<int>> grid;
  List<List<bool>> isFixed;

  SudokuBoard(this.grid, {List<List<bool>>? isFixed})
    : isFixed =
          isFixed ?? List.generate(9, (_) => List.generate(9, (_) => false));

  factory SudokuBoard.empty() {
    return SudokuBoard(List.generate(9, (_) => List.generate(9, (_) => 0)));
  }

  void setCell(int row, int col, int value) {
    if (value >= 0 && value <= 9) {
      grid[row][col] = value;
    }
  }

  void lockCurrentClues() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0) {
          isFixed[r][c] = true;
        }
      }
    }
  }

  SudokuBoard clone() {
    List<List<int>> newGrid = grid.map((row) => List<int>.from(row)).toList();
    List<List<bool>> newIsFixed = isFixed
        .map((row) => List<bool>.from(row))
        .toList();

    return SudokuBoard(newGrid, isFixed: newIsFixed);
  }
}
