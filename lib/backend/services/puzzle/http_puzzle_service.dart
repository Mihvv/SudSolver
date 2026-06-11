import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'puzzle_service.dart';

class HttpPuzzleService implements IPuzzleService {
  final String baseUrl;
  final Duration timeout;

  const HttpPuzzleService({
    this.baseUrl = 'https://sugoku.onrender.com',
    this.timeout = const Duration(seconds: 20),
  });

  @override
  Future<List<List<int>>> fetchRandomPuzzle({
    String difficulty = 'medium',
  }) async {
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
      throw PuzzleException('Brak połączenia z serwerem: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw PuzzleException(
        'Błąd serwera (HTTP ${response.statusCode}): '
        '${response.body.substring(0, response.body.length.clamp(0, 200))}',
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
      );
    }

    final rawBoard = json['board'];
    if (rawBoard == null) {
      throw const PuzzleException('Odpowiedź API nie zawiera klucza "board".');
    }

    try {
      return (rawBoard as List)
          .map((row) => (row as List).map((v) => (v as num).toInt()).toList())
          .toList();
    } catch (_) {
      throw const PuzzleException(
        'Nieoczekiwany format planszy w odpowiedzi API.',
      );
    }
  }
}
