import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_repository.dart';

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

  Stream<List<Map<String, dynamic>>> chatsStream(
      BuildContext context, WidgetRef ref, String key) {
    return chatRepository.getChatsStream(context, ref, key);
  }

  Stream<List<Map<String, dynamic>>> chatMessagesStream(
      BuildContext context, WidgetRef ref, String chatId, String key) {
    return chatRepository.getMessagesStream(context, ref, chatId, key);
  }

  void sendTextMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text, String key) {
    chatRepository.sendMessage(context, ref, deviceId, chatId, text, key,MessageEnum.text);
  }
  void sendCurrentLocationMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String key) {
    chatRepository.sendMessage(context, ref, deviceId, chatId, '', key,MessageEnum.location);
  }
  void sendMediaMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text, String key, MessageEnum messageEnum, File file) {
    chatRepository.sendMediaMessage(context, ref, deviceId, chatId, text, key,messageEnum,file);
  }

  void setChatSeen(
      BuildContext context, WidgetRef ref, String deviceId, String chatId) {
    chatRepository.setChatSeen(
      context,
      ref,
      deviceId,
      chatId,
    );
  }
}
