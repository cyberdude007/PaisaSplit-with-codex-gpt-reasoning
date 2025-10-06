import 'package:equatable/equatable.dart';

const String currentUserMemberId = 'me';

class ExpenseGroupOption extends Equatable {
  const ExpenseGroupOption({
    required this.id,
    required this.name,
    required this.members,
  });

  final String id;
  final String name;
  final List<GroupMemberOption> members;

  @override
  List<Object?> get props => [id, name, members];
}

class GroupMemberOption extends Equatable {
  const GroupMemberOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class ExpenseAccountOption extends Equatable {
  const ExpenseAccountOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class ExpenseSplitShareInput extends Equatable {
  const ExpenseSplitShareInput({
    required this.memberId,
    required this.sharePaise,
  });

  final String memberId;
  final int sharePaise;

  @override
  List<Object?> get props => [memberId, sharePaise];
}

class ExpenseDraft extends Equatable {
  const ExpenseDraft({
    this.id,
    required this.groupId,
    required this.title,
    required this.amountPaise,
    required this.category,
    required this.paidByMemberId,
    required this.date,
    required this.accountId,
    this.notes,
    required this.splits,
  });

  final String? id;
  final String groupId;
  final String title;
  final int amountPaise;
  final String category;
  final String paidByMemberId;
  final DateTime date;
  final String accountId;
  final String? notes;
  final List<ExpenseSplitShareInput> splits;

  ExpenseDraft copyWith({
    String? id,
    String? groupId,
    String? title,
    int? amountPaise,
    String? category,
    String? paidByMemberId,
    DateTime? date,
    String? accountId,
    String? notes,
    List<ExpenseSplitShareInput>? splits,
  }) {
    return ExpenseDraft(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amountPaise: amountPaise ?? this.amountPaise,
      category: category ?? this.category,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      splits: splits ?? this.splits,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    title,
    amountPaise,
    category,
    paidByMemberId,
    date,
    accountId,
    notes,
    splits,
  ];
}

class ExpenseFormData extends Equatable {
  const ExpenseFormData({required this.groups, required this.accounts});

  final List<ExpenseGroupOption> groups;
  final List<ExpenseAccountOption> accounts;

  @override
  List<Object?> get props => [groups, accounts];
}
