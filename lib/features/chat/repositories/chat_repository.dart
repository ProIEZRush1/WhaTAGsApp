import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/common/repositories/common_firebase_storage_repository.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/login_screen.dart';
import 'package:com.jee.tag.whatagsapp/models/chat.dart';
import 'package:com.jee.tag.whatagsapp/models/chat_contact.dart';
import 'package:com.jee.tag.whatagsapp/models/group.dart';
import 'package:com.jee.tag.whatagsapp/models/message.dart';
import 'package:com.jee.tag.whatagsapp/models/user_model.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/FIleUtils.dart';

import '../../../utils/DeviceUtils.dart';

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  ChatRepository({
    required this.firestore,
    required this.auth,
  });

  Future<bool> firstTime() async {
    QuerySnapshot snapshot = await firestore.collection('users').doc(auth.currentUser!.uid).collection('chats').limit(1).get();
    return snapshot.docs.isEmpty;
  }

  Stream<int?> getActualChatLengthStream(BuildContext context, WidgetRef ref) {
    return firestore
        .collection('loadedMessages')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['actualChatLength'] as int?);
  }

  Future<int> getRealChatLength(BuildContext context, WidgetRef ref) async {
    DocumentSnapshot snapshot = await firestore
        .collection('loadedMessages')
        .doc(auth.currentUser!.uid)
        .get();

    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    return data?['realChatLength'] as int? ?? 0;
  }

  Future<bool> getHasLoadedAllMessages(BuildContext context, WidgetRef ref) async {
    return await firestore
        .collection('loadedMessages')
        .doc(auth.currentUser!.uid)
        .get()
        .then((value) => value.data()?['hasLoadedAllMessages'] as bool? ?? false);
  }

  Stream<List<Chat>> getChatsStream(BuildContext context, WidgetRef ref) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<Chat> chats = [];
      for (var document in event.docs) {
        try {
          var chat = Chat.fromMap(document.data());
          chats.add(
            chat,
          );
        }
        catch (e) {
        }
      }
      chats.sort((a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));
      return chats;
    });
  }

  Stream<List<Message>> getChatMessagesStream(BuildContext context, WidgetRef ref, String chatId) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .asyncMap((event) async {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  void addMessageToFirebase(BuildContext context, WidgetRef ref, String chatId, Message message) async {
    await firestore.collection('users').doc(auth.currentUser!.uid).collection('chats').doc(chatId).collection('messages').add(message.toMap());
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
      final firebaseUid = ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      final dataToSend = {
        "type": "text",
        "data": text
      };
      final jsonDataToSend = jsonEncode(dataToSend);

      final data = await apiService.get(context, ref, "${apiService.sendMessageEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid&to=$receiverUserId&data=$jsonDataToSend");
      if (!apiService.checkSuccess(data)) {
        Fluttertoast.showToast(msg: 'Something went wrong');
        return;
      }
      if (!await apiService.checkIfLoggedIn(context, ref, data)) {
        return;
      }

    }
    catch (e) {
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

  void setChatMessageSeen(
    BuildContext context,
    String receiverUserId,
    String messageId,
  ) async {
    try {
      await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});

      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
