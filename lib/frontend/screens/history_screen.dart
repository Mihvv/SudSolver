import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/history_notifier.dart';
import '../../backend/providers/sudoku_notifier.dart';
import '../../backend/models/sudoku_record.dart';
import 'board_view_screen.dart';
import 'solve_screen.dart';

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
            onView: record.solvedGrid != null
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoardViewScreen(record: record),
                    ),
                  )
                : null,
            onResume: record.solvedGrid != null
                ? () {
                    ref.read(sudokuProvider.notifier).resumeRecord(record);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SolveScreen()),
                    );
                  }
                : null,
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
  final VoidCallback? onView;
  final VoidCallback? onResume;

  const _HistoryCard({
    required this.record,
    required this.onDelete,
    this.onView,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final date = record.scannedAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    final (icon, color, label) = switch (record.solveMode) {
      SolveModeRecord.manual => (Icons.person_outline, Colors.green, 'Ręcznie'),
      SolveModeRecord.auto => (
        Icons.auto_fix_high,
        Colors.orange,
        'Automatycznie',
      ),
      SolveModeRecord.inProgress => (
        Icons.pause_circle_outline,
        Colors.blue,
        'W trakcie',
      ),
      SolveModeRecord.unsolved => (
        Icons.cancel_outlined,
        Colors.grey,
        'Nierozwiązane',
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            dateStr,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              if (record.solveTime != null)
                Text('Czas: ${_formatTime(record.solveTime!)}'),
              if (record.hintsUsed > 0)
                Text('Podpowiedzi: ${record.hintsUsed}'),
            ],
          ),
          isThreeLine: record.solveTime != null || record.hintsUsed > 0,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onView != null)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Podgląd',
                  onPressed: onView,
                ),
              if (onResume != null)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.blue),
                  tooltip: record.solveMode == SolveModeRecord.inProgress
                      ? 'Wznów'
                      : 'Zagraj ponownie',
                  onPressed: onResume,
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
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
