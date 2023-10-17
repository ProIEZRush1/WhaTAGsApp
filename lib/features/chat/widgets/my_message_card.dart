import 'package:flutter/material.dart' hide DateUtils;
import 'package:swipe_to/swipe_to.dart';

import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/display_text_image_gif.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';

class MyMessageCard extends StatelessWidget {
  final String id;
  final String body;
  final int timestamp;
  final MessageEnum type;
  final bool media;
  final String url;
  final bool sent;
  final bool delivery;
  final bool seen;
  final bool hasQuotedMsg;
  final String quotedMessageBody;
  final MessageEnum quotedMessageType;
  final VoidCallback onLeftSwipe;

  const MyMessageCard({
    Key? key,
    required this.id,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.media,
    required this.url,
    required this.sent,
    required this.delivery,
    required this.seen,
    required this.hasQuotedMsg,
    required this.quotedMessageBody,
    required this.quotedMessageType,
    required this.onLeftSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SwipeTo(
      onLeftSwipe: onLeftSwipe,
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
                            media: media ? url : null,
                            type: quotedMessageType,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      DisplayTextImageGIF(
                        message: body,
                        media: media ? url : null,
                        type: type,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 10,
                  child: Row(
                    children: [
                      Text(
                        DateUtils.formatDate(timestamp),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      getSentIcon(20, seen ? Colors.blue : Colors.white60),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon getSentIcon(double size, Color color) {
    if (!sent) {
      return Icon(
        Icons.lock_clock,
        size: size,
        color: color,
      );
    }
    if (!delivery) {
      return Icon(
        Icons.done,
        size: size,
        color: color,
      );
    }
    return Icon(
      Icons.done_all,
      size: size,
      color: color,
    );
  }
}
