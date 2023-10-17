import 'dart:async';

import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  Future<Map<String, String>>? data;

  @override
  void initState() {
    super.initState();

    data = getDeviceIdAndKeyFromHive();
  }

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
    ref.read(messageReplyProvider.state).update(
          (state) => MessageReply(
            message,
            isMe,
            messageEnum,
          ),
        );
  }

  List<Map<String, dynamic>>? cachedStreamData;
  Stream<List<Map<String, dynamic>>>? stream;

  Future<Map<String, String>> getDeviceIdAndKeyFromHive() async {
    var box = await Hive.openBox('config');

    String deviceId = box.get('lastDeviceId') ?? "";
    String key = box.get('lastEncryptionKey') ?? "";

    final ChatDatabase chatDatabase = ChatDatabase();
    cachedStreamData = await chatDatabase.getMessages(widget.recieverUserId);

    stream ??= ref
        .read(chatControllerProvider)
        .chatMessagesStream(context, ref, widget.recieverUserId, key);

    ref.read(chatControllerProvider).setChatSeen(
          context,
          ref,
          deviceId,
          widget.recieverUserId,
        );

    return {"deviceId": deviceId, "key": key};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
        future: data,
        // Make sure to have this function return a Future<String>
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return StreamBuilder<List<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, streamSnapshot) {
                  if (streamSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return (cachedStreamData == null ||
                            cachedStreamData!.isEmpty
                        ? const Loader()
                        : getListView(cachedStreamData));
                  }

                  if ((cachedStreamData == null || cachedStreamData!.isEmpty) &&
                      !streamSnapshot.hasData) {
                    return Text('No data available');
                  }

                  return getListView(streamSnapshot.data);
                });
          }
        });
  }

  Widget getListView(List<Map<String, dynamic>>? data) {
    data = data!.reversed.toList();
    return ListView.builder(
      controller: messageController,
      reverse: true,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final messageData = data![index];

        if (messageData["information"] == null) {
          return Container();
        }

        final information = messageData["information"];
        final status = information["status"];
        final fromMe = information["fromMe"];

        final id = messageData["key"]["id"];
        final body = information["body"] ?? "";
        final timestamp = (information["timestamp"] ?? 0) * 1000;
        final type = information["type"];
        final media = information["media"];
        final url = information["url"] ?? "";
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
          return MyMessageCard(
            id: id,
            body: body,
            timestamp: timestamp,
            type: ConvertMessage(type).toEnum(),
            media: media,
            url: url,
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
        }
        return SenderMessageCard(
          id: id,
          body: body,
          timestamp: timestamp,
          type: ConvertMessage(type).toEnum(),
          media: media,
          url: url,
          hasQuotedMsg: hasQuotedMsg,
          quotedMessageBody: quotedMessageBody,
          quotedMessageType: ConvertMessage(quotedMessageType).toEnum(),
          onRightSwipe: () => onMessageSwipe(
            body,
            false,
            ConvertMessage(type).toEnum(),
          ),
        );
      },
    );
  }
}
