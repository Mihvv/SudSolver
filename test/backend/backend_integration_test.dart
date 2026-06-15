import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sudsolver/backend/models/app_user.dart';
import 'package:sudsolver/backend/models/sudoku_board.dart';
import 'package:sudsolver/backend/models/sudoku_record.dart';
import 'package:sudsolver/backend/providers/auth_notifier.dart';
import 'package:sudsolver/backend/providers/history_notifier.dart';
import 'package:sudsolver/backend/providers/sudoku_notifier.dart';
import 'package:sudsolver/backend/providers/sudoku_state.dart';
import 'package:sudsolver/backend/repositories/repository_provider.dart';
import 'package:sudsolver/backend/repositories/sudoku_repository.dart';
import 'package:sudsolver/backend/repositories/synced_sudoku_repository.dart';
import 'package:sudsolver/backend/repositories/firestore_sudoku_repository.dart';
import 'package:sudsolver/backend/services/auth/auth_service.dart';
import 'package:sudsolver/backend/services/auth/mock_auth_service.dart';
import 'package:sudsolver/backend/services/puzzle/mock_puzzle_service.dart';
import 'package:sudsolver/backend/services/puzzle/puzzle_service.dart';
import 'package:sudsolver/backend/services/scanner/mock_scanner_service.dart';
import 'package:sudsolver/backend/services/scanner/scanner_service.dart';

class FakeSudokuRepository implements ISudokuRepository {
  final Map<String, SudokuRecord> _store = {};

  @override
  Future<void> save(SudokuRecord record) async => _store[record.id] = record;

  @override
  Future<List<SudokuRecord>> getAll() async {
    final list = _store.values.toList();
    list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return list;
  }

  @override
  Future<SudokuRecord?> getById(String id) async => _store[id];

  @override
  Future<void> delete(String id) async => _store.remove(id);

  int get count => _store.length;
  bool contains(String id) => _store.containsKey(id);
}

class FakeFirestoreRepository implements FirestoreSudokuRepository {
  final Map<String, SudokuRecord> _store = {};
  int uploadBatchCalls = 0;

  @override
  String get uid => 'fake-uid';

  @override
  Future<void> save(SudokuRecord record) async => _store[record.id] = record;

  @override
  Future<List<SudokuRecord>> getAll() async {
    final list = _store.values.toList();
    list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return list;
  }

  @override
  Future<SudokuRecord?> getById(String id) async => _store[id];

  @override
  Future<void> delete(String id) async => _store.remove(id);

  int get count => _store.length;
  bool contains(String id) => _store.containsKey(id);

  @override
  Future<void> uploadBatch(List<SudokuRecord> records) async {
    uploadBatchCalls++;
    for (final r in records) {
      await save(r);
    }
  }
}

class FailingScannerService implements IScannerService {
  @override
  Future<List<List<int>>> scanImage(String imagePath) =>
      Future.error(const ScannerException('Simulated scan error'));
}

class FailingPuzzleService implements IPuzzleService {
  @override
  Future<List<List<int>>> fetchRandomPuzzle({String difficulty = 'medium'}) =>
      Future.error(
        const PuzzleException('Simulated server error', isRetryable: false),
      );
}

ProviderContainer buildContainer({
  IAuthService? authService,
  ISudokuRepository? localRepo,
  FakeFirestoreRepository? remoteRepo,
  IScannerService? scannerService,
  IPuzzleService? puzzleService,
}) {
  final auth = authService ?? MockAuthService();
  final local = localRepo ?? FakeSudokuRepository();
  final remote = remoteRepo ?? FakeFirestoreRepository();
  final scanner = scannerService ?? const MockScannerService();
  final puzzle = puzzleService ?? const MockPuzzleService();

  return ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      localRepositoryProvider.overrideWithValue(local),
      sudokuRepositoryProvider.overrideWith((ref) {
        final user = ref.watch(currentUserProvider);
        if (user == null) return local;
        return SyncedSudokuRepository(local: local, remote: remote);
      }),
      scannerServiceProvider.overrideWithValue(scanner),
      puzzleServiceProvider.overrideWithValue(puzzle),
    ],
  );
}

void main() {
  group('Auth ↔ Repository integration', () {
    test(
      'sudokuRepositoryProvider returns local repository when user is not logged in',
      () {
        final container = buildContainer();
        addTearDown(container.dispose);

        final repo = container.read(sudokuRepositoryProvider);
        expect(repo, isA<FakeSudokuRepository>());
      },
    );

    test(
      'sudokuRepositoryProvider returns SyncedSudokuRepository after login',
      () async {
        final auth = MockAuthService();
        final container = buildContainer(authService: auth);
        addTearDown(container.dispose);

        // Subscribe to the stream provider so it starts listening
        container.read(authStateProvider);
        await auth.signInWithGoogle();
        // Allow StreamProvider to process the new value through its pipeline
        await Future.delayed(const Duration(milliseconds: 50));

        final repo = container.read(sudokuRepositoryProvider);
        expect(repo, isA<SyncedSudokuRepository>());
      },
    );

    test('repository reverts to local after logout', () async {
      final auth = MockAuthService();
      final container = buildContainer(authService: auth);
      addTearDown(container.dispose);

      container.read(authStateProvider);
      await auth.signInWithGoogle();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(sudokuRepositoryProvider),
        isA<SyncedSudokuRepository>(),
      );

      await auth.signOut();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(sudokuRepositoryProvider),
        isA<FakeSudokuRepository>(),
      );
    });
  });

  group('SudokuNotifier ↔ Repository integration', () {
    late FakeSudokuRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeSudokuRepository();
      container = buildContainer(localRepo: repo);
    });

    tearDown(() => container.dispose());

    test('solveBoard saves record to repository', () async {
      final notifier = container.read(sudokuProvider.notifier);

      notifier.debugSetState(
        SudokuState(
          board: SudokuBoard([
            [5, 3, 0, 0, 7, 0, 0, 0, 0],
            [6, 0, 0, 1, 9, 5, 0, 0, 0],
            [0, 9, 8, 0, 0, 0, 0, 6, 0],
            [8, 0, 0, 0, 6, 0, 0, 0, 3],
            [4, 0, 0, 8, 0, 3, 0, 0, 1],
            [7, 0, 0, 0, 2, 0, 0, 0, 6],
            [0, 6, 0, 0, 0, 0, 2, 8, 0],
            [0, 0, 0, 4, 1, 9, 0, 0, 5],
            [0, 0, 0, 0, 8, 0, 0, 7, 9],
          ], List.generate(9, (_) => List.filled(9, false))),
          status: GameStatus.playing,
          sessionId: 'test-session-1',
        ),
      );

      notifier.solveBoard();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.count, 1);
      final records = await repo.getAll();
      expect(records.first.solveMode, SolveModeRecord.auto);
    });

    test('manual board completion saves record with manual mode', () async {
      final notifier = container.read(sudokuProvider.notifier);

      final almostSolved = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 0, 9],
      ];

      notifier.debugSetState(
        SudokuState(
          board: SudokuBoard(
            almostSolved,
            List.generate(
              9,
              (r) => List.generate(9, (c) => !(r == 8 && c == 7)),
            ),
          ),
          status: GameStatus.playing,
          sessionId: 'test-session-2',
        ),
      );

      notifier.selectCell(8, 7);
      notifier.updateSelectedCell(7);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.count, 1);
      final records = await repo.getAll();
      expect(records.first.solveMode, SolveModeRecord.manual);
      expect(records.first.solvedGrid![8][7], 7);
    });

    test(
      'scanBoard + confirmScannedBoard does not save - game is still in progress',
      () async {
        final notifier = container.read(sudokuProvider.notifier);

        await notifier.scanBoard('/fake/image.jpg');
        notifier.confirmScannedBoard();

        await Future.delayed(const Duration(milliseconds: 50));

        expect(container.read(sudokuProvider).status, GameStatus.playing);
        expect(repo.count, 0);
      },
    );

    test('saveCurrentProgress saves record with inProgress mode', () async {
      final notifier = container.read(sudokuProvider.notifier);

      notifier.debugSetState(
        SudokuState(
          board: SudokuBoard(
            List.generate(9, (_) => List.filled(9, 0)),
            List.generate(9, (_) => List.filled(9, false)),
          ),
          status: GameStatus.playing,
          sessionId: 'test-session-progress',
        ),
      );

      notifier.saveCurrentProgress();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.count, 1);
      final records = await repo.getAll();
      expect(records.first.solveMode, SolveModeRecord.inProgress);
    });

    test('dispose saves inProgress automatically', () async {
      final notifier = container.read(sudokuProvider.notifier);

      notifier.debugSetState(
        SudokuState(
          board: SudokuBoard(
            List.generate(9, (_) => List.filled(9, 0)),
            List.generate(9, (_) => List.filled(9, false)),
          ),
          status: GameStatus.playing,
          sessionId: 'test-session-dispose',
        ),
      );

      container.dispose();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.count, 1);
    });
  });

  group('HistoryNotifier ↔ Repository integration', () {
    late FakeSudokuRepository repo;
    late ProviderContainer container;

    SudokuRecord _makeRecord(String id) => SudokuRecord(
      id: id,
      scannedAt: DateTime.now(),
      initialGrid: List.generate(9, (_) => List.filled(9, 0)),
      solveMode: SolveModeRecord.manual,
    );

    setUp(() {
      repo = FakeSudokuRepository();
      container = buildContainer(localRepo: repo);
    });

    tearDown(() => container.dispose());

    test('loadHistory loads records from repository', () async {
      await repo.save(_makeRecord('r1'));
      await repo.save(_makeRecord('r2'));

      final notifier = container.read(historyProvider.notifier);
      await notifier.loadHistory();

      final state = container.read(historyProvider);
      expect(state.status, HistoryLoadStatus.loaded);
      expect(state.records.length, 2);
    });

    test(
      'deleteRecord removes from repository and updates state (optimistic update)',
      () async {
        await repo.save(_makeRecord('del-1'));
        await repo.save(_makeRecord('del-2'));

        final notifier = container.read(historyProvider.notifier);
        await notifier.loadHistory();
        await notifier.deleteRecord('del-1');

        final state = container.read(historyProvider);
        expect(state.records.length, 1);
        expect(state.records.first.id, 'del-2');
        expect(repo.contains('del-1'), isFalse);
      },
    );

    test(
      'deleteRecord reverts optimistic update upon repository error',
      () async {
        final failRepo = _FailOnDeleteRepository();
        final c = buildContainer(localRepo: failRepo);
        addTearDown(c.dispose);

        await failRepo.save(_makeRecord('fail-1'));
        final notifier = c.read(historyProvider.notifier);
        await notifier.loadHistory();

        await notifier.deleteRecord('fail-1');

        final state = c.read(historyProvider);
        expect(state.records.length, 1);
        expect(state.errorMessage, isNotNull);
      },
    );
  });

  group('SyncedSudokuRepository integration', () {
    late FakeSudokuRepository local;
    late FakeFirestoreRepository remote;
    late SyncedSudokuRepository synced;

    SudokuRecord _makeRecord(String id, {DateTime? scannedAt}) => SudokuRecord(
      id: id,
      scannedAt: scannedAt ?? DateTime(2024, 1, 1),
      initialGrid: List.generate(9, (_) => List.filled(9, 0)),
      solveMode: SolveModeRecord.manual,
    );

    setUp(() {
      local = FakeSudokuRepository();
      remote = FakeFirestoreRepository();
      synced = SyncedSudokuRepository(local: local, remote: remote);
    });

    test('syncFromCloud imports records present only in the cloud', () async {
      await remote.save(_makeRecord('cloud-only'));

      final result = await synced.syncFromCloud();

      expect(result.isSuccess, isTrue);
      expect(result.added, 1);
      expect(local.contains('cloud-only'), isTrue);
    });

    test('syncFromCloud uploads records present only locally', () async {
      await local.save(_makeRecord('local-only'));

      final result = await synced.syncFromCloud();

      expect(result.isSuccess, isTrue);
      expect(result.uploaded, 1);
      expect(remote.uploadBatchCalls, 1);
    });

    test(
      'syncFromCloud updates local record when cloud record is newer',
      () async {
        final older = _makeRecord('shared', scannedAt: DateTime(2024, 1, 1));
        final newer = _makeRecord('shared', scannedAt: DateTime(2024, 6, 1));

        await local.save(older);
        await remote.save(newer);

        final result = await synced.syncFromCloud();

        expect(result.updated, 1);
        final localRecord = await local.getById('shared');
        expect(localRecord!.scannedAt, DateTime(2024, 6, 1));
      },
    );

    test(
      'syncFromCloud does not overwrite local record when it is newer or equal',
      () async {
        final newer = _makeRecord('shared', scannedAt: DateTime(2024, 6, 1));
        final older = _makeRecord('shared', scannedAt: DateTime(2024, 1, 1));

        await local.save(newer);
        await remote.save(older);

        final result = await synced.syncFromCloud();

        expect(result.updated, 0);
        final localRecord = await local.getById('shared');
        expect(localRecord!.scannedAt, DateTime(2024, 6, 1));
      },
    );

    test(
      'syncFromCloud returns SyncResult.failed when remote throws an exception',
      () async {
        final brokenRemote = _ThrowingFirestoreRepository();
        final s = SyncedSudokuRepository(local: local, remote: brokenRemote);

        final result = await s.syncFromCloud();

        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
      },
    );

    test('save saves locally and fire-and-forget to remote', () async {
      final record = _makeRecord('save-test');
      await synced.save(record);

      expect(local.contains('save-test'), isTrue);
    });

    test('delete removes locally and fire-and-forget to remote', () async {
      final record = _makeRecord('del-test');
      await local.save(record);
      await remote.save(record);

      await synced.delete('del-test');

      expect(local.contains('del-test'), isFalse);
    });
  });

  group('SudokuNotifier - service error handling', () {
    test(
      'scanBoard sets error status when scanner throws an exception',
      () async {
        final container = buildContainer(
          scannerService: FailingScannerService(),
        );
        addTearDown(container.dispose);

        await container.read(sudokuProvider.notifier).scanBoard('/fake.jpg');

        final state = container.read(sudokuProvider);
        expect(state.status, GameStatus.error);
        expect(state.errorMessage, contains('Scan error'));
      },
    );

    test(
      'fetchRandomPuzzle sets error status when puzzle service fails',
      () async {
        final container = buildContainer(puzzleService: FailingPuzzleService());
        addTearDown(container.dispose);

        await container.read(sudokuProvider.notifier).fetchRandomPuzzle();

        final state = container.read(sudokuProvider);
        expect(state.status, GameStatus.error);
        expect(state.errorMessage, isNotNull);
      },
    );

    test('fetchRandomPuzzle starts timer after success', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(sudokuProvider.notifier)
          .fetchRandomPuzzle(difficulty: 'easy');

      final state = container.read(sudokuProvider);
      expect(state.status, GameStatus.playing);
    });
  });

  group('AuthNotifier ↔ AuthService integration', () {
    test('signInWithGoogle changes authState to logged in user', () async {
      final auth = MockAuthService();
      final container = buildContainer(authService: auth);
      addTearDown(container.dispose);

      // Subscribe so StreamProvider starts listening to authStateChanges
      container.read(authStateProvider);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();
      await Future.delayed(const Duration(milliseconds: 50));

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.email, 'test@example.com');
    });

    test('signOut removes user from authState', () async {
      final auth = MockAuthService();
      final container = buildContainer(authService: auth);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      await container.read(authNotifierProvider.notifier).signOut();

      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });

    test(
      'authNotifier changes status to error when signIn throws AuthException',
      () async {
        final container = buildContainer(authService: _ThrowingAuthService());
        addTearDown(container.dispose);

        await container.read(authNotifierProvider.notifier).signInWithGoogle();

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.error);
        expect(state.errorMessage, isNotNull);
      },
    );
  });

  group('resumeRecord integration', () {
    test('resumeRecord restores board and time from record', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final record = SudokuRecord(
        id: 'resume-1',
        scannedAt: DateTime.now(),
        initialGrid: [
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ],
        solveMode: SolveModeRecord.inProgress,
        solveTime: const Duration(minutes: 3, seconds: 42),
        hintsUsed: 2,
      );

      container.read(sudokuProvider.notifier).resumeRecord(record);

      final state = container.read(sudokuProvider);
      expect(state.status, GameStatus.playing);
      expect(state.elapsed, const Duration(minutes: 3, seconds: 42));
      expect(state.hintsUsed, 2);
      expect(state.sessionId, 'resume-1');
      expect(state.board.isFixed[0][0], isTrue);
      expect(state.board.isFixed[0][2], isFalse);
    });
  });
}

class _FailOnDeleteRepository extends FakeSudokuRepository {
  @override
  Future<void> delete(String id) =>
      Future.error(Exception('Simulated delete error'));
}

class _ThrowingFirestoreRepository extends FakeFirestoreRepository {
  @override
  Future<List<SudokuRecord>> getAll() =>
      Future.error(Exception('Firestore unavailable'));
}

class _ThrowingAuthService implements IAuthService {
  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser?> signInWithGoogle() =>
      Future.error(const AuthException('Simulated login error'));

  @override
  Future<void> signOut() async {}
}
