import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Detail'),
      ),
      body: Center(
        child: Text(
          'Activity ID: $activityId',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
