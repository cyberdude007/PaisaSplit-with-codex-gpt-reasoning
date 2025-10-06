import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/data/db.dart';
import 'package:paisasplit/features/accounts/data/account_repo.dart';
import 'package:paisasplit/features/expenses/data/expense_models.dart';
import 'package:paisasplit/features/expenses/data/expense_repository.dart';

void main() {
  late PaisaSplitDatabase db;
  late ExpenseRepository repository;
  late int idCounter;

  setUp(() async {
    db = PaisaSplitDatabase.forTesting(NativeDatabase.memory());
    idCounter = 0;
    repository = ExpenseRepository(
      db,
      idGenerator: () {
        idCounter += 1;
        return 'gen_$idCounter';
      },
      nowBuilder: () => DateTime(2025, 1, 1, 12),
    );

    await db
        .into(db.members)
        .insert(MembersCompanion.insert(id: 'me', name: 'Me'));
    await db
        .into(db.members)
        .insert(MembersCompanion.insert(id: 'm_anu', name: 'Anu'));
    await db.into(db.groups).insert(
          GroupsCompanion.insert(
            id: 'g1',
            name: 'Trip',
            createdAt: DateTime(2025, 8, 10),
          ),
        );
    await db.into(db.groupMembers).insert(
          GroupMembersCompanion.insert(
            id: 'gm1',
            groupId: 'g1',
            memberId: 'me',
          ),
        );
    await db.into(db.groupMembers).insert(
          GroupMembersCompanion.insert(
            id: 'gm2',
            groupId: 'g1',
            memberId: 'm_anu',
          ),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: AccountRepository.defaultAccountId,
            name: AccountRepository.defaultAccountName,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  ExpenseDraft buildDraft({
    required int amountPaise,
    required String paidBy,
    List<ExpenseSplitShareInput>? splits,
  }) {
    return ExpenseDraft(
      groupId: 'g1',
      title: 'Dinner',
      amountPaise: amountPaise,
      category: 'Food',
      paidByMemberId: paidBy,
      date: DateTime(2025, 8, 12),
      accountId: AccountRepository.defaultAccountId,
      notes: null,
      splits: splits ??
          [
            ExpenseSplitShareInput(
              memberId: 'me',
              sharePaise: (amountPaise ~/ 2) + (amountPaise % 2),
            ),
            ExpenseSplitShareInput(
              memberId: 'm_anu',
              sharePaise: amountPaise ~/ 2,
            ),
          ],
    );
  }

  test(
    'createExpense inserts expense, splits, and ledger when payer is me',
    () async {
      final draft = buildDraft(amountPaise: 12000, paidBy: 'me');

      final expenseId = await repository.createExpense(draft);

      final expense = await (db.select(
        db.expenses,
      )..where((tbl) => tbl.id.equals(expenseId)))
          .getSingle();
      expect(expense.title, 'Dinner');
      expect(expense.amountPaise, 12000);

      final splits = await (db.select(
        db.expenseSplits,
      )..where((tbl) => tbl.expenseId.equals(expenseId)))
          .get();
      expect(splits, hasLength(2));
      expect(splits.map((s) => s.sharePaise), containsAll(<int>[6000, 6000]));

      final txns = await (db.select(
        db.accountTxns,
      )..where((tbl) => tbl.relatedExpenseId.equals(expenseId)))
          .get();
      expect(txns, hasLength(1));
      expect(txns.first.amountPaise, -12000);
      expect(txns.first.type, 'expensePayment');
    },
  );

  test('createExpense skips ledger when payer is not me', () async {
    final draft = buildDraft(amountPaise: 12000, paidBy: 'm_anu');

    final expenseId = await repository.createExpense(draft);

    final txns = await (db.select(
      db.accountTxns,
    )..where((tbl) => tbl.relatedExpenseId.equals(expenseId)))
        .get();
    expect(txns, isEmpty);
  });

  test('updateExpense posts adjustment when amount changes', () async {
    final expenseId = await repository.createExpense(
      buildDraft(amountPaise: 12000, paidBy: 'me'),
    );

    await repository.updateExpense(
      buildDraft(
        amountPaise: 15000,
        paidBy: 'me',
        splits: const [
          ExpenseSplitShareInput(memberId: 'me', sharePaise: 7500),
          ExpenseSplitShareInput(memberId: 'm_anu', sharePaise: 7500),
        ],
      ).copyWith(id: expenseId),
    );

    final txns = await (db.select(
      db.accountTxns,
    )..where((tbl) => tbl.relatedExpenseId.equals(expenseId)))
        .get();
    expect(txns, hasLength(2));
    final total = txns.fold<int>(0, (sum, txn) => sum + txn.amountPaise);
    expect(total, -15000);
    expect(txns.last.type, 'adjustment');
  });

  test('deleteExpense soft deletes and posts reversing adjustment', () async {
    final expenseId = await repository.createExpense(
      buildDraft(amountPaise: 8000, paidBy: 'me'),
    );

    await repository.deleteExpense(expenseId);

    final expense = await (db.select(
      db.expenses,
    )..where((tbl) => tbl.id.equals(expenseId)))
        .getSingle();
    expect(expense.isDeleted, isTrue);

    final txns = await (db.select(
      db.accountTxns,
    )..where((tbl) => tbl.relatedExpenseId.equals(expenseId)))
        .get();
    expect(txns, hasLength(2));
    final total = txns.fold<int>(0, (sum, txn) => sum + txn.amountPaise);
    expect(total, 0);
    expect(txns.last.type, 'adjustment');
  });
}
