import 'package:bt_business/features/voice/data/voice_history_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('voice history keeps latest 20 entries', () async {
    final store = VoiceHistoryStore.create();

    for (var i = 0; i < 25; i++) {
      await store.add('command $i');
    }

    final history = await store.readAll();
    expect(history.length, VoiceHistoryStore.maxEntries);
    expect(history.first, 'command 24');
    expect(history.last, 'command 5');
  });
}
