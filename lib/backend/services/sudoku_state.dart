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

  const SudokuState({
    required this.board,
    this.status = GameStatus.idle,
    this.errorMessage,
    this.selectedRow,
    this.selectedCol,
  });

  bool get hasSelection => selectedRow != null && selectedCol != null;
  bool isSelected(int r, int c) => selectedRow == r && selectedCol == c;
  bool get isEditable =>
      status == GameStatus.playing || status == GameStatus.correctingOCR;
  bool get canSolve =>
      (status == GameStatus.playing || status == GameStatus.correctingOCR) &&
      errorMessage == null;
  bool get isScanning => status == GameStatus.scanning;

  SudokuState copyWith({
    SudokuBoard? board,
    GameStatus? status,
    Object? errorMessage = _keep,
    Object? selectedRow = _keep,
    Object? selectedCol = _keep,
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
    );
  }
}

const Object _keep = Object();
