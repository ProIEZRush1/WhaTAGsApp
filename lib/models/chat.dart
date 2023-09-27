import 'dart:ffi';

class Chat {
  final String chatId;
  final bool archived;
  final bool isGroup;
  final bool isMuted;
  final bool isReadOnly;
  final CMessage lastMessage;
  final bool pinned;
  final int timestamp;
  final int unreadCount;
  final Contact contact;

  Chat({
    required this.chatId,
    this.archived = false,
    required this.isGroup,
    required this.isMuted,
    required this.isReadOnly,
    required this.lastMessage,
    required this.pinned,
    required this.timestamp,
    required this.unreadCount,
    required this.contact,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'archived': archived,
      'isGroup': isGroup,
      'isMuted': isMuted,
      'isReadOnly': isReadOnly,
      'lastMessage': lastMessage.toMap(),
      'pinned': pinned,
      'timestamp': timestamp,
      'unreadCount': unreadCount,
      'contact': contact.toMap(),
    };
  }

  static Chat fromMap(Map<String, dynamic> map) {
    final chatData = map['chat'];
    return Chat(
      chatId: chatData['chatId'],
      archived: chatData['archived'],
      isGroup: chatData['isGroup'],
      isMuted: chatData['isMuted'],
      isReadOnly: chatData['isReadOnly'],
      lastMessage: CMessage.fromMap(chatData['lastMessage']),
      pinned: chatData['pinned'],
      timestamp: chatData['timestamp'] * 1000,
      unreadCount: chatData['unreadCount'],
      contact: Contact.fromMap(map['contact']),
    );
  }
}

class CMessage {
  final String body;
  final int timestamp;

  CMessage({
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'body': body,
      'timestamp': timestamp,
    };
  }

  static CMessage fromMap(Map<String, dynamic> map) {
    return CMessage(
      body: map['body'],
      timestamp: map['timestamp'] * 1000,
    );
  }
}

class Contact {
  final String id;
  final bool isBlocked;
  final bool isMe;
  final String name;
  final String number;
  final String pushname;
  final String profilePicUrl;

  Contact({
    required this.id,
    required this.isBlocked,
    required this.isMe,
    required this.name,
    required this.number,
    required this.pushname,
    required this.profilePicUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isBlocked': isBlocked,
      'isMe': isMe,
      'name': name,
      'number': number,
      'pushname': pushname,
      'profilePicUrl': profilePicUrl,
    };
  }

  static Contact fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      isBlocked: map['isBlocked'],
      isMe: map['isMe'],
      name: map['name'],
      number: map['number'],
      pushname: map['pushname'],
      profilePicUrl: map['profilePicUrl'],
    );
  }
}