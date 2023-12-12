import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/ImageProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/audio_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/file_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/location_properties.dart';
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
  final String? participantId,name;
  final String body;
  final int timestamp;
  final MessageEnum type;
  final bool media;

  final ImageProperties? imageProperties;
  final VideoProperties? videoProperties;
  final VCardProperties? vCardProperties;
  final FileProperties? fileProperties;
  final AudioProperties? audioProperties;
 final LocationProperties? locationProperties;
  final bool hasQuotedMsg;
  final bool isGroupChat;
  final String quotedMessageBody;
  final MessageEnum quotedMessageType;
  final VoidCallback onRightSwipe;
  const SenderMessageCard({
    Key? key,
    required this.ref,
    required this.chatId,
    required this.id,
    required this.participantId,
    required this.name,
    required this.body,
    required this.timestamp,
    required this.isGroupChat,
    required this.type,
    required this.media,
    this.imageProperties,
    this.videoProperties,
    this.vCardProperties,
    this.locationProperties,
    this.fileProperties,
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
                  if(isGroupChat&&(participantId?.isNotEmpty??false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5,right: 10,left: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            MessageUtils.getNameFromData(participantId!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.pink,
                            ),
                          ),
                          if(MessageUtils.getContactName(participantId!)==null)
                          Padding(
                            padding: const EdgeInsets.only(left:10.0),
                            child: Text(
                              name??'',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        locationProperties: locationProperties,
                        chatId: chatId,
                        messageId: id,
                        message: quotedMessageBody,
                        type: quotedMessageType,
                        imageProperties: imageProperties,
                        videoProperties: videoProperties,
                        audioProperties: audioProperties,
                        vCardProperties: vCardProperties,
                        fileProperties: fileProperties,
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
                    locationProperties: locationProperties,
                    imageProperties: imageProperties,
                    videoProperties: videoProperties,
                    vCardProperties: vCardProperties,
                    audioProperties: audioProperties,
                    fileProperties: fileProperties,
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
