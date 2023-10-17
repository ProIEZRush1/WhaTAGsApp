import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hive/hive.dart';

// Imported your project-specific libraries
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/screens/mobile_chat_screen.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsList extends ConsumerStatefulWidget {
  ContactsList({Key? key}) : super(key: key);

  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends ConsumerState<ContactsList> {
  String? lastDeviceId;
  String? lastEncryptionKey;
  List<Contact>? cachedContacts;

  Stream<List<Map<String, dynamic>>>? stream;
  List<Map<String, dynamic>>? cachedStreamData;

  Future<Map<String, dynamic>>? data;

  @override
  void initState() {
    super.initState();
    data = _initializeData();
  }

  Future<void> requestContactPermission() async {
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted) {
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.contacts,
      ].request();
      if (statuses[Permission.contacts]!.isGranted) {
        FlutterContacts.getContacts(withProperties: true)
            .then((value) => cachedContacts = value);
      }
    }
  }

  Future<Map<String, dynamic>> _initializeData() async {
    // Open the Hive box for storing config values
    var box = await Hive.openBox('config');

    // Check if lastDeviceId is already stored, otherwise fetch and store it
    lastDeviceId = box.get('lastDeviceId') ?? await DeviceUtils.getDeviceId();
    box.put('lastDeviceId', lastDeviceId);

    // Same for lastEncryptionKey
    lastEncryptionKey = box.get('lastEncryptionKey') ??
        EncryptionUtils.deriveKeyFromPassword(lastDeviceId!, "salt");
    box.put('lastEncryptionKey', lastEncryptionKey);

    if (await Permission.contacts.isGranted) {
      FlutterContacts.getContacts(withProperties: true)
          .then((value) => cachedContacts = value);
    } else {
      requestContactPermission();
    }

    final ChatDatabase chatDatabase = ChatDatabase();
    cachedStreamData = await chatDatabase.getChats();

    // Initialize the stream
    stream ??= ref.watch(chatControllerProvider).chatsStream(
          context,
          ref,
          lastEncryptionKey!,
        );

    return {
      'lastDeviceId': lastDeviceId,
      'lastEncryptionKey': lastEncryptionKey,
      'cachedContacts': cachedContacts,
    };
  }

  String? getContactName(String phoneNumber) {
    String sanitizedInput = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (sanitizedInput.length >= 4) {
      sanitizedInput = sanitizedInput.substring(4);
    }

    if (cachedContacts != null) {
      for (var contact in cachedContacts!) {
        for (final phone in contact.phones) {
          String sanitizedContact = phone.number.replaceAll(RegExp(r'\D'), '');

          if (sanitizedContact.length >= 3) {
            sanitizedContact = sanitizedContact.substring(3);
          }

          if (sanitizedInput == sanitizedContact ||
              sanitizedContact == sanitizedInput) {
            return contact.displayName;
          }
        }
      }
    }
    return null; // Return null if no contact is found
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('An error occurred '));
        } else {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return (cachedStreamData == null || cachedStreamData!.isEmpty
                    ? const Loader()
                    : getListView(cachedStreamData));
              }

              if ((cachedStreamData == null || cachedStreamData!.isEmpty) &&
                  !streamSnapshot.hasData) {
                return const Text('No data available');
              }

              return getListView(streamSnapshot.data);
            },
          );
        }
      },
    );
  }

  Widget getListView(List<Map<String, dynamic>>? data) {
    return ListView.builder(
      //physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: data!.length,
      itemBuilder: (context, index) {
        var chatContactData = data[index];
        if (chatContactData["id"] == null) {
          return Container();
        }

        String phoneNumber = chatContactData["id"].split("@")[0];
        final contactName = getContactName(phoneNumber) ??
            chatContactData["name"] ??
            "+$phoneNumber";
        final unreadCount = chatContactData["unreadCount"] ?? 0;

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
                    'profilePic': chatContactData["profilePicUrl"],
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(
                    contactName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      chatContactData["lastMessage"]["body"] ?? "",
                      style: const TextStyle(fontSize: 15),
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
                            chatContactData["lastMessage"]["timestamp"] * 1000),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 8.0),
                              margin: const EdgeInsets.only(top: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const Text("")
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: dividerColor, indent: 85),
          ],
        );
      },
    );
  }
}
