import 'package:flutter/material.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group $groupId'),
      ),
      body: Center(
        child: Text(
          'Group Detail Placeholder for $groupId',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
