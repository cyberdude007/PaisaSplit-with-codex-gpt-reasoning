import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../data/analytics_models.dart';
import 'analytics_controller.dart';
import '../widgets/charts/analytics_donut_chart.dart';
import '../widgets/charts/analytics_trend_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewDataAsync = ref.watch(analyticsViewDataProvider);
    final selection = ref.watch(analyticsSelectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: viewDataAsync.when(
          data: (data) => _AnalyticsContent(selection: selection, data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AnalyticsError(message: error.toString()),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent({required this.selection, required this.data});

  final AnalyticsSelection selection;
  final AnalyticsViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!data.hasData) {
      return _AnalyticsEmptyState(selection: selection);
    }

    final controller = ref.read(analyticsSelectionProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Mode',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AnalyticsMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(mode.label),
                  selected: selection.mode == mode,
                  onSelected: (_) => controller.selectMode(mode),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Period',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AnalyticsPeriod.values.map((period) {
                final isSelected = selection.period == period;
                final isEnabled = period != AnalyticsPeriod.custom;
                return ChoiceChip(
                  label: Text(period.label),
                  selected: isSelected,
                  onSelected:
                      isEnabled ? (_) => controller.selectPeriod(period) : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _KpiRow(kpis: data.kpis),
          const SizedBox(height: 24),
          _AnalyticsCard(
            title: 'Category Breakdown',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnalyticsDonutChart(
                  segments: data.donutSegments,
                  selectedCategory: selection.categoryFilter,
                  onSegmentSelected: controller.toggleCategoryFilter,
                ),
                const SizedBox(height: 16),
                _DonutLegend(
                  segments: data.donutSegments,
                  selectedCategory: selection.categoryFilter,
                  onCategoryTap: controller.toggleCategoryFilter,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _AnalyticsCard(
            title: 'Trend',
            child: AnalyticsTrendChart(points: data.trendPoints),
          ),
          const SizedBox(height: 24),
          _AnalyticsCard(
            title: selection.categoryFilter == null
                ? 'Top Groups'
                : 'Top Groups · ${selection.categoryFilter}',
            child: _TopGroupsList(groups: data.topGroups),
          ),
          const SizedBox(height: 24),
          _AnalyticsCard(
            title: 'Top Categories',
            child: _TopCategoriesList(
              categories: data.topCategories,
              selectedCategory: selection.categoryFilter,
              onCategoryTap: controller.toggleCategoryFilter,
            ),
          ),
          if (selection.categoryFilter != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.clearCategoryFilter,
                child: const Text('Clear category filter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalyticsEmptyState extends ConsumerWidget {
  const _AnalyticsEmptyState({required this.selection});

  final AnalyticsSelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(analyticsSelectionProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.pie_chart_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            'No data for this period yet. Add an expense to get insights.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: AnalyticsPeriod.values.map((period) {
              final isEnabled = period != AnalyticsPeriod.custom;
              return ChoiceChip(
                label: Text(period.label),
                selected: selection.period == period,
                onSelected:
                    isEnabled ? (_) => controller.selectPeriod(period) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.message});

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis});

  final AnalyticsKpis kpis;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Total',
            value: formatCurrencyFromPaise(kpis.totalPaise),
            highlight: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Daily Avg',
            value: formatCurrencyFromPaise(kpis.dailyAveragePaise),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: '#Expenses',
            value: NumberFormat.decimalPattern(
              'en_IN',
            ).format(kpis.expenseCount),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: '#Active Groups',
            value: NumberFormat.decimalPattern(
              'en_IN',
            ).format(kpis.activeGroupCount),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  final String title;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    final backgroundColor = highlight
        ? tokens?.accentGold ?? theme.colorScheme.tertiary
        : tokens?.backgroundSurface ?? theme.colorScheme.surfaceContainerLow;
    final foregroundColor = highlight
        ? tokens?.accentOnGold ?? theme.colorScheme.onTertiary
        : theme.colorScheme.onSurface;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    return Card(
      color: tokens?.backgroundSurface ?? theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({
    required this.segments,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final List<AnalyticsDonutSegment> segments;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: segments.map((segment) {
        final isSelected = segment.category == selectedCategory;
        return _LegendChip(
          label: segment.category,
          amount: formatCurrencyFromPaise(segment.amountPaise),
          isSelected: isSelected,
          isInteractive: !segment.isOther,
          onTap: segment.isOther ? null : () => onCategoryTap(segment.category),
        );
      }).toList(),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.amount,
    required this.isSelected,
    required this.isInteractive,
    this.onTap,
  });

  final String label;
  final String amount;
  final bool isSelected;
  final bool isInteractive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    final background = isSelected
        ? (tokens?.brandPrimary ?? theme.colorScheme.primary)
        : (tokens?.backgroundSurface ?? theme.colorScheme.surfaceContainerLow);
    final foreground = isSelected
        ? tokens?.brandOnPrimary ?? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );

    if (!isInteractive) {
      return Opacity(
        opacity: 0.7,
        child: Card(color: background, child: content),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: content,
      ),
    );
  }
}

class _TopGroupsList extends StatelessWidget {
  const _TopGroupsList({required this.groups});

  final List<AnalyticsGroupTotal> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Text('No groups to display');
    }
    return Column(
      children: [
        for (final entry in groups)
          _MetricTile(
            title: entry.groupName,
            value: formatCurrencyFromPaise(entry.amountPaise),
          ),
      ],
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  const _TopCategoriesList({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final List<AnalyticsCategoryTotal> categories;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('No categories to display');
    }
    return Column(
      children: [
        for (final entry in categories)
          _MetricTile(
            title: entry.category,
            value: formatCurrencyFromPaise(entry.amountPaise),
            isSelected: entry.category == selectedCategory,
            onTap: () => onCategoryTap(entry.category),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    final background = isSelected
        ? (tokens?.brandPrimary ?? theme.colorScheme.primary)
        : Colors.transparent;
    final foreground = isSelected
        ? tokens?.brandOnPrimary ?? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(color: foreground),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
      ),
    );

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: tile,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: tile,
      ),
    );
  }
}
