import 'package:drift/drift.dart';

class Settings extends Table {
  TextColumn get id => text()();

  TextColumn get currency => text().withDefault(const Constant('INR'))();

  TextColumn get theme => text().withDefault(const Constant('system'))();

  TextColumn get prefsJson => text().withDefault(const Constant('{}'))();

  BoolColumn get appLockEnabled => boolean().withDefault(const Constant(false))();

  TextColumn get appLockMethod => text().withDefault(const Constant('biometric'))();

  @override
  Set<Column> get primaryKey => {id};
}
