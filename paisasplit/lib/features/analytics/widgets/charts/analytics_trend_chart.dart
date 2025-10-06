import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/analytics_models.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/formatters/currency_formatter.dart';

class AnalyticsTrendChart extends StatelessWidget {
  const AnalyticsTrendChart({super.key, required this.points});

  final List<AnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 200);
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<PaisaColorTokens>();
    final barColor = tokens?.brandPrimary ?? theme.colorScheme.primary;
    final values = points
        .map((point) => point.amountPaise.toDouble() / 100)
        .toList(growable: false);
    final maxValue = values.fold<double>(0, math.max);
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    const locale = 'en_IN';

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: [
            for (var index = 0; index < points.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    color: barColor,
                    borderRadius: BorderRadius.circular(8),
                    width: 18,
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 60,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0) {
                    return const SizedBox.shrink();
                  }
                  final paise = (value * 100).round();
                  if (paise == 0) {
                    return Text('0', style: theme.textTheme.labelSmall);
                  }
                  return Text(
                    formatCompactCurrency(paise),
                    style: theme.textTheme.labelSmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final point = points[index];
                  final formatter = DateFormat('d MMM', locale);
                  if (point.isDaily) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        formatter.format(point.start),
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  }
                  final startLabel = formatter.format(point.start);
                  final endLabel = formatter.format(point.end);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$startLabel\n$endLabel',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
