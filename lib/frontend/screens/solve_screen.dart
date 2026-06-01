import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/services/sudoku_notifier.dart';
import '../../backend/services/sudoku_state.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';

class SolveScreen extends ConsumerWidget {
  const SolveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sudokuProvider);
    final notifier = ref.read(sudokuProvider.notifier);
    final isSolved = state.status == GameStatus.solved;

    void goHome() {
      notifier.reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isSolved ? '🎉 Rozwiązano!' : 'Rozwiązywanie'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(state.elapsed),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          if (isSolved)
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Czas: ${_formatTime(state.elapsed)}  •  Podpowiedzi: ${state.hintsUsed}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Center(
              child: SudokuGrid(state: state, notifier: notifier),
            ),
          ),
          if (!isSolved)
            NumberPad(notifier: notifier, isEditable: state.isEditable),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: goHome,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('POWRÓT'),
                  ),
                ),
                if (!isSolved) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.canSolve ? () => notifier.solveBoard() : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('ROZWIĄŻ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCheck(context, state),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('SPRAWDŹ'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: goHome,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('NOWA GRA'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCheck(BuildContext context, SudokuState state) {
    final hasError = state.errorMessage != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasError ? state.errorMessage! : 'Jak dotąd wszystko się zgadza!',
        ),
        backgroundColor: hasError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}