import 'package:drift/drift.dart';

class Members extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get upiId => text().nullable()();

  TextColumn get avatar => text().nullable()();

  BoolColumn get isGlobal => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
