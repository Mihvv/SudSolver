import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudsolver/backend/services/scanner_service.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_record.dart';
import '../repositories/sudoku_repository.dart';
import 'sudoku_state.dart';
import 'sudoku_solver.dart';
import 'sudoku_validator.dart';

final sudokuProvider = StateNotifierProvider<SudokuNotifier, SudokuState>((
  ref,
) {
  return SudokuNotifier(ref.read(sudokuRepositoryProvider));
});

class SudokuNotifier extends StateNotifier<SudokuState> {
  final SudokuSolver _solver = SudokuSolver();
  final ISudokuRepository _repository;
  final MockScannerService _scanner = MockScannerService();

  Timer? _timer;

  SudokuNotifier(this._repository)
    : super(SudokuState(board: SudokuBoard.empty()));

  //Selekcja komórki
  void selectCell(int row, int col) {
    if (state.canEditCell(row, col)) {
      state = state.copyWith(selectedRow: row, selectedCol: col);
    }
  }

  // Wpisywanie cyfry
  void updateSelectedCell(int value) {
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null) return;
    if (!state.canEditCell(r, c)) return;

    final newBoard = state.board.copyWithCell(r, c, value);

    String? error;
    if (state.status == GameStatus.playing && value != 0) {
      if (!SudokuValidator.isValidMove(state.board, r, c, value)) {
        error = 'Cyfra $value narusza zasady Sudoku!';
      }
    }

    // Detekcja ukończenia manualnego
    if (error == null && SudokuValidator.isBoardComplete(newBoard)) {
      _stopTimer();
      _saveRecord(newBoard, solvedManually: true);
      state = state.copyWith(
        board: newBoard,
        status: GameStatus.solved,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(board: newBoard, errorMessage: error);
  }

  // Potwierdzenie planszy po OCR
  void confirmScannedBoard() {
    if (SudokuValidator.isBoardValid(state.board)) {
      state = state.copyWith(
        board: state.board.lock(),
        status: GameStatus.playing,
        errorMessage: null,
        selectedRow: null,
        selectedCol: null,
      );
      _startTimer();
    } else {
      state = state.copyWith(errorMessage: 'Plansza zawiera błędy!');
    }
  }

  // Auto-rozwiązywanie
  void solveBoard() {
    final solution = _solver.solve(state.board);
    if (solution != null) {
      _stopTimer();
      final solvedBoard = SudokuBoard(solution, state.board.isFixed);
      _saveRecord(solvedBoard, solvedManually: false);
      state = state.copyWith(
        board: solvedBoard,
        status: GameStatus.solved,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(errorMessage: 'Tej planszy nie da się rozwiązać.');
    }
  }

  // Podpowiedź
  void giveHint() {
    if (!state.canSolve) return;

    final solution = _solver.solve(state.board);
    if (solution == null) {
      state = state.copyWith(errorMessage: 'Brak rozwiązania dla tej planszy.');
      return;
    }

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (state.board.grid[r][c] == 0) {
          final hintBoard = state.board.copyWithCell(r, c, solution[r][c]);
          state = state.copyWith(
            board: hintBoard,
            hintsUsed: state.hintsUsed + 1,
            errorMessage: null,
          );
          return;
        }
      }
    }
  }

  // Skanowanie
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

  // Reset
  void reset() {
    _stopTimer();
    state = SudokuState(board: SudokuBoard.empty());
  }

  // Timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Zapis do archiwum
  Future<void> _saveRecord(
    SudokuBoard solvedBoard, {
    required bool solvedManually,
  }) async {
    final record = SudokuRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scannedAt: DateTime.now(),
      initialGrid: state.board.grid,
      solvedGrid: solvedBoard.grid,
      solveMode: solvedManually ? SolveModeRecord.manual : SolveModeRecord.auto,
      solveTime: solvedManually ? state.elapsed : null,
      hintsUsed: state.hintsUsed,
    );
    await _repository.save(record);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
