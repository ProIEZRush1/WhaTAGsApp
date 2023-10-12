import 'dart:async';

import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';

import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/my_message_card.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/sender_message_card.dart';
import 'package:com.jee.tag.whatagsapp/models/message.dart';

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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: DeviceUtils.getDeviceId(),
        // Make sure to have this function return a Future<String>
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // Your main build logic here using snapshot.data
            return StreamBuilder<List<Map<String, dynamic>>>(
                stream: ref.read(chatControllerProvider).chatMessagesStream(
                    context,
                    ref,
                    widget.recieverUserId,
                    EncryptionUtils.deriveKeyFromPassword(
                        snapshot.data!, "salt")),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Loader();
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    // Handle the case where snapshot.data is null
                    return Text('No data available');
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Delay the scrolling by 100 milliseconds to ensure proper layout
                    Future.delayed(Duration(milliseconds: 100), () {
                      messageController
                          .jumpTo(messageController.position.maxScrollExtent);
                    });
                  });

                  ref.read(chatControllerProvider).setChatSeen(
                        context,
                        widget.recieverUserId,
                      );

                  return ListView.builder(
                    controller: messageController,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final messageData = snapshot.data![index];

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
                      final delivery = status == 3;
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
                          delivery: delivery,
                          seen: seen,
                          hasQuotedMsg: hasQuotedMsg,
                          quotedMessageBody: quotedMessageBody,
                          quotedMessageType:
                              ConvertMessage(quotedMessageType).toEnum(),
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
                        delivery: delivery,
                        hasQuotedMsg: hasQuotedMsg,
                        quotedMessageBody: quotedMessageBody,
                        quotedMessageType:
                            ConvertMessage(quotedMessageType).toEnum(),
                        onRightSwipe: () => onMessageSwipe(
                          body,
                          false,
                          ConvertMessage(type).toEnum(),
                        ),
                      );
                    },
                  );
                });
          }
        });
  }
}
