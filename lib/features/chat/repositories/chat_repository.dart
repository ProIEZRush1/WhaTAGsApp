import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/auth/screens/login_screen.dart';
import 'package:whatsapp_ui/models/chat.dart';
import 'package:whatsapp_ui/models/chat_contact.dart';
import 'package:whatsapp_ui/models/group.dart';
import 'package:whatsapp_ui/models/message.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/requests/ApiService.dart';
import 'package:whatsapp_ui/utils/FIleUtils.dart';

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

  void retrieveChats(BuildContext context, WidgetRef ref) {
    Future(() async {
      final ApiService listMessagesApiService = ApiService();

      final deviceToken = await DeviceUtils.getDeviceId();

      final dataR = await listMessagesApiService.get("${listMessagesApiService.listMessagesEndpoint}?deviceToken=$deviceToken");
      final success = dataR['success'];

      if (success) {
        final data = dataR['data'];

        final loggedIn = data['loggedIn'];
        if (!loggedIn) {
          // firebase logout and redirect to login screen
          await auth.signOut();

          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
                (route) => false,
          );
        } else {
          final chats = data['chats'];
          for (var chat in chats) {
            final String chatId = chat["chat"]["chatId"]["_serialized"];
            final bool isGroup = chat["chat"]["isGroup"]!;

            final Map lastMessageMap = chat["chat"]["lastMessage"];
            final String lastMessage = lastMessageMap["body"];
            final String lastMessageTimestamp = lastMessageMap["timestamp"];

            final String name = chat["contact"]["name"];
            final String number = chat["contact"]["number"];
            final String profilePicUrl = chat["contact"]["profilePicUrl"];

            saveChat(chatId, isGroup, lastMessage, lastMessageTimestamp, name, number, profilePicUrl);
          }
        }
      }
    });
  }

  void retrieveChatMessages(BuildContext context, WidgetRef ref, String chatId) {
    Future(() async {
      final ApiService listChatMessagesApiService = ApiService();

      final deviceToken = await DeviceUtils.getDeviceId();

      final dataR = await listChatMessagesApiService.get(
          "${listChatMessagesApiService
              .listChatMessagesEndpoint}?chatId=$chatId&deviceToken=$deviceToken");
      final success = dataR['success'];

      if (success) {
        final data = dataR['data'];

        final loggedIn = data['loggedIn'];
        if (!loggedIn) {
          // firebase logout and redirect to login screen
          await auth.signOut();

          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
                (route) => false,
          );
        }
        else {
          final messages = data['messages'];
          for (var message in messages) {
            final String id = message["id"]["_serialized"];
            final String author = message["author"];
            final bool fromMe = message["fromMe"];
            final String body = message["body"];
            final String timestamp = message["timestamp"];
            final MessageEnum type = ConvertMessage(message["type"]).toEnum();
            final String media = message["media"];
            final bool delivery = message["delivery"];
            final bool seen = message["seen"];
            final bool hasQuotedMsg = message["hasQuotedMsg"];
            final String quotedMessageBody = message["quotedMessageBody"];
            final MessageEnum quotedMessageType = ConvertMessage(message["quotedMessageType"]).toEnum();

            saveChatMessage(ref, chatId, id, author, fromMe, body, timestamp, type, media, delivery, seen, hasQuotedMsg, quotedMessageBody, quotedMessageType);
          }
        }
      }
    });
  }

  void saveChat(chatId, isGroup, lastMessageBody, lastMessageTimestamp, name, number, profilePicUrl) async {
    await firestore.collection('users').doc(auth.currentUser!.uid).collection('chats').doc(chatId).set(
      Chat(
          chatId: chatId,
          isGroup: isGroup,
          lastMessageBody: lastMessageBody,
          lastMessageTimestamp: lastMessageTimestamp,
          name: name,
          number: number,
          profilePicUrl: profilePicUrl
      ).toMap(),
    );
  }

  void saveChatMessage(ref, chatId, id, author, fromMe, body, timestamp, type, media, delivery, seen, hasQuotedMsg, quotedMessageBody, quotedMessageType) async {
    // Upload media base64 to firebase and get url
    String mediaUrl = "";
    if (media != "") {
      mediaUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase('chat/$chatId/$id', await FileUtils.base64ToFile(media, 'chat$chatId$id'));
    }

    await firestore.collection('users').doc(auth.currentUser!.uid).collection('chats').doc(chatId).collection('messages').add(
      Message(
        id: id,
        author: author,
        fromMe: fromMe,
        body: body,
        timestamp: timestamp,
        type: type,
        media: mediaUrl,
        delivery: delivery,
        seen: seen,
        hasQuotedMsg: hasQuotedMsg,
        quotedMessageBody: quotedMessageBody,
        quotedMessageType: quotedMessageType
      ).toMap(),
    );
  }

  Stream<List<Chat>> getChatContacts(BuildContext context, WidgetRef ref) {
    retrieveChats(context, ref);

    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<Chat> contacts = [];
      for (var document in event.docs) {
        var chat = Chat.fromMap(document.data());

        contacts.add(
          chat,
        );
      }
      return contacts;
    });
  }

  Stream<List<Group>> getChatGroups(BuildContext context, WidgetRef ref){
    return firestore.collection('groups').snapshots().map((event) {
      List<Group> groups = [];
      for (var document in event.docs) {
        var group = Group.fromMap(document.data());
        if (group.membersUid.contains(auth.currentUser!.uid)) {
          groups.add(group);
        }
      }
      return groups;
    });
  }

  Stream<List<Message>> getChatStream(BuildContext context, WidgetRef ref, String chatId) {
    //retrieveChatMessages(context, ref, chatId);

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
        //print(Message.fromMap(document.data()));
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  Stream<List<Message>> getGroupChatStream(String groudId) {
    return firestore
        .collection('groups')
        .doc(groudId)
        .collection('chats')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  void sendTextMessage({
    required BuildContext context,
    required String text,
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
