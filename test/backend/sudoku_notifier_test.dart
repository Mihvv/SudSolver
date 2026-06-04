import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';
import 'package:sudsolver/backend/models/sudoku_record.dart';
import 'package:sudsolver/backend/repositories/sudoku_repository.dart';
import 'package:sudsolver/backend/services/sudoku_notifier.dart';
import 'package:sudsolver/backend/services/sudoku_state.dart';

class FakeRepository implements ISudokuRepository {
  final List<SudokuRecord> saved = [];

  @override
  Future<void> save(SudokuRecord r) async => saved.add(r);
  @override
  Future<List<SudokuRecord>> getAll() async => List.from(saved);
  @override
  Future<SudokuRecord?> getById(String id) async =>
      saved.where((r) => r.id == id).firstOrNull;
  @override
  Future<void> delete(String id) async => saved.removeWhere((r) => r.id == id);
}

SudokuNotifier _makeNotifier(FakeRepository repo) => SudokuNotifier(repo);

// A valid puzzle from MockScannerService
final _puzzle = [
  [5, 3, 0, 0, 7, 0, 0, 0, 0],
  [6, 0, 0, 1, 9, 5, 0, 0, 0],
  [0, 9, 8, 0, 0, 0, 0, 6, 0],
  [8, 0, 0, 0, 6, 0, 0, 0, 3],
  [4, 0, 0, 8, 0, 3, 0, 0, 1],
  [7, 0, 0, 0, 2, 0, 0, 0, 6],
  [0, 6, 0, 0, 0, 0, 2, 8, 0],
  [0, 0, 0, 4, 1, 9, 0, 0, 5],
  [0, 0, 0, 0, 8, 0, 0, 7, 9],
];

SudokuNotifier _notifierWithPuzzlePlaying(FakeRepository repo) {
  final notifier = _makeNotifier(repo);
  final board = SudokuBoard(
    _puzzle.map((r) => List<int>.from(r)).toList(),
    List.generate(9, (_) => List.filled(9, false)),
  ).lock();
  notifier.debugSetState(SudokuState(board: board, status: GameStatus.playing));
  return notifier;
}

void main() {
  group('SudokuNotifier.selectCell', () {
    test('selects an editable cell during playing', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.selectCell(0, 2);
      expect(n.state.selectedRow, 0);
      expect(n.state.selectedCol, 2);
    });

    test('does not select a fixed cell during playing', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.selectCell(0, 0);
      expect(n.state.selectedRow, isNull);
    });
  });

  group('SudokuNotifier.updateSelectedCell', () {
    test('writes a valid value to a selected cell', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.selectCell(0, 2);
      n.updateSelectedCell(4);
      expect(n.state.board.grid[0][2], 4);
      expect(n.state.errorMessage, isNull);
    });

    test('does not set errorMessage for a conflicting value', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.selectCell(0, 2);
      n.updateSelectedCell(5);
      expect(n.state.errorMessage, isNull);
    });

    test('clears invalidCells after editing a cell', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.debugSetState(n.state.copyWith(invalidCells: {(0, 2), (0, 0)}));
      n.selectCell(0, 2);
      n.updateSelectedCell(4);
      expect(n.state.invalidCells, isEmpty);
    });

    test('does nothing when no cell is selected', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      final before = n.state.board.grid[0][2];
      n.updateSelectedCell(4);
      expect(n.state.board.grid[0][2], before);
    });
  });

  group('SudokuNotifier.validateBoard', () {
    test('sets invalidCells and errorMessage when board has conflicts', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.selectCell(0, 2);
      n.updateSelectedCell(5);
      n.validateBoard();
      expect(n.state.invalidCells, isNotEmpty);
      expect(n.state.errorMessage, isNotNull);
    });

    test(
      'clears invalidCells and errorMessage when board has no conflicts',
      () {
        final repo = FakeRepository();
        final n = _notifierWithPuzzlePlaying(repo);
        n.selectCell(0, 2);
        n.updateSelectedCell(4);
        n.validateBoard();
        expect(n.state.invalidCells, isEmpty);
        expect(n.state.errorMessage, isNull);
      },
    );

    test('marks conflicting cells in both directions', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.selectCell(0, 2);
      n.updateSelectedCell(5);
      n.validateBoard();
      expect(n.state.invalidCells.contains((0, 0)), isTrue);
      expect(n.state.invalidCells.contains((0, 2)), isTrue);
    });

    test('does nothing harmful on an empty board', () {
      final repo = FakeRepository();
      final n = _makeNotifier(repo);
      n.validateBoard();
      expect(n.state.invalidCells, isEmpty);
      expect(n.state.errorMessage, isNull);
    });
  });

  group('SudokuNotifier.confirmScannedBoard', () {
    test('transitions to playing status on a valid board', () {
      final repo = FakeRepository();
      final n = _makeNotifier(repo);
      final board = SudokuBoard(
        _puzzle.map((r) => List<int>.from(r)).toList(),
        List.generate(9, (_) => List.filled(9, false)),
      );
      n.debugSetState(
        SudokuState(board: board, status: GameStatus.correctingOCR),
      );
      n.confirmScannedBoard();
      expect(n.state.status, GameStatus.playing);
      expect(n.state.errorMessage, isNull);
      expect(n.state.invalidCells, isEmpty);
    });

    test('sets errorMessage and invalidCells when board has conflicts', () {
      final repo = FakeRepository();
      final n = _makeNotifier(repo);
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[0][1] = 5; // row conflict
      final board = SudokuBoard(
        grid,
        List.generate(9, (_) => List.filled(9, false)),
      );
      n.debugSetState(
        SudokuState(board: board, status: GameStatus.correctingOCR),
      );
      n.confirmScannedBoard();
      expect(n.state.status, GameStatus.correctingOCR);
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.invalidCells, containsAll([(0, 0), (0, 1)]));
    });
  });

  group('SudokuNotifier.solveBoard', () {
    test('solves a valid puzzle and transitions to solved', () async {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.solveBoard();
      expect(n.state.status, GameStatus.solved);
      expect(n.state.errorMessage, isNull);
      expect(n.state.invalidCells, isEmpty);
    });

    test('saves a record with auto solve mode', () async {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.solveBoard();
      await Future.microtask(() {}); // let async save complete
      expect(repo.saved, hasLength(1));
      expect(repo.saved.first.solveMode, SolveModeRecord.auto);
    });
  });

  group('SudokuNotifier.giveHint', () {
    test('fills in one empty cell', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      final emptyBefore = n.state.board.grid
          .expand((r) => r)
          .where((v) => v == 0)
          .length;
      n.giveHint();
      final emptyAfter = n.state.board.grid
          .expand((r) => r)
          .where((v) => v == 0)
          .length;
      expect(emptyAfter, emptyBefore - 1);
    });

    test('increments hintsUsed', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.giveHint();
      expect(n.state.hintsUsed, 1);
    });

    test('clears invalidCells after giving a hint', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.debugSetState(n.state.copyWith(invalidCells: {(1, 1)}));
      n.giveHint();
      expect(n.state.invalidCells, isEmpty);
    });

    test('does nothing when canSolve is false', () {
      final repo = FakeRepository();
      final n = _makeNotifier(repo);
      n.giveHint();
      expect(n.state.hintsUsed, 0);
    });
  });

  group('SudokuNotifier.reset', () {
    test('resets state to empty board with idle status', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.reset();
      expect(n.state.status, GameStatus.idle);
      expect(n.state.board.grid.expand((r) => r).every((v) => v == 0), isTrue);
    });

    test('clears invalidCells on reset', () {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.debugSetState(n.state.copyWith(invalidCells: {(0, 0), (0, 1)}));
      n.reset();
      expect(n.state.invalidCells, isEmpty);
    });
  });
}
