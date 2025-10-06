import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db.dart';
import '../../expenses/data/expense_models.dart';

class DashboardRepository {
  DashboardRepository(this._db);

  final PaisaSplitDatabase _db;

  Stream<DashboardData> watchDashboard({
    int counterpartyLimit = 4,
    int activityLimit = 10,
  }) {
    final groupsStream = _db.select(_db.groups).watch();
    final membersStream = _db.select(_db.members).watch();
    final groupMembersStream = _db.select(_db.groupMembers).watch();
    final expensesStream = (_db.select(
      _db.expenses,
    )..where((tbl) => tbl.isDeleted.equals(false)))
        .watch();
    final splitsStream = _db.select(_db.expenseSplits).watch();
    final settlementsStream = _db.select(_db.settlements).watch();

    return Stream.multi((controller) {
      List<Group>? latestGroups;
      List<Member>? latestMembers;
      List<GroupMember>? latestGroupMembers;
      List<Expense>? latestExpenses;
      List<ExpenseSplit>? latestSplits;
      List<Settlement>? latestSettlements;

      void emitIfReady() {
        final groups = latestGroups;
        final members = latestMembers;
        final groupMembers = latestGroupMembers;
        final expenses = latestExpenses;
        final splits = latestSplits;
        final settlements = latestSettlements;
        if (groups == null ||
            members == null ||
            groupMembers == null ||
            expenses == null ||
            splits == null ||
            settlements == null) {
          return;
        }

        try {
          final data = _computeDashboard(
            groups: groups,
            members: members,
            groupMembers: groupMembers,
            expenses: expenses,
            splits: splits,
            settlements: settlements,
            counterpartyLimit: counterpartyLimit,
            activityLimit: activityLimit,
          );
          controller.add(data);
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      final subscriptions = <StreamSubscription<dynamic>>[
        groupsStream.listen((value) {
          latestGroups = value;
          emitIfReady();
        }, onError: controller.addError),
        membersStream.listen((value) {
          latestMembers = value;
          emitIfReady();
        }, onError: controller.addError),
        groupMembersStream.listen((value) {
          latestGroupMembers = value;
          emitIfReady();
        }, onError: controller.addError),
        expensesStream.listen((value) {
          latestExpenses = value;
          emitIfReady();
        }, onError: controller.addError),
        splitsStream.listen((value) {
          latestSplits = value;
          emitIfReady();
        }, onError: controller.addError),
        settlementsStream.listen((value) {
          latestSettlements = value;
          emitIfReady();
        }, onError: controller.addError),
      ];

      controller
        ..onPause = () {
          for (final sub in subscriptions) {
            sub.pause();
          }
        }
        ..onResume = () {
          for (final sub in subscriptions) {
            sub.resume();
          }
        }
        ..onCancel = () async {
          for (final sub in subscriptions) {
            await sub.cancel();
          }
        };
    });
  }

  DashboardData _computeDashboard({
    required List<Group> groups,
    required List<Member> members,
    required List<GroupMember> groupMembers,
    required List<Expense> expenses,
    required List<ExpenseSplit> splits,
    required List<Settlement> settlements,
    required int counterpartyLimit,
    required int activityLimit,
  }) {
    final memberNames = {for (final member in members) member.id: member.name};
    final groupsById = {for (final group in groups) group.id: group};
    final membersByGroup = groupBy<GroupMember, String>(
      groupMembers,
      (member) => member.groupId,
    );

    final userGroupIds = <String>{
      for (final entry in membersByGroup.entries)
        if (entry.value.any((member) => member.memberId == currentUserMemberId))
          entry.key,
    };

    int totalYouOwe = 0;
    int totalYouGet = 0;
    int netBalance = 0;
    final counterparties = <DashboardCounterparty>[];

    final expensesByGroup = groupBy<Expense, String>(
      expenses,
      (expense) => expense.groupId,
    );
    final splitsByExpense = groupBy<ExpenseSplit, String>(
      splits,
      (split) => split.expenseId,
    );
    final settlementsByGroup = groupBy<Settlement, String>(
      settlements,
      (settlement) => settlement.groupId,
    );

    for (final groupId in userGroupIds) {
      final group = groupsById[groupId];
      if (group == null) {
        continue;
      }
      final groupMemberRecords =
          membersByGroup[groupId] ?? const <GroupMember>[];
      final memberDetails = groupMemberRecords
          .map(
            (record) => _MemberDetail(
              id: record.memberId,
              name: memberNames[record.memberId] ?? '—',
            ),
          )
          .toList(growable: false);
      if (memberDetails.isEmpty) {
        continue;
      }

      final groupExpenses = expensesByGroup[groupId] ?? const <Expense>[];
      final groupSettlements =
          settlementsByGroup[groupId] ?? const <Settlement>[];

      final netByMember = <String, int>{
        for (final member in memberDetails) member.id: 0,
      };

      for (final expense in groupExpenses) {
        final expenseSplits =
            splitsByExpense[expense.id] ?? const <ExpenseSplit>[];
        for (final split in expenseSplits) {
          if (split.memberId == expense.paidByMemberId) {
            continue;
          }
          netByMember.update(
            split.memberId,
            (value) => value - split.sharePaise,
            ifAbsent: () => -split.sharePaise,
          );
        }

        final payerShare = expenseSplits
                .firstWhereOrNull(
                  (split) => split.memberId == expense.paidByMemberId,
                )
                ?.sharePaise ??
            0;
        final payerNet = expense.amountPaise - payerShare;
        netByMember.update(
          expense.paidByMemberId,
          (value) => value + payerNet,
          ifAbsent: () => payerNet,
        );
      }

      for (final settlement in groupSettlements) {
        netByMember.update(
          settlement.fromMemberId,
          (value) => value + settlement.amountPaise,
          ifAbsent: () => settlement.amountPaise,
        );
        netByMember.update(
          settlement.toMemberId,
          (value) => value - settlement.amountPaise,
          ifAbsent: () => -settlement.amountPaise,
        );
      }

      final currentUserNet = netByMember[currentUserMemberId] ?? 0;
      if (currentUserNet > 0) {
        totalYouGet += currentUserNet;
      } else if (currentUserNet < 0) {
        totalYouOwe += -currentUserNet;
      }
      netBalance += currentUserNet;

      if (currentUserNet == 0) {
        continue;
      }

      final relevantMembers = memberDetails.where((member) {
        if (member.id == currentUserMemberId) {
          return false;
        }
        final memberNet = netByMember[member.id] ?? 0;
        if (currentUserNet > 0) {
          return memberNet < 0;
        }
        return memberNet > 0;
      });

      for (final member in relevantMembers) {
        final memberNet = netByMember[member.id] ?? 0;
        final suggestedAmount = currentUserNet.abs().min(memberNet.abs());
        if (suggestedAmount <= 0) {
          continue;
        }
        counterparties.add(
          DashboardCounterparty(
            memberId: member.id,
            memberName: member.name,
            groupId: group.id,
            groupName: group.name,
            amountPaise: suggestedAmount,
            direction: currentUserNet > 0
                ? CounterpartyDirection.youGet
                : CounterpartyDirection.youOwe,
          ),
        );
      }
    }

    counterparties.sort((a, b) => b.amountPaise.compareTo(a.amountPaise));
    final limitedCounterparties =
        counterparties.take(counterpartyLimit).toList(growable: false);

    final activities = <DashboardActivity>[];

    for (final expense in expenses) {
      if (!userGroupIds.contains(expense.groupId)) {
        continue;
      }
      final splitsForExpense =
          splitsByExpense[expense.id] ?? const <ExpenseSplit>[];
      final userShare = splitsForExpense
              .firstWhereOrNull(
                (split) => split.memberId == currentUserMemberId,
              )
              ?.sharePaise ??
          0;
      final isPayer = expense.paidByMemberId == currentUserMemberId;
      if (!isPayer && userShare == 0) {
        continue;
      }

      final payerName = memberNames[expense.paidByMemberId] ?? '—';
      final groupName = groupsById[expense.groupId]?.name ?? '—';
      final impact = isPayer ? expense.amountPaise - userShare : -userShare;

      activities.add(
        DashboardActivity(
          id: 'expense:${expense.id}',
          type: DashboardActivityType.expense,
          title: expense.title,
          groupId: expense.groupId,
          groupName: groupName,
          actorName: payerName,
          date: expense.date,
          amountPaise: impact,
        ),
      );
    }

    for (final settlement in settlements) {
      if (!userGroupIds.contains(settlement.groupId)) {
        continue;
      }

      final isSender = settlement.fromMemberId == currentUserMemberId;
      final isReceiver = settlement.toMemberId == currentUserMemberId;
      if (!isSender && !isReceiver) {
        continue;
      }

      final counterpartyId =
          isSender ? settlement.toMemberId : settlement.fromMemberId;
      final counterpartyName = memberNames[counterpartyId] ?? '—';
      final groupName = groupsById[settlement.groupId]?.name ?? '—';
      final amount =
          isReceiver ? settlement.amountPaise : -settlement.amountPaise;

      activities.add(
        DashboardActivity(
          id: 'settlement:${settlement.id}',
          type: DashboardActivityType.settlement,
          title: 'Settlement',
          groupId: settlement.groupId,
          groupName: groupName,
          actorName: counterpartyName,
          date: settlement.date,
          amountPaise: amount,
        ),
      );
    }

    activities.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.id.compareTo(b.id);
    });

    final limitedActivities =
        activities.take(activityLimit).toList(growable: false);

    return DashboardData(
      snapshot: DashboardSnapshot(
        youOwePaise: totalYouOwe,
        youGetPaise: totalYouGet,
        netBalancePaise: netBalance,
      ),
      counterparties: limitedCounterparties,
      recentActivity: limitedActivities,
    );
  }
}

extension on int {
  int min(int other) => this < other ? this : other;
}

class DashboardData extends Equatable {
  const DashboardData({
    required this.snapshot,
    required this.counterparties,
    required this.recentActivity,
  });

  final DashboardSnapshot snapshot;
  final List<DashboardCounterparty> counterparties;
  final List<DashboardActivity> recentActivity;

  @override
  List<Object?> get props => [snapshot, counterparties, recentActivity];
}

class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.youOwePaise,
    required this.youGetPaise,
    required this.netBalancePaise,
  });

  final int youOwePaise;
  final int youGetPaise;
  final int netBalancePaise;

  @override
  List<Object?> get props => [youOwePaise, youGetPaise, netBalancePaise];
}

enum CounterpartyDirection { youOwe, youGet }

class DashboardCounterparty extends Equatable {
  const DashboardCounterparty({
    required this.memberId,
    required this.memberName,
    required this.groupId,
    required this.groupName,
    required this.amountPaise,
    required this.direction,
  });

  final String memberId;
  final String memberName;
  final String groupId;
  final String groupName;
  final int amountPaise;
  final CounterpartyDirection direction;

  bool get isYouOwe => direction == CounterpartyDirection.youOwe;
  bool get isYouGet => direction == CounterpartyDirection.youGet;

  @override
  List<Object?> get props => [
        memberId,
        memberName,
        groupId,
        groupName,
        amountPaise,
        direction,
      ];
}

enum DashboardActivityType { expense, settlement }

class DashboardActivity extends Equatable {
  const DashboardActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.groupId,
    required this.groupName,
    required this.actorName,
    required this.date,
    required this.amountPaise,
  });

  final String id;
  final DashboardActivityType type;
  final String title;
  final String groupId;
  final String groupName;
  final String actorName;
  final DateTime date;
  final int amountPaise;

  bool get isCredit => amountPaise > 0;
  bool get isDebit => amountPaise < 0;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        groupId,
        groupName,
        actorName,
        date,
        amountPaise,
      ];
}

class _MemberDetail {
  const _MemberDetail({required this.id, required this.name});

  final String id;
  final String name;
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = PaisaSplitDatabase.instance;
  return DashboardRepository(db);
});

final dashboardDataProvider = StreamProvider<DashboardData>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.watchDashboard();
});
