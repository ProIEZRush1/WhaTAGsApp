class Chat {
  // chatId, isGroup, lastMessageBody, lastMessageTimestamp, name, number, profilePicUrl
  final String chatId;
  final bool isGroup;
  final String lastMessageBody;
  final String lastMessageTimestamp;
  final String name;
  final String number;
  final String profilePicUrl;
  Chat({
    required this.chatId,
    required this.isGroup,
    required this.lastMessageBody,
    required this.lastMessageTimestamp,
    required this.name,
    required this.number,
    required this.profilePicUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'isGroup': isGroup,
      'lastMessageBody': lastMessageBody,
      'lastMessageTimestamp': lastMessageTimestamp,
      'name': name,
      'number': number,
      'profilePicUrl': profilePicUrl,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      chatId: map['chatId'] ?? '',
      isGroup: map['isGroup'] ?? false,
      lastMessageBody: map['lastMessageBody'] ?? '',
      lastMessageTimestamp: map['lastMessageTimestamp'] ?? '',
      name: map['name'] ?? '',
      number: map['number'] ?? '',
      profilePicUrl: map['profilePicUrl'] ?? '',
    );
  }
}
