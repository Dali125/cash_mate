// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SalesModelAdapter extends TypeAdapter<SalesModel> {
  @override
  final int typeId = 0;

  @override
  SalesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalesModel()
      ..date = fields[0] as String?
      ..total = fields[1] as double?
      ..itemsSold = (fields[2] as List?)?.cast<CartItem>();
  }

  @override
  void write(BinaryWriter writer, SalesModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.total)
      ..writeByte(2)
      ..write(obj.itemsSold);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
