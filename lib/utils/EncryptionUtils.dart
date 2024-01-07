import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // Add crypto package for SHA-256
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart';
import 'package:hive/hive.dart';

class EncryptionUtils {
  static const encryptionSignature = 'ECH:';

  static Future<Box> _openBox() async {
    if (!Hive.isBoxOpen('encryptionCache')) {
      return await Hive.openBox('encryptionCache');
    }
    return Hive.box('encryptionCache');
  }

  static Future<String> deriveKeyFromPassword(String password, String salt,
      {int keyLength = 32, int iterations = 10000}) async {
    var gen = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    gen.init(Pbkdf2Parameters(
        Uint8List.fromList(utf8.encode(salt)), iterations, keyLength));
    var key = gen.process(Uint8List.fromList(utf8.encode(password)));
    return base64Encode(key);
  }

  static Future<String> encrypt(String plainText, String keyS) async {
    if (isEncrypted(plainText)) {
      return plainText;
    }

    var box = await _openBox();
    String cacheKey = _generateCacheKey(plainText, keyS);
    if (box.containsKey(cacheKey)) {
      return box.get(cacheKey);
    }

    Uint8List keyBytes = base64Decode(keyS);
    final key = Key(keyBytes);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    String result = encryptionSignature + iv.base64 + encrypted.base64;
    await box.put(cacheKey, result);
    return result;
  }

  static Future<String> decrypt(String encryptedText, String keyS) async {
    if (!isEncrypted(encryptedText)) {
      return encryptedText;
    }
    encryptedText = encryptedText.substring(encryptionSignature.length);

    var box = await _openBox();
    String cacheKey = _generateCacheKey(encryptedText, keyS);
    if (box.containsKey(cacheKey)) {
      return box.get(cacheKey);
    }

    Uint8List keyBytes = base64Decode(keyS);
    final key = Key(keyBytes);
    final iv = IV.fromBase64(encryptedText.substring(0, 24));
    final cipherText = Encrypted.fromBase64(encryptedText.substring(24));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final decrypted = encrypter.decrypt(cipherText, iv: iv);

    await box.put(cacheKey, decrypted);
    return decrypted;
  }

  static bool isEncrypted(String text) {
    return text.startsWith(encryptionSignature);
  }

  static String _generateCacheKey(String text, String keyS) {
    var bytes = utf8.encode(text + keyS);
    var digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  ///Accepts encrypted data and decrypt it. Returns plain text
  static Uint8List decryptFileWithAES(
      {required Uint8List key,
      required Uint8List iv,
      required Uint8List encryptedData}) {
    final cipherKey = Key(key);
    final encryptService = Encrypter(
      AES(
        cipherKey,
        mode: AESMode.cbc,
      ),
    ); //Using AES CBC encryption
    final initVector = IV(iv);
    var val =
        encryptService.decryptBytes(Encrypted(encryptedData), iv: initVector);
    return Uint8List.fromList(val);
  }
}
