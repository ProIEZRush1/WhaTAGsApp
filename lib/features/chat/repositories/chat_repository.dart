import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
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
import 'package:rxdart/rxdart.dart';

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
    final Stream<List<Map<String, dynamic>>> firebaseStream = firestore
        .collection('users')
        .doc(userId)
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('information.timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Process documents from Firestore
      List<Map<String, dynamic>> firestoreMessages =
          snapshot.docChanges.map((doc) => doc.doc.data() ?? {}).toList();

      firestoreMessages.sort((a, b) {
        int aTimestamp = a['information']['timestamp'] as int? ?? 0;
        int bTimestamp = b['information']['timestamp'] as int? ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      for (var message in firestoreMessages) {
        //print("HOLA " + message['key']['id'] + " " + message["information"]["body"]);
      }

      await chatDatabase.saveMessages(ref, chatId, firestoreMessages);
      List<Map<String, dynamic>> messages =
          await chatDatabase.getMessages(chatId);

      return messages;
    });

    final databaseStreamController =
        chatDatabase.getChatsStreamController(chatId);
    databaseStreamController.stream.listen((event) {
      for (var message in event) {
        //print("ADIOS " + message['key']['id'] + " " + message["information"]["body"]);
      }
    });

    return CombineLatestStream.list(
            [firebaseStream, databaseStreamController.stream])
        .map((List<List<Map<String, dynamic>>> combinedList) {
      final allMessages = {...combinedList[0], ...combinedList[1]}.toList();

      return combinedList[1];
    }).asBroadcastStream();
  }

  void sendTextMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text, String key) async {
    try {
      // Create default message in storage
      final id =
          await chatDatabase.createDefaultMessage(ref, chatId, true, text, key);

      final ApiService apiService = ApiService();

      final firebaseUid =
          ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      final dataToSend = {"type": "text", "data": text};
      final jsonDataToSend = Uri.encodeComponent(jsonEncode(dataToSend));

      apiService
          .get(context, ref,
              "${apiService.sendMessageEndpoint}?deviceToken=$deviceId&firebaseUid=$firebaseUid&to=$chatId&data=$jsonDataToSend&id=$id")
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
