import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sudoku_record.dart';
import '../providers/auth_notifier.dart';
import 'sudoku_repository.dart';
import 'firestore_sudoku_repository.dart';
import 'synced_sudoku_repository.dart';

final localRepositoryProvider = Provider<ISudokuRepository>(
  (_) => HiveSudokuRepository(),
);

final sudokuRepositoryProvider = Provider<ISudokuRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  final local = ref.watch(localRepositoryProvider);

  if (user == null) return local;

  final remote = FirestoreSudokuRepository(uid: user.uid);
  return SyncedSudokuRepository(local: local, remote: remote);
});

enum SyncStatus { idle, syncing, done, error }

class SyncState {
  final SyncStatus status;
  final SyncResult? lastResult;

  const SyncState({this.status = SyncStatus.idle, this.lastResult});

  SyncState copyWith({SyncStatus? status, SyncResult? lastResult}) => SyncState(
    status: status ?? this.status,
    lastResult: lastResult ?? this.lastResult,
  );
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((
  ref,
) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  String? _lastSyncedUid;

  SyncNotifier(this._ref) : super(const SyncState()) {
    _ref.listen<dynamic>(currentUserProvider, (_, next) {
      final uid = (next as dynamic)?.uid as String?;
      if (uid != null && uid != _lastSyncedUid) {
        _triggerSync();
      }
      if (uid == null) {
        _lastSyncedUid = null;
        state = const SyncState();
      }
    });
  }

  Future<void> _triggerSync() async {
    final repo = _ref.read(sudokuRepositoryProvider);
    if (repo is! SyncedSudokuRepository) return;

    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    _lastSyncedUid = uid;

    state = state.copyWith(status: SyncStatus.syncing);

    final result = await repo.syncFromCloud();

    if (!mounted) return;

    state = SyncState(
      status: result.isSuccess ? SyncStatus.done : SyncStatus.error,
      lastResult: result,
    );

    if (result.isSuccess) {}
  }

  Future<SyncResult?> manualSync() async {
    final repo = _ref.read(sudokuRepositoryProvider);
    if (repo is! SyncedSudokuRepository) return null;

    state = state.copyWith(status: SyncStatus.syncing);
    final result = await repo.syncFromCloud();

    if (!mounted) return result;

    state = SyncState(
      status: result.isSuccess ? SyncStatus.done : SyncStatus.error,
      lastResult: result,
    );
    return result;
  }
}
