import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/download_upload_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:com.jee.tag.whatagsapp/utils/message_utils.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/LocationUtils.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:mime/mime.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:http_parser/http_parser.dart' as http;
import 'package:whatsapp_camera/modle/file_media_model.dart';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      storage: FirebaseStorage.instance,
      messaging: FirebaseMessaging.instance),
);

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;
  final FirebaseMessaging messaging;

  ChatRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
    required this.messaging,
  });

  final chatDatabase = ChatDatabase();

  Stream<List<Map<String, dynamic>>> getChatsStream(
      BuildContext context, WidgetRef ref, String key) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots(includeMetadataChanges: false)
        .asyncMap((event) async {
      // Step 1: Retrieve existing chats from local database
      List<Map<String, dynamic>> existingChats = await chatDatabase.getChats();

      List<Map<String, dynamic>> changedChats = [];
      for (var document in event.docChanges) {
        changedChats.add(document.doc.data() ?? {});
      }
      changedChats = changedChats.where((chat) => chat.isNotEmpty).toList();

      // Merge changes into existing chats
      for (var changedChat in changedChats) {
        final index =
            existingChats.indexWhere((chat) => chat["id"] == changedChat["id"]);

        if (index != -1) {
          existingChats[index] = changedChat;
        } else {
          existingChats.add(changedChat);
        }
      }

      // Sort and save merged chats to local database
      existingChats.sort((a, b) {
        return b['lastMessage']['timestamp']
            .compareTo(a['lastMessage']['timestamp']);
      });

      await chatDatabase.saveChats(existingChats);

      // Return the merged chats
      return existingChats;
    });
  }

  Future<void> removeSentId(String chatId, String messageId) async {
    final String userId = auth.currentUser!.uid;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'sentId': FieldValue.delete(),
    });
  }

  Future<bool> isNewChat(String chatId) async {
    final String userId = auth.currentUser!.uid;
    var msg = await firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .get();
    return msg.data()?.isEmpty ?? true;
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(
      BuildContext context, WidgetRef ref, String chatId, String key) {
    final String userId = auth.currentUser!.uid;
    return firestore
        .collection('users')
        .doc(userId)
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('information.timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Process documents from Firestore
      List<Map<String, dynamic>> firestoreMessages = [];
      for (var document in snapshot.docChanges) {
        var message = document.doc.data() ?? {};
        message["type"] = document.type;
        firestoreMessages.add(message);
      }

      return firestoreMessages;
    });
  }

  void sendMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text, String key, MessageEnum messageEnum,
      {Contact? contact}) async {
    try {
      final dataToSend = {"type": messageEnum.name, "data": text};
      // Create default message in storage
      final String messageId = const Uuid().v4(); // Generates a unique ID
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      final Map<String, dynamic> defaultMessage = {
        "key": {
          "remoteJid": chatId,
          "fromMe": true,
          "id": messageId,
        },
        "information": {
          "status": 1,
          "timestamp": timestamp ~/ 1000,
          if (messageEnum == MessageEnum.text)
            "body": await EncryptionUtils.encrypt(text, key),
          "type": messageEnum.name,
          "fromMe": true,
          "media": false,
        },
        "messageTimestamp": timestamp ~/ 1000,
        "status": 1,
      };
      if (messageEnum == MessageEnum.location) {
        var location = await LocationUtils.getLocation();
        if (location == null) {
          Fluttertoast.showToast(
            msg: "Unable to get location",
          );
          return;
        }
        defaultMessage["information"]['degreesLatitude'] = location.latitude;
        defaultMessage["information"]['degreesLongitude'] = location.longitude;
        dataToSend['degreesLatitude'] = location.latitude.toString();
        dataToSend['degreesLongitude'] = location.longitude.toString();
      } else if (messageEnum == MessageEnum.vcard) {
        if (contact == null) {
          Fluttertoast.showToast(
            msg: "Please select contact",
          );
          return;
        }
        var name = contact.name.first + contact.name.middle + contact.name.last;

        // dataToSend['displayName']=name;
        // var vcard=contact.toVCard();
        final number = contact.phones.map((e) => e.number).join();
        // int index= vcard.indexOf('TYPE=cell');
        //  vcard=  vcard.replaceAll('TYPE=cell,', 'TYPE=cell;waid=${number.replaceAll('+', '').replaceAll(' ', '')}:$number;');
        //  dataToSend['vcard']=vcard;
        //  print('object==$vcard');//waid=911234567890

        // print('object===$number');
        final vcard = 'BEGIN:VCARD\n' // metadata of the contact card
            +
            'VERSION:3.0\n' +
            'FN:$name\n' // full name
            +
            'ORG:${contact.organizations.firstOrNull?.title ?? ""};\n' // the organization of the contact
            +
            'TEL;type=CELL;type=VOICE;waid=${number.replaceAll('+', '').replaceAll(' ', '')}:$number\n' // WhatsApp ID + phone number
            // + 'TEL;type=CELL;type=VOICE;waid=911234567890:+91 12345 67890\n' // WhatsApp ID + phone number
            +
            'END:VCARD';
        dataToSend['displayName'] = name;
        defaultMessage["information"]['displayName'] = name;
        dataToSend['vcard'] = vcard;
        defaultMessage["information"]['vcard'] = vcard;
      }
      firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(defaultMessage);

      final ApiService apiService = ApiService();

      final firebaseUid =
          ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      final jsonDataToSend = Uri.encodeComponent(jsonEncode(dataToSend));

      apiService
          .get(context, ref,
              "${apiService.sendMessageEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&to=$chatId&data=$jsonDataToSend&id=$messageId")
          .then((data) {
        if (!apiService.checkSuccess(data)) {
          Fluttertoast.showToast(
            msg: "Something went wrong",
          );
          return Future.error("Something went wrong");
        }
        apiService.checkIfLoggedIn(context, ref, data);
      });
    } catch (e) {
      debugPrint('Error $e');
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendMediaMessage(
      BuildContext context,
      WidgetRef ref,
      String deviceId,
      String chatId,
      String text,
      String key,
      MessageEnum messageEnum,
      File file,
      {double? time,
      FileMediaModel? model}) async {
    try {
      final name = file.path.split('/').last;
      final dataToSend = <String, String>{
        "type": messageEnum.type,
        if (text.isNotEmpty) "caption": text,
        // 'file':file,
        if (model?.thumbnail != null)
          'jpegThumbnail': base64.encode(model!.thumbnail!),
        if (model?.duration != null) 'seconds': model!.duration.toString(),
        if (model?.width != null) 'width': model!.width.toString(),
        if (model?.height != null) 'height': model!.height.toString(),
        'mimetype': lookupMimeType(file.path) ?? '${messageEnum.type}/',
        'fileName': name,
        // 'media': await MultipartFile.fromFile(
        //   file.path,
        //   // contentType: http.MediaType(),
        //   filename: name,
        // )
      };
      print('dataToSend $dataToSend');
      // Create default message in storage
      final String messageId = const Uuid().v4(); // Generates a unique ID
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      MessageUtils.saveSendFile(messageId, name, file, messageEnum);

      final Map<String, dynamic> defaultMessage = {
        "key": {
          "remoteJid": chatId,
          "fromMe": true,
          "id": messageId,
        },
        "information": {
          "status": 1,
          "timestamp": timestamp ~/ 1000,
          if (text.isNotEmpty)
            "caption": await EncryptionUtils.encrypt(text, key),
          "type": messageEnum.name,
          "fromMe": true,
          "media": true,
          'seconds': model?.duration,
          'width': model?.width,
          'height': model?.height,
          if (time != null) 'seconds': time,
          "fileName": file.path.split('/').last,
          'jpegThumbnail': model?.thumbnail,
          "fileLength": file.readAsBytesSync().length,
        },
        "messageTimestamp": timestamp ~/ 1000,
        "status": 1,
      };
      if (messageEnum == MessageEnum.image) {
        var decodedImage = await decodeImageFromList(file.readAsBytesSync());
        defaultMessage["information"]['height'] = decodedImage.height;
        defaultMessage["information"]['width'] = decodedImage.width;
        dataToSend['height'] = decodedImage.height.toString();
        dataToSend['width'] = decodedImage.width.toString();
      } else if (messageEnum == MessageEnum.video) {
        var height = 848, width = 384;
        defaultMessage["information"]['height'] = height;
        defaultMessage["information"]['width'] = width;
        dataToSend['height'] = height.toString();
        dataToSend['width'] = width.toString();
      }
      firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(defaultMessage);

      final ApiService apiService = ApiService();

      final firebaseUid =
          ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      debugPrint(dataToSend.toString());

      final url =
          "${apiService.baseUrl}${apiService.sendMediaMessageEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&to=$chatId&id=$messageId";

      // return;
      // apiService
      //     .postMultipart(
      //     url,
      //         dataToSend)
      UploadCtr.instance.upload(
              path: file.path, url: url, data: dataToSend, id: messageId)
          .then((d) {
        print('data url==$url');
        var data = json.decode(d ?? '');
        print('data postMultipart==$data');
        data = data['data'];
        if (!apiService.checkSuccess(data)) {
          Fluttertoast.showToast(
            msg: "Something went wrong",
          );
          return Future.error("Something went wrong");
        } else {
          final id = data['messageData']?['key']?['id'];
          if (id is String) {
            MessageUtils.updateSaveMediaMessageId(messageId, id);
          } else {
            debugPrint('id not found ');
          }
        }
        apiService.checkIfLoggedIn(context, ref, data);
      });
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void setChatSeen(BuildContext context, WidgetRef ref, String deviceId,
      String chatId) async {
    final ApiService apiService = ApiService();

    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    apiService
        .get(context, ref,
            "${apiService.markAllAsReadEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&chatId=$chatId")
        .then((data) {
      if (!apiService.checkSuccess(data)) {
        Fluttertoast.showToast(msg: 'Something went wrong');
      }
      apiService.checkIfLoggedIn(context, ref, data);
    });
  }

  Future<String?> getProfileUrl(BuildContext context, WidgetRef ref,
      String deviceId, String profileId) async {
    final ApiService apiService = ApiService();

    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    var data = await apiService.get(context, ref,
        "${apiService.getProfileEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&profileId=$profileId");
    if (!apiService.checkSuccess(data)) {
      // Fluttertoast.showToast(msg: 'Something went wrong');
    } else {
      // print(data);
      return data['profileUrl'];
    }
    return null;
  }

  Future<bool> isAvailableOnWhatsApp(BuildContext context, WidgetRef ref,
      String deviceId, String number) async {
    final ApiService apiService = ApiService();

    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    var data = await apiService.get(context, ref,
        "${apiService.isAvailableEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&number=$number");
    if (!apiService.checkSuccess(data)) {
      // Fluttertoast.showToast(msg: 'Something went wrong');
    } else {
      // print(data);
      return data['exists'] ?? false;
    }
    return false;
  }
  Future<Map<String, dynamic>?> getUserDetails(BuildContext context, WidgetRef ref,
      String deviceId, String number) async {
    final ApiService apiService = ApiService();

    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    var data = await apiService.get(context, ref,
        "${apiService.getUserDetailEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&number=$number");
    if (!apiService.checkSuccess(data)) {
      // Fluttertoast.showToast(msg: 'Something went wrong');
    } else {
      // print(data);
      return data;
    }
    return null;
  }
}
