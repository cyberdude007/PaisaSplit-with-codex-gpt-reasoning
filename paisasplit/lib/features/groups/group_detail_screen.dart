import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../core/formatters/currency_formatter.dart';
import '../settle/data/settle_models.dart';
import '../settle/data/settle_repository.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(groupBalancesProvider(groupId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: summaryAsync.maybeWhen(
            data: (summary) => Text(summary.groupName),
            orElse: () => const Text('Group'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                context.goNamed(
                  AppRoute.groupSettings.name,
                  pathParameters: {'groupId': groupId},
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Members'),
              Tab(text: 'Balances'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _PlaceholderTab(label: 'Expenses list coming soon.'),
            const _PlaceholderTab(label: 'Members management coming soon.'),
            _BalancesTab(groupId: groupId),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(groupBalancesProvider(groupId));
    return summaryAsync.when(
      data: (summary) => _BalancesContent(groupId: groupId, summary: summary),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load balances: $error'),
        ),
      ),
    );
  }
}

class _BalancesContent extends StatelessWidget {
  const _BalancesContent({required this.groupId, required this.summary});

  final String groupId;
  final GroupBalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toReceive = formatCurrencyFromPaise(summary.totalToReceivePaise);
    final toPay = formatCurrencyFromPaise(summary.totalToPayPaise);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _BalanceCard(
                  title: 'To Receive',
                  amountLabel: toReceive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceCard(title: 'To Pay', amountLabel: toPay),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Members', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (summary.memberBalances.isEmpty)
            const Text('No members yet.')
          else
            ...summary.memberBalances.map(
              (balance) => _MemberBalanceTile(balance: balance),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  summary.totalToReceivePaise == 0 &&
                      summary.totalToPayPaise == 0
                  ? null
                  : () {
                      context.goNamed(
                        AppRoute.settleUp.name,
                        pathParameters: {'groupId': groupId},
                      );
                    },
              child: const Text('Settle Up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.title, required this.amountLabel});

  final String title;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(amountLabel, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _MemberBalanceTile extends StatelessWidget {
  const _MemberBalanceTile({required this.balance});

  final MemberBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = formatCurrencyFromPaise(balance.netBalancePaise.abs());
    final isPositive = balance.netBalancePaise > 0;
    final isNegative = balance.netBalancePaise < 0;
    final title = balance.isCurrentUser ? 'You' : balance.memberName;

    String subtitle;
    if (balance.isSettled) {
      subtitle = balance.isCurrentUser ? 'You are settled up' : 'Settled up';
    } else if (balance.isCurrentUser) {
      subtitle = isPositive ? 'You should receive' : 'You owe';
    } else {
      subtitle = isPositive ? 'Should receive' : 'Owes';
    }

    final amountStyle = theme.textTheme.titleMedium?.copyWith(
      color: isNegative
          ? negativeAmountHintColor(context, balance.netBalancePaise) ??
                theme.colorScheme.error
          : theme.colorScheme.primary,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(_initialFor(balance.memberName))),
        title: Text(title),
        subtitle: Text('$subtitle • $amount'),
        trailing: isNegative || isPositive
            ? Text(isPositive ? amount : '-$amount', style: amountStyle)
            : Text(amount, style: amountStyle),
      ),
    );
  }
}

String _initialFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}
