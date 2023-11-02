import 'dart:io';
import 'dart:typed_data';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class MessageUtils {
  static Future<String?> getLocalFilePath(String messageId) async {
    var box = await Hive.openBox('config');
    return box.get('localFilePath_$messageId');
  }

  static Future<void> deleteLocalFilePath(String messageId) async {
    var box = await Hive.openBox('config');
    box.delete('localFilePath_$messageId');
  }

  static Future<bool> downloadAndSaveFile(BuildContext context, WidgetRef ref,
      String chatId, String messageId, MessageEnum type) async {
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

      if (apiService.checkSuccess(value)) {
        Uint8List uint8list =
            Uint8List.fromList(List<int>.from(value['buffer']['data']));
        String savedPath =
            await saveFileToPermanentLocation(type, messageId, uint8list);

        box.put('localFilePath_$messageId', savedPath);
        downloadSuccess = true;
      } else {
        Fluttertoast.showToast(msg: 'Something went wrong');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Something went wrong');
    }

    return downloadSuccess;
  }

  static String getFileExtension(MessageEnum type) {
    switch (type) {
      case MessageEnum.image:
        return ".jpg";
      case MessageEnum.audio:
        return ".mp3";
      case MessageEnum.video:
        return ".mp4";
      case MessageEnum.gif:
        return ".gif";
      default:
        return ".txt";
    }
  }

  static Future<String> saveFileToPermanentLocation(
      MessageEnum type, String messageId, Uint8List buffer) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileExtension = getFileExtension(type);
    final filePath = '${directory.path}/$messageId$fileExtension';
    final file = File(filePath);
    await file.writeAsBytes(buffer);
    return filePath;
  }

  static Future<bool> openFile(String path) async {
    final result = await OpenFile.open(path);
    final type = result.type;

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
