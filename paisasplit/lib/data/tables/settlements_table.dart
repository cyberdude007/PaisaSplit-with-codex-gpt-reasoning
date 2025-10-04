import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';

@TableIndex(
  name: 'idx_settlements_group_date',
  columns: {#groupId, #date},
)
class Settlements extends Table {
  TextColumn get id => text()();

  TextColumn get groupId => text().references(
        Groups,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  @ReferenceName('settlementsFrom')
  TextColumn get fromMemberId => text().references(
        Members,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  @ReferenceName('settlementsTo')
  TextColumn get toMemberId => text().references(
        Members,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  IntColumn get amountPaise => integer()();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
