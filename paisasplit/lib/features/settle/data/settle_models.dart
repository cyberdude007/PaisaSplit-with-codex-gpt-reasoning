import 'package:equatable/equatable.dart';

import '../../expenses/data/expense_models.dart';

class MemberBalance extends Equatable {
  const MemberBalance({
    required this.memberId,
    required this.memberName,
    required this.netBalancePaise,
  });

  final String memberId;
  final String memberName;
  final int netBalancePaise;

  bool get isCurrentUser => memberId == currentUserMemberId;
  bool get isSettled => netBalancePaise == 0;
  bool get isCreditor => netBalancePaise > 0;
  bool get isDebtor => netBalancePaise < 0;

  @override
  List<Object?> get props => [memberId, memberName, netBalancePaise];
}

class GroupBalanceSummary extends Equatable {
  const GroupBalanceSummary({
    required this.groupId,
    required this.groupName,
    required this.totalToReceivePaise,
    required this.totalToPayPaise,
    required this.memberBalances,
  });

  final String groupId;
  final String groupName;
  final int totalToReceivePaise;
  final int totalToPayPaise;
  final List<MemberBalance> memberBalances;

  MemberBalance? get currentUserBalance => memberBalances
      .where((balance) => balance.isCurrentUser)
      .cast<MemberBalance?>()
      .firstWhere((balance) => balance != null, orElse: () => null);

  List<MemberBalance> get otherMemberBalances => memberBalances
      .where((balance) => !balance.isCurrentUser)
      .toList(growable: false);

  @override
  List<Object?> get props => [
    groupId,
    groupName,
    totalToReceivePaise,
    totalToPayPaise,
    memberBalances,
  ];
}

class SettlementHistoryEntry extends Equatable {
  const SettlementHistoryEntry({
    required this.id,
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amountPaise,
    required this.date,
    this.note,
  });

  final String id;
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final int amountPaise;
  final DateTime date;
  final String? note;

  bool get involvesCurrentUser =>
      fromMemberId == currentUserMemberId || toMemberId == currentUserMemberId;

  @override
  List<Object?> get props => [
    id,
    fromMemberId,
    fromMemberName,
    toMemberId,
    toMemberName,
    amountPaise,
    date,
    note,
  ];
}
