import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  Future<bool> firstTime() async {
    QuerySnapshot snapshot = await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .limit(1)
        .get();
    return snapshot.docs.isEmpty;
  }

  Stream<List<Map<String, dynamic>>> getChatsStreamJson(
      BuildContext context, WidgetRef ref, String key) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      var decryptFutures = <Future<Map<String, dynamic>>>[];

      for (var document in event.docs) {
        decryptFutures.add(_processDocument(document, key));
      }

      // Await all decryption tasks to complete
      List<Map<String, dynamic>> chats = await Future.wait(decryptFutures);
      chats = chats.where((chat) => chat.isNotEmpty).toList();
      chats.sort((a, b) => b['lastMessage']['timestamp']
          .compareTo(a['lastMessage']['timestamp']));

      return chats;
    });
  }

  Future<Map<String, dynamic>> _processDocument(
      DocumentSnapshot document, String key) async {
    try {
      final chat = document.data() as Map<String, dynamic>;

      // Decrypt all strings in the chat map
      final decryptedChat = deepDecrypt(chat, key);

      // Check if id contains @g.us
      final chatId = decryptedChat['id'];

      decryptedChat["lastMessage"] =
          deepDecrypt(decryptedChat['lastMessage'], key);
      if (chatId.contains('@g.us') || chatId.contains('@s.whatsapp.net')) {
        return decryptedChat;
      }
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
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .asyncMap((event) async {
      var decryptFutures = <Future<Map<String, dynamic>>>[];

      for (var document in event.docs) {
        decryptFutures.add(_processMessageDocument(document, key));
      }

      // Await all decryption tasks to complete
      List<Map<String, dynamic>> messages = await Future.wait(decryptFutures);
      messages = messages.where((message) => message.isNotEmpty).toList();
      try {
        messages.sort(
            (a, b) => b['messageTimestamp'].compareTo(a['messageTimestamp']));
      } catch (e) {}

      return messages.reversed.toList();
    });
  }

  Future<Map<String, dynamic>> _processMessageDocument(
      DocumentSnapshot document, String key) async {
    var messageData = document.data() as Map<String, dynamic>;

    // Assuming deepDecrypt is a function that decrypts necessary fields
    final decryptedMessageData = deepDecrypt(messageData, key);

    return decryptedMessageData;
  }

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
            newObj[k] =
                EncryptionUtils.decrypt(v, key); // Decrypt string values
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

  void sendTextMessage({
    required BuildContext context,
    required WidgetRef ref,
    required String chatId,
    required String text,
    required String receiverUserId,
  }) async {
    try {
      final ApiService apiService = ApiService();

      final deviceToken = await DeviceUtils.getDeviceId();
      final firebaseUid =
          ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      final dataToSend = {"type": "text", "data": text};
      final jsonDataToSend = Uri.encodeComponent(jsonEncode(dataToSend));

      final data = await apiService.get(context, ref,
          "${apiService.sendMessageEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid&to=$receiverUserId&data=$jsonDataToSend");
      if (!apiService.checkSuccess(data)) {
        Fluttertoast.showToast(msg: 'Something went wrong');
        return;
      }
      if (!await apiService.checkIfLoggedIn(context, ref, data)) {
        return;
      }
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

  void setChatSeen(BuildContext context, String chatId) async {
    final chatDoc = firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(chatId);

    await chatDoc.update({'unreadCount': 0});

    final messagesCollection = chatDoc.collection('messages');
    final messages = await messagesCollection.get();
    for (final message in messages.docs) {
      final data = message.data();
      final information = data['information'];
      final status = information['status'];
      if (status == 0) {
        await messagesCollection.doc(message.id).update({
          'information.status': 4,
        });
      }
    }
  }
}
