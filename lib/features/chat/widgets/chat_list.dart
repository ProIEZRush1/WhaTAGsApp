import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/ImageProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/audio_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/file_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/location_properties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/vcardProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/videoProperties.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';

import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/my_message_card.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/sender_message_card.dart';
import 'package:hive/hive.dart';

class ChatList extends ConsumerStatefulWidget {
  final String chatId;
  final bool isGroupChat;

  const ChatList({
    Key? key,
    required this.chatId,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController _messageController = ScrollController();
  late final StreamSubscription<List<Map<String, dynamic>>>
      _messageStreamSubscription;
  LinkedHashMap<String, Map<String, dynamic>> _messages = LinkedHashMap();
  final List<String> _messageIds = [];
  String? _deviceId;
  String? _key;
  final Map<String, String> _decryptedMessageCache = {};
  final Map<String, Future<String>> _decryptedMessageFutures = {};
  late final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  Future<void> initializeChat() async {
    var box = await Hive.openBox('config');
    _deviceId = box.get('lastDeviceId') ?? "";
    _key = box.get('lastEncryptionKey') ?? "";

    _subscribeToMessageUpdates();
  }

  void _subscribeToMessageUpdates() {
    final controller = ref.read(chatControllerProvider);
    _messageStreamSubscription = controller
        .chatMessagesStream(context, ref, widget.chatId, _key!)
        .listen((newMessages) {
      print('newMessages length = ${newMessages.length}');
      setState(() {
        for (var message in newMessages) {
          final messageId = message["key"]["id"];
          final placeHolderId = message["key"]["placeHolderId"];
          if (message['type'] == DocumentChangeType.removed) {
            //locally added message was deleted
            // _messages.remove(messageId);
            return;
          }
          if (placeHolderId != null) {
            // var res = _messages.remove(placeHolderId);
            // print(res);
            if (_messages.containsKey(placeHolderId)) {
              _messages[placeHolderId] = message;
              print('replacing');
              return;
            }
          }
          if (!_messages.containsKey(messageId)) {
            _messages[messageId] = message;
            _messageIds.insert(0, messageId);
          } else if (_messages[messageId] != message) {
            int index = _messageIds.indexOf(messageId);
            if (index != -1) {
              _messages[messageId] = message;
            }
          }
        }
        // for (var message in newMessages) {
        //   final messageId = message["key"]["id"];
        //   if (!_messages.containsKey(messageId)) {
        //     _messages[messageId] = message;
        //     _messageIds.insert(0, messageId);
        //   } else if (_messages[messageId] != message) {
        //     int index = _messageIds.indexOf(messageId);
        //     if (index != -1) {
        //       _messages[messageId] = message;
        //     }
        //   }
        // }
      });
    });
  }

  Future<String> _decryptText(String encryptedText) async {
    if (_decryptedMessageCache.containsKey(encryptedText)) {
      return _decryptedMessageCache[encryptedText]!;
    }
    String decryptedText = await EncryptionUtils.decrypt(encryptedText, _key!);

    _decryptedMessageCache[encryptedText] = decryptedText;
    if (_decryptedMessageCache.length == 1) {
      if (mounted) {
        setState(() {});
      }
    }
    return decryptedText;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageStreamSubscription.cancel();
    super.dispose();
  }

  void onMessageSwipe(String message, bool isMe, MessageEnum messageEnum) {
    // Your existing implementation
  }

  @override
  Widget build(BuildContext context) {
    var sortedMessages = _sortMessages(_messages.values.toList());
    return _buildMessageList(sortedMessages);
  }

  List<Map<String, dynamic>> _sortMessages(
      List<Map<String, dynamic>> messages) {
    messages.sort((a, b) {
      int aTimestamp = a['information']['timestamp'] as int? ?? 0;
      int bTimestamp = b['information']['timestamp'] as int? ?? 0;
      return bTimestamp.compareTo(aTimestamp);
    });
    return messages;
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    return Stack(
      children: [
        AnimatedList(
          key: GlobalKey<AnimatedListState>(),
          controller: _messageController,
          reverse: true,
          initialItemCount: messages.length,
          itemBuilder: (context, index, animation) {
            return _buildListItem(messages[index], animation);
          },
        ),
        if (_decryptedMessageCache.isEmpty)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildListItem(
      Map<String, dynamic> message, Animation<double> animation) {
    final encryptedBody = message["information"]["body"] ?? "";
    if (!_decryptedMessageFutures.containsKey(encryptedBody)) {
      _decryptedMessageFutures[encryptedBody] = _decryptText(encryptedBody);
    }

    return FutureBuilder<String>(
      initialData: _decryptedMessageCache[encryptedBody],
      future: _decryptedMessageFutures[encryptedBody],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return Container(); // Placeholder or loading indicator
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final body = snapshot.data ?? "Decryption failed";
        final caption = ""; // Decrypted caption

        return SizeTransition(
          sizeFactor: animation,
          child: getMessageCard(message, body, caption),
        );
      },
    );
  }

  Widget getMessageCard(
      Map<String, dynamic> messageData, String body, String caption) {
    final id = messageData["key"]["id"];
    final information = messageData["information"];
    // print('information $information' );
    final status = information["status"];
    final fromMe = information["fromMe"];

    final timestamp = (information["timestamp"] ?? 0) * 1000;
    final type = information["type"];
    final media = information["media"];

    ImageProperties? imageProperties;
    if (type == "image") {
      double? heightValue = (information["height"] is num)
          ? (information["height"] as num).toDouble()
          : null;
      double? widthValue = (information["width"] is num)
          ? (information["width"] as num).toDouble()
          : null;
      List<int> sortedValues = [];
      // Convert keys to a list and sort them
      if (information["jpegThumbnail"] != null) {
        var sortedKeys = information["jpegThumbnail"].keys.toList()
          ..sort((a, b) =>
              int.parse(a.toString()).compareTo(int.parse(b.toString())));
        // Retrieve values based on sorted keys
        sortedValues = sortedKeys
            .map((key) => information["jpegThumbnail"][key])
            .toList()
            .cast<int>();
      }
      imageProperties = ImageProperties(
        height: heightValue ?? 0.0,
        width: widthValue ?? 0.0,
        mimetype: information["mimetype"] ?? '',
        jpegThumbnail: Uint8List.fromList(sortedValues),
        caption: caption,
      );
    }

    VideoProperties? videoProperties;
    if (type == MessageEnum.video.name) {
      double? heightValue = (information["height"] is num)
          ? (information["height"] as num).toDouble()
          : null;
      double? widthValue = (information["width"] is num)
          ? (information["width"] as num).toDouble()
          : null;
      print("heightValue: $heightValue");
      print("widthValue: $widthValue");
      List<int> sortedValues = [];
      // Convert keys to a list and sort them
      if (information["jpegThumbnail"] != null) {
        var sortedKeys = information["jpegThumbnail"].keys.toList()
          ..sort((a, b) =>
              int.parse(a.toString()).compareTo(int.parse(b.toString())));

        // Retrieve values based on sorted keys
        sortedValues = sortedKeys
            .map((key) => information["jpegThumbnail"][key])
            .toList()
            .cast<int>();
      }

      videoProperties = VideoProperties(
        height: (heightValue ?? 0.0),
        width: widthValue ?? 0.0,
        seconds: information["seconds"] ?? 0,
        mimetype: information["mimetype"] ?? '',
        jpegThumbnail: Uint8List.fromList(sortedValues),
        caption: caption,
      );
    }

    VCardProperties? vcardProperties;
    if (type == MessageEnum.vcard.name) {
      vcardProperties = VCardProperties(
          displayName: information["displayName"] ?? "",
          vcard: information["vcard"] ?? "");
    }
    AudioProperties? audioProperties;
    if (type == MessageEnum.voice.name || type == MessageEnum.audio.name) {
      audioProperties = AudioProperties(
        seconds: information["seconds"] ?? 13,
      );
      // print('type audio ${audioProperties.seconds}');
    }
    FileProperties? fileProperties;
    if (type == MessageEnum.document.name) {
      fileProperties = FileProperties(
        sizeInBytes: int.tryParse(information['fileLength'].toString()) ?? 0,
        fileName: information['fileName'] ?? '',
      );
      // fileProperties.fileName=information['fileName']??'';
    }
    LocationProperties? locationProperties;
    if (type == MessageEnum.location.name) {
      locationProperties = LocationProperties(
        lat: double.tryParse(information['degreesLatitude'].toString()) ?? 0,
        long: double.tryParse(information['degreesLongitude'].toString()) ?? 0,
      );
      // fileProperties.fileName=information['fileName']??'';
    }
    // print('information ===$information');
    final sent = status != 1;
    final delivery = status == 3 || status == 4;
    final seen = status == 4;
    final hasQuotedMsg = false;
    final quotedMessageBody = "";
    final quotedMessageType = "";

    if (type == null || fromMe == null) {
      return Container();
    }

    final update = messageData["update"];
    if (update != null) {
      if (update["starred"] == true) {
        return Container();
      }
    }

    final messageKey = ValueKey(id);

    if (fromMe) {
      final MyMessageCard myMessageCard = MyMessageCard(
        key: messageKey,
        ref: ref,
        chatId: widget.chatId,
        id: id,
        body: body,
        timestamp: timestamp,
        type: ConvertMessage(type).toEnum(),
        media: media,
        imageProperties: imageProperties,
        videoProperties: videoProperties,
        fileProperties: fileProperties,
        vCardProperties: vcardProperties,
        locationProperties: locationProperties,
        sent: sent,
        audioProperties: audioProperties,
        delivery: delivery,
        seen: seen,
        hasQuotedMsg: hasQuotedMsg,
        quotedMessageBody: quotedMessageBody,
        quotedMessageType: ConvertMessage(quotedMessageType).toEnum(),
        onLeftSwipe: () => onMessageSwipe(
          body,
          true,
          ConvertMessage(type).toEnum(),
        ),
      );

      return myMessageCard;
    }
    final SenderMessageCard senderMessageCard = SenderMessageCard(
      key: messageKey,
      ref: ref,
      chatId: widget.chatId,
      id: id,
      body: body,
      timestamp: timestamp,
      type: ConvertMessage(type).toEnum(),
      media: media,
      imageProperties: imageProperties,
      videoProperties: videoProperties,
      audioProperties: audioProperties,
      vCardProperties: vcardProperties,
      locationProperties: locationProperties,
      fileProperties: fileProperties,
      hasQuotedMsg: hasQuotedMsg,
      quotedMessageBody: quotedMessageBody,
      quotedMessageType: ConvertMessage(quotedMessageType).toEnum(),
      onRightSwipe: () => onMessageSwipe(
        body,
        false,
        ConvertMessage(type).toEnum(),
      ),
    );

    return senderMessageCard;
  }
}
