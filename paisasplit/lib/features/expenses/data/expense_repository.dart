import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/db.dart';
import '../../accounts/data/account_repo.dart';
import 'expense_models.dart';

typedef ExpenseNowBuilder = DateTime Function();
typedef ExpenseIdGenerator = String Function();

class ExpenseRepository {
  ExpenseRepository(
    this._db, {
    ExpenseIdGenerator? idGenerator,
    ExpenseNowBuilder? nowBuilder,
  })  : _generateId = idGenerator ?? const Uuid().v4,
        _nowBuilder = nowBuilder ?? DateTime.now;

  final PaisaSplitDatabase _db;
  final ExpenseIdGenerator _generateId;
  final ExpenseNowBuilder _nowBuilder;

  Future<ExpenseFormData> loadFormData() async {
    final groups = await _loadGroupsWithMembers();
    final accounts = await _loadAccounts();
    return ExpenseFormData(groups: groups, accounts: accounts);
  }

  Future<List<ExpenseGroupOption>> _loadGroupsWithMembers() async {
    final groupsQuery = _db.select(_db.groups)
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
      ]);

    final groups = await groupsQuery.get();
    final results = <ExpenseGroupOption>[];

    for (final group in groups) {
      final joinQuery = _db.select(_db.groupMembers).join([
        innerJoin(
          _db.members,
          _db.members.id.equalsExp(_db.groupMembers.memberId),
        ),
      ])
        ..where(_db.groupMembers.groupId.equals(group.id))
        ..orderBy([
          OrderingTerm(
            expression: _db.members.name,
            mode: OrderingMode.asc,
          ),
        ]);

      final rows = await joinQuery.get();
      final members = rows
          .map((row) => row.readTable(_db.members))
          .map((member) => GroupMemberOption(id: member.id, name: member.name))
          .toList(growable: false);

      results.add(
        ExpenseGroupOption(id: group.id, name: group.name, members: members),
      );
    }

    return results;
  }

  Future<List<ExpenseAccountOption>> _loadAccounts() async {
    await _ensureDefaultAccountExists();
    final accountsQuery = _db.select(_db.accounts)
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
      ]);
    final accounts = await accountsQuery.get();
    return accounts
        .map(
          (account) => ExpenseAccountOption(id: account.id, name: account.name),
        )
        .toList(growable: false);
  }

  Future<void> _ensureDefaultAccountExists() async {
    final existing = await (_db.select(_db.accounts)
          ..where(
            (tbl) => tbl.id.equals(AccountRepository.defaultAccountId),
          ))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }

    await _db.into(_db.accounts).insert(
          AccountsCompanion.insert(
            id: AccountRepository.defaultAccountId,
            name: AccountRepository.defaultAccountName,
            openingBalancePaise: const Value(0),
          ),
        );
  }

  Future<String> createExpense(ExpenseDraft draft) async {
    _validateDraft(draft);

    final expenseId = draft.id ?? _generateId();
    await _db.transaction(() async {
      await _db.into(_db.expenses).insert(
            ExpensesCompanion(
              id: Value(expenseId),
              groupId: Value(draft.groupId),
              title: Value(draft.title.trim()),
              amountPaise: Value(draft.amountPaise),
              paidByMemberId: Value(draft.paidByMemberId),
              date: Value(
                DateTime(draft.date.year, draft.date.month, draft.date.day),
              ),
              category: Value(draft.category.trim()),
              notes: _nullableTextValue(draft.notes),
              isDeleted: const Value(false),
            ),
          );

      await _insertSplits(expenseId, draft.splits);
      await _postInitialLedger(expenseId, draft);
    });

    return expenseId;
  }

  Future<void> updateExpense(ExpenseDraft draft) async {
    if (draft.id == null || draft.id!.isEmpty) {
      throw ArgumentError('Expense id is required for updates.');
    }
    _validateDraft(draft);

    final expenseId = draft.id!;
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.expenses,
      )..where((tbl) => tbl.id.equals(expenseId)))
          .getSingle();
      if (existing.isDeleted) {
        throw StateError('Cannot update a deleted expense.');
      }

      await (_db.update(
        _db.expenses,
      )..where((tbl) => tbl.id.equals(expenseId)))
          .write(
        ExpensesCompanion(
          title: Value(draft.title.trim()),
          groupId: Value(draft.groupId),
          amountPaise: Value(draft.amountPaise),
          paidByMemberId: Value(draft.paidByMemberId),
          date: Value(
            DateTime(draft.date.year, draft.date.month, draft.date.day),
          ),
          category: Value(draft.category.trim()),
          notes: _nullableTextValue(draft.notes),
        ),
      );

      await (_db.delete(
        _db.expenseSplits,
      )..where((tbl) => tbl.expenseId.equals(expenseId)))
          .go();
      await _insertSplits(expenseId, draft.splits);

      await _applyLedgerAdjustments(expenseId, draft);
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.expenses,
      )..where((tbl) => tbl.id.equals(expenseId)))
          .getSingle();
      if (existing.isDeleted) {
        return;
      }

      await (_db.update(_db.expenses)..where((tbl) => tbl.id.equals(expenseId)))
          .write(const ExpensesCompanion(isDeleted: Value(true)));

      await _reverseLedger(expenseId, groupId: existing.groupId);
    });
  }

  void _validateDraft(ExpenseDraft draft) {
    if (draft.amountPaise <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
    if (draft.title.trim().isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (draft.category.trim().isEmpty) {
      throw ArgumentError('Category is required.');
    }
    if (draft.groupId.isEmpty) {
      throw ArgumentError('Group is required.');
    }
    if (draft.accountId.isEmpty) {
      throw ArgumentError('Account is required.');
    }
    final totalShares = draft.splits.fold<int>(
      0,
      (sum, item) => sum + item.sharePaise,
    );
    if (totalShares != draft.amountPaise) {
      throw ArgumentError('Split shares must equal the total amount.');
    }
  }

  Future<void> _insertSplits(
    String expenseId,
    List<ExpenseSplitShareInput> splits,
  ) async {
    if (splits.isEmpty) {
      throw ArgumentError('At least one split is required.');
    }

    await _db.batch((batch) {
      batch.insertAll(
        _db.expenseSplits,
        splits.map(
          (split) => ExpenseSplitsCompanion.insert(
            id: _generateId(),
            expenseId: expenseId,
            memberId: split.memberId,
            sharePaise: split.sharePaise,
          ),
        ),
      );
    });
  }

  Future<void> _postInitialLedger(String expenseId, ExpenseDraft draft) async {
    if (draft.paidByMemberId != currentUserMemberId) {
      return;
    }

    await _db.into(_db.accountTxns).insert(
          AccountTxnsCompanion.insert(
            id: _generateId(),
            accountId: draft.accountId,
            type: 'expensePayment',
            amountPaise: -draft.amountPaise,
            relatedGroupId: Value(draft.groupId),
            relatedMemberId: Value(draft.paidByMemberId),
            relatedExpenseId: Value(expenseId),
            createdAt: _nowBuilder(),
            note: Value(draft.title.trim()),
          ),
        );
  }

  Future<void> _applyLedgerAdjustments(
    String expenseId,
    ExpenseDraft draft,
  ) async {
    final existingTxns = await (_db.select(
      _db.accountTxns,
    )..where((tbl) => tbl.relatedExpenseId.equals(expenseId)))
        .get();

    final existingPerAccount = <String, int>{};
    for (final txn in existingTxns) {
      existingPerAccount.update(
        txn.accountId,
        (value) => value + txn.amountPaise,
        ifAbsent: () => txn.amountPaise,
      );
    }

    final targetPerAccount = <String, int>{};
    if (draft.paidByMemberId == currentUserMemberId) {
      targetPerAccount[draft.accountId] = -draft.amountPaise;
    }

    final allAccountIds = <String>{
      ...existingPerAccount.keys,
      ...targetPerAccount.keys,
    };

    for (final accountId in allAccountIds) {
      final current = existingPerAccount[accountId] ?? 0;
      final target = targetPerAccount[accountId] ?? 0;
      final delta = target - current;
      if (delta == 0) {
        continue;
      }
      await _db.into(_db.accountTxns).insert(
            AccountTxnsCompanion.insert(
              id: _generateId(),
              accountId: accountId,
              type: 'adjustment',
              amountPaise: delta,
              relatedGroupId: Value(draft.groupId),
              relatedMemberId: const Value(currentUserMemberId),
              relatedExpenseId: Value(expenseId),
              createdAt: _nowBuilder(),
              note: Value('Adjustment for ${draft.title.trim()}'),
            ),
          );
    }
  }

  Future<void> _reverseLedger(
    String expenseId, {
    required String groupId,
  }) async {
    final existingTxns = await (_db.select(
      _db.accountTxns,
    )..where((tbl) => tbl.relatedExpenseId.equals(expenseId)))
        .get();
    if (existingTxns.isEmpty) {
      return;
    }

    final grouped = groupBy<AccountTxn, String>(
      existingTxns,
      (txn) => txn.accountId,
    );

    for (final entry in grouped.entries) {
      final total = entry.value.fold<int>(
        0,
        (sum, txn) => sum + txn.amountPaise,
      );
      if (total == 0) {
        continue;
      }
      await _db.into(_db.accountTxns).insert(
            AccountTxnsCompanion.insert(
              id: _generateId(),
              accountId: entry.key,
              type: 'adjustment',
              amountPaise: -total,
              relatedGroupId: Value(groupId),
              relatedMemberId: const Value(currentUserMemberId),
              relatedExpenseId: Value(expenseId),
              createdAt: _nowBuilder(),
              note: const Value('Expense deleted'),
            ),
          );
    }
  }

  Value<String?> _nullableTextValue(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const Value.absent();
    }
    return Value(trimmed);
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = PaisaSplitDatabase.instance;
  return ExpenseRepository(db);
});

final expenseFormDataProvider = FutureProvider<ExpenseFormData>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.loadFormData();
});
