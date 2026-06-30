import 'package:sqflite/sqflite.dart';

/// A single forward-only schema migration step.
abstract interface class Migration {
  int get version;

  Future<void> up(Database db);
}
