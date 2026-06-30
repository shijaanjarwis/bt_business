import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';

/// Resolves the on-disk path for the application SQLite database.
abstract final class DatabasePaths {
  static Future<String> resolve() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return p.join(supportDirectory.path, AppConstants.databaseName);
  }
}
