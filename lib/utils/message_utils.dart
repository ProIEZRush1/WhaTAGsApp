import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/FIleUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';

class MessageUtils {
  static List<Contact>? cachedContacts;

  static String getNameFromData(String id, {String? name}) {
    // final String id = chatContactData["id"];
    String phoneNumber = id.split("@")[0];
    final contactName = getContactName(phoneNumber) ?? name ?? "+$phoneNumber";
    return contactName;
  }

  static String? getContactName(String phoneNumber, {bool fromId = false}) {
    if (fromId) {
      try {
        phoneNumber = phoneNumber.split("@")[0];
      } on Exception catch (e) {
        debugPrint(e.toString());
        return null;
      }
    }
    String sanitizedInput = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (sanitizedInput.length >= 4) {
      // sanitizedInput = sanitizedInput.substring(2);
      sanitizedInput = sanitizedInput.substring(4);
    }

    if (cachedContacts != null) {
      for (var contact in cachedContacts!) {
        for (final phone in contact.phones) {
          String sanitizedContact = phone.number.replaceAll(RegExp(r'\D'), '');

          if (sanitizedContact.length >= 3) {
            // sanitizedContact = sanitizedContact.substring(2);
            sanitizedContact = sanitizedContact.substring(3);
          }
          // print('sanitizedInput $sanitizedInput $sanitizedContact');
          if (sanitizedInput == sanitizedContact ||
              sanitizedContact == sanitizedInput) {
            return contact.displayName;
          }
        }
      }
    }
    return null; // Return null if no contact is found
  }

  static Future<String?> getLocalFilePath(String messageId) async {
    var box = await Hive.openBox('config');
    return box.get('localFilePath_$messageId');
  }

  static Future<void> deleteLocalFilePath(String messageId) async {
    var box = await Hive.openBox('config');
    box.delete('localFilePath_$messageId');
  }

  static Future<bool> downloadAndSaveFile(BuildContext context, WidgetRef ref,
      String chatId, String messageId, MessageEnum messageEnum) async {
    bool downloadSuccess = false;

    final ApiService apiService = ApiService();
    var box = await Hive.openBox('config');
    String deviceToken = box.get('lastDeviceId') ?? "";
    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    try {
      var value = await apiService.get(
        context,
        ref,
        "${apiService.downloadMessageEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid&chatId=$chatId&messageId=$messageId",
      );
      // log('value### ${value}');
      var fileName =
          value['fileName'] ?? FileUtils.getFileNameByType(messageEnum);
      if (apiService.checkSuccess(value)) {
        Uint8List uint8list =
            Uint8List.fromList(List<int>.from(value['buffer']['data']));
        String savedPath = await saveFileToPermanentLocation(
            fileName, messageId, uint8list, messageEnum);
        // print('File save at ${savedPath}');
        box.put('localFilePath_$messageId', savedPath);
        downloadSuccess = true;
      } else {
        Fluttertoast.showToast(msg: 'Something went wrong');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Something went wrong $e');
    }

    return downloadSuccess;
  }

  static Future updateSaveMediaMessageId(
    String messageId,
    String newMessageId,
  ) async {
    var box = await Hive.openBox('config');
    var path = await getLocalFilePath(messageId);
    box.put('localFilePath_$newMessageId', path);
  }

  static Future<bool> saveSendFile(String messageId, String fileName, File file,
      MessageEnum messageEnum) async {
    bool downloadSuccess = false;
    var box = await Hive.openBox('config');
    try {
      String savedPath = await saveFileToPermanentLocation(
          fileName, messageId, await file.readAsBytes(), messageEnum,
          isSend: true);
      // print('File save at ${savedPath}');
      box.put('localFilePath_$messageId', savedPath);
      downloadSuccess = true;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Something went wrong');
    }

    return downloadSuccess;
  }

  static String? getFileExtension(MessageEnum type) {
    switch (type) {
      case MessageEnum.image:
        return "jpg";
      case MessageEnum.audio:
      case MessageEnum.voice:
        return "mp3";
      case MessageEnum.video:
        return "mp4";
      case MessageEnum.gif:
        return "gif";
      case MessageEnum.sticker:
        return "webp";
      default:
        return null;
    }
  }

  static Future<String> saveFileToPermanentLocation(String fileName,
      String messageId, Uint8List buffer, MessageEnum messageEnum,
      {bool isSend = false}) async {
    final directory = await getApplicationDocumentsDirectory();
    // final fileExtension = getFileExtension(type);
    // final filePath =
    //     '${directory.path}/downloads/$messageId.${fileExtension.toLowerCase()}';
    final filePath =
        '${directory.path}/Media/Whatagsapp ${messageEnum.name}/${isSend ? 'sent/' : ''}$fileName';
    final file = FileUtils.checkExistingFile(filePath);

    await file.writeAsBytes(buffer);
    return file.path;
  }

  static Future deleteAllDownload() async {
    var value = await getApplicationDocumentsDirectory();
    var downloads = Directory('${value.path}/downloads');
    if (await downloads.exists()) {
      try {
        var delete = await downloads.delete(recursive: true);
        debugPrint('${delete.path} is deleted successful');
      } catch (e) {
        debugPrint('deleted downloads failed');
      }
    }
  }

  static Future<bool> openFile(String path) async {
    print(path);
    final result = await OpenFile.open(path);
    final type = result.type;
    print(result.message);
    if (type == ResultType.fileNotFound) {
      Fluttertoast.showToast(msg: 'File not found try re downloading');
      return false;
    } else if (type != ResultType.done) {
      Fluttertoast.showToast(msg: 'Could not open the file');
      return false;
    }
    return true;
  }

  static Future<bool> isFileDownloaded(String messageId) async {
    String? localFilePath = await getLocalFilePath(messageId);
    return localFilePath != null && localFilePath.isNotEmpty;
  }
}