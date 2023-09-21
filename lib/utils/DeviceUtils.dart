import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceUtils {

  static Future<String?> getDeviceId() async {
    if (kIsWeb) {
      // Importing this way might not be efficient but it's a workaround
      var uuid = Uuid();
      return uuid.v4().replaceAll("-", "");
    } else if (Platform.isIOS) {
      var deviceInfo = DeviceInfoPlugin();
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return _sanitizeId(iosDeviceInfo.identifierForVendor); // unique ID on iOS
    } else if (Platform.isAndroid) {
      var deviceInfo = DeviceInfoPlugin();
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return _sanitizeId(androidDeviceInfo.id); // unique ID on Android
    }
    return "";
  }

  static String _sanitizeId(String? id) {
    if (id != null) {
      return id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    }
    return "";
  }

}