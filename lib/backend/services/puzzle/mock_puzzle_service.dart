import 'puzzle_service.dart';

class MockPuzzleService implements IPuzzleService {
  const MockPuzzleService();

  @override
  Future<List<List<int>>> fetchRandomPuzzle({
    String difficulty = 'medium',
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return switch (difficulty) {
      'easy' => _easy,
      'hard' => _hard,
      _ => _medium,
    };
  }

  static const _easy = [
    [1, 0, 3, 0, 2, 0, 6, 0, 4],
    [0, 0, 0, 3, 0, 4, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 0, 0, 9, 0],
    [0, 0, 7, 0, 0, 0, 3, 0, 0],
    [0, 4, 0, 0, 0, 0, 0, 2, 0],
    [0, 0, 0, 0, 4, 0, 0, 0, 0],
    [0, 0, 0, 9, 0, 7, 0, 0, 0],
    [7, 0, 5, 0, 3, 0, 9, 0, 1],
  ];

  static const _medium = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  static const _hard = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 3, 0, 8, 5],
    [0, 0, 1, 0, 2, 0, 0, 0, 0],
    [0, 0, 0, 5, 0, 7, 0, 0, 0],
    [0, 0, 4, 0, 0, 0, 1, 0, 0],
    [0, 9, 0, 0, 0, 0, 0, 0, 0],
    [5, 0, 0, 0, 0, 0, 0, 7, 3],
    [0, 0, 2, 0, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 4, 0, 0, 0, 9],
  ];
}
