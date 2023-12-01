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

class SenderMessageCard extends StatelessWidget {
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

  final AudioProperties? audioProperties;
  final bool hasQuotedMsg;
  final String quotedMessageBody;
  final MessageEnum quotedMessageType;
  final VoidCallback onRightSwipe;

  const SenderMessageCard({
    Key? key,
    required this.ref,
    required this.chatId,
    required this.id,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.media,
    this.imageProperties,
    this.videoProperties,
    this.vCardProperties,
    this.audioProperties,
    required this.hasQuotedMsg,
    required this.quotedMessageBody,
    required this.quotedMessageType,
    required this.onRightSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwipeTo(
      // onRightSwipe: onRightSwipe,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 45,
          ),
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: senderMessageColor,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        type: quotedMessageType,
                        imageProperties: imageProperties,
                        videoProperties: videoProperties,
                        audioProperties: audioProperties,
                        vCardProperties: vCardProperties,
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
                    videoProperties: videoProperties,
                    vCardProperties: vCardProperties,
                    audioProperties: audioProperties,
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
                            color: Colors.grey,
                          ),
                        ),
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
}
