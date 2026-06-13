// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sudoku_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SudokuRecordAdapter extends TypeAdapter<SudokuRecord> {
  @override
  final int typeId = 0;

  @override
  SudokuRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SudokuRecord(
      id: fields[0] as String,
      scannedAt: fields[1] as DateTime,
      initialGrid: (fields[2] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList(),
      solvedGrid: (fields[3] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      solveMode: fields[4] as SolveModeRecord,
      solveTime: fields[5] as Duration?,
      hintsUsed: fields[6] as int,
      userId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SudokuRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scannedAt)
      ..writeByte(2)
      ..write(obj.initialGrid)
      ..writeByte(3)
      ..write(obj.solvedGrid)
      ..writeByte(4)
      ..write(obj.solveMode)
      ..writeByte(5)
      ..write(obj.solveTime)
      ..writeByte(6)
      ..write(obj.hintsUsed)
      ..writeByte(7)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SudokuRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
