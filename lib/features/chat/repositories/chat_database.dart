import 'dart:async';
import 'dart:convert';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_repository.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class ChatDatabase {
  static const String chatsBoxName = 'chats';
  static const String messagesBoxName = 'messages';

  /* INSTANCES */
  static final ChatDatabase _instance = ChatDatabase._internal();

  factory ChatDatabase() => _instance;

  ChatDatabase._internal() {
    _init();
  }

  Map<String, StreamController<List<Map<String, dynamic>>>>
      messagesStreamControllers = {};

  StreamController<List<Map<String, dynamic>>> getChatsStreamController(
      String chatId) {
    StreamController<List<Map<String, dynamic>>>? messageStreamController =
        messagesStreamControllers[chatId];
    if (messageStreamController == null) {
      messageStreamController =
          StreamController<List<Map<String, dynamic>>>.broadcast();
      messagesStreamControllers[chatId] = messageStreamController;
    }
    return messageStreamController;
  }

  Future<void> _init() async {}

  void disposeMessagesStreamController(String chatId) {
    messagesStreamControllers[chatId]?.close();
  }

  /* END INSTANCES */

  /* HELPER METHODS */
  Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    final box = await Hive.openBox<String>(chatsBoxName);
    final String chatsJson = jsonEncode(chats);
    await box.put('chats', chatsJson);
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final box = await Hive.openBox<String>(chatsBoxName);
    final String? chatsJson = box.get('chats');
    if (chatsJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(chatsJson));
    }
    return [];
  }

  Future<void> saveMessages(WidgetRef ref, String chatId,
      List<Map<String, dynamic>> newMessages) async {
    final box = await Hive.openBox<String>(messagesBoxName);

    // Load the existing messages for the given chatId
    final String? existingMessagesJson = box.get(chatId);
    List<Map<String, dynamic>> existingMessages = existingMessagesJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(existingMessagesJson))
        : [];

    // Merge newMessages into existingMessages
    for (var i = 0; i < newMessages.length; i++) {
      Map<String, dynamic> newMessage = newMessages[i];
      if (newMessage["sentId"] != null) {
        int index = existingMessages.indexWhere(
            (element) => element['key']['id'] == newMessage['sentId']);
        if (index != -1) {
          newMessage.remove('sentId');
          existingMessages[index]['key']['id'] = newMessage['key']['id'];

          // Remove sentId from firebase
          final controller = ref.read(chatRepositoryProvider);
          await controller.removeSentId(chatId, newMessage['key']['id']);
        }
      }

      int index = existingMessages.indexWhere(
          (message) => message['key']['id'] == newMessage['key']['id']);
      if (index != -1) {
        // Update the existing message if it already exists
        existingMessages[index] = newMessage;
      } else {
        // Add the new message if it doesn't exist
        existingMessages.add(newMessage);
      }
    }

    // Save the merged list of messages back to the local database
    final String mergedMessagesJson = jsonEncode(existingMessages);
    await box.put(chatId, mergedMessagesJson);

    getChatsStreamController(chatId).add(await getMessages(chatId));
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final box = await Hive.openBox<String>(messagesBoxName);
    final String? messagesJson = box.get(chatId);
    if (messagesJson != null) {
      final List<Map<String, dynamic>> messages =
          List<Map<String, dynamic>>.from(
        jsonDecode(messagesJson),
      );
      messages.sort((a, b) {
        int aTimestamp = a['information']['timestamp'] as int? ?? 0;
        int bTimestamp = b['information']['timestamp'] as int? ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });
      return messages;
    }
    return [];
  }

  Future<void> deleteMessage(
      WidgetRef ref, String chatId, String messageId) async {
    final box = await Hive.openBox<String>(messagesBoxName);
    String? messagesJson = box.get(chatId);
    if (messagesJson == null) return;

    List<Map<String, dynamic>> messages =
        List<Map<String, dynamic>>.from(jsonDecode(messagesJson));
    messages.removeWhere((msg) => msg['key']['id'] == messageId);
    await saveMessages(ref, chatId, messages);
  }

  Future<void> deleteAll() async {
    final box = await Hive.openBox<String>(chatsBoxName);
    await box.deleteFromDisk();

    final box2 = await Hive.openBox<String>(messagesBoxName);
    await box2.deleteFromDisk();
  }

  /* END HELPER METHODS */

  // Method to create a default message
  Future<String> createDefaultMessage(WidgetRef ref, String remoteJid,
      bool fromMe, String body, String key) async {
    final messages = await getMessages(remoteJid);
    final String messageId = const Uuid().v4(); // Generates a unique ID
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Map<String, dynamic> defaultMessage = {
      "key": {
        "remoteJid": remoteJid,
        "fromMe": fromMe,
        "id": messageId,
      },
      "information": {
        "status": 1,
        "timestamp": timestamp ~/ 1000,
        "body": await EncryptionUtils.encrypt(body, key),
        "type": "text",
        "fromMe": fromMe,
        "media": false,
      },
      "messageTimestamp": timestamp ~/ 1000,
      "status": 1,
    };

    messages.add(defaultMessage);
    await saveMessages(ref, remoteJid, messages);

    return messageId;
  }
}
