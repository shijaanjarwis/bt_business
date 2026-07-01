import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/di/data_revision.dart';
import '../../../../data/local/database/tables/accounting_tables.dart';

/// Last activity timestamp per party — for Hisaab list cards.
final partyLastActivityProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  ref.watch(dataRevisionProvider);
  final db = ref.watch(appDatabaseProvider).requireValue;

  final rows = await db.rawQuery(
    '''
    SELECT ${TransactionsTable.partyId}, MAX(${TransactionsTable.createdAt}) AS last_at
    FROM ${TransactionsTable.tableName}
    WHERE ${TransactionsTable.deletedAt} IS NULL
    GROUP BY ${TransactionsTable.partyId}
    ''',
  );

  final map = <String, DateTime>{};
  for (final row in rows) {
    final partyId = row[TransactionsTable.partyId] as String?;
    final lastAt = row['last_at'] as String?;
    if (partyId == null || lastAt == null) continue;
    map[partyId] = DateTime.parse(lastAt);
  }
  return map;
});
