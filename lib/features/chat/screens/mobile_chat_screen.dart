import 'package:com.jee.tag.whatagsapp/features/chat/widgets/selecte_share_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/call/controller/call_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/call/screens/call_pickup_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/bottom_chat_field.dart';
import 'package:com.jee.tag.whatagsapp/models/user_model.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/chat_list.dart';

class MobileChatScreen extends ConsumerStatefulWidget {
  static const String routeName = '/mobile-chat-screen';
  final String name;
  final String uid;
  final bool isGroupChat;
  final int unreadCount;
  final String profilePic;

  const MobileChatScreen({
    Key? key,
    required this.name,
    required this.unreadCount,
    required this.uid,
    required this.isGroupChat,
    required this.profilePic,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  String get name => widget.name;

  String get uid => widget.uid;

  bool get isGroupChat => widget.isGroupChat;

  String get profilePic => widget.profilePic;

  void hideShareOption() {
    showShareOptions = false;
    setState(() {});
  }

  void makeCall(WidgetRef ref, BuildContext context) {
    ref.read(callControllerProvider).makeCall(
          context,
          name,
          uid,
          profilePic,
          isGroupChat,
        );
  }

  bool showShareOptions = false;

  @override
  Widget build(BuildContext context) {
    return CallPickupScreen(
      scaffold: Scaffold(
        appBar: AppBar(
          backgroundColor: appBarColor,
          title: Text(name),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () => makeCall(ref, context),
              icon: const Icon(Icons.video_call),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  InkWell(
                    onTap: showShareOptions ? hideShareOption : null,
                    child: ChatList(
                      chatId: uid,
                      isGroupChat: isGroupChat,
                      unreadCount: widget.unreadCount,
                    ),
                  ),

                    Positioned(
                      right: 0,
                      left: 0,
                      bottom: 0,
                      child: Visibility(
                         visible: showShareOptions,
                        child: SelectShareOptionContainer(
                          recieverUserId: uid,
                          ref: ref,
                          hideShareButton: () {
                            showShareOptions = false;
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            BottomChatField(
              recieverUserId: uid,
              isGroupChat: isGroupChat,
              setShareVisibility: (val) {
                showShareOptions = val;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
