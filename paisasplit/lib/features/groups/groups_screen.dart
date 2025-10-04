import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: Center(
        child: Text(
          'Groups Placeholder',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
