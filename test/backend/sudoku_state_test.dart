import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';
import 'package:sudsolver/backend/services/sudoku_state.dart';

void main() {
  group('SudokuState', () {
    late SudokuState base;

    setUp(() {
      base = SudokuState(board: SudokuBoard.empty());
    });

    test('default values are correct', () {
      expect(base.status, GameStatus.idle);
      expect(base.errorMessage, isNull);
      expect(base.selectedRow, isNull);
      expect(base.selectedCol, isNull);
      expect(base.hintsUsed, 0);
      expect(base.elapsed, Duration.zero);
      expect(base.invalidCells, isEmpty);
    });

    test('hasSelection is false when no cell selected', () {
      expect(base.hasSelection, isFalse);
    });

    test('hasSelection is true when both row and col are set', () {
      final state = base.copyWith(selectedRow: 2, selectedCol: 3);
      expect(state.hasSelection, isTrue);
    });

    test('isSelected returns true only for the selected cell', () {
      final state = base.copyWith(selectedRow: 1, selectedCol: 4);
      expect(state.isSelected(1, 4), isTrue);
      expect(state.isSelected(0, 4), isFalse);
      expect(state.isSelected(1, 3), isFalse);
    });

    group('isEditable', () {
      test('is true when status is playing', () {
        expect(base.copyWith(status: GameStatus.playing).isEditable, isTrue);
      });

      test('is true when status is correctingOCR', () {
        expect(
          base.copyWith(status: GameStatus.correctingOCR).isEditable,
          isTrue,
        );
      });

      test('is false when status is idle, solved, scanning, or error', () {
        for (final s in [
          GameStatus.idle,
          GameStatus.solved,
          GameStatus.scanning,
          GameStatus.error,
        ]) {
          expect(base.copyWith(status: s).isEditable, isFalse);
        }
      });
    });

    group('canSolve', () {
      test('is true when playing and no error', () {
        expect(base.copyWith(status: GameStatus.playing).canSolve, isTrue);
      });

      test('is false when playing but errorMessage is set', () {
        final state = base.copyWith(
          status: GameStatus.playing,
          errorMessage: 'oops',
        );
        expect(state.canSolve, isFalse);
      });

      test('is false when status is idle', () {
        expect(base.canSolve, isFalse);
      });
    });

    group('canEditCell', () {
      test('always true during correctingOCR regardless of isFixed', () {
        final grid = List.generate(9, (_) => List.filled(9, 5));
        final isFixed = List.generate(9, (_) => List.filled(9, true));
        final board = SudokuBoard(grid, isFixed);
        final state = SudokuState(
          board: board,
          status: GameStatus.correctingOCR,
        );
        expect(state.canEditCell(0, 0), isTrue);
      });

      test('false during playing for a fixed cell', () {
        final grid = List.generate(9, (_) => List.filled(9, 0));
        final isFixed = List.generate(9, (_) => List.filled(9, false));
        isFixed[0][0] = true;
        final board = SudokuBoard(grid, isFixed);
        final state = SudokuState(board: board, status: GameStatus.playing);
        expect(state.canEditCell(0, 0), isFalse);
      });

      test('true during playing for a non-fixed cell', () {
        final state = base.copyWith(status: GameStatus.playing);
        expect(state.canEditCell(0, 0), isTrue);
      });

      test('false when status is idle', () {
        expect(base.canEditCell(0, 0), isFalse);
      });
    });

    group('isCellInvalid', () {
      test('returns false for all cells when invalidCells is empty', () {
        expect(base.isCellInvalid(0, 0), isFalse);
        expect(base.isCellInvalid(4, 4), isFalse);
      });

      test('returns true for a cell that is in invalidCells', () {
        final state = base.copyWith(invalidCells: {(2, 3), (5, 7)});
        expect(state.isCellInvalid(2, 3), isTrue);
        expect(state.isCellInvalid(5, 7), isTrue);
      });

      test('returns false for a cell that is not in invalidCells', () {
        final state = base.copyWith(invalidCells: {(2, 3)});
        expect(state.isCellInvalid(0, 0), isFalse);
        expect(state.isCellInvalid(2, 4), isFalse);
      });
    });

    group('copyWith', () {
      test('null errorMessage can be explicitly cleared', () {
        final withError = base.copyWith(errorMessage: 'err');
        final cleared = withError.copyWith(errorMessage: null);
        expect(cleared.errorMessage, isNull);
      });

      test('keeps existing errorMessage when not specified', () {
        final withError = base.copyWith(errorMessage: 'err');
        final copy = withError.copyWith(hintsUsed: 1);
        expect(copy.errorMessage, 'err');
      });

      test('null selectedRow and selectedCol can be explicitly cleared', () {
        final withSel = base.copyWith(selectedRow: 3, selectedCol: 4);
        final cleared = withSel.copyWith(selectedRow: null, selectedCol: null);
        expect(cleared.selectedRow, isNull);
        expect(cleared.selectedCol, isNull);
      });

      test('invalidCells can be updated via copyWith', () {
        final state = base.copyWith(invalidCells: {(1, 1)});
        expect(state.isCellInvalid(1, 1), isTrue);
      });

      test('invalidCells can be cleared via copyWith', () {
        final withInvalid = base.copyWith(invalidCells: {(1, 1)});
        final cleared = withInvalid.copyWith(invalidCells: {});
        expect(cleared.invalidCells, isEmpty);
      });

      test('keeps existing invalidCells when not specified', () {
        final withInvalid = base.copyWith(invalidCells: {(3, 3)});
        final copy = withInvalid.copyWith(hintsUsed: 2);
        expect(copy.isCellInvalid(3, 3), isTrue);
      });
    });
  });
}
