import 'dart:async';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db.dart';

/// Repository responsible for interacting with the Accounts ledger tables.
class AccountRepository {
  AccountRepository(this._db);

  final PaisaSplitDatabase _db;

  static const String defaultAccountId = 'acc_default';
  static const String defaultAccountName = 'Default Account';

  Future<void> ensureDefaultAccountExists() async {
    await _db.transaction(() async {
      final query = _db.select(_db.accounts)
        ..where((tbl) => tbl.id.equals(defaultAccountId));
      final existing = await query.getSingleOrNull();
      if (existing != null) {
        return;
      }

      await _db.into(_db.accounts).insert(
            AccountsCompanion.insert(
              id: defaultAccountId,
              name: defaultAccountName,
              openingBalancePaise: const Value(0),
            ),
          );
    });
  }

  Stream<AccountSummary> watchAccountSummary(String accountId) {
    final accountStream = (_db.select(_db.accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .watchSingle();

    final totalTxnStream = _db
        .customSelect(
          'SELECT COALESCE(SUM(amount_paise), 0) AS total FROM account_txns WHERE account_id = ?',
          variables: [Variable<String>(accountId)],
          readsFrom: {_db.accountTxns},
        )
        .watchSingle()
        .map((row) {
          try {
            return row.read<int>('total');
          } catch (error) {
            if (error is ArgumentError || error is TypeError) {
              final bigIntValue = row.read<BigInt?>('total');
              if (bigIntValue != null) {
                return bigIntValue.toInt();
              }
              return 0;
            }
            rethrow;
          }
        });

    return Stream.multi((controller) {
      Account? latestAccount;
      int? latestTotal;

      void emitIfReady() {
        final account = latestAccount;
        final total = latestTotal;
        if (account == null || total == null) {
          return;
        }
        controller.add(
          AccountSummary(
            id: account.id,
            name: account.name,
            openingBalancePaise: account.openingBalancePaise,
            balancePaise: account.openingBalancePaise + total,
          ),
        );
      }

      final accountSub = accountStream.listen(
        (account) {
          latestAccount = account;
          emitIfReady();
        },
        onError: controller.addError,
      );

      final totalSub = totalTxnStream.listen(
        (total) {
          latestTotal = total;
          emitIfReady();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await accountSub.cancel();
        await totalSub.cancel();
      };
    });
  }

  Stream<List<AccountLedgerEntry>> watchAccountTransactions(String accountId) {
    final query = _db.select(_db.accountTxns)
      ..where((tbl) => tbl.accountId.equals(accountId))
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (txn) => AccountLedgerEntry(
                  id: txn.id,
                  accountId: txn.accountId,
                  type: txn.type,
                  amountPaise: txn.amountPaise,
                  createdAt: txn.createdAt,
                  note: txn.note,
                  relatedGroupId: txn.relatedGroupId,
                  relatedMemberId: txn.relatedMemberId,
                  relatedExpenseId: txn.relatedExpenseId,
                  relatedSettlementId: txn.relatedSettlementId,
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<AccountSummary> watchDefaultAccountSummary() =>
      watchAccountSummary(defaultAccountId);

  Stream<List<AccountLedgerEntry>> watchDefaultAccountTransactions() =>
      watchAccountTransactions(defaultAccountId);
}

class AccountSummary extends Equatable {
  const AccountSummary({
    required this.id,
    required this.name,
    required this.openingBalancePaise,
    required this.balancePaise,
  });

  final String id;
  final String name;
  final int openingBalancePaise;
  final int balancePaise;

  @override
  List<Object?> get props => [id, name, openingBalancePaise, balancePaise];
}

class AccountLedgerEntry extends Equatable {
  const AccountLedgerEntry({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountPaise,
    required this.createdAt,
    this.note,
    this.relatedGroupId,
    this.relatedMemberId,
    this.relatedExpenseId,
    this.relatedSettlementId,
  });

  final String id;
  final String accountId;
  final String type;
  final int amountPaise;
  final DateTime createdAt;
  final String? note;
  final String? relatedGroupId;
  final String? relatedMemberId;
  final String? relatedExpenseId;
  final String? relatedSettlementId;

  @override
  List<Object?> get props => [
        id,
        accountId,
        type,
        amountPaise,
        createdAt,
        note,
        relatedGroupId,
        relatedMemberId,
        relatedExpenseId,
        relatedSettlementId,
      ];
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = PaisaSplitDatabase.instance;
  return AccountRepository(db);
});

final defaultAccountSummaryProvider =
    StreamProvider<AccountSummary>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  await repository.ensureDefaultAccountExists();
  yield* repository.watchDefaultAccountSummary();
});

final defaultAccountTransactionsProvider =
    StreamProvider<List<AccountLedgerEntry>>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  await repository.ensureDefaultAccountExists();
  yield* repository.watchDefaultAccountTransactions();
});
