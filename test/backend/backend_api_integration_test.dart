@Tags(['integration'])
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sudsolver/backend/services/puzzle/http_puzzle_service.dart';
import 'package:sudsolver/backend/services/puzzle/puzzle_service.dart';
import 'package:sudsolver/backend/services/scanner/http_scanner_service.dart';
import 'package:sudsolver/backend/services/scanner/scanner_service.dart';

const _defaultSudokuImagePath = 'test/assets/sample_sudoku.jpg';

String get _sudokuImagePath =>
    Platform.environment['SUDOKU_IMAGE_PATH'] ?? _defaultSudokuImagePath;

void _assertValidSudokuGrid(List<List<int>> grid) {
  expect(grid.length, equals(9), reason: 'Grid must have 9 rows');
  for (int r = 0; r < 9; r++) {
    expect(grid[r].length, equals(9), reason: 'Row $r must have 9 columns');
    for (int c = 0; c < 9; c++) {
      expect(
        grid[r][c],
        inInclusiveRange(0, 9),
        reason: 'Cell [$r][$c] = ${grid[r][c]} is out of range',
      );
    }
  }
}

int _filledCells(List<List<int>> grid) =>
    grid.expand((r) => r).where((v) => v != 0).length;

void main() {
  const puzzleService = HttpPuzzleService(
    timeout: Duration(seconds: 60),
    maxRetries: 3,
  );

  group('[integration] HttpPuzzleService — sugoku.onrender.com', () {
    test('fetchRandomPuzzle(medium) returns a valid 9x9 grid', () async {
      final grid = await puzzleService.fetchRandomPuzzle(difficulty: 'medium');
      _assertValidSudokuGrid(grid);
    });

    test('easy puzzle has at least as many clues as hard', () async {
      final easy = await puzzleService.fetchRandomPuzzle(difficulty: 'easy');
      final hard = await puzzleService.fetchRandomPuzzle(difficulty: 'hard');

      expect(
        _filledCells(easy),
        greaterThanOrEqualTo(_filledCells(hard)),
        reason:
            'Easy (${_filledCells(easy)} filled) should be >= hard (${_filledCells(hard)} filled)',
      );
    });

    test('easy puzzle has at least 30 filled cells', () async {
      final grid = await puzzleService.fetchRandomPuzzle(difficulty: 'easy');
      expect(
        _filledCells(grid),
        greaterThanOrEqualTo(30),
        reason: 'Expected >= 30 clues, got ${_filledCells(grid)}',
      );
    });

    test('hard puzzle has at most 35 filled cells', () async {
      final grid = await puzzleService.fetchRandomPuzzle(difficulty: 'hard');
      expect(
        _filledCells(grid),
        lessThanOrEqualTo(35),
        reason: 'Expected <= 35 clues, got ${_filledCells(grid)}',
      );
    });

    test('two consecutive random puzzles differ', () async {
      final a = await puzzleService.fetchRandomPuzzle(difficulty: 'random');
      final b = await puzzleService.fetchRandomPuzzle(difficulty: 'random');

      final identical = List.generate(
        9,
        (r) => List.generate(9, (c) => a[r][c] == b[r][c]).every((v) => v),
      ).every((v) => v);

      expect(identical, isFalse, reason: 'Two random puzzles should differ');
    });

    test(
      'unknown difficulty falls back and returns a valid 9x9 grid',
      () async {
        final grid = await puzzleService.fetchRandomPuzzle(
          difficulty: 'impossible_level_99',
        );
        _assertValidSudokuGrid(grid);
      },
    );

    test('all four difficulty levels return valid grids', () async {
      for (final difficulty in ['easy', 'medium', 'hard', 'random']) {
        final grid = await puzzleService.fetchRandomPuzzle(
          difficulty: difficulty,
        );
        _assertValidSudokuGrid(grid);
      }
    });

    test('invalid base URL throws PuzzleException', () async {
      const badService = HttpPuzzleService(
        baseUrl: 'https://this-domain-does-not-exist-xyz.example.com',
        timeout: Duration(seconds: 5),
        maxRetries: 1,
      );

      expect(
        () => badService.fetchRandomPuzzle(),
        throwsA(isA<PuzzleException>()),
      );
    });

    test('1ms timeout throws on fetch', () async {
      const timeoutService = HttpPuzzleService(
        timeout: Duration(milliseconds: 1),
        maxRetries: 1,
      );

      Object? caught;
      try {
        await timeoutService.fetchRandomPuzzle();
      } catch (e) {
        caught = e;
      }

      expect(caught, isNotNull, reason: 'Should throw on 1ms timeout');
    });
  });

  group('[integration] HttpScannerService — lmhi.7o7.cx/sudsolver', () {
    const scannerService = HttpScannerService(
      baseUrl: 'https://lmhi.7o7.cx/sudsolver',
      timeout: Duration(seconds: 30),
    );

    test(
      'scanImage on a real sudoku image returns a valid 9x9 grid',
      () async {
        if (!File(_sudokuImagePath).existsSync()) {
          markTestSkipped(
            'Image not found: $_sudokuImagePath — set SUDOKU_IMAGE_PATH.',
          );
          return;
        }

        final grid = await scannerService.scanImage(_sudokuImagePath);
        _assertValidSudokuGrid(grid);
      },
      timeout: const Timeout(Duration(seconds: 40)),
    );

    test(
      'scanImage on a real sudoku image returns >= 17 filled cells',
      () async {
        if (!File(_sudokuImagePath).existsSync()) {
          markTestSkipped('Image not found: $_sudokuImagePath');
          return;
        }

        final grid = await scannerService.scanImage(_sudokuImagePath);
        expect(
          _filledCells(grid),
          greaterThanOrEqualTo(17),
          reason:
              'Valid sudoku needs at least 17 clues, got ${_filledCells(grid)}',
        );
      },
      timeout: const Timeout(Duration(seconds: 40)),
    );

    test('scanImage throws ScannerException for non-existent file', () async {
      expect(
        () => scannerService.scanImage('/nonexistent/path/image.jpg'),
        throwsA(
          isA<ScannerException>().having(
            (e) => e.message,
            'message',
            contains('Plik nie istnieje'),
          ),
        ),
      );
    });

    test(
      'scanImage throws ScannerException for an empty file',
      () async {
        final tmp = await File(
          '${Directory.systemTemp.path}/empty_sudoku.jpg',
        ).create();
        addTearDown(() => tmp.deleteSync());

        expect(
          () => scannerService.scanImage(tmp.path),
          throwsA(isA<ScannerException>()),
        );
      },
      timeout: const Timeout(Duration(seconds: 35)),
    );

    test(
      'scanImage throws ScannerException for a non-image file',
      () async {
        final tmp = await File(
          '${Directory.systemTemp.path}/not_an_image.jpg',
        ).writeAsString('this is not an image');
        addTearDown(() => tmp.deleteSync());

        expect(
          () => scannerService.scanImage(tmp.path),
          throwsA(isA<ScannerException>()),
        );
      },
      timeout: const Timeout(Duration(seconds: 35)),
    );

    test('invalid base URL throws ScannerException', () async {
      if (!File(_sudokuImagePath).existsSync()) {
        markTestSkipped('Image not found: $_sudokuImagePath');
        return;
      }

      const badScanner = HttpScannerService(
        baseUrl: 'https://this-domain-does-not-exist-xyz.example.com',
        timeout: Duration(seconds: 5),
      );

      expect(
        () => badScanner.scanImage(_sudokuImagePath),
        throwsA(isA<ScannerException>()),
      );
    });
  });

  group('[integration] Puzzle + Scanner — data shape consistency', () {
    test(
      'PuzzleService and ScannerService grids share the same structure',
      () async {
        final puzzle = await puzzleService.fetchRandomPuzzle();
        _assertValidSudokuGrid(puzzle);

        if (!File(_sudokuImagePath).existsSync()) return;

        const scanner = HttpScannerService(timeout: Duration(seconds: 30));
        final scanned = await scanner.scanImage(_sudokuImagePath);
        _assertValidSudokuGrid(scanned);

        expect(puzzle.length, equals(scanned.length));
        expect(puzzle[0].length, equals(scanned[0].length));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });
}
