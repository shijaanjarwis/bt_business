/// Contract for future Firebase / cloud sync orchestration.
abstract interface class SyncService {
  Future<void> pushPendingChanges();

  Future<void> pullRemoteChanges();

  Stream<SyncStatus> watchSyncStatus();
}

enum SyncStatus {
  idle,
  syncing,
  error,
}
