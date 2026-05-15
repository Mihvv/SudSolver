import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend/services/sudoku_state.dart';
import 'backend/services/sudoku_notifier.dart';

void main() {
  runApp(const ProviderScope(child: SudokuApp()));
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SudokuScreen(),
    );
  }
}

class SudokuScreen extends ConsumerWidget {
  const SudokuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sudokuProvider);
    final notifier = ref.read(sudokuProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('SudSolver')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: 450,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(border: Border.all(width: 2)),
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
                        final value = state.board.grid[r][c];
                        final isFixed = state.board.isFixed[r][c];
                        final isSelected = state.isSelected(r, c);

                        return GestureDetector(
                          onTap: () => notifier.selectCell(r, c),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                value == 0 ? '' : value.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: isFixed
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isFixed
                                      ? Colors.black
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: List.generate(10, (index) {
                  return ElevatedButton(
                    onPressed: state.isEditable
                        ? () => notifier.updateSelectedCell(index)
                        : null,
                    child: Text(index == 0 ? 'X' : index.toString()),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => notifier.scanBoard('path_to_image'),
                    child: const Text('Skanuj (Mock)'),
                  ),
                  const SizedBox(width: 10),
                  if (state.status == GameStatus.correctingOCR)
                    ElevatedButton(
                      onPressed: () => notifier.confirmScannedBoard(),
                      child: const Text('Zatwierdź'),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: state.canSolve
                        ? () => notifier.solveBoard()
                        : null,
                    child: const Text('Rozwiąż'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => notifier.reset(),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              if (state.status == GameStatus.scanning)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
