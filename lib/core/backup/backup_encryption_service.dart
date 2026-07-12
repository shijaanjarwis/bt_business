import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM encryption for backup payloads — never stores plain business data.
final class BackupEncryptionService {
  BackupEncryptionService();

  static const _appSalt = 'bt_business_secure_backup_v1';

  final AesGcm _algorithm = AesGcm.with256bits();
  final Random _random = Random.secure();

  String generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Encode(bytes);
  }

  Future<SecretKey> deriveKey({
    required String businessId,
    required String saltBase64,
  }) async {
    final salt = base64Decode(saltBase64);
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode('$businessId$_appSalt')),
      nonce: salt,
    );
  }

  Future<Uint8List> encrypt({
    required Uint8List plainBytes,
    required String businessId,
    required String saltBase64,
  }) async {
    final secretKey = await deriveKey(
      businessId: businessId,
      saltBase64: saltBase64,
    );
    final nonce = _randomBytes(12);
    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );
    return Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  Future<Uint8List> decrypt({
    required Uint8List encryptedBytes,
    required String businessId,
    required String saltBase64,
  }) async {
    if (encryptedBytes.length < 28) {
      throw const FormatException('Invalid encrypted backup payload');
    }

    final secretKey = await deriveKey(
      businessId: businessId,
      saltBase64: saltBase64,
    );
    final nonce = encryptedBytes.sublist(0, 12);
    final mac = encryptedBytes.sublist(encryptedBytes.length - 16);
    final cipherText = encryptedBytes.sublist(12, encryptedBytes.length - 16);

    final clearBytes = await _algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: secretKey,
    );
    return Uint8List.fromList(clearBytes);
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}
