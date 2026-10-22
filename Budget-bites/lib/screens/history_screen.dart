import 'package:flutter/material.dart';

/// Screen 4: date range, total spent, and the purchase list.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(child: Text('Purchase history')),
    );
  }
}
