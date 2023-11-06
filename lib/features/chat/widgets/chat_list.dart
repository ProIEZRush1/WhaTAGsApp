import 'dart:async';
import 'dart:typed_data';

import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/ImageProperties.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/properties/vcardProperties.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';

import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/my_message_card.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/sender_message_card.dart';
import 'package:hive/hive.dart';

class ChatList extends ConsumerStatefulWidget {
  final String recieverUserId;
  final bool isGroupChat;

  const ChatList({
    Key? key,
    required this.recieverUserId,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageController = ScrollController();
  String? deviceId;
  String? key;
  Map<String, String> decryptedMessageCache = {};
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  Future<void> initializeChat() async {
    var box = await Hive.openBox('config');
    deviceId = box.get('lastDeviceId') ?? "";
    key = box.get('lastEncryptionKey') ?? "";
    final ChatDatabase chatDatabase = ChatDatabase();
    messages = await chatDatabase.getMessages(widget.recieverUserId);
    final controller = ref.read(chatControllerProvider);
    // Subscribe to the stream and update the UI in place
    controller
        .chatMessagesStream(
      context,
      ref,
      widget.recieverUserId,
      key!,
    )
        .listen((newMessages) {
      setState(() {
        messages = newMessages;
        // Optionally, purge cache of messages no longer present
        decryptedMessageCache = Map.fromIterable(
          messages,
          key: (message) => message["key"]["id"],
          value: (message) => decryptedMessageCache[message["key"]["id"]] ?? '',
        );

        controller.setChatSeen(context, ref, deviceId!, widget.recieverUserId);
      });
    });
  }

  Future<String> decryptMessage(String body) async {
    // Use the cache if the message has already been decrypted
    if (decryptedMessageCache.containsKey(body)) {
      return decryptedMessageCache[body]!;
    }

    // Otherwise, decrypt and add to the cache
    String decryptedBody = await EncryptionUtils.decrypt(body, key!);
    decryptedMessageCache[body] = decryptedBody;
    return decryptedBody;
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void onMessageSwipe(String message, bool isMe, MessageEnum messageEnum) {
    ref.read(messageReplyProvider.state).update(
          (state) => MessageReply(message, isMe, messageEnum),
        );
  }

  @override
  Widget build(BuildContext context) {
    // No need for FutureBuilder or StreamBuilder here
    return getListView(messages);
  }

  Widget getListView(List<Map<String, dynamic>> data) {
    return ListView.builder(
      controller: messageController,
      reverse: true,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final messageData = data[index];
        if (messageData["information"] == null) {
          return Container();
        }

        final encryptedBody = messageData["information"]["body"] ?? "";
        final decryptedBodyFuture = decryptMessage(encryptedBody);

        return FutureBuilder<String>(
          future: decryptedBodyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Return an empty container or some placeholder
              // to avoid the loader if the message is already in view
              return Container(); // Or some placeholder widget
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            // When data is available, build the message card
            final body = snapshot.data ?? "Decryption failed";
            return getMessageCard(messageData, body, index);
          },
        );
      },
    );
  }

  Widget getMessageCard(
      Map<String, dynamic> messageData, String body, int index) {
    final id = messageData["key"]["id"];
    final information = messageData["information"];
    final status = information["status"];
    final fromMe = information["fromMe"];

    final timestamp = (information["timestamp"] ?? 0) * 1000;
    final type = information["type"];
    final media = information["media"];

    ImageProperties? imageProperties;
    if (information["jpegThumbnail"] != null) {
      double? heightValue = (information["height"] is num)
          ? (information["height"] as num).toDouble()
          : null;
      double? widthValue = (information["width"] is num)
          ? (information["width"] as num).toDouble()
          : null;

      // Convert keys to a list and sort them
      var sortedKeys = information["jpegThumbnail"].keys.toList()
        ..sort((a, b) =>
            int.parse(a.toString()).compareTo(int.parse(b.toString())));

      // Retrieve values based on sorted keys
      List<int> sortedValues = sortedKeys
          .map((key) => information["jpegThumbnail"][key])
          .toList()
          .cast<int>();

      imageProperties = ImageProperties(
        height: heightValue ?? 0.0,
        width: widthValue ?? 0.0,
        mimetype: information["mimetype"],
        jpegThumbnail: Uint8List.fromList(sortedValues),
        caption: information["caption"],
      );
    }

    VCardProperties? vcardProperties;
    if (information["vCard"] != null) {
      vcardProperties = VCardProperties(
          displayName: information["displayName"] ?? "",
          vcard: information["vcard"] ?? "");
    }

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

    if (fromMe) {
      final MyMessageCard myMessageCard = MyMessageCard(
        ref: ref,
        chatId: widget.recieverUserId,
        id: id,
        body: body,
        timestamp: timestamp,
        type: ConvertMessage(type).toEnum(),
        media: media,
        imageProperties: imageProperties,
        vCardProperties: vcardProperties,
        sent: sent,
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
      ref: ref,
      chatId: widget.recieverUserId,
      id: id,
      body: body,
      timestamp: timestamp,
      type: ConvertMessage(type).toEnum(),
      media: media,
      imageProperties: imageProperties,
      vCardProperties: vcardProperties,
      hasQuotedMsg: hasQuotedMsg,
      quotedMessageBody: quotedMessageBody,
      quotedMessageType: ConvertMessage(quotedMessageType).toEnum(),
      onRightSwipe: () => onMessageSwipe(
        body!,
        false,
        ConvertMessage(type).toEnum(),
      ),
    );

    return senderMessageCard;
  }
}
