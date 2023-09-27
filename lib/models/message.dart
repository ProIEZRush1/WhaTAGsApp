import 'dart:ffi';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';

class Message {

  final String id;
  final String author;
  final bool fromMe;
  final String body;
  final int timestamp;
  final MessageEnum type;
  final String media;
  final bool delivery;
  final bool seen;
  final bool hasQuotedMsg;
  final String quotedMessageBody;
  final MessageEnum quotedMessageType;

  Message({
    required this.id,
    required this.author,
    required this.fromMe,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.media,
    required this.delivery,
    required this.seen,
    required this.hasQuotedMsg,
    required this.quotedMessageBody,
    required this.quotedMessageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author': author,
      'fromMe': fromMe,
      'body': body,
      'timestamp': timestamp,
      'type': type.type,
      'delivery': delivery,
      'seen': seen,
      'hasQuotedMsg': hasQuotedMsg,
      'quotedMessageBody': quotedMessageBody,
      'quotedMessageType': quotedMessageType.type,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      author: map['author'],
      fromMe: map['fromMe'],
      body: map['body'],
      timestamp: map['timestamp'] * 1000,
      type: ConvertMessage(map['type']).toEnum(),
      media: map['media'] != null ? map['media'][0] : '',
      delivery: map['delivery'],
      seen: map['seen'],
      hasQuotedMsg: map['hasQuotedMsg'],
      quotedMessageBody: map['quotedMessageBody'],
      quotedMessageType: ConvertMessage(map['quotedMessageType']).toEnum(),
    );
  }
}
