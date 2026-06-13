import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/sudoku_notifier.dart';
import '../../backend/providers/sudoku_state.dart';
import '../../backend/providers/auth_notifier.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'solve_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasShownLoginScreen = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final errorMessage = ref.watch(
      sudokuProvider.select((s) => s.errorMessage),
    );
    final isLoading = ref.watch(
      sudokuProvider.select((s) => s.status == GameStatus.scanning),
    );

    // Automatycznie wyjdź z LoginScreen gdy użytkownik się zaloguje
    authState.whenData((user) {
      if (_hasShownLoginScreen && user != null && context.mounted) {
        _hasShownLoginScreen = false;
        Navigator.pop(context);
      }
    });

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildUI(context, ref, errorMessage, isLoading, null),
      data: (currentUser) => _buildUI(context, ref, errorMessage, isLoading, currentUser),
    );
  }

  Widget _buildUI(
      BuildContext context,
      WidgetRef ref,
      String? errorMessage,
      bool isLoading,
      dynamic currentUser,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SudSolver'),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
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
              const SizedBox(height: 32),
              if (currentUser == null)
                TextButton(
                  onPressed: () {
                    _hasShownLoginScreen = true;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Zaloguj się'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}