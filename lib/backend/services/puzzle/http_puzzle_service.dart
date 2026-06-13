import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'puzzle_service.dart';

class HttpPuzzleService implements IPuzzleService {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;

  const HttpPuzzleService({
    this.baseUrl = 'https://sugoku.onrender.com',
    this.timeout = const Duration(seconds: 45),
    this.maxRetries = 2,
  });

  @override
  Future<List<List<int>>> fetchRandomPuzzle({
    String difficulty = 'medium',
  }) async {
    PuzzleException? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await _fetchOnce(difficulty: difficulty);
      } on PuzzleException catch (e) {
        lastError = e;
        if (!e.isRetryable) rethrow;
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    throw lastError!;
  }

  Future<List<List<int>>> _fetchOnce({required String difficulty}) async {
    const validDifficulties = {'easy', 'medium', 'hard', 'random'};
    final level = validDifficulties.contains(difficulty)
        ? difficulty
        : 'medium';

    final uri = Uri.parse(
      '$baseUrl/board',
    ).replace(queryParameters: {'difficulty': level});

    final http.Response response;
    try {
      response = await http.get(uri).timeout(timeout);
    } on SocketException catch (e) {
      throw PuzzleException(
        'Brak połączenia z serwerem: ${e.message}',
        isRetryable: true,
      );
    } on TimeoutException {
      throw const PuzzleException(
        'Serwer nie odpowiada — spróbuj ponownie za chwilę.',
        isRetryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw PuzzleException(
        'Błąd serwera (HTTP ${response.statusCode}): '
        '${response.body.substring(0, response.body.length.clamp(0, 200))}',
        isRetryable: false,
      );
    }

    return _parseBoard(response.body);
  }

  List<List<int>> _parseBoard(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw PuzzleException(
        'Nieprawidłowy JSON z serwera: '
        '${body.substring(0, body.length.clamp(0, 100))}',
        isRetryable: false,
      );
    }

    final rawBoard = json['board'];
    if (rawBoard == null) {
      throw const PuzzleException(
        'Odpowiedź API nie zawiera klucza "board".',
        isRetryable: false,
      );
    }

    try {
      return (rawBoard as List)
          .map((row) => (row as List).map((v) => (v as num).toInt()).toList())
          .toList();
    } catch (_) {
      throw const PuzzleException(
        'Nieoczekiwany format planszy w odpowiedzi API.',
        isRetryable: false,
      );
    }
  }
}
