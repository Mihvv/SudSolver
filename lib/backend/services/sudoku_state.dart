import 'package:flutter/foundation.dart';
import '../models/sudoku_board.dart';

enum GameStatus { idle, scanning, correctingOCR, playing, solved, error }

@immutable
class SudokuState {
  final SudokuBoard board;
  final GameStatus status;
  final String? errorMessage;
  final int? selectedRow;
  final int? selectedCol;
  final int hintsUsed;
  final Duration elapsed;
  final Set<(int, int)> invalidCells;
  final String? sessionId;

  const SudokuState({
    required this.board,
    this.status = GameStatus.idle,
    this.errorMessage,
    this.selectedRow,
    this.selectedCol,
    this.hintsUsed = 0,
    this.elapsed = Duration.zero,
    this.invalidCells = const {},
    this.sessionId,
  });

  bool get hasSelection => selectedRow != null && selectedCol != null;
  bool isSelected(int r, int c) => selectedRow == r && selectedCol == c;

  bool get isEditable =>
      status == GameStatus.playing || status == GameStatus.correctingOCR;

  bool get canSolve =>
      (status == GameStatus.playing || status == GameStatus.correctingOCR) &&
      errorMessage == null;

  bool get isScanning => status == GameStatus.scanning;

  bool isCellInvalid(int r, int c) => invalidCells.contains((r, c));

  bool canEditCell(int row, int col) {
    if (status == GameStatus.correctingOCR) return true;
    if (status == GameStatus.playing) return !board.isFixed[row][col];
    return false;
  }

  SudokuState copyWith({
    SudokuBoard? board,
    GameStatus? status,
    Object? errorMessage = _keep,
    Object? selectedRow = _keep,
    Object? selectedCol = _keep,
    int? hintsUsed,
    Duration? elapsed,
    Set<(int, int)>? invalidCells,
    Object? sessionId = _keep,
  }) {
    return SudokuState(
      board: board ?? this.board,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _keep)
          ? this.errorMessage
          : errorMessage as String?,
      selectedRow: identical(selectedRow, _keep)
          ? this.selectedRow
          : selectedRow as int?,
      selectedCol: identical(selectedCol, _keep)
          ? this.selectedCol
          : selectedCol as int?,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsed: elapsed ?? this.elapsed,
      invalidCells: invalidCells ?? this.invalidCells,
      sessionId: identical(sessionId, _keep)
          ? this.sessionId
          : sessionId as String?,
    );
  }
}

const Object _keep = Object();
