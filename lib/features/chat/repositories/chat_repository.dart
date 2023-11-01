import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';

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
        return obj;
      }

      if (obj is List) {
        return obj.map((item) => deepDecrypt(item, key)).toList();
      }

      if (obj is Map<String, dynamic>) {
        Map<String, dynamic> newObj = {};
        obj.forEach((k, v) {
          decryptionCache.clear();
          if (v is String) {
            if (decryptionCache.containsKey(v)) {
              newObj[k] = decryptionCache[v];
            } else {
              newObj[k] = EncryptionUtils.decrypt(v, key);
              decryptionCache[v] = newObj[k];
            }
          } else {
            newObj[k] = deepDecrypt(v, key);
          }
        });
        return newObj;
      }

      return obj;
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
