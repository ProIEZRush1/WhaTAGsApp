import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';

import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/my_message_card.dart';
import 'package:whatsapp_ui/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapp_ui/models/message.dart';

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
    return StreamBuilder<List<Message>>(
        stream: ref
                .read(chatControllerProvider)
                .chatStream(context, ref, widget.recieverUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            // Handle the case where snapshot.data is null
            return Text('No data available');
          }

          SchedulerBinding.instance.addPostFrameCallback((_) {
            messageController
                .jumpTo(messageController.position.maxScrollExtent);
          });

          return ListView.builder(
            controller: messageController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final messageData = snapshot.data![index];
              var timeSent = messageData.timestamp;

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
}
