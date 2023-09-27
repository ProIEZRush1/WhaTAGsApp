import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/screens/mobile_chat_screen.dart';
import 'package:com.jee.tag.whatagsapp/models/chat.dart';
import 'package:com.jee.tag.whatagsapp/models/group.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';

class ContactsList extends ConsumerWidget {
  const ContactsList({Key? key}) : super(key: key);

  void reviveClient(BuildContext context, WidgetRef ref) async {
    final ApiService apiService = ApiService();

    final deviceToken = await DeviceUtils.getDeviceId();

    final data = await apiService.get(context, ref, "${apiService.reviveClientEndpoint}?deviceToken=$deviceToken");
    if (!apiService.checkSuccess(data)) {
      Fluttertoast.showToast(msg: 'Something went wrong');
      return;
    }
    if (!await apiService.checkIfLoggedIn(context, ref, data)) {
      return;
    }
    final message = data['message'];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    reviveClient(context, ref);

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
                    physics: const NeverScrollableScrollPhysics(),
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
