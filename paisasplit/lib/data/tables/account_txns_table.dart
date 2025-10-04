import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'expenses_table.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'settlements_table.dart';

@TableIndex(
  name: 'idx_account_txns_account_date',
  columns: {#accountId, #createdAt},
)
class AccountTxns extends Table {
  TextColumn get id => text()();

  TextColumn get accountId => text().references(
        Accounts,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get type => text()();

  IntColumn get amountPaise => integer()();

  TextColumn get relatedGroupId => text().nullable().references(
        Groups,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get relatedMemberId => text().nullable().references(
        Members,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get relatedExpenseId => text().nullable().references(
        Expenses,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get relatedSettlementId => text().nullable().references(
        Settlements,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
