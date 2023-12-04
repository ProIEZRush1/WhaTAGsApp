import 'dart:typed_data';

import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/ImageProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/audio_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/vcardProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/videoProperties.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_to/swipe_to.dart';

import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';

class MyMessageCard extends StatelessWidget {
  final WidgetRef ref;
  final String chatId;
  final String id;
  final String body;
  final int timestamp;
  final MessageEnum type;
  final bool media;

  final ImageProperties? imageProperties;
  final VideoProperties? videoProperties;
  final VCardProperties? vCardProperties;

  final bool sent;
  final bool delivery;
  final bool seen;
  final bool hasQuotedMsg;
  final String quotedMessageBody;
  final MessageEnum quotedMessageType;
  final VoidCallback onLeftSwipe;
 final AudioProperties? audioProperties;
  const MyMessageCard({
    Key? key,
    required this.ref,
    required this.id,
    required this.chatId,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.media,
    this.imageProperties,
    this.videoProperties,
    this.vCardProperties,
    required this.sent,
    required this.delivery,
    required this.seen,
    required this.hasQuotedMsg,
    required this.quotedMessageBody,
    required this.quotedMessageType,
    required this.onLeftSwipe,
    required this.audioProperties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Minimum width for the date container
    const double dateContainerMinWidth = 80;

    return SwipeTo(
      // onLeftSwipe: onLeftSwipe,
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 45,
          ),
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: messageColor,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasQuotedMsg) ...[
                    Text(
                      quotedMessageBody,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.5),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Message(
                        ref: ref,
                        chatId: chatId,
                        messageId: id,
                        message: quotedMessageBody,
                        audioProperties: audioProperties,
                        type: quotedMessageType,
                        imageProperties: null,
                        // Quoted messages don't have image properties
                        vCardProperties:
                            null, // Quoted messages don't have vCard properties
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Message(
                    ref: ref,
                    chatId: chatId,
                    messageId: id,
                    message: body,
                    type: type,
                    imageProperties: imageProperties,
                    audioProperties: audioProperties,
                    videoProperties: videoProperties,
                    vCardProperties: vCardProperties,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateUtils.formatDate(timestamp),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(width: 5),
                        getSentIcon(20, seen ? Colors.blue : Colors.white60),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Icon getSentIcon(double size, Color color) {
    if (!sent) {
      return Icon(Icons.lock_clock, size: size, color: color);
    }
    if (!delivery) {
      return Icon(Icons.done, size: size, color: color);
    }
    if (seen) {
      return Icon(Icons.done_all, size: size, color: color);
    }
    return Icon(Icons.done, size: size, color: color);
  }
}
