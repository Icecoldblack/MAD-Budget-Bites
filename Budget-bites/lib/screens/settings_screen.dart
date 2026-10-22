import 'package:flutter/material.dart';

/// Screen 5: daily budget slider and display option.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Budget and display settings')),
    );
  }
}
