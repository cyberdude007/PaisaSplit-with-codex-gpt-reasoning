import 'analytics_models.dart';

class _DateRange {
  _DateRange(this.start, this.end)
      : assert(!end.isBefore(start), 'end must not be before start');

  final DateTime start;
  final DateTime end;

  int get inclusiveDayCount => end.difference(start).inDays + 1;
}

DateTime _normalizeDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

_DateRange? _resolveRange(
  AnalyticsPeriod period,
  DateTime today, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final normalizedToday = _normalizeDate(today);
  switch (period) {
    case AnalyticsPeriod.thisMonth:
      final start = DateTime(normalizedToday.year, normalizedToday.month, 1);
      final end = DateTime(normalizedToday.year, normalizedToday.month + 1, 0);
      return _DateRange(start, end);
    case AnalyticsPeriod.lastMonth:
      final start = DateTime(normalizedToday.year, normalizedToday.month, 1);
      final previousMonthEnd = start.subtract(const Duration(days: 1));
      final previousMonthStart = DateTime(
        previousMonthEnd.year,
        previousMonthEnd.month,
        1,
      );
      return _DateRange(previousMonthStart, previousMonthEnd);
    case AnalyticsPeriod.last30Days:
      final end = normalizedToday;
      final start = end.subtract(const Duration(days: 29));
      return _DateRange(start, end);
    case AnalyticsPeriod.custom:
      if (customStart == null || customEnd == null) {
        return null;
      }
      final normalizedStart = _normalizeDate(customStart);
      final normalizedEnd = _normalizeDate(customEnd);
      if (normalizedEnd.isBefore(normalizedStart)) {
        return null;
      }
      return _DateRange(normalizedStart, normalizedEnd);
  }
}

DateTime _startOfWeek(DateTime value) {
  final weekdayIndex = value.weekday - DateTime.monday;
  return _normalizeDate(value.subtract(Duration(days: weekdayIndex)));
}

List<AnalyticsTrendPoint> _buildDailyTrend(
  Iterable<_ExpenseSlice> expenses,
  _DateRange range,
) {
  final amountsByDay = <DateTime, int>{};
  for (final slice in expenses) {
    amountsByDay.update(
      slice.expense.date,
      (value) => value + slice.amountPaise,
      ifAbsent: () => slice.amountPaise,
    );
  }

  final points = <AnalyticsTrendPoint>[];
  var cursor = range.start;
  while (!cursor.isAfter(range.end)) {
    final amount = amountsByDay[cursor] ?? 0;
    points.add(
      AnalyticsTrendPoint(start: cursor, end: cursor, amountPaise: amount),
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  return points;
}

List<AnalyticsTrendPoint> _buildWeeklyTrend(
  Iterable<_ExpenseSlice> expenses,
  _DateRange range,
) {
  final amountsByWeekStart = <DateTime, int>{};
  for (final slice in expenses) {
    final weekStart = _startOfWeek(slice.expense.date);
    amountsByWeekStart.update(
      weekStart,
      (value) => value + slice.amountPaise,
      ifAbsent: () => slice.amountPaise,
    );
  }

  final points = <AnalyticsTrendPoint>[];
  final firstWeekStart = _startOfWeek(range.start);
  final lastWeekStart = _startOfWeek(range.end);
  var cursor = firstWeekStart;
  while (!cursor.isAfter(lastWeekStart)) {
    final weekEnd = cursor.add(const Duration(days: 6));
    final amount = amountsByWeekStart[cursor] ?? 0;
    points.add(
      AnalyticsTrendPoint(start: cursor, end: weekEnd, amountPaise: amount),
    );
    cursor = cursor.add(const Duration(days: 7));
  }
  return points;
}

class _ExpenseSlice {
  const _ExpenseSlice({required this.expense, required this.amountPaise});

  final AnalyticsExpense expense;
  final int amountPaise;
}

AnalyticsViewData calculateAnalyticsViewData({
  required List<AnalyticsExpense> expenses,
  required AnalyticsMode mode,
  required AnalyticsPeriod period,
  String? categoryFilter,
  DateTime? today,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final referenceDate = _normalizeDate(today ?? DateTime.now());
  final range = _resolveRange(
    period,
    referenceDate,
    customStart: customStart,
    customEnd: customEnd,
  );
  if (range == null) {
    return AnalyticsViewData.empty();
  }

  final slices = <_ExpenseSlice>[];
  for (final expense in expenses) {
    if (expense.date.isBefore(range.start) || expense.date.isAfter(range.end)) {
      continue;
    }
    final amount = mode == AnalyticsMode.consumption
        ? expense.consumptionSharePaise
        : expense.outOfPocketPaise;
    if (amount <= 0) {
      continue;
    }
    slices.add(_ExpenseSlice(expense: expense, amountPaise: amount));
  }

  if (slices.isEmpty) {
    return AnalyticsViewData.empty();
  }

  final totalPaise = slices.fold<int>(
    0,
    (sum, slice) => sum + slice.amountPaise,
  );
  final dailyAverage = totalPaise ~/ range.inclusiveDayCount;
  final expenseCount = slices.length;
  final activeGroupCount =
      slices.map((slice) => slice.expense.groupId).toSet().length;

  final categoryTotals = <String, int>{};
  for (final slice in slices) {
    final category =
        slice.expense.category.isEmpty ? '—' : slice.expense.category;
    categoryTotals.update(
      category,
      (value) => value + slice.amountPaise,
      ifAbsent: () => slice.amountPaise,
    );
  }

  final sortedCategories = categoryTotals.entries.toList()
    ..sort((a, b) {
      final amountCompare = b.value.compareTo(a.value);
      if (amountCompare != 0) {
        return amountCompare;
      }
      return a.key.compareTo(b.key);
    });

  final donutSegments = <AnalyticsDonutSegment>[];
  if (sortedCategories.length <= 6) {
    for (final entry in sortedCategories) {
      donutSegments.add(
        AnalyticsDonutSegment(
          category: entry.key,
          amountPaise: entry.value,
          isOther: false,
        ),
      );
    }
  } else {
    final topSix = sortedCategories.take(6);
    for (final entry in topSix) {
      donutSegments.add(
        AnalyticsDonutSegment(
          category: entry.key,
          amountPaise: entry.value,
          isOther: false,
        ),
      );
    }
    final otherAmount = sortedCategories
        .skip(6)
        .fold<int>(0, (sum, entry) => sum + entry.value);
    if (otherAmount > 0) {
      donutSegments.add(
        AnalyticsDonutSegment(
          category: 'Other',
          amountPaise: otherAmount,
          isOther: true,
        ),
      );
    }
  }

  final topCategories = sortedCategories
      .map(
        (entry) => AnalyticsCategoryTotal(
          category: entry.key,
          amountPaise: entry.value,
        ),
      )
      .toList(growable: false);

  Iterable<_ExpenseSlice> slicesForTrend = slices;
  List<AnalyticsTrendPoint> trendPoints;
  switch (period) {
    case AnalyticsPeriod.thisMonth:
    case AnalyticsPeriod.lastMonth:
      trendPoints = _buildDailyTrend(slicesForTrend, range);
      break;
    case AnalyticsPeriod.last30Days:
      trendPoints = _buildWeeklyTrend(slicesForTrend, range);
      break;
    case AnalyticsPeriod.custom:
      // Custom defaults to daily when available.
      trendPoints = _buildDailyTrend(slicesForTrend, range);
      break;
  }

  Iterable<_ExpenseSlice> slicesForGroups = slices;
  if (categoryFilter != null && categoryFilter.isNotEmpty) {
    slicesForGroups = slicesForGroups.where(
      (slice) => slice.expense.category == categoryFilter,
    );
  }

  final groupTotals = <String, _GroupAccumulator>{};
  for (final slice in slicesForGroups) {
    groupTotals.update(
      slice.expense.groupId,
      (value) => value.add(slice.amountPaise),
      ifAbsent: () => _GroupAccumulator(
        groupId: slice.expense.groupId,
        groupName: slice.expense.groupName,
        amountPaise: slice.amountPaise,
      ),
    );
  }

  final topGroups = groupTotals.values.toList()
    ..sort((a, b) {
      final amountCompare = b.amountPaise.compareTo(a.amountPaise);
      if (amountCompare != 0) {
        return amountCompare;
      }
      return a.groupName.compareTo(b.groupName);
    });

  final groupTotalsView = topGroups
      .map(
        (value) => AnalyticsGroupTotal(
          groupId: value.groupId,
          groupName: value.groupName,
          amountPaise: value.amountPaise,
        ),
      )
      .toList(growable: false);

  return AnalyticsViewData(
    kpis: AnalyticsKpis(
      totalPaise: totalPaise,
      dailyAveragePaise: dailyAverage,
      expenseCount: expenseCount,
      activeGroupCount: activeGroupCount,
    ),
    donutSegments: donutSegments,
    trendPoints: trendPoints,
    topGroups: groupTotalsView,
    topCategories: topCategories,
    hasData: totalPaise > 0,
  );
}

class _GroupAccumulator {
  const _GroupAccumulator({
    required this.groupId,
    required this.groupName,
    required this.amountPaise,
  });

  final String groupId;
  final String groupName;
  final int amountPaise;

  _GroupAccumulator add(int value) {
    return _GroupAccumulator(
      groupId: groupId,
      groupName: groupName,
      amountPaise: amountPaise + value,
    );
  }
}
