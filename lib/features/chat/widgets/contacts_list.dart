import 'dart:ffi';

import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

// Imported your project-specific libraries
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/screens/mobile_chat_screen.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';

class ContactsList extends ConsumerWidget {
  const ContactsList({Key? key}) : super(key: key);

  Future<void> reviveClient(BuildContext context, WidgetRef ref) async {
    final ApiService apiService = ApiService();
    final deviceToken = await DeviceUtils.getDeviceId();
    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    final data = await apiService.get(context, ref,
        "${apiService.reviveClientEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid");
    if (!apiService.checkSuccess(data)) {
      Fluttertoast.showToast(msg: 'Something went wrong');
      return;
    }
    if (!await apiService.checkIfLoggedIn(context, ref, data)) {
      return;
    }
  }

  Future<String?> getContactName(String phoneNumber) async {
    final contacts = await FlutterContacts.getContacts();
    for (var contact in contacts) {
      for (final phone in contact.phones) {
        if (phone.number.replaceAll(RegExp(r'\D'), '') ==
            phoneNumber.replaceAll(RegExp(r'\D'), '')) {
          return contact.displayName;
        }
      }
    }
    return null; // Return null if no contact is found
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    reviveClient(context, ref);
    return FutureBuilder<String>(
      future: DeviceUtils.getDeviceId(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final String encryptionKey =
              EncryptionUtils.deriveKeyFromPassword(snapshot.data!, "salt");

          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: ref
                        .watch(chatControllerProvider)
                        .chatsStream(context, ref, encryptionKey),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Loader();
                      }

                      if (!snapshot.hasData || snapshot.data == null) {
                        // Handle the case where snapshot.data is null
                        return const Text('No data available');
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var chatContactData = snapshot.data![index];

                          String phoneNumber =
                              chatContactData["id"].split("@")[0];

                          if (chatContactData["lastMessage"]["body"] == null) {
                            return Container();
                          }

                          return FutureBuilder<String?>(
                            future: getContactName(phoneNumber),
                            builder: (context, nameSnapshot) {
                              if (nameSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              final contactName = chatContactData["name"] ??
                                  (nameSnapshot.data ?? "+$phoneNumber");

                              final unreadCount =
                                  chatContactData["unreadCount"] ?? 0;

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        MobileChatScreen.routeName,
                                        arguments: {
                                          'name': contactName,
                                          'uid': chatContactData["id"],
                                          'isGroupChat': false,
                                          'profilePic':
                                              chatContactData["profilePicUrl"],
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: ListTile(
                                        title: Text(
                                          contactName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6.0),
                                          child: Text(
                                            chatContactData["lastMessage"]
                                                    ["body"] ??
                                                "",
                                            style:
                                                const TextStyle(fontSize: 15),
                                            maxLines: 2,
                                          ),
                                        ),
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            chatContactData["profilePicUrl"],
                                          ),
                                          radius: 30,
                                        ),
                                        trailing: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              DateUtils.formatDate(
                                                  chatContactData["lastMessage"]
                                                          ["timestamp"] *
                                                      1000),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            unreadCount > 0
                                                ? Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 2.0,
                                                        horizontal: 8.0),
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 4.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      unreadCount.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  )
                                                : Text("")
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                      color: dividerColor, indent: 85),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
