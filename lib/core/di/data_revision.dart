import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented whenever SQLite business data changes to refresh dependents.
final dataRevisionProvider = StateProvider<int>((ref) => 0);

/// Notifies listeners that persisted business data changed.
void notifyDataChanged(WidgetRef ref) {
  ref.read(dataRevisionProvider.notifier).state++;
}

/// Notifier-friendly variant for use inside [AsyncNotifier].
void notifyDataChangedFromNotifier(Ref ref) {
  ref.read(dataRevisionProvider.notifier).state++;
}
