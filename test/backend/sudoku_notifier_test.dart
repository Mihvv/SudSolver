import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';
import 'package:sudsolver/backend/models/sudoku_record.dart';
import 'package:sudsolver/backend/repositories/sudoku_repository.dart';
import 'package:sudsolver/backend/services/scanner/scanner_service.dart';
import 'package:sudsolver/backend/services/auth/auth_service.dart';
import 'package:sudsolver/backend/models/app_user.dart';
import 'package:sudsolver/backend/providers/sudoku_notifier.dart';
import 'package:sudsolver/backend/providers/sudoku_state.dart';
import 'package:sudsolver/backend/providers/auth_notifier.dart';

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

class FakeScanner implements IScannerService {
  List<List<int>>? result;
  bool shouldThrow = false;

  @override
  Future<List<List<int>>> scanImage(String imagePath) async {
    if (shouldThrow) throw ScannerException('scan failed');
    return result ?? List.generate(9, (_) => List.filled(9, 0));
  }
}

class FakeAuthService implements IAuthService {
  AppUser? user;

  FakeAuthService({this.user});

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  AppUser? get currentUser => user;

  @override
  Future<AppUser?> signInWithGoogle() async => user;

  @override
  Future<void> signOut() async => user = null;
}

SudokuNotifier _makeNotifier(
  FakeRepository repo, {
  IScannerService? scanner,
  AppUser? authUser,
}) {
  final container = ProviderContainer(
    overrides: [
      sudokuRepositoryProvider.overrideWithValue(repo),
      scannerServiceProvider.overrideWithValue(scanner ?? FakeScanner()),
      authServiceProvider.overrideWithValue(FakeAuthService(user: authUser)),
    ],
  );
  return container.read(sudokuProvider.notifier);
}

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

SudokuNotifier _notifierWithPuzzlePlaying(
  FakeRepository repo, {
  AppUser? authUser,
}) {
  final notifier = _makeNotifier(repo, authUser: authUser);
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
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.selectCell(0, 2);
      expect(n.state.selectedRow, 0);
      expect(n.state.selectedCol, 2);
    });

    test('does not select a fixed cell during playing', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.selectCell(0, 0);
      expect(n.state.selectedRow, isNull);
    });
  });

  group('SudokuNotifier.updateSelectedCell', () {
    test('writes a valid value to a selected cell', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.selectCell(0, 2);
      n.updateSelectedCell(4);
      expect(n.state.board.grid[0][2], 4);
      expect(n.state.errorMessage, isNull);
    });

    test('does not set errorMessage for a conflicting value', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.selectCell(0, 2);
      n.updateSelectedCell(5); // 5 already in row 0
      expect(n.state.errorMessage, isNull);
    });

    test('clears invalidCells after editing a cell', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.debugSetState(n.state.copyWith(invalidCells: {(0, 2), (0, 0)}));
      n.selectCell(0, 2);
      n.updateSelectedCell(4);
      expect(n.state.invalidCells, isEmpty);
    });

    test('does nothing when no cell is selected', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      final before = n.state.board.grid[0][2];
      n.updateSelectedCell(4);
      expect(n.state.board.grid[0][2], before);
    });
  });

  group('SudokuNotifier.validateBoard', () {
    test('sets invalidCells and errorMessage when board has conflicts', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.selectCell(0, 2);
      n.updateSelectedCell(5); // conflicts with fixed 5 at (0,0)
      n.validateBoard();
      expect(n.state.invalidCells, isNotEmpty);
      expect(n.state.errorMessage, isNotNull);
    });

    test(
      'clears invalidCells and errorMessage when board has no conflicts',
      () {
        final n = _notifierWithPuzzlePlaying(FakeRepository());
        n.selectCell(0, 2);
        n.updateSelectedCell(4);
        n.validateBoard();
        expect(n.state.invalidCells, isEmpty);
        expect(n.state.errorMessage, isNull);
      },
    );

    test('marks only user-entered conflicting cells during playing', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.selectCell(0, 2);
      n.updateSelectedCell(5);
      n.validateBoard();
      expect(n.state.invalidCells.contains((0, 0)), isFalse);
      expect(n.state.invalidCells.contains((0, 2)), isTrue);
    });

    test('marks all conflicting cells during correctingOCR', () {
      final n = _makeNotifier(FakeRepository());
      final grid = _puzzle.map((r) => List<int>.from(r)).toList();
      grid[0][2] = 5;
      n.debugSetState(
        SudokuState(
          board: SudokuBoard(
            grid,
            List.generate(9, (_) => List.filled(9, false)),
          ),
          status: GameStatus.correctingOCR,
        ),
      );
      n.validateBoard();
      expect(n.state.invalidCells.contains((0, 0)), isTrue);
      expect(n.state.invalidCells.contains((0, 2)), isTrue);
    });

    test('does nothing harmful on an empty board', () {
      final n = _makeNotifier(FakeRepository());
      n.validateBoard();
      expect(n.state.invalidCells, isEmpty);
      expect(n.state.errorMessage, isNull);
    });
  });

  group('SudokuNotifier.confirmScannedBoard', () {
    test('transitions to playing on a valid board', () {
      final n = _makeNotifier(FakeRepository());
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

    test('sets errorMessage and invalidCells on conflict', () {
      final n = _makeNotifier(FakeRepository());
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[0][1] = 5;
      n.debugSetState(
        SudokuState(
          board: SudokuBoard(
            grid,
            List.generate(9, (_) => List.filled(9, false)),
          ),
          status: GameStatus.correctingOCR,
        ),
      );
      n.confirmScannedBoard();
      expect(n.state.status, GameStatus.correctingOCR);
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.invalidCells, containsAll([(0, 0), (0, 1)]));
    });
  });

  group('SudokuNotifier.scanBoard', () {
    test('populates board and sets correctingOCR on success', () async {
      final scanner = FakeScanner()..result = _puzzle;
      final n = _makeNotifier(FakeRepository(), scanner: scanner);
      await n.scanBoard('fake/path.jpg');
      expect(n.state.status, GameStatus.correctingOCR);
      expect(n.state.board.grid, _puzzle);
      expect(n.state.invalidCells, isEmpty);
    });

    test('sets error status on ScannerException', () async {
      final scanner = FakeScanner()..shouldThrow = true;
      final n = _makeNotifier(FakeRepository(), scanner: scanner);
      await n.scanBoard('fake/path.jpg');
      expect(n.state.status, GameStatus.error);
      expect(n.state.errorMessage, contains('scan failed'));
    });
  });

  group('SudokuNotifier.solveBoard', () {
    test('solves a valid puzzle and transitions to solved', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.solveBoard();
      expect(n.state.status, GameStatus.solved);
      expect(n.state.errorMessage, isNull);
      expect(n.state.invalidCells, isEmpty);
    });

    test('saves a record with auto solve mode', () async {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.solveBoard();
      await Future.microtask(() {});
      expect(repo.saved, hasLength(1));
      expect(repo.saved.first.solveMode, SolveModeRecord.auto);
    });

    test('saved record has null userId when not logged in', () async {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.solveBoard();
      await Future.microtask(() {});
      expect(repo.saved.first.userId, isNull);
    });

    test('saved record has correct userId when logged in', () async {
      final repo = FakeRepository();
      const user = AppUser(uid: 'test-uid', displayName: 'Test');
      final n = _notifierWithPuzzlePlaying(repo, authUser: user);
      n.solveBoard();
      await Future.microtask(() {});
      expect(repo.saved.first.userId, 'test-uid');
    });
  });

  group('SudokuNotifier.giveHint', () {
    test('fills in one empty cell', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
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
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.giveHint();
      expect(n.state.hintsUsed, 1);
    });

    test('clears invalidCells after giving a hint', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.debugSetState(n.state.copyWith(invalidCells: {(1, 1)}));
      n.giveHint();
      expect(n.state.invalidCells, isEmpty);
    });

    test('does nothing when canSolve is false', () {
      final n = _makeNotifier(FakeRepository());
      n.giveHint();
      expect(n.state.hintsUsed, 0);
    });
  });

  group('SudokuNotifier.reset', () {
    test('resets to empty board with idle status', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.reset();
      expect(n.state.status, GameStatus.idle);
      expect(n.state.board.grid.expand((r) => r).every((v) => v == 0), isTrue);
    });

    test('clears invalidCells on reset', () {
      final n = _notifierWithPuzzlePlaying(FakeRepository());
      n.debugSetState(n.state.copyWith(invalidCells: {(0, 0), (0, 1)}));
      n.reset();
      expect(n.state.invalidCells, isEmpty);
    });
  });

  group('SudokuNotifier.saveCurrentProgress', () {
    test('saves record with inProgress mode and non-null solveTime', () async {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.debugSetState(
        n.state.copyWith(elapsed: const Duration(minutes: 2, seconds: 30)),
      );
      n.saveCurrentProgress();
      await Future.microtask(() {});
      expect(repo.saved, hasLength(1));
      final record = repo.saved.first;
      expect(record.solveMode, SolveModeRecord.inProgress);
      expect(record.solveTime, const Duration(minutes: 2, seconds: 30));
    });

    test('does nothing when status is not playing', () async {
      final repo = FakeRepository();
      final n = _makeNotifier(repo);
      n.saveCurrentProgress();
      await Future.microtask(() {});
      expect(repo.saved, isEmpty);
    });

    test('dispose saves elapsed time when game is in progress', () async {
      final repo = FakeRepository();
      final n = _notifierWithPuzzlePlaying(repo);
      n.debugSetState(n.state.copyWith(elapsed: const Duration(seconds: 45)));
      n.dispose();
      await Future.microtask(() {});
      expect(repo.saved, hasLength(1));
      expect(repo.saved.first.solveTime, const Duration(seconds: 45));
      expect(repo.saved.first.solveMode, SolveModeRecord.inProgress);
    });
  });
}
