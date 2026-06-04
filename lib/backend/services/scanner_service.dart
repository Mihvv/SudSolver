abstract class IScannerService {
  /// Accepts a file path to an image and returns a 9x9 sudoku grid.
  /// Throws [ScannerException] on failure.
  Future<List<List<int>>> scanImage(String imagePath);
}

class ScannerException implements Exception {
  final String message;
  const ScannerException(this.message);

  @override
  String toString() => 'ScannerException: $message';
}
