import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_calculator.dart';
import '../data/analytics_models.dart';
import '../data/analytics_repository.dart';

class AnalyticsSelectionController extends StateNotifier<AnalyticsSelection> {
  AnalyticsSelectionController() : super(const AnalyticsSelection());

  void selectMode(AnalyticsMode mode) {
    if (state.mode == mode) {
      return;
    }
    state = state.copyWith(mode: mode, categoryFilter: () => null);
  }

  void selectPeriod(AnalyticsPeriod period) {
    if (state.period == period) {
      return;
    }
    state = state.copyWith(period: period, categoryFilter: () => null);
  }

  void toggleCategoryFilter(String category) {
    if (category == 'Other') {
      return;
    }
    if (state.categoryFilter == category) {
      state = state.copyWith(categoryFilter: () => null);
    } else {
      state = state.copyWith(categoryFilter: () => category);
    }
  }

  void clearCategoryFilter() {
    if (state.categoryFilter == null) {
      return;
    }
    state = state.copyWith(categoryFilter: () => null);
  }
}

final analyticsTodayProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final analyticsSelectionProvider =
    StateNotifierProvider<AnalyticsSelectionController, AnalyticsSelection>(
      (ref) => AnalyticsSelectionController(),
    );

final analyticsViewDataProvider = Provider<AsyncValue<AnalyticsViewData>>((
  ref,
) {
  final expensesAsync = ref.watch(analyticsExpensesProvider);
  final selection = ref.watch(analyticsSelectionProvider);
  final today = ref.watch(analyticsTodayProvider);

  return expensesAsync.whenData(
    (expenses) => calculateAnalyticsViewData(
      expenses: expenses,
      mode: selection.mode,
      period: selection.period,
      categoryFilter: selection.categoryFilter,
      today: today,
    ),
  );
});
