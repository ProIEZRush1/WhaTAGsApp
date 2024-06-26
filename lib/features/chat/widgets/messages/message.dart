import 'dart:typed_data';

import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/audio_message.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/document_message.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/image_message.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/location_message.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/ImageProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/audio_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/file_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/location_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/vcardProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/videoProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/text_message.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/vcard_message.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/video_message.dart';
import 'package:flutter/material.dart';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Message extends StatefulWidget {
  final WidgetRef ref;
  final String chatId;
  final String messageId;
  final String message;
  final MessageEnum type;
  final bool? sent;

  final ImageProperties? imageProperties;
  final VideoProperties? videoProperties;
  final VCardProperties? vCardProperties;
  final AudioProperties? audioProperties;
  final FileProperties? fileProperties;
  final LocationProperties? locationProperties;

  Message({
    Key? key,
    required this.ref,
    required this.chatId,
    required this.messageId,
    required this.message,
    required this.type,
    this.imageProperties,
    this.sent,
    this.locationProperties,
    this.audioProperties,
    this.fileProperties,
    this.videoProperties,
    this.vCardProperties,
  }) : super(key: key);

  @override
  _MessageState createState() => _MessageState();
}

class _MessageState extends State<Message> {
  late WidgetRef ref;
  late String chatId;
  late String messageId;
  late String message;
  late MessageEnum type;

  late ImageProperties? imageProperties;
  late VideoProperties? videoProperties;
  late VCardProperties? vCardProperties;

  AudioProperties? get audioProperties => widget.audioProperties;

  FileProperties? get fileProperties => widget.fileProperties;

  LocationProperties? get locationProperties => widget.locationProperties;

  @override
  void initState() {
    super.initState();

    ref = widget.ref;
    chatId = widget.chatId;
    messageId = widget.messageId;
    message = widget.message;
    type = widget.type;

    imageProperties = widget.imageProperties;
    videoProperties = widget.videoProperties;
    vCardProperties = widget.vCardProperties;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == MessageEnum.text) {
      return TextMessage(message: message);
    }

    switch (type) {

      case MessageEnum.sticker:
        // return ImageMessage(
        //   ref: ref,
        //   chatId: chatId,
        //   messageId: messageId,
        // );
        break;
      case MessageEnum.image:
        return ImageMessage(
          ref: ref,
          sent: widget.sent,
          chatId: chatId,
          messageId: messageId,
          height: imageProperties?.height,
          width: imageProperties?.width,
          mimetype: imageProperties?.mimetype,
          jpegThumbnail: imageProperties?.jpegThumbnail,
          caption: imageProperties!.caption,
        );
      case MessageEnum.audio:
      case MessageEnum.voice:
        // print('messageId:$messageId');
        return AudioMessage(
          ref: ref,
          chatId: chatId,
          messageId: messageId,
          seconds: audioProperties?.seconds ?? 0,
          // mimetype: videoProperties!.mimetype,
        );
      case MessageEnum.video:
        return VideoMessage(
          ref: ref,
          chatId: chatId,
          sent: widget.sent,
          messageId: messageId,
          height: videoProperties!.height,
          width: videoProperties!.width,
          seconds: videoProperties!.seconds,
          mimetype: videoProperties!.mimetype,
          jpegThumbnail: videoProperties!.jpegThumbnail,
          caption: videoProperties!.caption,
        );
      case MessageEnum.gif:
        break;
      case MessageEnum.vcard:
        return VCardMessage(
            messageId: (messageId),
            ref: ref,
            vcard: vCardProperties?.vcard ?? '',
            picture:
                "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png");
      case MessageEnum.document:
        return DocumentMessage(
          messageId: messageId,
          sent: widget.sent,
          chatId: chatId,
          fileName: fileProperties?.fileName ?? 'File',
          bytes: fileProperties?.sizeInBytes ?? 00,
        );
      case MessageEnum.location:
        return LocationMessage(
          messageId: messageId,
          lat: locationProperties?.lat ?? 0,
          long: locationProperties?.long ?? 0,
        );
      default:
        return Container();
    }
    return Container();
  }
}
