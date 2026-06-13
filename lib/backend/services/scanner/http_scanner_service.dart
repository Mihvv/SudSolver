import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'scanner_service.dart';

class HttpScannerService implements IScannerService {
  final String baseUrl;
  final Duration timeout;

  const HttpScannerService({
    this.baseUrl = 'https://lmhi.7o7.cx/sudsolver',
    this.timeout = const Duration(seconds: 20),
  });

  @override
  Future<List<List<int>>> scanImage(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw ScannerException('Plik nie istnieje: $imagePath');
    }

    final uri = Uri.parse('$baseUrl/recognize');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imagePath,
          contentType: MediaType('image', _extensionToSubtype(imagePath)),
        ),
      );

    final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(timeout);
    } on SocketException catch (e) {
      throw ScannerException('Brak połączenia z serwerem: ${e.message}');
    }

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 422) {
      final detail = _extractDetail(body);
      throw ScannerException('Nie udało się rozpoznać planszy: $detail');
    }

    if (streamed.statusCode != 200) {
      throw ScannerException(
        'Błąd serwera (HTTP ${streamed.statusCode}): ${body.substring(0, body.length.clamp(0, 200))}',
      );
    }

    return _parseGrid(body);
  }

  static String _extensionToSubtype(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      _ => 'jpeg',
    };
  }

  List<List<int>> _parseGrid(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ScannerException(
        'Nieprawidłowy JSON z serwera: ${body.substring(0, body.length.clamp(0, 100))}',
      );
    }

    final rawGrid = json['grid'];
    if (rawGrid == null) {
      throw const ScannerException('Odpowiedź API nie zawiera klucza "grid".');
    }

    try {
      return (rawGrid as List)
          .map((row) => (row as List).map((v) => (v as num).toInt()).toList())
          .toList();
    } catch (_) {
      throw const ScannerException(
        'Nieoczekiwany format siatki w odpowiedzi API.',
      );
    }
  }

  String _extractDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}
