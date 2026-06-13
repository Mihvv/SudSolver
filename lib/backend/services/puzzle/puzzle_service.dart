abstract class IPuzzleService {
  Future<List<List<int>>> fetchRandomPuzzle({String difficulty = 'medium'});
}

class PuzzleException implements Exception {
  final String message;
  final bool isRetryable;

  const PuzzleException(this.message, {this.isRetryable = false});

  @override
  String toString() => 'PuzzleException: $message';
}
