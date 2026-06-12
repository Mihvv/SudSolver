import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/sudoku_notifier.dart';
import '../../backend/providers/sudoku_state.dart';
import '../../backend/providers/auth_notifier.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'solve_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      sudokuProvider.select((s) => s.errorMessage),
    );
    final isLoading = ref.watch(
      sudokuProvider.select((s) => s.status == GameStatus.scanning),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('SudSolver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SudSolver',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Skanuj i rozwiązuj Sudoku',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 64),
              if (errorMessage != null) ...[
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const CameraScreen(fromGallery: false),
                  ),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Wczytaj z aparatu'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const CameraScreen(fromGallery: true),
                  ),
                ),
                icon: const Icon(Icons.photo_library),
                label: const Text('Wczytaj z galerii'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                  await ref
                      .read(sudokuProvider.notifier)
                      .fetchRandomPuzzle();
                  if (!context.mounted) return;
                  final status = ref.read(
                    sudokuProvider.select((s) => s.status),
                  );
                  if (status == GameStatus.playing) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SolveScreen(),
                      ),
                    );
                  }
                },
                icon: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.casino_outlined),
                label: Text(isLoading ? 'Pobieranie…' : 'Losowa plansza'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreen(),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Historie'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}