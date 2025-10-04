import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(child: Icon(Icons.person_outline)),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Dashboard Content Placeholder',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
