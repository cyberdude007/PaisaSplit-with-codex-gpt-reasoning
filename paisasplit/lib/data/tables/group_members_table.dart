import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';

class GroupMembers extends Table {
  TextColumn get id => text()();

  TextColumn get groupId => text().references(
        Groups,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get memberId => text().references(
        Members,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get role => text().withDefault(const Constant('member'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'UNIQUE(group_id, member_id)',
      ];
}
