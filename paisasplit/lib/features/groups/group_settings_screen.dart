import 'package:flutter/material.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
      ),
      body: Center(
        child: Text(
          'Group Settings Placeholder for $groupId',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
