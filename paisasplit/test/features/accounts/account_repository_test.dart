import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/data/db.dart';
import 'package:paisasplit/features/accounts/data/account_repo.dart';

void main() {
  late PaisaSplitDatabase db;
  late AccountRepository repository;

  setUp(() {
    db = PaisaSplitDatabase.forTesting(NativeDatabase.memory());
    repository = AccountRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureDefaultAccountExists inserts default account when missing', () async {
    await repository.ensureDefaultAccountExists();

    final defaultAccount = await (db.select(db.accounts)
          ..where((tbl) => tbl.id.equals(AccountRepository.defaultAccountId)))
        .getSingle();

    expect(defaultAccount.name, AccountRepository.defaultAccountName);
    expect(defaultAccount.openingBalancePaise, 0);

    await repository.ensureDefaultAccountExists();
    final accounts = await (db.select(db.accounts)
          ..where((tbl) => tbl.id.equals(AccountRepository.defaultAccountId)))
        .get();
    expect(accounts, hasLength(1));
  });

  test('watchAccountSummary emits updated balance when ledger changes', () async {
    await repository.ensureDefaultAccountExists();

    final summaryIterator = StreamIterator(
      repository.watchAccountSummary(AccountRepository.defaultAccountId),
    );

    expect(await summaryIterator.moveNext(), isTrue);
    final initial = summaryIterator.current;
    expect(initial.balancePaise, 0);

    await db.into(db.accountTxns).insert(
          AccountTxnsCompanion.insert(
            id: 'txn1',
            accountId: AccountRepository.defaultAccountId,
            type: 'expensePayment',
            amountPaise: -450000,
            createdAt: DateTime(2025, 8, 11),
          ),
        );

    expect(await summaryIterator.moveNext(), isTrue);
    final afterFirst = summaryIterator.current;
    expect(afterFirst.balancePaise, -450000);

    await db.into(db.accountTxns).insert(
          AccountTxnsCompanion.insert(
            id: 'txn2',
            accountId: AccountRepository.defaultAccountId,
            type: 'settlementReceived',
            amountPaise: 120000,
            createdAt: DateTime(2025, 8, 12),
          ),
        );

    expect(await summaryIterator.moveNext(), isTrue);
    final afterSecond = summaryIterator.current;
    expect(afterSecond.balancePaise, -330000);

    await summaryIterator.cancel();
  });

  test('watchAccountTransactions returns entries ordered by newest first', () async {
    await repository.ensureDefaultAccountExists();

    final iterator = StreamIterator(
      repository.watchAccountTransactions(AccountRepository.defaultAccountId),
    );

    expect(await iterator.moveNext(), isTrue);
    final initial = iterator.current;
    expect(initial, isEmpty);

    await db.into(db.accountTxns).insert(
          AccountTxnsCompanion.insert(
            id: 'txn1',
            accountId: AccountRepository.defaultAccountId,
            type: 'expensePayment',
            amountPaise: -120000,
            createdAt: DateTime(2025, 8, 10, 12),
          ),
        );

    expect(await iterator.moveNext(), isTrue);
    final afterFirst = iterator.current;
    expect(afterFirst.map((e) => e.id), ['txn1']);

    await db.into(db.accountTxns).insert(
          AccountTxnsCompanion.insert(
            id: 'txn2',
            accountId: AccountRepository.defaultAccountId,
            type: 'settlementReceived',
            amountPaise: 450000,
            createdAt: DateTime(2025, 8, 12, 8),
          ),
        );

    expect(await iterator.moveNext(), isTrue);
    final afterSecond = iterator.current;
    expect(afterSecond.map((e) => e.id), ['txn2', 'txn1']);

    await iterator.cancel();
  });
}
