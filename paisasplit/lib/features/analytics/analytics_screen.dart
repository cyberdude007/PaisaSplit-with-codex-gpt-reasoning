import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Center(
        child: Text(
          'Analytics Placeholder',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
