import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

void main() {
  runApp(const BudgetBitesApp());
}

class BudgetBitesApp extends StatelessWidget {
  const BudgetBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Bites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
