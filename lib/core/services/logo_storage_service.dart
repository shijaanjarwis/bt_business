import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../errors/exceptions.dart';

/// Persists business logo files in application support storage.
final class LogoStorageService {
  Future<String> persistLogo({
    required String businessId,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw CacheException('Selected logo file is no longer available');
    }

    final directory = await _logosDirectory();
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final destination = File(p.join(directory.path, '$businessId$extension'));

    await destination.parent.create(recursive: true);
    await source.copy(destination.path);
    return destination.path;
  }

  Future<void> deleteLogo(String? path) async {
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _logosDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(p.join(supportDirectory.path, 'logos'));
  }
}
