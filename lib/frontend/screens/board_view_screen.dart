import 'package:flutter/material.dart';
import '../../backend/models/sudoku_record.dart';

class BoardViewScreen extends StatelessWidget {
  final SudokuRecord record;

  const BoardViewScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final grid = record.solvedGrid ?? record.initialGrid;
    final isFixed = record.initialGrid
        .map((r) => r.map((v) => v != 0).toList())
        .toList();
    final colorScheme = Theme.of(context).colorScheme;
    final date = record.scannedAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return Scaffold(
      appBar: AppBar(title: Text('Plansza – $dateStr')),
      body: Column(
        children: [
          if (record.solveTime != null || record.hintsUsed > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (record.solveTime != null) ...[
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(record.solveTime!),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (record.hintsUsed > 0) ...[
                    const Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Podpowiedzi: ${record.hintsUsed}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemCount: 81,
                    itemBuilder: (context, index) {
                      final r = index ~/ 9;
                      final c = index % 9;
                      final value = grid[r][c];
                      final fixed = isFixed[r][c];

                      final bgColor = (r ~/ 3 + c ~/ 3) % 2 == 0
                          ? Colors.grey.shade50
                          : Colors.white;

                      return Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border(
                            top: BorderSide(
                              color: r % 3 == 0
                                  ? Colors.black87
                                  : Colors.grey.shade300,
                              width: r % 3 == 0 ? 1.5 : 0.5,
                            ),
                            left: BorderSide(
                              color: c % 3 == 0
                                  ? Colors.black87
                                  : Colors.grey.shade300,
                              width: c % 3 == 0 ? 1.5 : 0.5,
                            ),
                            right: BorderSide(
                              color: c == 8
                                  ? Colors.black87
                                  : Colors.grey.shade300,
                              width: c == 8 ? 1.5 : 0.5,
                            ),
                            bottom: BorderSide(
                              color: r == 8
                                  ? Colors.black87
                                  : Colors.grey.shade300,
                              width: r == 8 ? 1.5 : 0.5,
                            ),
                          ),
                        ),
                        child: Center(
                          child: value == 0
                              ? null
                              : Text(
                            value.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fixed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: fixed
                                  ? Colors.black
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}