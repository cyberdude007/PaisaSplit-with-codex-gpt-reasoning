import 'package:flutter/material.dart';

class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
      ),
      body: Center(
        child: Text(
          'Settle Up Placeholder',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
