import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/database_helper.dart';

/// Opens a fresh, empty database that only lives in memory.
/// Each test gets its own, so tests don't affect each other.
///
/// It also gives SharedPreferences an empty fake store, because tests
/// can't use the real one on a phone.
Future<Database> openTestDatabase() async {
  SharedPreferences.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  return DatabaseHelper.openAppDatabase(path: inMemoryDatabasePath);
}
