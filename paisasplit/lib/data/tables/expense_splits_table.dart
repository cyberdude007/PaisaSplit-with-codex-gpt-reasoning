import 'package:drift/drift.dart';

import 'expenses_table.dart';
import 'members_table.dart';

@TableIndex(
  name: 'idx_splits_expense_member',
  columns: {#expenseId, #memberId},
)
class ExpenseSplits extends Table {
  TextColumn get id => text()();

  TextColumn get expenseId => text().references(
        Expenses,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get memberId => text().references(
        Members,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  IntColumn get sharePaise => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
