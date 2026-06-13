import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sudoku_record.dart';
import '../repositories/sudoku_repository.dart';
import '../repositories/repository_provider.dart';

// Stan
enum HistoryLoadStatus { idle, loading, loaded, error }

class HistoryState {
  final List<SudokuRecord> records;
  final HistoryLoadStatus status;
  final String? errorMessage;
  final bool isSyncing;

  const HistoryState({
    this.records = const [],
    this.status = HistoryLoadStatus.idle,
    this.errorMessage,
    this.isSyncing = false,
  });

  HistoryState copyWith({
    List<SudokuRecord>? records,
    HistoryLoadStatus? status,
    String? errorMessage,
    bool? isSyncing,
  }) => HistoryState(
    records: records ?? this.records,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    isSyncing: isSyncing ?? this.isSyncing,
  );
}

// Provider
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier.fromRef(ref),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  final ISudokuRepository _repository;
  final Ref? _ref;
  bool _isLoading = false;

  HistoryNotifier.fromRef(Ref ref)
    : _repository = ref.read(sudokuRepositoryProvider),
      _ref = ref,
      super(const HistoryState()) {
    ref.listen<SyncState>(syncNotifierProvider, (prev, next) {
      if (prev?.status == SyncStatus.syncing &&
          next.status == SyncStatus.done) {
        loadHistory();
      }
      if (mounted) {
        state = state.copyWith(isSyncing: next.status == SyncStatus.syncing);
      }
    });
  }

  @visibleForTesting
  HistoryNotifier(ISudokuRepository repository)
    : _repository = repository,
      _ref = null,
      super(const HistoryState());

  Future<void> loadHistory() async {
    if (_isLoading) return;
    _isLoading = true;

    state = state.copyWith(status: HistoryLoadStatus.loading);
    try {
      final records = await _repository.getAll();
      if (!mounted) return;
      state = state.copyWith(
        records: records,
        status: HistoryLoadStatus.loaded,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: HistoryLoadStatus.error,
        errorMessage: 'Błąd ładowania historii: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
    }
  }

  Future<void> deleteRecord(String id) async {
    final previous = state.records;
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
    try {
      await _repository.delete(id);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        records: previous,
        errorMessage: 'Błąd usuwania rekordu: ${e.toString()}',
      );
    }
  }

  Future<void> manualSync() async {
    if (_ref == null) return;
    final result = await _ref!.read(syncNotifierProvider.notifier).manualSync();
    if (result != null && !result.isSuccess && mounted) {
      state = state.copyWith(
        errorMessage: 'Błąd synchronizacji: ${result.error}',
      );
    }
  }
}
