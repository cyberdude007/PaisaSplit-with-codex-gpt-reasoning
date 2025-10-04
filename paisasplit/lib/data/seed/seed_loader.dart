import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../db.dart';

class SeedLoader {
  SeedLoader({required this.database, AssetBundle? bundle})
      : bundle = bundle ?? rootBundle;

  final PaisaSplitDatabase database;
  final AssetBundle bundle;

  static const String _seedAssetPath = 'assets/seed/seed.json';

  Future<void> seedIfNeeded() async {
    if (await _hasExistingData()) {
      return;
    }

    final data = await _loadSeedData();
    await database.transaction(() async {
      await _seedMembers(data);
      await _seedGroups(data);
      await _seedGroupMembers(data);
      await _seedAccounts(data);
      await _seedExpenses(data);
      await _seedSplits(data);
    });
  }

  Future<bool> _hasExistingData() async {
    final countRow = await database.customSelect(
      'SELECT COUNT(*) AS c FROM members',
      readsFrom: {database.members},
    ).getSingle();
    final countValue = countRow.data['c'];
    if (countValue is int) {
      return countValue > 0;
    }
    if (countValue is BigInt) {
      return countValue > BigInt.zero;
    }
    return false;
  }

  Future<Map<String, dynamic>> _loadSeedData() async {
    final rawJson = await bundle.loadString(_seedAssetPath);
    final decoded = json.decode(rawJson);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<void> _seedMembers(Map<String, dynamic> data) async {
    final members = List<Map<String, dynamic>>.from(
      data['members'] as List? ?? <Object?>[],
    );
    if (members.isEmpty) {
      return;
    }

    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.members,
        members.map(
          (member) => MembersCompanion(
            id: Value(member['id'] as String),
            name: Value(member['name'] as String),
            upiId: Value(member['upiId'] as String?),
            avatar: Value(member['avatar'] as String?),
            isGlobal: Value(member['isGlobal'] as bool? ?? false),
          ),
        ),
      );
    });
  }

  Future<void> _seedGroups(Map<String, dynamic> data) async {
    final groups = List<Map<String, dynamic>>.from(
      data['groups'] as List? ?? <Object?>[],
    );
    if (groups.isEmpty) {
      return;
    }

    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.groups,
        groups.map(
          (group) => GroupsCompanion(
            id: Value(group['id'] as String),
            name: Value(group['name'] as String),
            description: const Value.absent(),
            createdAt: Value(DateTime.parse(group['createdAt'] as String)),
          ),
        ),
      );
    });
  }

  Future<void> _seedGroupMembers(Map<String, dynamic> data) async {
    final groupMembers = List<Map<String, dynamic>>.from(
      data['groupMembers'] as List? ?? <Object?>[],
    );
    if (groupMembers.isEmpty) {
      return;
    }

    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.groupMembers,
        groupMembers.map(
          (groupMember) => GroupMembersCompanion(
            id: Value(groupMember['id'] as String),
            groupId: Value(groupMember['groupId'] as String),
            memberId: Value(groupMember['memberId'] as String),
            role: const Value.absent(),
          ),
        ),
      );
    });
  }

  Future<void> _seedAccounts(Map<String, dynamic> data) async {
    final accounts = List<Map<String, dynamic>>.from(
      data['accounts'] as List? ?? <Object?>[],
    );
    if (accounts.isEmpty) {
      return;
    }

    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.accounts,
        accounts.map(
          (account) => AccountsCompanion(
            id: Value(account['id'] as String),
            name: Value(account['name'] as String),
            openingBalancePaise:
                Value(account['openingBalancePaise'] as int? ?? 0),
            type: const Value.absent(),
            notes: const Value.absent(),
          ),
        ),
      );
    });
  }

  Future<void> _seedExpenses(Map<String, dynamic> data) async {
    final expenses = List<Map<String, dynamic>>.from(
      data['expenses'] as List? ?? <Object?>[],
    );
    if (expenses.isEmpty) {
      return;
    }

    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.expenses,
        expenses.map(
          (expense) => ExpensesCompanion(
            id: Value(expense['id'] as String),
            groupId: Value(expense['groupId'] as String),
            title: Value(expense['title'] as String),
            amountPaise: Value(expense['amountPaise'] as int),
            paidByMemberId: Value(expense['paidByMemberId'] as String),
            date: Value(DateTime.parse(expense['date'] as String)),
            category: Value(expense['category'] as String),
            notes: Value(expense['notes'] as String?),
            isDeleted: const Value(false),
          ),
        ),
      );
    });
  }

  Future<void> _seedSplits(Map<String, dynamic> data) async {
    final splits = List<Map<String, dynamic>>.from(
      data['splits'] as List? ?? <Object?>[],
    );
    if (splits.isEmpty) {
      return;
    }

    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.expenseSplits,
        splits.map(
          (split) => ExpenseSplitsCompanion(
            id: Value(split['id'] as String),
            expenseId: Value(split['expenseId'] as String),
            memberId: Value(split['memberId'] as String),
            sharePaise: Value(split['sharePaise'] as int),
          ),
        ),
      );
    });
  }
}
