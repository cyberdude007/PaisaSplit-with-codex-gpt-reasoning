import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/db.dart';
import '../../accounts/data/account_repo.dart';
import '../../expenses/data/expense_models.dart';
import 'settle_models.dart';

typedef SettlementIdGenerator = String Function();
typedef SettlementNowBuilder = DateTime Function();

class SettleRepository {
  SettleRepository(
    this._db, {
    SettlementIdGenerator? idGenerator,
    SettlementNowBuilder? nowBuilder,
  }) : _generateId = idGenerator ?? const Uuid().v4,
       _nowBuilder = nowBuilder ?? DateTime.now;

  final PaisaSplitDatabase _db;
  final SettlementIdGenerator _generateId;
  final SettlementNowBuilder _nowBuilder;

  Stream<GroupBalanceSummary> watchGroupBalances(String groupId) {
    final groupStream = (_db.select(
      _db.groups,
    )..where((tbl) => tbl.id.equals(groupId))).watchSingle();
    final membersStream = _watchGroupMembers(groupId);
    final expensesStream = _watchGroupExpenses(groupId);
    final splitsStream = _watchGroupExpenseSplits(groupId);
    final settlementsStream = _watchGroupSettlements(groupId);

    return Stream.multi((controller) {
      Group? latestGroup;
      List<_MemberDetail>? latestMembers;
      List<_ExpenseDetail>? latestExpenses;
      List<_ExpenseSplitDetail>? latestSplits;
      List<Settlement>? latestSettlements;

      void emitIfReady() {
        final group = latestGroup;
        final members = latestMembers;
        final expenses = latestExpenses;
        final splits = latestSplits;
        final settlements = latestSettlements;
        if (group == null ||
            members == null ||
            expenses == null ||
            splits == null ||
            settlements == null) {
          return;
        }

        try {
          final summary = _computeSummary(
            group: group,
            members: members,
            expenses: expenses,
            splits: splits,
            settlements: settlements,
          );
          controller.add(summary);
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        groupStream.listen((value) {
          latestGroup = value;
          emitIfReady();
        }, onError: controller.addError),
        membersStream.listen((value) {
          latestMembers = value;
          emitIfReady();
        }, onError: controller.addError),
        expensesStream.listen((value) {
          latestExpenses = value;
          emitIfReady();
        }, onError: controller.addError),
        splitsStream.listen((value) {
          latestSplits = value;
          emitIfReady();
        }, onError: controller.addError),
        settlementsStream.listen((value) {
          latestSettlements = value;
          emitIfReady();
        }, onError: controller.addError),
      ];

      controller
        ..onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        }
        ..onPause = () {
          for (final subscription in subscriptions) {
            subscription.pause();
          }
        }
        ..onResume = () {
          for (final subscription in subscriptions) {
            subscription.resume();
          }
        };
    });
  }

  Stream<List<SettlementHistoryEntry>> watchSettlementHistory(String groupId) {
    final toMembers = _db.members.createAlias('to_members');
    final query =
        (_db.select(_db.settlements)
              ..where((tbl) => tbl.groupId.equals(groupId))
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
              ]))
            .join([
              innerJoin(
                _db.members,
                _db.members.id.equalsExp(_db.settlements.fromMemberId),
              ),
              innerJoin(
                toMembers,
                toMembers.id.equalsExp(_db.settlements.toMemberId),
              ),
            ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => SettlementHistoryEntry(
              id: row.readTable(_db.settlements).id,
              fromMemberId: row.readTable(_db.members).id,
              fromMemberName: row.readTable(_db.members).name,
              toMemberId: row.readTable(toMembers).id,
              toMemberName: row.readTable(toMembers).name,
              amountPaise: row.readTable(_db.settlements).amountPaise,
              date: row.readTable(_db.settlements).date,
              note: row.readTable(_db.settlements).note,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<GroupBalanceSummary> fetchGroupBalances(String groupId) async {
    final group = await (_db.select(
      _db.groups,
    )..where((tbl) => tbl.id.equals(groupId))).getSingle();
    final members = await _loadGroupMembers(groupId);
    final expenses = await _loadGroupExpenses(groupId);
    final splits = await _loadGroupExpenseSplits(groupId);
    final settlements = await (_db.select(
      _db.settlements,
    )..where((tbl) => tbl.groupId.equals(groupId))).get();

    return _computeSummary(
      group: group,
      members: members,
      expenses: expenses,
      splits: splits,
      settlements: settlements,
    );
  }

  Future<List<SettlementHistoryEntry>> loadSettlementHistory(
    String groupId,
  ) async {
    final toMembers = _db.members.createAlias('to_members');
    final query =
        (_db.select(_db.settlements)
              ..where((tbl) => tbl.groupId.equals(groupId))
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
              ]))
            .join([
              innerJoin(
                _db.members,
                _db.members.id.equalsExp(_db.settlements.fromMemberId),
              ),
              innerJoin(
                toMembers,
                toMembers.id.equalsExp(_db.settlements.toMemberId),
              ),
            ]);

    final rows = await query.get();
    return rows
        .map(
          (row) => SettlementHistoryEntry(
            id: row.readTable(_db.settlements).id,
            fromMemberId: row.readTable(_db.members).id,
            fromMemberName: row.readTable(_db.members).name,
            toMemberId: row.readTable(toMembers).id,
            toMemberName: row.readTable(toMembers).name,
            amountPaise: row.readTable(_db.settlements).amountPaise,
            date: row.readTable(_db.settlements).date,
            note: row.readTable(_db.settlements).note,
          ),
        )
        .toList(growable: false);
  }

  Future<String> recordManualSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    if (fromMemberId == toMemberId) {
      throw ArgumentError('Settlement members must be different.');
    }
    if (amountPaise <= 0) {
      throw ArgumentError('Settlement amount must be positive.');
    }
    if (fromMemberId != currentUserMemberId &&
        toMemberId != currentUserMemberId) {
      throw ArgumentError('Manual settlements must involve the current user.');
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);

    return _db.transaction(() async {
      await _ensureGroupExists(groupId);
      await _ensureMembersBelongToGroup(groupId, {fromMemberId, toMemberId});
      await _ensureDefaultAccountExists();

      final settlementId = _generateId();
      final trimmedNote = note?.trim();

      await _db
          .into(_db.settlements)
          .insert(
            SettlementsCompanion.insert(
              id: settlementId,
              groupId: groupId,
              fromMemberId: fromMemberId,
              toMemberId: toMemberId,
              amountPaise: amountPaise,
              date: normalizedDate,
              note: _nullableTextValue(trimmedNote),
            ),
          );

      final counterpartyId = fromMemberId == currentUserMemberId
          ? toMemberId
          : fromMemberId;
      final counterparty = await (_db.select(
        _db.members,
      )..where((tbl) => tbl.id.equals(counterpartyId))).getSingle();

      final ledgerAmount = fromMemberId == currentUserMemberId
          ? -amountPaise
          : amountPaise;
      final ledgerNote = trimmedNote != null && trimmedNote.isNotEmpty
          ? trimmedNote
          : fromMemberId == currentUserMemberId
          ? 'Settlement paid to ${counterparty.name}'
          : 'Settlement received from ${counterparty.name}';

      await _db
          .into(_db.accountTxns)
          .insert(
            AccountTxnsCompanion.insert(
              id: _generateId(),
              accountId: AccountRepository.defaultAccountId,
              type: 'manualSettlement',
              amountPaise: ledgerAmount,
              relatedGroupId: Value(groupId),
              relatedMemberId: Value(counterpartyId),
              relatedSettlementId: Value(settlementId),
              createdAt: _nowBuilder(),
              note: Value(ledgerNote),
            ),
          );

      return settlementId;
    });
  }

  Future<void> _ensureGroupExists(String groupId) async {
    final existing = await (_db.select(
      _db.groups,
    )..where((tbl) => tbl.id.equals(groupId))).getSingleOrNull();
    if (existing == null) {
      throw StateError('Group $groupId was not found.');
    }
  }

  Future<void> _ensureMembersBelongToGroup(
    String groupId,
    Set<String> memberIds,
  ) async {
    final query = _db.select(_db.groupMembers)
      ..where(
        (tbl) => tbl.groupId.equals(groupId) & tbl.memberId.isIn(memberIds),
      );
    final rows = await query.get();
    final foundIds = rows.map((row) => row.memberId).toSet();
    if (!foundIds.containsAll(memberIds)) {
      throw StateError('All members must belong to the group.');
    }
  }

  Future<void> _ensureDefaultAccountExists() async {
    final existing =
        await (_db.select(_db.accounts)..where(
              (tbl) => tbl.id.equals(AccountRepository.defaultAccountId),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return;
    }

    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: AccountRepository.defaultAccountId,
            name: AccountRepository.defaultAccountName,
            openingBalancePaise: const Value(0),
          ),
        );
  }

  GroupBalanceSummary _computeSummary({
    required Group group,
    required List<_MemberDetail> members,
    required List<_ExpenseDetail> expenses,
    required List<_ExpenseSplitDetail> splits,
    required List<Settlement> settlements,
  }) {
    final netByMember = <String, int>{
      for (final member in members) member.memberId: 0,
    };

    final splitsByExpense = groupBy<_ExpenseSplitDetail, String>(
      splits,
      (split) => split.expenseId,
    );

    for (final expense in expenses) {
      final expenseSplits =
          splitsByExpense[expense.expenseId] ?? const <_ExpenseSplitDetail>[];
      for (final split in expenseSplits) {
        if (split.memberId == expense.paidByMemberId) {
          continue;
        }
        netByMember.update(
          split.memberId,
          (value) => value - split.sharePaise,
          ifAbsent: () => -split.sharePaise,
        );
      }

      final payerShare =
          expenseSplits
              .firstWhereOrNull(
                (split) => split.memberId == expense.paidByMemberId,
              )
              ?.sharePaise ??
          0;
      final payerNet = expense.amountPaise - payerShare;
      netByMember.update(
        expense.paidByMemberId,
        (value) => value + payerNet,
        ifAbsent: () => payerNet,
      );
    }

    for (final settlement in settlements) {
      netByMember.update(
        settlement.fromMemberId,
        (value) => value + settlement.amountPaise,
        ifAbsent: () => settlement.amountPaise,
      );
      netByMember.update(
        settlement.toMemberId,
        (value) => value - settlement.amountPaise,
        ifAbsent: () => -settlement.amountPaise,
      );
    }

    final memberBalances = members
        .map(
          (member) => MemberBalance(
            memberId: member.memberId,
            memberName: member.memberName,
            netBalancePaise: netByMember[member.memberId] ?? 0,
          ),
        )
        .sorted((a, b) => b.netBalancePaise.compareTo(a.netBalancePaise))
        .toList(growable: false);

    final totalToReceive = memberBalances
        .where((balance) => balance.netBalancePaise > 0)
        .fold<int>(0, (sum, item) => sum + item.netBalancePaise);
    final totalToPay = memberBalances
        .where((balance) => balance.netBalancePaise < 0)
        .fold<int>(0, (sum, item) => sum + item.netBalancePaise.abs());

    return GroupBalanceSummary(
      groupId: group.id,
      groupName: group.name,
      totalToReceivePaise: totalToReceive,
      totalToPayPaise: totalToPay,
      memberBalances: memberBalances,
    );
  }

  Stream<List<_MemberDetail>> _watchGroupMembers(String groupId) {
    final query =
        (_db.select(
          _db.groupMembers,
        )..where((tbl) => tbl.groupId.equals(groupId))).join([
          innerJoin(
            _db.members,
            _db.members.id.equalsExp(_db.groupMembers.memberId),
          ),
        ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _MemberDetail(
              memberId: row.readTable(_db.members).id,
              memberName: row.readTable(_db.members).name,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<_MemberDetail>> _loadGroupMembers(String groupId) async {
    final query =
        (_db.select(
          _db.groupMembers,
        )..where((tbl) => tbl.groupId.equals(groupId))).join([
          innerJoin(
            _db.members,
            _db.members.id.equalsExp(_db.groupMembers.memberId),
          ),
        ]);

    final rows = await query.get();
    return rows
        .map(
          (row) => _MemberDetail(
            memberId: row.readTable(_db.members).id,
            memberName: row.readTable(_db.members).name,
          ),
        )
        .toList(growable: false);
  }

  Stream<List<_ExpenseDetail>> _watchGroupExpenses(String groupId) {
    final query = _db.select(_db.expenses)
      ..where(
        (tbl) => tbl.groupId.equals(groupId) & tbl.isDeleted.equals(false),
      );
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _ExpenseDetail(
              expenseId: row.id,
              amountPaise: row.amountPaise,
              paidByMemberId: row.paidByMemberId,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<_ExpenseDetail>> _loadGroupExpenses(String groupId) async {
    final query = _db.select(_db.expenses)
      ..where(
        (tbl) => tbl.groupId.equals(groupId) & tbl.isDeleted.equals(false),
      );
    final rows = await query.get();
    return rows
        .map(
          (row) => _ExpenseDetail(
            expenseId: row.id,
            amountPaise: row.amountPaise,
            paidByMemberId: row.paidByMemberId,
          ),
        )
        .toList(growable: false);
  }

  Stream<List<_ExpenseSplitDetail>> _watchGroupExpenseSplits(String groupId) {
    final query = _db.customSelect(
      'SELECT es.id, es.expense_id, es.member_id, es.share_paise '
      'FROM expense_splits es '
      'INNER JOIN expenses e ON e.id = es.expense_id '
      'WHERE e.group_id = ? AND e.is_deleted = 0',
      variables: [Variable<String>(groupId)],
      readsFrom: {_db.expenseSplits, _db.expenses},
    );
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _ExpenseSplitDetail(
              splitId: row.read<String>('id'),
              expenseId: row.read<String>('expense_id'),
              memberId: row.read<String>('member_id'),
              sharePaise: row.read<int>('share_paise'),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<_ExpenseSplitDetail>> _loadGroupExpenseSplits(
    String groupId,
  ) async {
    final query = _db.customSelect(
      'SELECT es.id, es.expense_id, es.member_id, es.share_paise '
      'FROM expense_splits es '
      'INNER JOIN expenses e ON e.id = es.expense_id '
      'WHERE e.group_id = ? AND e.is_deleted = 0',
      variables: [Variable<String>(groupId)],
      readsFrom: {_db.expenseSplits, _db.expenses},
    );
    final rows = await query.get();
    return rows
        .map(
          (row) => _ExpenseSplitDetail(
            splitId: row.read<String>('id'),
            expenseId: row.read<String>('expense_id'),
            memberId: row.read<String>('member_id'),
            sharePaise: row.read<int>('share_paise'),
          ),
        )
        .toList(growable: false);
  }

  Stream<List<Settlement>> _watchGroupSettlements(String groupId) {
    final query = _db.select(_db.settlements)
      ..where((tbl) => tbl.groupId.equals(groupId));
    return query.watch();
  }

  Value<String?> _nullableTextValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const Value.absent();
    }
    return Value(raw);
  }
}

class _MemberDetail {
  const _MemberDetail({required this.memberId, required this.memberName});

  final String memberId;
  final String memberName;
}

class _ExpenseDetail {
  const _ExpenseDetail({
    required this.expenseId,
    required this.amountPaise,
    required this.paidByMemberId,
  });

  final String expenseId;
  final int amountPaise;
  final String paidByMemberId;
}

class _ExpenseSplitDetail {
  const _ExpenseSplitDetail({
    required this.splitId,
    required this.expenseId,
    required this.memberId,
    required this.sharePaise,
  });

  final String splitId;
  final String expenseId;
  final String memberId;
  final int sharePaise;
}

final settleRepositoryProvider = Provider<SettleRepository>((ref) {
  final db = PaisaSplitDatabase.instance;
  return SettleRepository(db);
});

final groupBalancesProvider =
    StreamProvider.family<GroupBalanceSummary, String>((ref, groupId) {
      final repository = ref.watch(settleRepositoryProvider);
      return repository.watchGroupBalances(groupId);
    });

final settlementHistoryProvider =
    StreamProvider.family<List<SettlementHistoryEntry>, String>((ref, groupId) {
      final repository = ref.watch(settleRepositoryProvider);
      return repository.watchSettlementHistory(groupId);
    });
