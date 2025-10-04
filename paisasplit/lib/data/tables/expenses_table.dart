import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';

@TableIndex(name: 'idx_expenses_group_date', columns: {#groupId, #date})
class Expenses extends Table {
  TextColumn get id => text()();

  TextColumn get groupId => text().references(
        Groups,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get title => text()();

  IntColumn get amountPaise => integer()();

  TextColumn get paidByMemberId => text().references(
        Members,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  DateTimeColumn get date => dateTime()();

  TextColumn get category => text()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
