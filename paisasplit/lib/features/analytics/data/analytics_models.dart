import 'package:equatable/equatable.dart';

enum AnalyticsMode { consumption, outOfPocket }

extension AnalyticsModeDisplay on AnalyticsMode {
  String get label {
    switch (this) {
      case AnalyticsMode.consumption:
        return 'Consumption (My Share)';
      case AnalyticsMode.outOfPocket:
        return 'Out-of-Pocket';
    }
  }
}

enum AnalyticsPeriod { thisMonth, lastMonth, last30Days, custom }

extension AnalyticsPeriodDisplay on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.thisMonth:
        return 'This Month';
      case AnalyticsPeriod.lastMonth:
        return 'Last Month';
      case AnalyticsPeriod.last30Days:
        return 'Last 30 Days';
      case AnalyticsPeriod.custom:
        return 'Custom';
    }
  }
}

class AnalyticsExpense extends Equatable {
  const AnalyticsExpense({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.category,
    required this.date,
    required this.amountPaise,
    required this.consumptionSharePaise,
    required this.outOfPocketPaise,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String category;
  final DateTime date;
  final int amountPaise;
  final int consumptionSharePaise;
  final int outOfPocketPaise;

  bool get contributesToConsumption => consumptionSharePaise > 0;
  bool get contributesToOutOfPocket => outOfPocketPaise > 0;

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        category,
        date,
        amountPaise,
        consumptionSharePaise,
        outOfPocketPaise,
      ];
}

class AnalyticsKpis extends Equatable {
  const AnalyticsKpis({
    required this.totalPaise,
    required this.dailyAveragePaise,
    required this.expenseCount,
    required this.activeGroupCount,
  });

  final int totalPaise;
  final int dailyAveragePaise;
  final int expenseCount;
  final int activeGroupCount;

  @override
  List<Object?> get props => [
        totalPaise,
        dailyAveragePaise,
        expenseCount,
        activeGroupCount,
      ];
}

class AnalyticsDonutSegment extends Equatable {
  const AnalyticsDonutSegment({
    required this.category,
    required this.amountPaise,
    required this.isOther,
  });

  final String category;
  final int amountPaise;
  final bool isOther;

  @override
  List<Object?> get props => [category, amountPaise, isOther];
}

class AnalyticsTrendPoint extends Equatable {
  const AnalyticsTrendPoint({
    required this.start,
    required this.end,
    required this.amountPaise,
  });

  final DateTime start;
  final DateTime end;
  final int amountPaise;

  bool get isDaily => start.isAtSameMomentAs(end);

  @override
  List<Object?> get props => [start, end, amountPaise];
}

class AnalyticsCategoryTotal extends Equatable {
  const AnalyticsCategoryTotal({
    required this.category,
    required this.amountPaise,
  });

  final String category;
  final int amountPaise;

  @override
  List<Object?> get props => [category, amountPaise];
}

class AnalyticsGroupTotal extends Equatable {
  const AnalyticsGroupTotal({
    required this.groupId,
    required this.groupName,
    required this.amountPaise,
  });

  final String groupId;
  final String groupName;
  final int amountPaise;

  @override
  List<Object?> get props => [groupId, groupName, amountPaise];
}

class AnalyticsViewData extends Equatable {
  const AnalyticsViewData({
    required this.kpis,
    required this.donutSegments,
    required this.trendPoints,
    required this.topGroups,
    required this.topCategories,
    required this.hasData,
  });

  factory AnalyticsViewData.empty() => const AnalyticsViewData(
        kpis: AnalyticsKpis(
          totalPaise: 0,
          dailyAveragePaise: 0,
          expenseCount: 0,
          activeGroupCount: 0,
        ),
        donutSegments: [],
        trendPoints: [],
        topGroups: [],
        topCategories: [],
        hasData: false,
      );

  final AnalyticsKpis kpis;
  final List<AnalyticsDonutSegment> donutSegments;
  final List<AnalyticsTrendPoint> trendPoints;
  final List<AnalyticsGroupTotal> topGroups;
  final List<AnalyticsCategoryTotal> topCategories;
  final bool hasData;

  @override
  List<Object?> get props => [
        kpis,
        donutSegments,
        trendPoints,
        topGroups,
        topCategories,
        hasData,
      ];
}

class AnalyticsSelection extends Equatable {
  const AnalyticsSelection({
    this.mode = AnalyticsMode.consumption,
    this.period = AnalyticsPeriod.thisMonth,
    this.categoryFilter,
  });

  final AnalyticsMode mode;
  final AnalyticsPeriod period;
  final String? categoryFilter;

  AnalyticsSelection copyWith({
    AnalyticsMode? mode,
    AnalyticsPeriod? period,
    String? Function()? categoryFilter,
  }) {
    return AnalyticsSelection(
      mode: mode ?? this.mode,
      period: period ?? this.period,
      categoryFilter:
          categoryFilter != null ? categoryFilter() : this.categoryFilter,
    );
  }

  @override
  List<Object?> get props => [mode, period, categoryFilter];
}
