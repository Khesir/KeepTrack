import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class WrongPasswordException implements Exception {
  const WrongPasswordException();
}

class InvalidBackupException implements Exception {
  const InvalidBackupException();
}

class BackupEncryptionService {
  List<int> _deriveKey(String password, List<int> salt) {
    var digest = sha256.convert([...utf8.encode(password), ...salt]).bytes;
    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert([...digest, ...salt]).bytes;
    }
    return digest;
  }

  String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  List<int> _fromHex(String hex) => List.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      );

  String encrypt(String payload, String password) {
    final rand = Random.secure();
    final salt = List.generate(16, (_) => rand.nextInt(256));
    final ivBytes = List.generate(16, (_) => rand.nextInt(256));

    final key = Key(Uint8List.fromList(_deriveKey(password, salt)));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(payload, iv: iv);

    return jsonEncode({
      'version': '1.0',
      'salt': _toHex(salt),
      'iv': _toHex(ivBytes),
      'data': encrypted.base64,
    });
  }

  String decrypt(String envelopeJson, String password) {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
    } catch (_) {
      throw const InvalidBackupException();
    }

    if (envelope['version'] != '1.0') throw const InvalidBackupException();

    final salt = _fromHex(envelope['salt'] as String);
    final ivBytes = _fromHex(envelope['iv'] as String);
    final cipherData = envelope['data'] as String;

    final key = Key(Uint8List.fromList(_deriveKey(password, salt)));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key));

    try {
      final decrypted = encrypter.decrypt(Encrypted.fromBase64(cipherData), iv: iv);
      final parsed = jsonDecode(decrypted) as Map<String, dynamic>;
      if (parsed['boxes'] == null) throw const InvalidBackupException();
      return decrypted;
    } on ArgumentError {
      throw const WrongPasswordException();
    } on FormatException {
      throw const WrongPasswordException();
    }
  }
}
