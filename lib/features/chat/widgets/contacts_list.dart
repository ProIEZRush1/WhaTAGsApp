import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/screens/mobile_chat_screen.dart';
import 'package:whatsapp_ui/models/chat.dart';
import 'package:whatsapp_ui/models/group.dart';
import 'package:whatsapp_ui/utils/DateUtils.dart';

class ContactsList extends ConsumerWidget {
  const ContactsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<List<Chat>>(
                stream: ref.watch(chatControllerProvider).chatsStream(context, ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Loader();
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    // Handle the case where snapshot.data is null
                    return Text('No data available');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var chatContactData = snapshot.data![index];

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                MobileChatScreen.routeName,
                                arguments: {
                                  'name': chatContactData.contact.name,
                                  'uid': chatContactData.chatId,
                                  'isGroupChat': false,
                                  'profilePic': chatContactData.contact.profilePicUrl,
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(
                                  chatContactData.contact.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    chatContactData.lastMessage.body,
                                    style: const TextStyle(fontSize: 15),
                                    maxLines: 2,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    chatContactData.contact.profilePicUrl,
                                  ),
                                  radius: 30,
                                ),
                                trailing: Text(
                                  DateUtils.formatDate(DateTime.fromMicrosecondsSinceEpoch(chatContactData.lastMessage.timestamp)),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Divider(color: dividerColor, indent: 85),
                        ],
                      );
                    },
                  );
                }),
          ],
        ),
      ),
    );
  }
}
