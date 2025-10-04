import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get openingBalancePaise => integer().withDefault(const Constant(0))();

  TextColumn get type => text().withDefault(const Constant('cash'))();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
