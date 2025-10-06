import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/analytics_models.dart';
import '../../../../app/theme/colors.dart';

class AnalyticsDonutChart extends StatelessWidget {
  const AnalyticsDonutChart({
    super.key,
    required this.segments,
    required this.selectedCategory,
    required this.onSegmentSelected,
  });

  final List<AnalyticsDonutSegment> segments;
  final String? selectedCategory;
  final ValueChanged<String> onSegmentSelected;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    final total = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.amountPaise,
    );
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final palette = _buildPalette(theme, tokens);

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 60,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions ||
                  response?.touchedSection == null) {
                return;
              }
              if (event is! PointerUpEvent) {
                return;
              }
              final index = response!.touchedSection!.touchedSectionIndex;
              if (index < 0 || index >= segments.length) {
                return;
              }
              onSegmentSelected(segments[index].category);
            },
          ),
          sections: [
            for (var i = 0; i < segments.length; i++)
              _buildSection(
                context,
                segment: segments[i],
                color: palette[i % palette.length],
                isSelected: segments[i].category == selectedCategory,
                totalPaise: total,
              ),
          ],
        ),
      ),
    );
  }

  List<Color> _buildPalette(ThemeData theme, PaisaColorTokens? tokens) {
    final base = <Color?>[
      tokens?.brandPrimary ?? theme.colorScheme.primary,
      tokens?.accentGold ?? theme.colorScheme.secondary,
      tokens?.stateInfo,
      tokens?.stateSuccess,
      tokens?.stateWarn,
      tokens?.stateError,
    ];
    return base
        .whereType<Color>()
        .map((color) => color)
        .toList(growable: false);
  }

  PieChartSectionData _buildSection(
    BuildContext context, {
    required AnalyticsDonutSegment segment,
    required Color color,
    required bool isSelected,
    required int totalPaise,
  }) {
    final radius = isSelected ? 70.0 : 62.0;
    final theme = Theme.of(context);
    final borderColor = theme.scaffoldBackgroundColor;

    return PieChartSectionData(
      color: color,
      value: segment.amountPaise.toDouble(),
      radius: radius,
      showTitle: false,
      borderSide: BorderSide(color: borderColor, width: 2),
    );
  }
}
