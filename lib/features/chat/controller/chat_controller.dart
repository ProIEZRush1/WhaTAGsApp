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

  Stream<List<Map<String, dynamic>>> chatsStream(
      BuildContext context, WidgetRef ref, String key) {
    return chatRepository.getChatsStreamJson(context, ref, key);
  }

  Stream<List<Map<String, dynamic>>> chatMessagesStream(
      BuildContext context, WidgetRef ref, String chatId, String key) {
    return chatRepository.getChatMessagesStream(context, ref, chatId, key);
  }

  void sendTextMessage(BuildContext context, WidgetRef ref, String deviceId,
      String chatId, String text) {
    chatRepository.sendTextMessage(context, ref, deviceId, chatId, text);
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
