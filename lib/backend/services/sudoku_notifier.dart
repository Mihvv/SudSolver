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
  final _solver = SudokuSolver(SudokuValidator());
  final _validator = SudokuValidator();
  final _scanner = MockScannerService();

  SudokuNotifier() : super(SudokuState(board: SudokuBoard.empty()));

  // ---------------------------------------------------------------------------
  // Selecting Cell
  // ---------------------------------------------------------------------------

  void selectCell(int row, int col) {
    final isEditable =
        state.status == GameStatus.correctingOCR ||
        (state.status == GameStatus.playing && !state.board.isFixed[row][col]);

    if (!isEditable) return;

    state = state.copyWith(selectedRow: row, selectedCol: col);
  }

  // ---------------------------------------------------------------------------
  // Correcting OCR
  // ---------------------------------------------------------------------------

  void updateDraftCell(int row, int col, int value) {
    if (state.status != GameStatus.correctingOCR) return;

    final newBoard = state.board.clone();
    newBoard.setCell(row, col, value);
    state = state.copyWith(board: newBoard, errorMessage: null);
  }

  void updateSelectedDraftCell(int value) {
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (row == null || col == null) return;
    updateDraftCell(row, col, value);
  }

  void confirmScannedBoard() {
    if (_validator.isValidBoard(state.board)) {
      final newBoard = state.board.clone();
      newBoard.lockCurrentClues();
      state = state.copyWith(
        board: newBoard,
        status: GameStatus.playing,
        errorMessage: null,
        selectedRow: null,
        selectedCol: null,
      );
    } else {
      state = state.copyWith(
        errorMessage: 'Plansza zawiera błędy i narusza zasady Sudoku!',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Manual mode
  // ---------------------------------------------------------------------------

  void playCell(int row, int col, int value) {
    if (state.status != GameStatus.playing) return;
    if (state.board.isFixed[row][col]) return;

    final newBoard = state.board.clone();
    newBoard.setCell(row, col, value);

    final isValid =
        value == 0 || _validator.isValidMove(newBoard, row, col, value);

    state = state.copyWith(
      board: newBoard,
      errorMessage: isValid ? null : 'Cyfra $value narusza zasady Sudoku!',
    );
  }

  void playSelectedCell(int value) {
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (row == null || col == null) return;
    playCell(row, col, value);
  }

  // ---------------------------------------------------------------------------
  // Solver
  // ---------------------------------------------------------------------------

  void solveBoard() {
    final newBoard = state.board.clone();
    if (_solver.solve(newBoard)) {
      state = state.copyWith(
        board: newBoard,
        status: GameStatus.solved,
        errorMessage: null,
        selectedRow: null,
        selectedCol: null,
      );
    } else {
      state = state.copyWith(errorMessage: 'Tej planszy nie da się rozwiązać.');
    }
  }

  // ---------------------------------------------------------------------------
  // Scanning board
  // ---------------------------------------------------------------------------

  Future<void> scanBoard(String imagePath) async {
    state = state.copyWith(status: GameStatus.scanning);
    try {
      final scannedGrid = await _scanner.scanImage(imagePath);
      state = state.copyWith(
        board: SudokuBoard(scannedGrid),
        status: GameStatus.correctingOCR,
        errorMessage: null,
        selectedRow: null,
        selectedCol: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Błąd podczas skanowania: ${e.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void reset() {
    state = SudokuState(board: SudokuBoard.empty());
  }
}
