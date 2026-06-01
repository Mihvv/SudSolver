import 'package:flutter/material.dart';
import '../../backend/services/sudoku_notifier.dart';
import '../../backend/services/sudoku_state.dart';

class SudokuGrid extends StatelessWidget {
  final SudokuState state;
  final SudokuNotifier notifier;

  const SudokuGrid({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final r = index ~/ 9;
            final c = index % 9;
            final value = state.board.grid[r][c];
            final isFixed = state.board.isFixed[r][c];
            final isSelected = state.isSelected(r, c);
            final canEdit = state.canEditCell(r, c);

            // Podświetlanie wiersza, kolumny i bloku 3x3
            final isHighlighted = state.hasSelection &&
                !isSelected &&
                (state.selectedRow == r ||
                    state.selectedCol == c ||
                    ((r ~/ 3) == (state.selectedRow! ~/ 3) &&
                        (c ~/ 3) == (state.selectedCol! ~/ 3)));

            Color bgColor = Colors.white;
            if (isSelected) {
              bgColor = colorScheme.primaryContainer;
            } else if (isHighlighted) {
              bgColor = colorScheme.primaryContainer.withOpacity(0.25);
            } else if ((r ~/ 3 + c ~/ 3) % 2 == 0) {
              bgColor = Colors.grey.shade50;
            }

            return GestureDetector(
              onTap: canEdit ? () => notifier.selectCell(r, c) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    top: BorderSide(
                      color: r % 3 == 0 ? Colors.black87 : Colors.grey.shade300,
                      width: r % 3 == 0 ? 1.5 : 0.5,
                    ),
                    left: BorderSide(
                      color: c % 3 == 0 ? Colors.black87 : Colors.grey.shade300,
                      width: c % 3 == 0 ? 1.5 : 0.5,
                    ),
                    right: BorderSide(
                      color: c == 8 ? Colors.black87 : Colors.grey.shade300,
                      width: c == 8 ? 1.5 : 0.5,
                    ),
                    bottom: BorderSide(
                      color: r == 8 ? Colors.black87 : Colors.grey.shade300,
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
                      fontWeight:
                      isFixed ? FontWeight.bold : FontWeight.normal,
                      color: isFixed ? Colors.black : colorScheme.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}