import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/theme/colors.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_utils.dart';
import '../data/dashboard_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(child: Icon(Icons.person_outline)),
          ),
        ],
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          data: (data) => _DashboardContent(data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DashboardError(message: error.toString()),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final snapshot = data.snapshot;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: _SearchPlaceholder()),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SnapshotRow(snapshot: snapshot),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _SettleUpStrip(counterparties: data.counterparties),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _RecentActivitySection(activities: data.recentActivity),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();

    return TextField(
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search',
        filled: true,
        fillColor:
            tokens?.backgroundSurface ?? theme.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: tokens?.borderDivider ?? theme.dividerColor,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: tokens?.borderDivider ?? theme.dividerColor,
          ),
        ),
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SnapshotCard(
            title: 'You Owe',
            amountPaise: snapshot.youOwePaise,
            accent: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SnapshotCard(
            title: 'You Get',
            amountPaise: snapshot.youGetPaise,
            accent: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SnapshotCard(
            title: 'Net',
            amountPaise: snapshot.netBalancePaise,
            accent: false,
          ),
        ),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.title,
    required this.amountPaise,
    required this.accent,
  });

  final String title;
  final int amountPaise;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    final backgroundColor = accent
        ? tokens?.accentGold ?? theme.colorScheme.tertiary
        : tokens?.backgroundSurface ?? theme.colorScheme.surfaceContainer;
    final foregroundColor = accent
        ? tokens?.accentOnGold ?? theme.colorScheme.onTertiary
        : theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;
    final amountColor =
        negativeAmountHintColor(context, amountPaise) ?? foregroundColor;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formatCurrencyFromPaise(amountPaise),
              style: theme.textTheme.titleLarge?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettleUpStrip extends StatelessWidget {
  const _SettleUpStrip({required this.counterparties});

  final List<DashboardCounterparty> counterparties;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (counterparties.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settle Up', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('All settled for now.', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settle Up', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final counterparty in counterparties)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _CounterpartyChip(counterparty: counterparty),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterpartyChip extends StatelessWidget {
  const _CounterpartyChip({required this.counterparty});

  final DashboardCounterparty counterparty;

  @override
  Widget build(BuildContext context) {
    final amountText = formatCurrencyFromPaise(counterparty.amountPaise);
    final theme = Theme.of(context);
    final label = counterparty.isYouGet
        ? '${counterparty.memberName} owes you'
        : 'You owe ${counterparty.memberName}';

    return ActionChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            amountText,
            style: theme.textTheme.titleSmall?.copyWith(
              color:
                  negativeAmountHintColor(
                    context,
                    counterparty.isYouGet
                        ? counterparty.amountPaise
                        : -counterparty.amountPaise,
                  ) ??
                  theme.textTheme.titleSmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(counterparty.groupName, style: theme.textTheme.bodySmall),
        ],
      ),
      onPressed: () => context.goNamed(
        AppRoute.settleUp.name,
        pathParameters: {'groupId': counterparty.groupId},
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              Text(
                'No activity yet. Add an expense to get started.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ListView.separated(
                itemCount: activities.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _ActivityTile(activity: activity);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = activity.type == DashboardActivityType.expense
        ? Icons.receipt_long
        : Icons.swap_horiz;
    final amountText = formatCurrencyFromPaise(activity.amountPaise);
    final amountColor = negativeAmountHintColor(context, activity.amountPaise);
    final subtitleLines = <String>[
      activity.type == DashboardActivityType.expense
          ? '${activity.actorName} paid • ${activity.groupName}'
          : activity.amountPaise >= 0
          ? '${activity.actorName} paid you • ${activity.groupName}'
          : 'You paid ${activity.actorName} • ${activity.groupName}',
      formatDisplayDate(activity.date),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(activity.title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitleLines.join('\n'),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        amountText,
        style: theme.textTheme.titleMedium?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
