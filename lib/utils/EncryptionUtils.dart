import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionUtils {
  static String deriveKeyFromPassword(String password, String salt,
      {int keyLength = 32, int iterations = 10000}) {
    var gen = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    gen.init(Pbkdf2Parameters(
        Uint8List.fromList(utf8.encode(salt)), iterations, keyLength));
    var key = gen.process(Uint8List.fromList(utf8.encode(password)));

    // Convert the Uint8List to a Base64 string
    return base64Encode(key);
  }

  static String encrypt(String plainText, String keyS) {
    Uint8List keyBytes = base64Decode(keyS);
    final key = Key(keyBytes);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return iv.base64 + encrypted.base64;
  }

  static String decrypt(String encryptedText, String keyS) {
    try {
      Uint8List keyBytes = base64Decode(keyS);
      final key = Key(keyBytes);
      final iv = IV.fromBase64(encryptedText.substring(0, 24));
      final cipherText = Encrypted.fromBase64(encryptedText.substring(24));
      final encrypter =
          Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
      final decrypted = encrypter.decrypt(cipherText, iv: iv);
      return decrypted;
    } catch (e) {
      return encryptedText;
    }
  }
}
