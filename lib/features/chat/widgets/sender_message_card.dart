import 'package:flutter/material.dart' hide DateUtils;
import 'package:swipe_to/swipe_to.dart';

import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/features/chat/widgets/display_text_image_gif.dart';
import 'package:whatsapp_ui/utils/DateUtils.dart';

class SenderMessageCard extends StatelessWidget {
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
  final VoidCallback onRightSwipe;
  const SenderMessageCard({
    Key? key,
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
    required this.onRightSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwipeTo(
      onRightSwipe: onRightSwipe,
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
            child: Stack(
              children: [
                Padding(
                  padding: type == MessageEnum.text
                      ? const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 5,
                          bottom: 20,
                        )
                      : const EdgeInsets.only(
                          left: 5,
                          top: 5,
                          right: 5,
                          bottom: 25,
                        ),
                  child: Column(
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
                            borderRadius: const BorderRadius.all(
                              Radius.circular(
                                5,
                              ),
                            ),
                          ),
                          child: DisplayTextImageGIF(
                            message: quotedMessageBody,
                            type: quotedMessageType,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      DisplayTextImageGIF(
                        message: body,
                        media: type != MessageEnum.text ? media : null,
                        type: type,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 10,
                  child: Text(
                    DateUtils.formatDate(DateTime.fromMicrosecondsSinceEpoch(timestamp)),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
