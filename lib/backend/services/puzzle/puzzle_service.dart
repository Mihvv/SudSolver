abstract class IPuzzleService {
  Future<List<List<int>>> fetchRandomPuzzle({String difficulty = 'medium'});
}

class PuzzleException implements Exception {
  final String message;
  const PuzzleException(this.message);

  @override
  String toString() => 'PuzzleException: $message';
}
