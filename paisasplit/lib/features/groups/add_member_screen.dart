import 'package:flutter/material.dart';

class AddMemberScreen extends StatelessWidget {
  const AddMemberScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Member'),
      ),
      body: Center(
        child: Text(
          'Add Member Placeholder for $groupId',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
