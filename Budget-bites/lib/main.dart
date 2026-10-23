import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data/database_helper.dart';
import 'data/meal_repository.dart';
import 'data/purchase_repository.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Browsers like Edge need the web version of SQLite.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  final db = await DatabaseHelper.openAppDatabase();
  runApp(BudgetBitesApp(
    mealRepository: MealRepository(db),
    purchaseRepository: PurchaseRepository(db),
  ));
}

class BudgetBitesApp extends StatelessWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;

  const BudgetBitesApp({
    super.key,
    required this.mealRepository,
    required this.purchaseRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Bites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomeShell(
        mealRepository: mealRepository,
        purchaseRepository: purchaseRepository,
      ),
    );
  }
}
