import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'seed/seed_loader.dart';
import 'tables/account_txns_table.dart';
import 'tables/accounts_table.dart';
import 'tables/expense_splits_table.dart';
import 'tables/expenses_table.dart';
import 'tables/group_members_table.dart';
import 'tables/groups_table.dart';
import 'tables/members_table.dart';
import 'tables/settings_table.dart';
import 'tables/settlements_table.dart';
import 'tables/users_table.dart';

part 'db.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/paisasplit.db');
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    Users,
    Members,
    Groups,
    GroupMembers,
    Expenses,
    ExpenseSplits,
    Accounts,
    AccountTxns,
    Settlements,
    Settings,
  ],
)
class PaisaSplitDatabase extends _$PaisaSplitDatabase {
  PaisaSplitDatabase._(super.executor);

  static final PaisaSplitDatabase _instance = PaisaSplitDatabase._(_openConnection());

  static PaisaSplitDatabase get instance => _instance;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2 && to >= 2) {
            await _runMigration1to2Placeholder(m);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          final loader = SeedLoader(
            database: this,
            bundle: rootBundle,
          );
          await loader.seedIfNeeded();
        },
      );

  Future<void> _runMigration1to2Placeholder(Migrator m) async {
    // Placeholder for the schema migration from v1 to v2 per PRD v1.1 §10.
  }
}
