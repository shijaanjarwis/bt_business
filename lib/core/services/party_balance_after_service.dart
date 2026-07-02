import '../../features/ledger/data/datasources/party_local_datasource.dart';
import '../../features/ledger/domain/entities/party_history_builder.dart';

/// Computes party running balance after a specific transaction.
final class PartyBalanceAfterService {
  const PartyBalanceAfterService(this._partyLocalDataSource);

  final PartyLocalDataSource _partyLocalDataSource;

  Future<double?> balanceAfterTransaction({
    required String partyId,
    required String transactionId,
  }) async {
    final balances = await balancesForParty(partyId);
    return balances[transactionId];
  }

  Future<Map<String, double>> balancesForParty(String partyId) async {
    final rows = await _partyLocalDataSource.fetchPartyHistory(partyId);
    final entries = PartyHistoryBuilder.build(rows);
    return {for (final entry in entries) entry.id: entry.runningBalance};
  }

  /// Batch lookup keyed by transaction id for payment register cards.
  Future<Map<String, double>> balancesForTransactions(
    Iterable<({String id, String partyId})> items,
  ) async {
    final result = <String, double>{};
    final partyIds = items.map((item) => item.partyId).toSet();

    for (final partyId in partyIds) {
      final balances = await balancesForParty(partyId);
      result.addAll(balances);
    }

    return result;
  }
}
