import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/database_helper.dart';

/// Opens a fresh, empty database that only lives in memory.
/// Each test gets its own, so tests don't affect each other.
Future<Database> openTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  return DatabaseHelper.openAppDatabase(path: inMemoryDatabasePath);
}
