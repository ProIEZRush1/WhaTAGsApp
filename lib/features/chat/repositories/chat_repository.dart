import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/common/repositories/common_firebase_storage_repository.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/models/chat.dart';
import 'package:com.jee.tag.whatagsapp/models/message.dart';
import 'package:com.jee.tag.whatagsapp/models/user_model.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';

import '../../../utils/DeviceUtils.dart';

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

  Stream<List<Map<String, dynamic>>> getChatsStreamJson(
      BuildContext context, WidgetRef ref, String key) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots(includeMetadataChanges: false)
        .asyncMap((event) async {
      // Step 1: Retrieve existing chats from local database
      List<Map<String, dynamic>> existingChats = await chatDatabase.getChats();

      var decryptFutures = <Future<Map<String, dynamic>>>[];

      for (var document in event.docChanges) {
        decryptFutures.add(_processDocument(document, key));
      }

      // Step 2: Await all decryption tasks to complete
      List<Map<String, dynamic>> changedChats =
          await Future.wait(decryptFutures);

      // Filter out empty chats
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

      // Step 3: Sort and save merged chats to local database
      existingChats.sort((a, b) {
        return b['lastMessage']['timestamp']
            .compareTo(a['lastMessage']['timestamp']);
      });

      await chatDatabase.saveChats(existingChats);

      // Step 4: Return the merged chats
      return existingChats;
    });
  }

  Future<Map<String, dynamic>> _processDocument(
      DocumentChange document, String key) async {
    try {
      final chat = document.doc.data() as Map<String, dynamic>;

      // Decrypt all strings in the chat map
      final decryptedChat = deepDecrypt(chat, key);

      if (decryptedChat["lastMessage"]["body"] == null) {
        return {};
      }

      decryptedChat["lastMessage"] =
          deepDecrypt(decryptedChat['lastMessage'], key);
      return decryptedChat;
    } catch (e) {
      print(e);
    }
    return {}; // return an empty map if there's an error or the condition fails
  }

  Stream<List<Map<String, dynamic>>> getChatMessagesStream(
      BuildContext context, WidgetRef ref, String chatId, String key) {
    final String userId = auth.currentUser!.uid;

    return firestore
        .collection('users')
        .doc(userId)
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .snapshots(includeMetadataChanges: false)
        .asyncMap((event) async {
      // Step 1: Retrieve existing messages from local database
      List<Map<String, dynamic>> existingMessages =
          await chatDatabase.getMessages(chatId);

      var decryptFutures = <Future<Map<String, dynamic>>>[];

      for (var document in event.docChanges) {
        decryptFutures.add(_processMessageDocument(document, key));
      }

      // Step 2: Await all decryption tasks to complete
      List<Map<String, dynamic>> changedMessages =
          await Future.wait(decryptFutures);
      changedMessages =
          changedMessages.where((message) => message.isNotEmpty).toList();

      // Merge changes into existing messages
      for (var changedMessage in changedMessages) {
        final index = existingMessages.indexWhere(
            (message) => message["key"]["id"] == changedMessage["key"]["id"]);

        if (index != -1) {
          existingMessages[index] = changedMessage;
        } else {
          existingMessages.add(changedMessage);
        }
      }

      // Step 3: Sort and save merged messages to local database
      try {
        existingMessages.sort(
            (a, b) => b['messageTimestamp'].compareTo(a['messageTimestamp']));
      } catch (e) {
        print("Sorting error: $e");
      }

      await chatDatabase.saveMessages(chatId, existingMessages);

      // Step 4: Return the merged messages
      return existingMessages.reversed.toList();
    });
  }

  Future<Map<String, dynamic>> _processMessageDocument(
      DocumentChange document, String key) async {
    var messageData = document.doc.data() as Map<String, dynamic>;

    // Assuming deepDecrypt is a function that decrypts necessary fields
    final decryptedMessageData = deepDecrypt(messageData, key);

    return decryptedMessageData;
  }

  // Cache to store decrypted values
  Map<String, dynamic> decryptionCache = {};

  dynamic deepDecrypt(dynamic obj, String key) {
    try {
      if (obj == null) {
        return obj; // Return the object as is if it's null
      }

      if (obj is List) {
        // Recursively decrypt each item if the obj is an array
        return obj.map((item) => deepDecrypt(item, key)).toList();
      }

      if (obj is Map<String, dynamic>) {
        // Recursively decrypt each value if the obj is an object
        Map<String, dynamic> newObj = {};
        obj.forEach((k, v) {
          if (v is String) {
            // Check if value is in cache
            if (decryptionCache.containsKey(v)) {
              newObj[k] = decryptionCache[v];
            } else {
              newObj[k] =
                  EncryptionUtils.decrypt(v, key); // Decrypt string values
              decryptionCache[v] = newObj[k]; // Cache decrypted value
            }
          } else {
            newObj[k] = deepDecrypt(v, key);
          }
        });
        return newObj;
      }

      return obj; // Return the object as is if it's not an object/array
    } catch (e) {
      return obj;
    }
  }

  void sendTextMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text) async {
    try {
      final ApiService apiService = ApiService();

      final firebaseUid =
          ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      final dataToSend = {"type": "text", "data": text};
      final jsonDataToSend = Uri.encodeComponent(jsonEncode(dataToSend));

      apiService
          .get(context, ref,
              "${apiService.sendMessageEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&to=$chatId&data=$jsonDataToSend")
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

  void sendFileMessage({
    required BuildContext context,
    required File file,
    required String receiverUserId,
    required UserModel senderUserData,
    required ProviderRef ref,
    required MessageEnum messageEnum,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();

      String imageUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'chat/${messageEnum.type}/${senderUserData.uid}/$receiverUserId/$messageId',
            file,
          );

      UserModel? receiverUserData;
      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      String contactMsg;

      switch (messageEnum) {
        case MessageEnum.image:
          contactMsg = '📷 Photo';
          break;
        case MessageEnum.video:
          contactMsg = '📸 Video';
          break;
        case MessageEnum.audio:
          contactMsg = '🎵 Audio';
          break;
        case MessageEnum.gif:
          contactMsg = 'GIF';
          break;
        default:
          contactMsg = 'GIF';
      }
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendGIFMessage({
    required BuildContext context,
    required String gifUrl,
    required String receiverUserId,
    required UserModel senderUser,
    required MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      UserModel? receiverUserData;

      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();
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
