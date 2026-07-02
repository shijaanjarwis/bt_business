import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/business/data/datasources/business_table.dart';
import 'core_providers.dart';
import 'data_revision.dart';

/// Cached active business id — avoids repeated `SELECT LIMIT 1` per query.
final cachedBusinessIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(dataRevisionProvider);
  final db = ref.watch(appDatabaseProvider).requireValue;
  final rows = await db.query(BusinessTable.tableName, limit: 1);
  if (rows.isEmpty) return null;
  return rows.first[BusinessTable.id] as String;
});
