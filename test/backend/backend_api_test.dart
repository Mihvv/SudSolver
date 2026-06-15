import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:sudsolver/backend/services/auth/auth_service.dart';
import 'package:sudsolver/backend/services/auth/mock_auth_service.dart';
import 'package:sudsolver/backend/services/puzzle/puzzle_service.dart';
import 'package:sudsolver/backend/services/puzzle/mock_puzzle_service.dart';
import 'package:sudsolver/backend/services/scanner/scanner_service.dart';
import 'package:sudsolver/backend/services/scanner/mock_scanner_service.dart';
import 'package:sudsolver/backend/repositories/sudoku_repository.dart';
import 'package:sudsolver/backend/repositories/synced_sudoku_repository.dart';
import 'package:sudsolver/backend/repositories/firestore_sudoku_repository.dart';
import 'package:sudsolver/backend/models/sudoku_record.dart';
import 'package:sudsolver/backend/models/app_user.dart';
import 'package:sudsolver/backend/providers/auth_notifier.dart';
import 'package:sudsolver/backend/providers/history_notifier.dart';
import 'package:sudsolver/backend/repositories/repository_provider.dart';

@GenerateMocks([ISudokuRepository, FirestoreSudokuRepository])
import 'backend_api_test.mocks.dart';

void main() {
  group('MockAuthService', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('initial currentUser is null', () {
      expect(authService.currentUser, isNull);
    });

    test('authStateChanges emits null initially', () async {
      final first = await authService.authStateChanges.first;
      expect(first, isNull);
    });

    test(
      'signInWithGoogle returns fake user and updates currentUser',
      () async {
        final user = await authService.signInWithGoogle();
        expect(user, isNotNull);
        expect(user!.uid, equals('mock-uid-123'));
        expect(user.email, equals('test@example.com'));
        expect(authService.currentUser, equals(user));
      },
    );

    test('authStateChanges emits user after sign in', () async {
      final events = <AppUser?>[];
      final sub = authService.authStateChanges.listen(events.add);

      await authService.signInWithGoogle();
      await Future.delayed(const Duration(milliseconds: 100));

      await sub.cancel();

      expect(events, contains(isA<AppUser>()));
    });

    test('signOut clears currentUser and emits null', () async {
      await authService.signInWithGoogle();
      await authService.signOut();

      expect(authService.currentUser, isNull);

      final events = <AppUser?>[];
      final sub = authService.authStateChanges.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.last, isNull);
    });
  });

  group('MockPuzzleService', () {
    const service = MockPuzzleService();

    test('returns 9x9 grid for medium difficulty', () async {
      final grid = await service.fetchRandomPuzzle(difficulty: 'medium');
      expect(grid.length, equals(9));
      for (final row in grid) {
        expect(row.length, equals(9));
      }
    });

    test('returns different grids for different difficulties', () async {
      final easy = await service.fetchRandomPuzzle(difficulty: 'easy');
      final hard = await service.fetchRandomPuzzle(difficulty: 'hard');
      expect(easy, isNot(equals(hard)));
    });

    test('returns medium grid for unknown difficulty', () async {
      final grid = await service.fetchRandomPuzzle(difficulty: 'extreme');
      final medium = await service.fetchRandomPuzzle(difficulty: 'medium');
      expect(grid, equals(medium));
    });

    test('grid values are between 0 and 9', () async {
      final grid = await service.fetchRandomPuzzle();
      for (final row in grid) {
        for (final val in row) {
          expect(val, inInclusiveRange(0, 9));
        }
      }
    });
  });

  group('MockScannerService', () {
    const service = MockScannerService();

    test('scanImage returns 9x9 grid', () async {
      final grid = await service.scanImage('/fake/path.jpg');
      expect(grid.length, equals(9));
      for (final row in grid) {
        expect(row.length, equals(9));
      }
    });

    test('scanImage returns valid sudoku values', () async {
      final grid = await service.scanImage('/fake/path.png');
      for (final row in grid) {
        for (final val in row) {
          expect(val, inInclusiveRange(0, 9));
        }
      }
    });
  });

  group('SyncedSudokuRepository', () {
    late MockISudokuRepository mockLocal;
    late MockFirestoreSudokuRepository mockRemote;
    late SyncedSudokuRepository syncedRepo;

    final record1 = SudokuRecord(
      id: 'rec-1',
      scannedAt: DateTime(2024, 1, 1),
      initialGrid: List.generate(9, (_) => List.filled(9, 0)),
      solveMode: SolveModeRecord.manual,
    );

    final record2 = SudokuRecord(
      id: 'rec-2',
      scannedAt: DateTime(2024, 1, 2),
      initialGrid: List.generate(9, (_) => List.filled(9, 0)),
      solveMode: SolveModeRecord.auto,
    );

    setUp(() {
      mockLocal = MockISudokuRepository();
      mockRemote = MockFirestoreSudokuRepository();
      syncedRepo = SyncedSudokuRepository(local: mockLocal, remote: mockRemote);
    });

    test('save writes to local and fires remote save', () async {
      when(mockLocal.save(record1)).thenAnswer((_) async {});
      when(mockRemote.save(record1)).thenAnswer((_) async {});

      await syncedRepo.save(record1);

      verify(mockLocal.save(record1)).called(1);
      await Future.delayed(const Duration(milliseconds: 50));
      verify(mockRemote.save(record1)).called(1);
    });

    test('getAll delegates to local', () async {
      when(mockLocal.getAll()).thenAnswer((_) async => [record1, record2]);

      final result = await syncedRepo.getAll();

      expect(result, equals([record1, record2]));
      verifyNever(mockRemote.getAll());
    });

    test('delete removes from local and fires remote delete', () async {
      when(mockLocal.delete('rec-1')).thenAnswer((_) async {});
      when(mockRemote.delete('rec-1')).thenAnswer((_) async {});

      await syncedRepo.delete('rec-1');

      verify(mockLocal.delete('rec-1')).called(1);
      await Future.delayed(const Duration(milliseconds: 50));
      verify(mockRemote.delete('rec-1')).called(1);
    });

    test('syncFromCloud adds remote-only records to local', () async {
      when(mockRemote.getAll()).thenAnswer((_) async => [record1, record2]);
      when(mockLocal.getAll()).thenAnswer((_) async => [record1]);
      when(mockLocal.save(record2)).thenAnswer((_) async {});
      when(mockRemote.uploadBatch(any)).thenAnswer((_) async {});

      final result = await syncedRepo.syncFromCloud();

      expect(result.isSuccess, isTrue);
      expect(result.added, equals(1));
      verify(mockLocal.save(record2)).called(1);
    });

    test('syncFromCloud uploads local-only records to remote', () async {
      when(mockRemote.getAll()).thenAnswer((_) async => [record1]);
      when(mockLocal.getAll()).thenAnswer((_) async => [record1, record2]);
      when(mockRemote.uploadBatch([record2])).thenAnswer((_) async {});

      final result = await syncedRepo.syncFromCloud();

      expect(result.isSuccess, isTrue);
      expect(result.uploaded, equals(1));
      verify(mockRemote.uploadBatch([record2])).called(1);
    });

    test('syncFromCloud updates local record if remote is newer', () async {
      final older = SudokuRecord(
        id: 'rec-1',
        scannedAt: DateTime(2024, 1, 1),
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        solveMode: SolveModeRecord.manual,
      );
      final newer = SudokuRecord(
        id: 'rec-1',
        scannedAt: DateTime(2024, 6, 1),
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        solveMode: SolveModeRecord.manual,
      );

      when(mockRemote.getAll()).thenAnswer((_) async => [newer]);
      when(mockLocal.getAll()).thenAnswer((_) async => [older]);
      when(mockLocal.save(newer)).thenAnswer((_) async {});
      when(mockRemote.uploadBatch(any)).thenAnswer((_) async {});

      final result = await syncedRepo.syncFromCloud();

      expect(result.updated, equals(1));
      verify(mockLocal.save(newer)).called(1);
    });

    test('syncFromCloud returns failed SyncResult on exception', () async {
      when(mockRemote.getAll()).thenThrow(Exception('network error'));
      when(mockLocal.getAll()).thenAnswer((_) async => []);

      final result = await syncedRepo.syncFromCloud();

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('network error'));
    });
  });

  group('AuthNotifier (Riverpod)', () {
    late ProviderContainer container;
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
      container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(mockAuth)],
      );
    });

    tearDown(() {
      mockAuth.dispose();
      container.dispose();
    });

    test('initial state is idle with no error', () {
      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.idle));
      expect(state.errorMessage, isNull);
    });

    test('signInWithGoogle transitions through loading to idle', () async {
      final statuses = <AuthStatus>[];
      container.listen(
        authNotifierProvider.select((s) => s.status),
        (_, status) => statuses.add(status),
        fireImmediately: true,
      );

      await container.read(authNotifierProvider.notifier).signInWithGoogle();

      expect(
        statuses,
        containsAllInOrder([
          AuthStatus.idle,
          AuthStatus.loading,
          AuthStatus.idle,
        ]),
      );
    });

    test('signOut resets state to idle', () async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      await container.read(authNotifierProvider.notifier).signOut();

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.idle));
      expect(state.errorMessage, isNull);
    });

    test('currentUserProvider is null before sign in', () {
      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('HistoryNotifier (Riverpod)', () {
    late ProviderContainer container;
    late MockISudokuRepository mockRepo;

    final records = [
      SudokuRecord(
        id: 'h-1',
        scannedAt: DateTime(2024, 3, 1),
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        solveMode: SolveModeRecord.auto,
      ),
      SudokuRecord(
        id: 'h-2',
        scannedAt: DateTime(2024, 3, 2),
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        solveMode: SolveModeRecord.manual,
      ),
    ];

    setUp(() {
      mockRepo = MockISudokuRepository();
      when(mockRepo.getAll()).thenAnswer((_) async => records);
      when(mockRepo.delete(any)).thenAnswer((_) async {});
      when(mockRepo.save(any)).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [sudokuRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() => container.dispose());

    test('initial status is idle', () {
      final state = container.read(historyProvider);
      expect(state.status, equals(HistoryLoadStatus.idle));
    });

    test('loadHistory sets status to loaded and populates records', () async {
      await container.read(historyProvider.notifier).loadHistory();

      final state = container.read(historyProvider);
      expect(state.status, equals(HistoryLoadStatus.loaded));
      expect(state.records.length, equals(2));
    });

    test('deleteRecord removes entry optimistically', () async {
      await container.read(historyProvider.notifier).loadHistory();
      await container.read(historyProvider.notifier).deleteRecord('h-1');

      final state = container.read(historyProvider);
      expect(state.records.any((r) => r.id == 'h-1'), isFalse);
      verify(mockRepo.delete('h-1')).called(1);
    });

    test('deleteRecord restores records on repository error', () async {
      when(mockRepo.delete('h-2')).thenThrow(Exception('delete failed'));

      await container.read(historyProvider.notifier).loadHistory();
      await container.read(historyProvider.notifier).deleteRecord('h-2');

      final state = container.read(historyProvider);
      expect(state.records.any((r) => r.id == 'h-2'), isTrue);
      expect(state.errorMessage, isNotNull);
    });

    test('loadHistory on repository error sets error status', () async {
      when(mockRepo.getAll()).thenThrow(Exception('db error'));

      await container.read(historyProvider.notifier).loadHistory();

      final state = container.read(historyProvider);
      expect(state.status, equals(HistoryLoadStatus.error));
      expect(state.errorMessage, contains('db error'));
    });
  });

  group('SyncResult', () {
    test('isSuccess is true when no error', () {
      const result = SyncResult(added: 1, updated: 0, uploaded: 2);
      expect(result.isSuccess, isTrue);
    });

    test('isSuccess is false for failed result', () {
      const result = SyncResult.failed('timeout');
      expect(result.isSuccess, isFalse);
      expect(result.error, equals('timeout'));
    });

    test('toString includes counts for successful result', () {
      const result = SyncResult(added: 3, updated: 1, uploaded: 5);
      expect(result.toString(), contains('+3'));
      expect(result.toString(), contains('↑5'));
    });

    test('toString includes error for failed result', () {
      const result = SyncResult.failed('network error');
      expect(result.toString(), contains('FAIL'));
      expect(result.toString(), contains('network error'));
    });
  });

  group('PuzzleException', () {
    test('isRetryable defaults to false', () {
      const e = PuzzleException('error');
      expect(e.isRetryable, isFalse);
    });

    test('isRetryable can be set to true', () {
      const e = PuzzleException('timeout', isRetryable: true);
      expect(e.isRetryable, isTrue);
    });

    test('toString contains message', () {
      const e = PuzzleException('not found');
      expect(e.toString(), contains('not found'));
    });
  });

  group('ScannerException', () {
    test('toString contains message', () {
      const e = ScannerException('file missing');
      expect(e.toString(), contains('file missing'));
    });
  });

  group('AuthException', () {
    test('toString contains message', () {
      const e = AuthException('unauthorized');
      expect(e.toString(), contains('unauthorized'));
    });
  });
}
