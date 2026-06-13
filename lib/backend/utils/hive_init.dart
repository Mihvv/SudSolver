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
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(_DurationAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(_SolveModeAdapter());
    }
  }
}

class _DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 1;

  @override
  Duration read(BinaryReader reader) =>
      Duration(microseconds: reader.readInt());

  @override
  void write(BinaryWriter writer, Duration obj) =>
      writer.writeInt(obj.inMicroseconds);
}

class _SolveModeAdapter extends TypeAdapter<SolveModeRecord> {
  @override
  final int typeId = 2;

  @override
  SolveModeRecord read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= SolveModeRecord.values.length) return SolveModeRecord.unsolved;
    return SolveModeRecord.values[index];
  }

  @override
  void write(BinaryWriter writer, SolveModeRecord obj) =>
      writer.writeByte(obj.index);
}
