import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/services/history_notifier.dart';
import '../../backend/models/sudoku_record.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyProvider.notifier).loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    Widget body;
    if (historyState.status == HistoryLoadStatus.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (historyState.status == HistoryLoadStatus.error) {
      body = Center(
        child: Text(historyState.errorMessage ?? 'Błąd ładowania historii'),
      );
    } else if (historyState.records.isEmpty) {
      body = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Brak rozwiązanych plansz',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: historyState.records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final record = historyState.records[i];
          return _HistoryCard(
            record: record,
            onDelete: () =>
                ref.read(historyProvider.notifier).deleteRecord(record.id),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historia')),
      body: body,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SudokuRecord record;
  final VoidCallback onDelete;

  const _HistoryCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAuto = record.solveMode == SolveModeRecord.auto;
    final date = record.scannedAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAuto
              ? Colors.orange.shade100
              : Colors.green.shade100,
          child: Icon(
            isAuto ? Icons.auto_fix_high : Icons.person_outline,
            color: isAuto ? Colors.orange : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAuto ? 'Rozwiązane automatycznie' : 'Rozwiązane ręcznie'),
            if (record.solveTime != null)
              Text('Czas: ${_formatTime(record.solveTime!)}'),
            if (record.hintsUsed > 0) Text('Podpowiedzi: ${record.hintsUsed}'),
          ],
        ),
        isThreeLine: record.solveTime != null || record.hintsUsed > 0,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
