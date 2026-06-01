import 'package:flutter/material.dart';
import '../../backend/services/sudoku_notifier.dart';

class NumberPad extends StatelessWidget {
  final SudokuNotifier notifier;
  final bool isEditable;

  const NumberPad({
    super.key,
    required this.notifier,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(10, (i) {
          final isErase = i == 0;
          final label = isErase ? 'X' : i.toString();

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 0.75,
                child: Material(
                  color: isErase ? Colors.red.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: isEditable
                        ? () => notifier.updateSelectedCell(i)
                        : null,
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: !isEditable
                              ? Colors.grey.shade400
                              : isErase
                              ? Colors.red
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
