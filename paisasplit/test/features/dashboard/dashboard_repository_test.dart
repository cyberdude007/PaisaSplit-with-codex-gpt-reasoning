import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/data/db.dart';
import 'package:paisasplit/features/accounts/data/account_repo.dart';
import 'package:paisasplit/features/dashboard/data/dashboard_repository.dart';

void main() {
  late PaisaSplitDatabase db;
  late DashboardRepository repository;

  setUp(() {
    db = PaisaSplitDatabase.forTesting(NativeDatabase.memory());
    repository = DashboardRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DashboardRepository', () {
    setUp(() async {
      await _seedCoreData(db);
    });

    test('computes snapshot and counterparties from seed', () async {
      final data = await repository.watchDashboard().first;

      expect(data.snapshot.youOwePaise, 0);
      expect(data.snapshot.youGetPaise, 260000);
      expect(data.snapshot.netBalancePaise, 260000);

      expect(data.counterparties, hasLength(2));
      expect(
        data.counterparties.map((c) => c.memberName),
        containsAll(['Rahul', 'Anu']),
      );
      final rahul = data.counterparties.firstWhere(
        (c) => c.memberName == 'Rahul',
      );
      expect(rahul.amountPaise, 190000);
      expect(rahul.direction, CounterpartyDirection.youGet);

      final activities = data.recentActivity;
      expect(activities, hasLength(2));
      expect(
        activities.map((a) => a.amountPaise),
        containsAll([300000, -40000]),
      );
    });

    test('reflects settlements in snapshot and activity', () async {
      final completerFirst = Completer<DashboardData>();
      final completerSecond = Completer<DashboardData>();

      final subscription = repository.watchDashboard().listen((event) {
        if (!completerFirst.isCompleted) {
          completerFirst.complete(event);
        } else if (!completerSecond.isCompleted) {
          completerSecond.complete(event);
        }
      });

      final initial = await completerFirst.future;
      expect(initial.snapshot.youGetPaise, 260000);

      await db
          .into(db.settlements)
          .insert(
            SettlementsCompanion.insert(
              id: 'settlement_1',
              groupId: 'g_trip',
              fromMemberId: 'm_rahul',
              toMemberId: 'me',
              amountPaise: 150000,
              date: DateTime(2025, 8, 12),
              note: const Value(null),
            ),
          );

      final updated = await completerSecond.future.timeout(
        const Duration(seconds: 5),
      );
      await subscription.cancel();

      expect(updated.snapshot.youGetPaise, 110000);
      expect(updated.counterparties, hasLength(2));
      final rahul = updated.counterparties.firstWhere(
        (c) => c.memberName == 'Rahul',
      );
      expect(rahul.amountPaise, 40000);
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

  await db
      .into(db.groups)
      .insert(
        GroupsCompanion.insert(
          id: 'g_trip',
          name: 'Goa Trip',
          createdAt: DateTime(2025, 8, 10),
        ),
      );

  await db
      .into(db.groupMembers)
      .insert(
        GroupMembersCompanion.insert(
          id: 'gm1',
          groupId: 'g_trip',
          memberId: 'me',
        ),
      );
  await db
      .into(db.groupMembers)
      .insert(
        GroupMembersCompanion.insert(
          id: 'gm2',
          groupId: 'g_trip',
          memberId: 'm_anu',
        ),
      );
  await db
      .into(db.groupMembers)
      .insert(
        GroupMembersCompanion.insert(
          id: 'gm3',
          groupId: 'g_trip',
          memberId: 'm_rahul',
        ),
      );

  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: AccountRepository.defaultAccountId,
          name: AccountRepository.defaultAccountName,
          openingBalancePaise: const Value(0),
        ),
      );

  await db
      .into(db.expenses)
      .insert(
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
  await db
      .into(db.expenses)
      .insert(
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

  await db
      .into(db.expenseSplits)
      .insert(
        ExpenseSplitsCompanion.insert(
          id: 's1',
          expenseId: 'e1',
          memberId: 'me',
          sharePaise: 150000,
        ),
      );
  await db
      .into(db.expenseSplits)
      .insert(
        ExpenseSplitsCompanion.insert(
          id: 's2',
          expenseId: 'e1',
          memberId: 'm_anu',
          sharePaise: 150000,
        ),
      );
  await db
      .into(db.expenseSplits)
      .insert(
        ExpenseSplitsCompanion.insert(
          id: 's3',
          expenseId: 'e1',
          memberId: 'm_rahul',
          sharePaise: 150000,
        ),
      );
  await db
      .into(db.expenseSplits)
      .insert(
        ExpenseSplitsCompanion.insert(
          id: 's4',
          expenseId: 'e2',
          memberId: 'me',
          sharePaise: 40000,
        ),
      );
  await db
      .into(db.expenseSplits)
      .insert(
        ExpenseSplitsCompanion.insert(
          id: 's5',
          expenseId: 'e2',
          memberId: 'm_anu',
          sharePaise: 40000,
        ),
      );
  await db
      .into(db.expenseSplits)
      .insert(
        ExpenseSplitsCompanion.insert(
          id: 's6',
          expenseId: 'e2',
          memberId: 'm_rahul',
          sharePaise: 40000,
        ),
      );
}
