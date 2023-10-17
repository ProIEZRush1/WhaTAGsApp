// chat_database.dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatDatabase {
  static const String boxName = 'chats';
  static const String messagesBoxName = 'messages';

  Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    final box = await Hive.openBox<String>(boxName);
    final String chatsJson = jsonEncode(chats);
    await box.put('chats', chatsJson);
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final box = await Hive.openBox<String>(boxName);
    final String? chatsJson = box.get('chats');
    if (chatsJson != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(chatsJson));
    }
    return [];
  }

  Future<void> saveMessages(
      String chatId, List<Map<String, dynamic>> messages) async {
    final box = await Hive.openBox<String>(messagesBoxName);
    final String messagesJson = jsonEncode(messages);
    await box.put(chatId, messagesJson);
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final box = await Hive.openBox<String>(messagesBoxName);
    final String? messagesJson = box.get(chatId);
    if (messagesJson != null) {
      final messages =
          List<Map<String, dynamic>>.from(jsonDecode(messagesJson));
      return messages;
    }
    return [];
  }

  Future<void> deleteAll() async {
    final box = await Hive.openBox<String>(boxName);
    await box.deleteFromDisk();

    final box2 = await Hive.openBox<String>(messagesBoxName);
    await box2.deleteFromDisk();
  }

  // Method to create a default message
  Future<String> createDefaultMessage(
    String chatId, {
    required String body,
    required dynamic media,
    required String type,
  }) async {
    final box = await Hive.openBox<String>(messagesBoxName);

    String? messagesJson = box.get(chatId);
    List<Map<String, dynamic>> messages = [];

    if (messagesJson != null) {
      messages = List<Map<String, dynamic>>.from(jsonDecode(messagesJson));
    }

    final String messageId = const Uuid().v4(); // Generates a unique ID
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    final Map<String, dynamic> defaultMessage = {
      'id': messageId,
      'body': body,
      'fromMe': true,
      'media': media,
      'status': 1,
      'timestamp': timestamp,
      'type': type,
    };

    messages.add(defaultMessage);
    await saveMessages(chatId, messages);

    return messageId;
  }

  // Method to delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    final box = await Hive.openBox<String>(messagesBoxName);

    String? messagesJson = box.get(chatId);
    if (messagesJson == null) {
      return;
    }

    List<Map<String, dynamic>> messages =
        List<Map<String, dynamic>>.from(jsonDecode(messagesJson));

    messages.removeWhere((msg) => msg['id'] == messageId);
    await saveMessages(chatId, messages);
  }
}
