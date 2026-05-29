import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';

void main() {
  group('SudokuBoard', () {
    test('empty() creates 9x9 grid of zeros with no fixed cells', () {
      final board = SudokuBoard.empty();
      expect(board.grid.length, 9);
      for (final row in board.grid) {
        expect(row.length, 9);
        expect(row.every((v) => v == 0), isTrue);
      }
      for (final row in board.isFixed) {
        expect(row.every((v) => v == false), isTrue);
      }
    });

    test(
      'copyWithCell() updates the correct cell without mutating original',
      () {
        final board = SudokuBoard.empty();
        final updated = board.copyWithCell(0, 0, 5);
        expect(updated.grid[0][0], 5);
        expect(board.grid[0][0], 0);
      },
    );

    test('lock() marks non-zero cells as fixed', () {
      final grid = List.generate(
        9,
        (r) => List.generate(9, (c) => (r == 0 && c == 0) ? 5 : 0),
      );
      final board = SudokuBoard(
        grid,
        List.generate(9, (_) => List.filled(9, false)),
      );
      final locked = board.lock();
      expect(locked.isFixed[0][0], isTrue);
      expect(locked.isFixed[0][1], isFalse);
    });

    test('lock() does not mark zero cells as fixed', () {
      final board = SudokuBoard.empty();
      final locked = board.lock();
      for (final row in locked.isFixed) {
        expect(row.every((v) => v == false), isTrue);
      }
    });
  });
}
