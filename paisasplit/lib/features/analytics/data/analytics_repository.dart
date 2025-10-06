import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db.dart';
import '../../expenses/data/expense_models.dart';
import 'analytics_models.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._db);

  final PaisaSplitDatabase _db;

  Stream<List<AnalyticsExpense>> watchExpenses() {
    final groupsStream = _db.select(_db.groups).watch();
    final groupMembersStream = _db.select(_db.groupMembers).watch();
    final expensesStream = (_db.select(
      _db.expenses,
    )..where((tbl) => tbl.isDeleted.equals(false))).watch();
    final splitsStream = _db.select(_db.expenseSplits).watch();

    return Stream.multi((controller) {
      List<Group>? latestGroups;
      List<GroupMember>? latestGroupMembers;
      List<Expense>? latestExpenses;
      List<ExpenseSplit>? latestSplits;

      void emitIfReady() {
        final groups = latestGroups;
        final groupMembers = latestGroupMembers;
        final expenses = latestExpenses;
        final splits = latestSplits;
        if (groups == null ||
            groupMembers == null ||
            expenses == null ||
            splits == null) {
          return;
        }

        try {
          final data = _buildAnalyticsExpenses(
            groups: groups,
            groupMembers: groupMembers,
            expenses: expenses,
            splits: splits,
          );
          controller.add(data);
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        groupsStream.listen((event) {
          latestGroups = event;
          emitIfReady();
        }, onError: controller.addError),
        groupMembersStream.listen((event) {
          latestGroupMembers = event;
          emitIfReady();
        }, onError: controller.addError),
        expensesStream.listen((event) {
          latestExpenses = event;
          emitIfReady();
        }, onError: controller.addError),
        splitsStream.listen((event) {
          latestSplits = event;
          emitIfReady();
        }, onError: controller.addError),
      ];

      controller
        ..onPause = () {
          for (final subscription in subscriptions) {
            subscription.pause();
          }
        }
        ..onResume = () {
          for (final subscription in subscriptions) {
            subscription.resume();
          }
        }
        ..onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
    });
  }

  List<AnalyticsExpense> _buildAnalyticsExpenses({
    required List<Group> groups,
    required List<GroupMember> groupMembers,
    required List<Expense> expenses,
    required List<ExpenseSplit> splits,
  }) {
    final groupNames = {for (final group in groups) group.id: group.name};
    final userGroupIds = groupMembers
        .where((member) => member.memberId == currentUserMemberId)
        .map((member) => member.groupId)
        .toSet();
    final splitsByExpense = groupBy<ExpenseSplit, String>(
      splits,
      (split) => split.expenseId,
    );

    final results = <AnalyticsExpense>[];
    for (final expense in expenses) {
      if (!userGroupIds.contains(expense.groupId)) {
        continue;
      }

      final expenseSplits =
          splitsByExpense[expense.id] ?? const <ExpenseSplit>[];
      final yourShare =
          expenseSplits
              .firstWhereOrNull(
                (split) => split.memberId == currentUserMemberId,
              )
              ?.sharePaise ??
          0;
      final outOfPocket = expense.paidByMemberId == currentUserMemberId
          ? expense.amountPaise
          : 0;

      if (yourShare == 0 && outOfPocket == 0) {
        continue;
      }

      results.add(
        AnalyticsExpense(
          id: expense.id,
          groupId: expense.groupId,
          groupName: groupNames[expense.groupId] ?? '—',
          category: expense.category.trim(),
          date: DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          ),
          amountPaise: expense.amountPaise,
          consumptionSharePaise: yourShare,
          outOfPocketPaise: outOfPocket,
        ),
      );
    }

    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final db = PaisaSplitDatabase.instance;
  return AnalyticsRepository(db);
});

final analyticsExpensesProvider =
    StreamProvider.autoDispose<List<AnalyticsExpense>>((ref) {
      final repository = ref.watch(analyticsRepositoryProvider);
      return repository.watchExpenses();
    });
