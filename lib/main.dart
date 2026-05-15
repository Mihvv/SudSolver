import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend/services/sudoku_notifier.dart';
import 'backend/services/sudoku_state.dart';

void main() {
  runApp(const ProviderScope(child: SudokuApp()));
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A2E)),
        useMaterial3: true,
      ),
      home: const TestScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kolory statusów
// ─────────────────────────────────────────────────────────────────────────────

extension _StatusStyle on GameStatus {
  Color get color => switch (this) {
    GameStatus.idle => Colors.grey,
    GameStatus.scanning => Colors.blue,
    GameStatus.correctingOCR => Colors.orange,
    GameStatus.playing => const Color(0xFF2E7D32),
    GameStatus.solved => Colors.purple,
    GameStatus.error => Colors.red,
  };

  String get label => switch (this) {
    GameStatus.idle => 'Oczekiwanie',
    GameStatus.scanning => 'Skanowanie…',
    GameStatus.correctingOCR => 'Korekta OCR',
    GameStatus.playing => 'Tryb gry',
    GameStatus.solved => 'Rozwiązano!',
    GameStatus.error => 'Błąd',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Główny ekran testowy
// ─────────────────────────────────────────────────────────────────────────────

class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sudokuProvider);
    final notifier = ref.read(sudokuProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Sudoku Solver — TEST'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: notifier.reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Center(
          child: Column(
            children: [
              // Status badge
              _StatusBadge(status: state.status),
              const SizedBox(height: 8),

              // Komunikat błędu / info
              if (state.errorMessage != null)
                _ErrorBanner(message: state.errorMessage!),

              // Info o zaznaczonej komórce
              _SelectedCellInfo(state: state),

              const SizedBox(height: 12),

              // Plansza
              _SudokuGrid(state: state, notifier: notifier),

              const SizedBox(height: 16),

              // Klawiatura numeryczna — widoczna gdy coś zaznaczono
              if (_showKeyboard(state))
                _NumericKeyboard(state: state, notifier: notifier),

              const SizedBox(height: 16),

              // Przyciski akcji
              _ActionButtons(state: state, notifier: notifier),

              const SizedBox(height: 20),
              _HelpText(status: state.status),
            ],
          ),
        ),
      ),
    );
  }

  bool _showKeyboard(SudokuState state) {
    if (state.selectedRow == null) return false;
    return state.status == GameStatus.correctingOCR ||
        state.status == GameStatus.playing;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final GameStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == GameStatus.scanning)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Baner błędu
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info o zaznaczonej komórce
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedCellInfo extends StatelessWidget {
  final SudokuState state;
  const _SelectedCellInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.selectedRow == null) return const SizedBox(height: 8);
    final r = state.selectedRow! + 1;
    final c = state.selectedCol! + 1;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Zaznaczono: wiersz $r, kolumna $c',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Siatka sudoku
// ─────────────────────────────────────────────────────────────────────────────

class _SudokuGrid extends StatelessWidget {
  final SudokuState state;
  final SudokuNotifier notifier;

  const _SudokuGrid({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const cellSize = 36.0;
    const outerBorder = 2.5;
    const innerBox = 1.0;
    const innerCell = 0.4;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: outerBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(9, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(9, (c) {
              final value = state.board.grid[r][c];
              final isFixed = state.board.isFixed[r][c];
              final isSelected =
                  state.selectedRow == r && state.selectedCol == c;

              // Wykryj błąd: wartość != 0 i jest nieważna
              final hasError =
                  value != 0 &&
                  state.status == GameStatus.playing &&
                  !isFixed &&
                  !_isCurrentlyValid(r, c, value);

              // Grubsze krawędzie co 3 komórki (granice 3×3)
              final borderRight = (c + 1) % 3 == 0 && c != 8
                  ? innerBox
                  : innerCell;
              final borderBottom = (r + 1) % 3 == 0 && r != 8
                  ? innerBox
                  : innerCell;

              Color bg;
              if (isSelected) {
                bg = Colors.blue.shade100;
              } else if (isFixed) {
                bg = const Color(0xFFE8E8E8);
              } else if (hasError) {
                bg = Colors.red.shade50;
              } else {
                bg = Colors.white;
              }

              return GestureDetector(
                onTap: () => notifier.selectCell(r, c),
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      right: BorderSide(
                        color: Colors.black87,
                        width: borderRight,
                      ),
                      bottom: BorderSide(
                        color: Colors.black87,
                        width: borderBottom,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      value == 0 ? '' : value.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isFixed
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: hasError
                            ? Colors.red
                            : isFixed
                            ? Colors.black87
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  /// Sprawdza czy wartość w komórce [r,c] nie koliduje z innymi.
  bool _isCurrentlyValid(int r, int c, int value) {
    final grid = state.board.grid;

    // Wiersz
    for (int cc = 0; cc < 9; cc++) {
      if (cc != c && grid[r][cc] == value) return false;
    }
    // Kolumna
    for (int rr = 0; rr < 9; rr++) {
      if (rr != r && grid[rr][c] == value) return false;
    }
    // Blok 3×3
    final sr = (r ~/ 3) * 3;
    final sc = (c ~/ 3) * 3;
    for (int rr = sr; rr < sr + 3; rr++) {
      for (int cc = sc; cc < sc + 3; cc++) {
        if ((rr != r || cc != c) && grid[rr][cc] == value) return false;
      }
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Klawiatura numeryczna
// ─────────────────────────────────────────────────────────────────────────────

class _NumericKeyboard extends StatelessWidget {
  final SudokuState state;
  final SudokuNotifier notifier;

  const _NumericKeyboard({required this.state, required this.notifier});

  void _onKey(int value) {
    if (state.status == GameStatus.correctingOCR) {
      notifier.updateSelectedDraftCell(value);
    } else if (state.status == GameStatus.playing) {
      notifier.playSelectedCell(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          state.status == GameStatus.correctingOCR
              ? 'Popraw wartość komórki:'
              : 'Wpisz cyfrę:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cyfry 1–9
            ...List.generate(9, (i) => i + 1).map(
              (n) => _KeyButton(
                label: '$n',
                onTap: () => _onKey(n),
                color: const Color(0xFF1A1A2E),
              ),
            ),
            // Kasowanie
            _KeyButton(
              label: '✕',
              onTap: () => _onKey(0),
              color: Colors.red.shade700,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _KeyButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Przyciski akcji
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final SudokuState state;
  final SudokuNotifier notifier;

  const _ActionButtons({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final status = state.status;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (status == GameStatus.idle || status == GameStatus.error)
          ElevatedButton.icon(
            onPressed: () => notifier.scanBoard('fake_path'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('1. Skanuj (Mock)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
            ),
          ),

        if (status == GameStatus.correctingOCR)
          ElevatedButton.icon(
            onPressed: notifier.confirmScannedBoard,
            icon: const Icon(Icons.check_circle),
            label: const Text('2. Zatwierdź OCR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),

        if (status == GameStatus.playing || status == GameStatus.solved)
          ElevatedButton.icon(
            onPressed: notifier.solveBoard,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('3. Rozwiąż automatycznie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tekst pomocniczy
// ─────────────────────────────────────────────────────────────────────────────

class _HelpText extends StatelessWidget {
  final GameStatus status;
  const _HelpText({required this.status});

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      GameStatus.idle => 'Kliknij "Skanuj" aby załadować przykładową planszę.',
      GameStatus.scanning => 'Trwa skanowanie…',
      GameStatus.correctingOCR =>
        'Kliknij komórkę, wpisz cyfrę z klawiatury. "✕" kasuje. Zatwierdź gdy plansza jest poprawna.',
      GameStatus.playing =>
        'Kliknij komórkę i wpisz cyfrę. Błędne cyfry są oznaczone na czerwono.',
      GameStatus.solved => 'Plansza rozwiązana! Możesz zresetować grę.',
      GameStatus.error => 'Wystąpił błąd. Zresetuj i spróbuj ponownie.',
    };

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
    );
  }
}
