import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/features/analytics/data/analytics_calculator.dart';
import 'package:paisasplit/features/analytics/data/analytics_models.dart';

void main() {
  group('calculateAnalyticsViewData', () {
    final today = DateTime(2025, 8, 31);
    final expenses = <AnalyticsExpense>[
      AnalyticsExpense(
        id: 'e_jul',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Travel',
        date: DateTime(2025, 7, 30),
        amountPaise: 80000,
        consumptionSharePaise: 50000,
        outOfPocketPaise: 80000,
      ),
      AnalyticsExpense(
        id: 'e1',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Food',
        date: DateTime(2025, 8, 5),
        amountPaise: 120000,
        consumptionSharePaise: 30000,
        outOfPocketPaise: 0,
      ),
      AnalyticsExpense(
        id: 'e2',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Lodging',
        date: DateTime(2025, 8, 11),
        amountPaise: 450000,
        consumptionSharePaise: 150000,
        outOfPocketPaise: 450000,
      ),
      AnalyticsExpense(
        id: 'e3',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Food',
        date: DateTime(2025, 8, 12),
        amountPaise: 120000,
        consumptionSharePaise: 40000,
        outOfPocketPaise: 0,
      ),
      AnalyticsExpense(
        id: 'e4',
        groupId: 'g_home',
        groupName: 'Home',
        category: 'Groceries',
        date: DateTime(2025, 8, 16),
        amountPaise: 60000,
        consumptionSharePaise: 20000,
        outOfPocketPaise: 0,
      ),
      AnalyticsExpense(
        id: 'e5',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Travel',
        date: DateTime(2025, 8, 23),
        amountPaise: 150000,
        consumptionSharePaise: 50000,
        outOfPocketPaise: 0,
      ),
      AnalyticsExpense(
        id: 'e6',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Misc',
        date: DateTime(2025, 8, 29),
        amountPaise: 80000,
        consumptionSharePaise: 10000,
        outOfPocketPaise: 0,
      ),
      AnalyticsExpense(
        id: 'e_sept',
        groupId: 'g_trip',
        groupName: 'Goa Trip',
        category: 'Food',
        date: DateTime(2025, 9, 3),
        amountPaise: 90000,
        consumptionSharePaise: 20000,
        outOfPocketPaise: 0,
      ),
    ];

    test('aggregates consumption KPIs and donut sum for this month', () {
      final view = calculateAnalyticsViewData(
        expenses: expenses,
        mode: AnalyticsMode.consumption,
        period: AnalyticsPeriod.thisMonth,
        today: today,
      );

      expect(view.kpis.totalPaise, 300000);
      expect(view.kpis.dailyAveragePaise, 9677);
      expect(view.kpis.expenseCount, 6);
      expect(view.kpis.activeGroupCount, 2);
      expect(view.hasData, isTrue);

      final donutSum = view.donutSegments.fold<int>(
        0,
        (sum, segment) => sum + segment.amountPaise,
      );
      expect(donutSum, view.kpis.totalPaise);

      expect(view.trendPoints.length, 31);
      expect(view.trendPoints.first.start, DateTime(2025, 8, 1));
      expect(view.trendPoints.last.end, DateTime(2025, 8, 31));
    });

    test('aggregates out-of-pocket for this month', () {
      final view = calculateAnalyticsViewData(
        expenses: expenses,
        mode: AnalyticsMode.outOfPocket,
        period: AnalyticsPeriod.thisMonth,
        today: today,
      );

      expect(view.kpis.totalPaise, 450000);
      expect(view.kpis.dailyAveragePaise, 14516);
      expect(view.kpis.expenseCount, 1);
      expect(view.kpis.activeGroupCount, 1);
    });

    test('creates Monday-aligned weekly buckets for last 30 days', () {
      final view = calculateAnalyticsViewData(
        expenses: expenses,
        mode: AnalyticsMode.consumption,
        period: AnalyticsPeriod.last30Days,
        today: today,
      );

      expect(view.trendPoints, isNotEmpty);
      expect(view.trendPoints.length, 5);
      expect(view.trendPoints.first.start, DateTime(2025, 7, 28));
      expect(view.trendPoints.last.end, DateTime(2025, 8, 31));
      final trendTotal = view.trendPoints.fold<int>(
        0,
        (sum, point) => sum + point.amountPaise,
      );
      expect(trendTotal, view.kpis.totalPaise);
    });

    test('filters top groups by category while preserving KPIs', () {
      final view = calculateAnalyticsViewData(
        expenses: expenses,
        mode: AnalyticsMode.consumption,
        period: AnalyticsPeriod.thisMonth,
        today: today,
        categoryFilter: 'Food',
      );

      expect(view.kpis.totalPaise, 300000);
      expect(view.topGroups, hasLength(1));
      expect(view.topGroups.first.groupName, 'Goa Trip');
    });

    test('adds other segment when more than six categories', () {
      final manyCategories = <AnalyticsExpense>[
        for (var i = 0; i < 7; i++)
          AnalyticsExpense(
            id: 'c$i',
            groupId: 'g_trip',
            groupName: 'Goa Trip',
            category: 'Category $i',
            date: DateTime(2025, 8, 10 + i),
            amountPaise: 1000 * (i + 1),
            consumptionSharePaise: 1000 * (i + 1),
            outOfPocketPaise: 0,
          ),
      ];

      final view = calculateAnalyticsViewData(
        expenses: manyCategories,
        mode: AnalyticsMode.consumption,
        period: AnalyticsPeriod.thisMonth,
        today: today,
      );

      expect(view.donutSegments.length, 7);
      final other = view.donutSegments.last;
      expect(other.isOther, isTrue);
      expect(other.amountPaise, 1000 * 1);
      final donutTotal = view.donutSegments.fold<int>(
        0,
        (sum, segment) => sum + segment.amountPaise,
      );
      expect(donutTotal, view.kpis.totalPaise);
    });
  });
}
