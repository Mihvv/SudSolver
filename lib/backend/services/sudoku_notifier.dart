import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudsolver/backend/services/scanner_service.dart';
import '../models/sudoku_board.dart';
import 'sudoku_state.dart';
import 'sudoku_solver.dart';
import 'sudoku_validator.dart';

final sudokuProvider = StateNotifierProvider<SudokuNotifier, SudokuState>((
  ref,
) {
  return SudokuNotifier();
});

class SudokuNotifier extends StateNotifier<SudokuState> {
  final _solver = SudokuSolver();
  final _scanner = MockScannerService();

  SudokuNotifier() : super(SudokuState(board: SudokuBoard.empty()));

  void selectCell(int row, int col) {
    final canEdit =
        state.status == GameStatus.correctingOCR ||
        (state.status == GameStatus.playing && !state.board.isFixed[row][col]);

    if (canEdit) {
      state = state.copyWith(selectedRow: row, selectedCol: col);
    }
  }

  void updateSelectedCell(int value) {
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null) return;

    final newBoard = state.board.copyWithCell(r, c, value);

    String? error;
    if (state.status == GameStatus.playing && value != 0) {
      if (!SudokuValidator.isValidMove(state.board, r, c, value)) {
        error = 'Cyfra $value narusza zasady Sudoku!';
      }
    }

    state = state.copyWith(board: newBoard, errorMessage: error);
  }

  void confirmScannedBoard() {
    if (SudokuValidator.isBoardValid(state.board)) {
      state = state.copyWith(
        board: state.board.lock(),
        status: GameStatus.playing,
        errorMessage: null,
        selectedRow: null,
        selectedCol: null,
      );
    } else {
      state = state.copyWith(errorMessage: 'Plansza zawiera błędy!');
    }
  }

  void solveBoard() {
    final gridCopy = state.board.grid.map((r) => List<int>.from(r)).toList();
    final boardCopy = SudokuBoard(gridCopy, state.board.isFixed);

    if (_solver.solve(boardCopy)) {
      state = state.copyWith(
        board: boardCopy,
        status: GameStatus.solved,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(errorMessage: 'Tej planszy nie da się rozwiązać.');
    }
  }

  Future<void> scanBoard(String imagePath) async {
    state = state.copyWith(status: GameStatus.scanning, errorMessage: null);
    try {
      final scannedGrid = await _scanner.scanImage(imagePath);
      state = state.copyWith(
        board: SudokuBoard(
          scannedGrid,
          List.generate(9, (_) => List.filled(9, false)),
        ),
        status: GameStatus.correctingOCR,
      );
    } catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Błąd skanowania: ${e.toString()}',
      );
    }
  }

  void reset() {
    state = SudokuState(board: SudokuBoard.empty());
  }
}
