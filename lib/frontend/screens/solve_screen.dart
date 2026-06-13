import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/sudoku_notifier.dart';
import '../../backend/providers/sudoku_state.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key});

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  bool _showOkMessage = false;

  void _handleCheck() {
    ref.read(sudokuProvider.notifier).validateBoard();
    final state = ref.read(sudokuProvider);
    if (state.invalidCells.isEmpty) {
      setState(() => _showOkMessage = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showOkMessage = false);
      });
    } else {
      setState(() => _showOkMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sudokuProvider);
    final notifier = ref.read(sudokuProvider.notifier);
    final isSolved = state.status == GameStatus.solved;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    void goHome() {
      if (!isSolved) notifier.saveCurrentProgress();
      notifier.reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    final bool showBanner = state.errorMessage != null || _showOkMessage;
    final Color bannerColor = _showOkMessage
        ? Colors.green.shade50
        : Colors.red.shade50;
    final Color textColor = _showOkMessage
        ? Colors.green.shade700
        : Colors.red.shade700;
    final String bannerText = _showOkMessage
        ? 'Jak dotąd wszystko się zgadza!'
        : (state.errorMessage ?? '');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goHome,
        ),
        title: Text(isSolved ? '🎉 Rozwiązano!' : 'Rozwiązywanie'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(state.elapsed),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zawsze rezerwuje miejsce — plansza nie drga
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 40,
            color: showBanner ? bannerColor : Colors.transparent,
            alignment: Alignment.center,
            child: showBanner
                ? Text(
                    bannerText,
                    style: TextStyle(color: textColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),
          if (isSolved)
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, 40 + bottomPadding),
            child: Column(
              children: [
                if (!isSolved) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.canSolve
                              ? () => notifier.giveHint()
                              : null,
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('PODPOWIEDŹ'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.canSolve ? _handleCheck : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('SPRAWDŹ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: state.canSolve
                              ? () => notifier.solveBoard()
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('ROZWIĄŻ'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
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
                  ),
                ],
              ],
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
