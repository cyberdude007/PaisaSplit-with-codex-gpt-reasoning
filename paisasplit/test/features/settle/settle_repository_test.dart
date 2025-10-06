import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/data/db.dart';
import 'package:paisasplit/features/accounts/data/account_repo.dart';
import 'package:paisasplit/features/settle/data/settle_repository.dart';

void main() {
  late PaisaSplitDatabase db;
  late SettleRepository repository;
  final now = DateTime(2025, 1, 1, 10, 0);
  final idQueue = <String>[];

  setUp(() {
    db = PaisaSplitDatabase.forTesting(NativeDatabase.memory());
    repository = SettleRepository(
      db,
      idGenerator: () => idQueue.removeAt(0),
      nowBuilder: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Group balance computations', () {
    setUp(() async {
      await _seedCoreData(db);
    });

    test('matches PRD worked example before settlements', () async {
      final summary = await repository.fetchGroupBalances('g_trip');
      expect(summary.totalToReceivePaise, 260000);
      expect(summary.totalToPayPaise, 260000);

      final byMember = {
        for (final balance in summary.memberBalances) balance.memberId: balance,
      };
      expect(byMember['me']?.netBalancePaise, 260000);
      expect(byMember['m_anu']?.netBalancePaise, -70000);
      expect(byMember['m_rahul']?.netBalancePaise, -190000);
    });

    test('records manual settlement and updates ledgers', () async {
      idQueue.addAll(['settlement_1', 'txn_1']);

      await repository.recordManualSettlement(
        groupId: 'g_trip',
        fromMemberId: 'm_rahul',
        toMemberId: 'me',
        amountPaise: 150000,
        date: DateTime(2025, 8, 12),
        note: 'Rahul paid cash',
      );

      final summary = await repository.fetchGroupBalances('g_trip');
      final byMember = {
        for (final balance in summary.memberBalances) balance.memberId: balance,
      };
      expect(summary.totalToReceivePaise, 110000);
      expect(summary.totalToPayPaise, 110000);
      expect(byMember['me']?.netBalancePaise, 110000);
      expect(byMember['m_rahul']?.netBalancePaise, -40000);
      expect(byMember['m_anu']?.netBalancePaise, -70000);

      final settlement = await (db.select(
        db.settlements,
      )..where((tbl) => tbl.id.equals('settlement_1')))
          .getSingle();
      expect(settlement.amountPaise, 150000);
      expect(settlement.note, 'Rahul paid cash');

      final txn = await (db.select(
        db.accountTxns,
      )..where((tbl) => tbl.relatedSettlementId.equals('settlement_1')))
          .getSingle();
      expect(txn.accountId, AccountRepository.defaultAccountId);
      expect(txn.amountPaise, 150000);
      expect(txn.note, 'Rahul paid cash');
    });
  });
}

Future<void> _seedCoreData(PaisaSplitDatabase db) async {
  await db
      .into(db.members)
      .insert(MembersCompanion.insert(id: 'me', name: 'Me'));
  await db
      .into(db.members)
      .insert(MembersCompanion.insert(id: 'm_anu', name: 'Anu'));
  await db
      .into(db.members)
      .insert(MembersCompanion.insert(id: 'm_rahul', name: 'Rahul'));

  await db.into(db.groups).insert(
        GroupsCompanion.insert(
          id: 'g_trip',
          name: 'Goa Trip',
          createdAt: DateTime(2025, 8, 10),
        ),
      );

  await db.into(db.groupMembers).insert(
        GroupMembersCompanion.insert(
          id: 'gm1',
          groupId: 'g_trip',
          memberId: 'me',
        ),
      );
  await db.into(db.groupMembers).insert(
        GroupMembersCompanion.insert(
          id: 'gm2',
          groupId: 'g_trip',
          memberId: 'm_anu',
        ),
      );
  await db.into(db.groupMembers).insert(
        GroupMembersCompanion.insert(
          id: 'gm3',
          groupId: 'g_trip',
          memberId: 'm_rahul',
        ),
      );

  await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          id: AccountRepository.defaultAccountId,
          name: AccountRepository.defaultAccountName,
          openingBalancePaise: const Value(0),
        ),
      );

  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          id: 'e1',
          groupId: 'g_trip',
          title: 'Hotel',
          amountPaise: 450000,
          paidByMemberId: 'me',
          date: DateTime(2025, 8, 11),
          category: 'Lodging',
          notes: const Value.absent(),
          isDeleted: const Value(false),
        ),
      );
  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          id: 'e2',
          groupId: 'g_trip',
          title: 'Dinner',
          amountPaise: 120000,
          paidByMemberId: 'm_anu',
          date: DateTime(2025, 8, 11),
          category: 'Food',
          notes: const Value.absent(),
          isDeleted: const Value(false),
        ),
      );

  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's1',
          expenseId: 'e1',
          memberId: 'me',
          sharePaise: 150000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's2',
          expenseId: 'e1',
          memberId: 'm_anu',
          sharePaise: 150000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's3',
          expenseId: 'e1',
          memberId: 'm_rahul',
          sharePaise: 150000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's4',
          expenseId: 'e2',
          memberId: 'me',
          sharePaise: 40000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's5',
          expenseId: 'e2',
          memberId: 'm_anu',
          sharePaise: 40000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's6',
          expenseId: 'e2',
          memberId: 'm_rahul',
          sharePaise: 40000,
        ),
      );
}
