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
        future: DeviceUtils
            .getDeviceId(), // Make sure to have this function return a Future<String>
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // Your main build logic here using snapshot.data
            return StreamBuilder<List<Message>>(
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

                  return ListView.builder(
                    controller: messageController,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final messageData = snapshot.data![index];

                      if (!messageData.seen && !messageData.fromMe) {
                        ref.read(chatControllerProvider).setChatMessageSeen(
                              context,
                              widget.recieverUserId,
                              messageData.id,
                            );
                      }
                      if (messageData.fromMe) {
                        return MyMessageCard(
                          id: messageData.id,
                          author: messageData.author,
                          fromMe: messageData.fromMe,
                          body: messageData.body,
                          timestamp: messageData.timestamp,
                          type: messageData.type,
                          media: messageData.media,
                          delivery: messageData.delivery,
                          seen: messageData.seen,
                          hasQuotedMsg: messageData.hasQuotedMsg,
                          quotedMessageBody: messageData.quotedMessageBody,
                          quotedMessageType: messageData.quotedMessageType,
                          onLeftSwipe: () => onMessageSwipe(
                            messageData.body,
                            true,
                            messageData.type,
                          ),
                        );
                      }
                      return SenderMessageCard(
                        id: messageData.id,
                        author: messageData.author,
                        fromMe: messageData.fromMe,
                        body: messageData.body,
                        timestamp: messageData.timestamp,
                        type: messageData.type,
                        media: messageData.media,
                        delivery: messageData.delivery,
                        seen: messageData.seen,
                        hasQuotedMsg: messageData.hasQuotedMsg,
                        quotedMessageBody: messageData.quotedMessageBody,
                        quotedMessageType: messageData.quotedMessageType,
                        onRightSwipe: () => onMessageSwipe(
                          messageData.body,
                          false,
                          messageData.type,
                        ),
                      );
                    },
                  );
                });
          }
        });
  }
}
