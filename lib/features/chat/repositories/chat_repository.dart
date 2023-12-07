import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

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

  void sendTextMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text, String key) async {
    try {
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
          "body": await EncryptionUtils.encrypt(text, key),
          "type": "text",
          "fromMe": true,
          "media": false,
        },
        "messageTimestamp": timestamp ~/ 1000,
        "status": 1,
      };
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

      final dataToSend = {"type": "text", "data": text};
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
      File file) async {
    try {
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
          if (text.isNotEmpty) "body": await EncryptionUtils.encrypt(text, key),
          "type": messageEnum.name,
          "fromMe": true,
          "media": true,
          "fileName":file.path.split('/').last,
          "fileLength": file.readAsBytesSync().length,
        },
        "messageTimestamp": timestamp ~/ 1000,
        "status": 1,
      };
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

      final dataToSend = {
        "type": messageEnum.type,
        "caption": text,
        // 'file':file,
        'fileName': file.path.split('/').last,
        'media': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        )
      };
      debugPrint(dataToSend.toString());
      apiService
          .postMultipart(
              "${apiService.sendMediaMessageEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&to=$chatId&id=$messageId",
              dataToSend)
          .then((data) {
        print('data postMultipart==$data');
        if (!apiService.checkSuccess(data)) {
          Fluttertoast.showToast(
            msg: "Something went wrong",
          );
          return Future.error("Something went wrong");
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
}
