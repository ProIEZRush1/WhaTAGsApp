import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_repository.dart';
import 'package:com.jee.tag.whatagsapp/models/chat.dart';
import 'package:com.jee.tag.whatagsapp/models/chat_contact.dart';
import 'package:com.jee.tag.whatagsapp/models/group.dart';
import 'package:com.jee.tag.whatagsapp/models/message.dart';

final chatControllerProvider = Provider((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return ChatController(
    chatRepository: chatRepository,
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;
  ChatController({
    required this.chatRepository,
    required this.ref,
  });

  Stream<int?> actualChatLengthStream(BuildContext context, WidgetRef ref) {
    return chatRepository.getActualChatLengthStream(context, ref);
  }

  Future<int> getRealChatLength(BuildContext context, WidgetRef ref) async {
    return await chatRepository.getRealChatLength(context, ref);
  }

  Future<bool> getHasLoadedAllMessages(BuildContext context, WidgetRef ref) async {
    return await chatRepository.getHasLoadedAllMessages(context, ref);
  }

  Stream<List<Chat>> chatsStream(BuildContext context, WidgetRef ref, String key) {
    return chatRepository.getChatsStream(context, ref, key);
  }

  Stream<List<Message>> chatMessagesStream(BuildContext context, WidgetRef ref, String chatId, String key) {
    return chatRepository.getChatMessagesStream(context, ref, chatId, key);
  }

  void sendTextMessage(
    BuildContext context,
    WidgetRef ref,
    String chatId,
    String text,
    String receiverUserId,
  ) {
    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendTextMessage(
            context: context,
            ref: ref,
            chatId: chatId,
            text: text,
            receiverUserId: receiverUserId,
          ),
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  void sendFileMessage(
    BuildContext context,
    File file,
    String receiverUserId,
    MessageEnum messageEnum,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendFileMessage(
            context: context,
            file: file,
            receiverUserId: receiverUserId,
            senderUserData: value!,
            messageEnum: messageEnum,
            ref: ref,
            messageReply: messageReply,
            isGroupChat: isGroupChat,
          ),
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  void sendGIFMessage(
    BuildContext context,
    String gifUrl,
    String receiverUserId,
    bool isGroupChat,
  ) {
    final messageReply = ref.read(messageReplyProvider);
    int gifUrlPartIndex = gifUrl.lastIndexOf('-') + 1;
    String gifUrlPart = gifUrl.substring(gifUrlPartIndex);
    String newgifUrl = 'https://i.giphy.com/media/$gifUrlPart/200.gif';

    ref.read(userDataAuthProvider).whenData(
          (value) => chatRepository.sendGIFMessage(
            context: context,
            gifUrl: newgifUrl,
            receiverUserId: receiverUserId,
            senderUser: value!,
            messageReply: messageReply,
            isGroupChat: isGroupChat,
          ),
        );
    ref.read(messageReplyProvider.state).update((state) => null);
  }

  void setChatMessageSeen(
    BuildContext context,
    String receiverUserId,
    String messageId,
  ) {
    chatRepository.setChatMessageSeen(
      context,
      receiverUserId,
      messageId,
    );
  }
}
