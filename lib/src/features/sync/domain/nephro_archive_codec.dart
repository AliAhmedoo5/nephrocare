import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'patient_sync_bundle.dart';

/// Exception thrown when `.nephro` archive decryption or authentication fails.
class NephroArchiveDecryptionException implements Exception {
  final String message;
  NephroArchiveDecryptionException(this.message);

  @override
  String toString() => 'NephroArchiveDecryptionException: $message';
}

/// Standalone codec for Encrypted Patient Export (`.nephro`) archives.
///
/// Encrypts and decrypts full relational datasets using AES-256-GCM authenticated
/// encryption with PBKDF2-HMAC-SHA256 key derivation from a user/clinician passphrase.
class NephroArchiveCodec {
  static const String magicHeader = 'NEPHRO1\x00';
  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int macLength = 16;

  static final _secureRandom = Random.secure();

  static List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _secureRandom.nextInt(256));
  }

  /// Encrypts a [PatientSyncBundle] into an authenticated `.nephro` binary archive.
  static Future<Uint8List> encryptBundle(
    PatientSyncBundle bundle, {
    required String passphrase,
  }) async {
    final jsonString = jsonEncode(bundle.toJson());
    final plainBytes = utf8.encode(jsonString);

    final salt = _randomBytes(saltLength);
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 10000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );

    final algorithm = AesGcm.with256bits();
    final nonce = algorithm.newNonce();
    final secretBox = await algorithm.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final headerBytes = utf8.encode(magicHeader);
    final macBytes = secretBox.mac.bytes;
    final cipherText = secretBox.cipherText;

    final builder = BytesBuilder(copy: false)
      ..add(headerBytes)
      ..add(salt)
      ..add(nonce)
      ..add(macBytes)
      ..add(cipherText);

    return builder.toBytes();
  }

  /// Decrypts and validates a `.nephro` binary archive using the provided passphrase.
  static Future<PatientSyncBundle> decryptBundle(
    Uint8List archiveBytes, {
    required String passphrase,
  }) async {
    final headerBytes = utf8.encode(magicHeader);
    final minLength = headerBytes.length + saltLength + nonceLength + macLength;
    if (archiveBytes.length < minLength) {
      throw NephroArchiveDecryptionException('Archive payload is too short or invalid.');
    }

    // Verify magic header
    for (int i = 0; i < headerBytes.length; i++) {
      if (archiveBytes[i] != headerBytes[i]) {
        throw NephroArchiveDecryptionException('Invalid archive magic header.');
      }
    }

    int offset = headerBytes.length;
    final salt = archiveBytes.sublist(offset, offset + saltLength);
    offset += saltLength;

    final nonce = archiveBytes.sublist(offset, offset + nonceLength);
    offset += nonceLength;

    final macBytes = archiveBytes.sublist(offset, offset + macLength);
    offset += macLength;

    final cipherText = archiveBytes.sublist(offset);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 10000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    try {
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      final jsonString = utf8.decode(decryptedBytes);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return PatientSyncBundle.fromJson(jsonMap);
    } catch (_) {
      throw NephroArchiveDecryptionException(
        'Decryption failed: incorrect passphrase or corrupted archive.',
      );
    }
  }
}
