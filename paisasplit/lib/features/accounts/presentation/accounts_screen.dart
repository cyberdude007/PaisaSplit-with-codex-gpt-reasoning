import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_utils.dart';
import '../data/account_repo.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(defaultAccountSummaryProvider);
    final transactionsAsync = ref.watch(defaultAccountTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: summaryAsync.when(
            data: (summary) => transactionsAsync.when(
              data: (transactions) => _AccountsContent(
                summary: summary,
                transactions: transactions,
              ),
              error: (error, stackTrace) => const _AccountsError(message: 'Unable to load transactions.'),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => const _AccountsError(message: 'Unable to load account.'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

class _AccountsContent extends StatelessWidget {
  const _AccountsContent({
    required this.summary,
    required this.transactions,
  });

  final AccountSummary summary;
  final List<AccountLedgerEntry> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrencyFromPaise(summary.balancePaise),
                  style: balanceStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Running balance',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: transactions.isEmpty
              ? const _EmptyTransactionsState()
              : ListView.separated(
                  itemBuilder: (context, index) {
                    final entry = transactions[index];
                    return _AccountTransactionTile(entry: entry);
                  },
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemCount: transactions.length,
                ),
        ),
      ],
    );
  }
}

class _AccountTransactionTile extends StatelessWidget {
  const _AccountTransactionTile({required this.entry});

  final AccountLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = formatCurrencyFromPaise(entry.amountPaise);
    final amountColor = negativeAmountHintColor(context, entry.amountPaise);
    final subtitleTexts = <String>[
      formatDisplayDate(entry.createdAt),
      if (entry.note != null && entry.note!.trim().isNotEmpty) entry.note!.trim(),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(_formatLedgerType(entry.type), style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitleTexts.join('\n'),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        amountText,
        style: theme.textTheme.titleMedium?.copyWith(color: amountColor),
      ),
    );
  }

  String _formatLedgerType(String rawType) {
    if (rawType.isEmpty) {
      return '—';
    }

    final buffer = StringBuffer();
    for (var i = 0; i < rawType.length; i++) {
      final char = rawType[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
        continue;
      }
      if (char == char.toUpperCase()) {
        buffer.write(' ');
      }
      buffer.write(char);
    }
    return buffer.toString();
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No transactions yet',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _AccountsError extends StatelessWidget {
  const _AccountsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
