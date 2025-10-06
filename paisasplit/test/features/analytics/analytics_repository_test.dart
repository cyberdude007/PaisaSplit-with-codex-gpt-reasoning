import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/data/db.dart';
import 'package:paisasplit/features/analytics/data/analytics_repository.dart';

void main() {
  late PaisaSplitDatabase db;
  late AnalyticsRepository repository;

  setUp(() {
    db = PaisaSplitDatabase.forTesting(NativeDatabase.memory());
    repository = AnalyticsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AnalyticsRepository', () {
    setUp(() async {
      await _seedCoreData(db);
    });

    test('emits expenses scoped to current user participation', () async {
      final result = await repository.watchExpenses().first;

      expect(result, hasLength(3));
      expect(
        result.map((expense) => expense.id),
        orderedEquals(['e4', 'e1', 'e2']),
      );

      final lodging = result.firstWhere((expense) => expense.id == 'e1');
      expect(lodging.groupId, 'g_trip');
      expect(lodging.category, 'Lodging');
      expect(lodging.consumptionSharePaise, 150000);
      expect(lodging.outOfPocketPaise, 450000);

      final dinner = result.firstWhere((expense) => expense.id == 'e2');
      expect(dinner.consumptionSharePaise, 40000);
      expect(dinner.outOfPocketPaise, 0);

      final misc = result.firstWhere((expense) => expense.id == 'e4');
      expect(misc.date, DateTime(2025, 7, 20));
      expect(misc.consumptionSharePaise, 20000);
      expect(misc.outOfPocketPaise, 90000);
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
      .into(db.members)
      .insert(MembersCompanion.insert(id: 'm_other', name: 'Other'));

  await db.into(db.groups).insert(
        GroupsCompanion.insert(
          id: 'g_trip',
          name: 'Goa Trip',
          createdAt: DateTime(2025, 7, 30),
        ),
      );
  await db.into(db.groups).insert(
        GroupsCompanion.insert(
          id: 'g_other',
          name: 'Other Group',
          createdAt: DateTime(2025, 7, 30),
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
  await db.into(db.groupMembers).insert(
        GroupMembersCompanion.insert(
          id: 'gm4',
          groupId: 'g_other',
          memberId: 'm_anu',
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
          date: DateTime(2025, 8, 12),
          category: 'Food',
          notes: const Value.absent(),
          isDeleted: const Value(false),
        ),
      );
  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          id: 'e3',
          groupId: 'g_other',
          title: 'Cab',
          amountPaise: 50000,
          paidByMemberId: 'm_anu',
          date: DateTime(2025, 8, 15),
          category: 'Travel',
          notes: const Value.absent(),
          isDeleted: const Value(false),
        ),
      );
  await db.into(db.expenses).insert(
        ExpensesCompanion.insert(
          id: 'e4',
          groupId: 'g_trip',
          title: 'Snacks',
          amountPaise: 90000,
          paidByMemberId: 'me',
          date: DateTime(2025, 7, 20),
          category: 'Misc',
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

  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's7',
          expenseId: 'e3',
          memberId: 'm_anu',
          sharePaise: 25000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's8',
          expenseId: 'e3',
          memberId: 'm_other',
          sharePaise: 25000,
        ),
      );

  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's9',
          expenseId: 'e4',
          memberId: 'me',
          sharePaise: 20000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's10',
          expenseId: 'e4',
          memberId: 'm_anu',
          sharePaise: 35000,
        ),
      );
  await db.into(db.expenseSplits).insert(
        ExpenseSplitsCompanion.insert(
          id: 's11',
          expenseId: 'e4',
          memberId: 'm_rahul',
          sharePaise: 35000,
        ),
      );
}
