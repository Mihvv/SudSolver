class SudokuBoard {
  List<List<int>> grid;

  SudokuBoard(this.grid);

  factory SudokuBoard.empty() {
    return SudokuBoard(List.generate(9, (_) => List.generate(9, (_) => 0)));
  }

  void setCell(int row, int col, int value) {
    if (value >= 0 && value <= 9) {
      grid[row][col] = value;
    }
  }

  SudokuBoard clone() {
    List<List<int>> newGrid = grid.map((row) => List<int>.from(row)).toList();
    return SudokuBoard(newGrid);
  }
}
