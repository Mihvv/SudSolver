import 'package:hive_flutter/hive_flutter.dart';
import '../models/sudoku_record.dart';

class HiveInit {
  HiveInit._();

  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SudokuRecordAdapter());
    }
  }
}
