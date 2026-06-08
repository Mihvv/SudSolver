import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/sudoku_notifier.dart';
import '../../backend/providers/sudoku_state.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import 'solve_screen.dart';

class BoardConfirmationScreen extends ConsumerWidget {
  const BoardConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sudokuProvider);
    final notifier = ref.read(sudokuProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprawdź planszę'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Text(
              state.errorMessage ??
                  'Popraw ewentualne błędy skanowania, następnie zatwierdź planszę.',
              style: TextStyle(
                color: state.errorMessage != null ? Colors.red : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: SudokuGrid(state: state, notifier: notifier),
            ),
          ),
          NumberPad(notifier: notifier, isEditable: state.isEditable),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  notifier.confirmScannedBoard();
                  final newStatus = ref.read(sudokuProvider).status;
                  if (newStatus == GameStatus.playing) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SolveScreen()),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Potwierdź planszę',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
