import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paisasplit/features/accounts/data/account_repo.dart';
import 'package:paisasplit/features/accounts/presentation/accounts_screen.dart';

void main() {
  testWidgets('renders default account with empty state', (tester) async {
    const summary = AccountSummary(
      id: AccountRepository.defaultAccountId,
      name: AccountRepository.defaultAccountName,
      openingBalancePaise: 0,
      balancePaise: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccountSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          defaultAccountTransactionsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );

    await tester.pump();

    expect(find.text(AccountRepository.defaultAccountName), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('shows transactions with formatted amounts', (tester) async {
    const summary = AccountSummary(
      id: AccountRepository.defaultAccountId,
      name: AccountRepository.defaultAccountName,
      openingBalancePaise: 0,
      balancePaise: -330000,
    );

    final transactions = [
      AccountLedgerEntry(
        id: 'txn1',
        accountId: AccountRepository.defaultAccountId,
        type: 'expensePayment',
        amountPaise: -450000,
        createdAt: DateTime(2025, 8, 11),
        note: 'Hotel stay',
      ),
      AccountLedgerEntry(
        id: 'txn2',
        accountId: AccountRepository.defaultAccountId,
        type: 'settlementReceived',
        amountPaise: 120000,
        createdAt: DateTime(2025, 8, 12),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccountSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          defaultAccountTransactionsProvider.overrideWith((ref) => Stream.value(transactions)),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Expense Payment'), findsOneWidget);
    expect(find.text('Settlement Received'), findsOneWidget);
    expect(find.textContaining('12 Aug 2025'), findsOneWidget);
    expect(find.textContaining('Hotel stay'), findsOneWidget);
  });
}
