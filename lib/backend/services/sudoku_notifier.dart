import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudsolver/backend/services/scanner_service.dart';
import 'package:sudsolver/backend/services/mock_scanner_service.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_record.dart';
import '../repositories/sudoku_repository.dart';
import 'sudoku_state.dart';
import 'sudoku_solver.dart';
import 'sudoku_validator.dart';

final scannerServiceProvider = Provider<IScannerService>(
      (_) => const MockScannerService(),
);

final sudokuProvider = StateNotifierProvider<SudokuNotifier, SudokuState>((
    ref,
    ) {
  return SudokuNotifier(
    ref.read(sudokuRepositoryProvider),
    ref.read(scannerServiceProvider),
  );
});

class SudokuNotifier extends StateNotifier<SudokuState> {
  final SudokuSolver _solver = SudokuSolver();
  final ISudokuRepository _repository;
  final IScannerService _scanner;

  Timer? _timer;

  SudokuNotifier(this._repository, this._scanner)
      : super(SudokuState(board: SudokuBoard.empty()));

  String get _sessionId =>
      state.sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

  void selectCell(int row, int col) {
    if (state.canEditCell(row, col)) {
      state = state.copyWith(selectedRow: row, selectedCol: col);
    }
  }

  void updateSelectedCell(int value) {
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null) return;
    if (!state.canEditCell(r, c)) return;

    final newBoard = state.board.copyWithCell(r, c, value);

    if (SudokuValidator.isBoardComplete(newBoard)) {
      _stopTimer();
      _saveRecord(newBoard, solveMode: SolveModeRecord.manual);
      state = state.copyWith(
        board: newBoard,
        status: GameStatus.solved,
        errorMessage: null,
        invalidCells: {},
      );
      return;
    }

    state = state.copyWith(
      board: newBoard,
      invalidCells: {},
      errorMessage: null,
    );
  }

  void validateBoard() {
    final invalid = SudokuValidator.getInvalidCells(state.board);
    state = state.copyWith(
      invalidCells: invalid,
      errorMessage: invalid.isEmpty
          ? null
          : 'Plansza zawiera błędy w ${invalid.length} komórkach.',
    );
  }

  void confirmScannedBoard() {
    final invalid = SudokuValidator.getInvalidCells(state.board);
    if (invalid.isNotEmpty) {
      state = state.copyWith(
        invalidCells: invalid,
        errorMessage: 'Plansza zawiera błędy — popraw zaznaczone komórki.',
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(
      board: state.board.lock(),
      status: GameStatus.playing,
      errorMessage: null,
      invalidCells: {},
      selectedRow: null,
      selectedCol: null,
      sessionId: id,
    );
    _startTimer();
  }

  void solveBoard() {
    final solution = _solver.solve(state.board);
    if (solution != null) {
      _stopTimer();
      final solvedBoard = SudokuBoard(solution, state.board.isFixed);
      _saveRecord(solvedBoard, solveMode: SolveModeRecord.auto);
      state = state.copyWith(
        board: solvedBoard,
        status: GameStatus.solved,
        errorMessage: null,
        invalidCells: {},
      );
    } else {
      state = state.copyWith(errorMessage: 'Tej planszy nie da się rozwiązać.');
    }
  }

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
            invalidCells: {},
          );
          return;
        }
      }
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
        invalidCells: {},
      );
    } on ScannerException catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Błąd skanowania: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Nieoczekiwany błąd: ${e.toString()}',
      );
    }
  }

  void resumeRecord(SudokuRecord record) {
    final grid = (record.solvedGrid ?? record.initialGrid)
        .map((r) => List<int>.from(r))
        .toList();
    final isFixed = record.initialGrid
        .map((r) => r.map((v) => v != 0).toList())
        .toList();
    final board = SudokuBoard(grid, isFixed);
    state = SudokuState(
      board: board,
      status: GameStatus.playing,
      elapsed: record.solveTime ?? Duration.zero,
      hintsUsed: record.hintsUsed,
      sessionId: record.id,
    );
    _startTimer();
  }

  /// Zapisuje aktualny postęp – wywołaj przed reset() gdy gra w toku.
  void saveCurrentProgress() {
    if (state.status != GameStatus.playing) return;
    _saveRecord(state.board, solveMode: SolveModeRecord.inProgress);
  }

  void reset() {
    _stopTimer();
    state = SudokuState(board: SudokuBoard.empty());
  }

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

  void _saveRecord(
      SudokuBoard solvedBoard, {
        required SolveModeRecord solveMode,
      }) {
    final record = SudokuRecord(
      id: _sessionId,
      scannedAt: DateTime.now(),
      initialGrid: state.board.grid,
      solvedGrid: solvedBoard.grid,
      solveMode: solveMode,
      solveTime: solveMode == SolveModeRecord.manual ? state.elapsed : null,
      hintsUsed: state.hintsUsed,
    );
    _repository.save(record).catchError((_) {});
  }

  @visibleForTesting
  void debugSetState(SudokuState s) => state = s;

  @override
  void dispose() {
    saveCurrentProgress();
    _timer?.cancel();
    super.dispose();
  }
}