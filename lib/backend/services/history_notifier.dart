import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sudoku_record.dart';
import '../repositories/sudoku_repository.dart';

// Stan
enum HistoryLoadStatus { idle, loading, loaded, error }

class HistoryState {
  final List<SudokuRecord> records;
  final HistoryLoadStatus status;
  final String? errorMessage;

  const HistoryState({
    this.records = const [],
    this.status = HistoryLoadStatus.idle,
    this.errorMessage,
  });

  HistoryState copyWith({
    List<SudokuRecord>? records,
    HistoryLoadStatus? status,
    String? errorMessage,
  }) => HistoryState(
    records: records ?? this.records,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

// Notifier
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(ref.read(sudokuRepositoryProvider)),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  final ISudokuRepository _repository;

  HistoryNotifier(this._repository) : super(const HistoryState());

  Future<void> loadHistory() async {
    state = state.copyWith(status: HistoryLoadStatus.loading);
    try {
      final records = await _repository.getAll();
      state = state.copyWith(
        records: records,
        status: HistoryLoadStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        status: HistoryLoadStatus.error,
        errorMessage: 'Błąd ładowania historii: ${e.toString()}',
      );
    }
  }

  Future<void> deleteRecord(String id) async {
    await _repository.delete(id);
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
  }
}
