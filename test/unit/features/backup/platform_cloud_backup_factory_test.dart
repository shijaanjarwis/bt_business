import 'package:bt_business/features/backup/data/cloud/platform_cloud_backup_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform cloud factory returns a provider name', () {
    final port = PlatformCloudBackupFactory.create();
    expect(port.providerName, isNotEmpty);
  });
}
