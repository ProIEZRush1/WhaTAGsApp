import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/DialogUtils.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';

// Imported your project-specific libraries
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/screens/mobile_chat_screen.dart';
import 'package:com.jee.tag.whatagsapp/utils/DateUtils.dart';

class ContactsList extends ConsumerStatefulWidget {
  final String searchTerm;
  final Function onChatOpened;

  const ContactsList(
      {Key? key, required this.searchTerm, required this.onChatOpened})
      : super(key: key);

  @override
  _ContactsListState createState() => _ContactsListState();
}

class _ContactsListState extends ConsumerState<ContactsList> {
  String? lastDeviceId;
  String? lastEncryptionKey;
  List<Contact>? get cachedContacts=>MessageUtils.cachedContacts;

  Stream<List<Map<String, dynamic>>>? stream;
  List<Map<String, dynamic>>? cachedStreamData;

  Future<Map<String, dynamic>>? valuesData;

  @override
  void initState() {
    super.initState();
    valuesData = _initializeData();
  }

  Future<Map<String, dynamic>> _initializeData() async {
    // Open the Hive box for storing config values
    var box = await Hive.openBox('config');

    // Check if lastDeviceId is already stored, otherwise fetch and store it
    lastDeviceId = box.get('lastDeviceId') ?? await DeviceUtils.getDeviceId();
    box.put('lastDeviceId', lastDeviceId);

    // Same for lastEncryptionKey
    lastEncryptionKey = box.get('lastEncryptionKey') ??
        await EncryptionUtils.deriveKeyFromPassword(lastDeviceId!, "salt");
    box.put('lastEncryptionKey', lastEncryptionKey);

    if (await FlutterContacts.requestPermission()) {
      print('contact sync from Device');
      FlutterContacts.getContacts(withProperties: true)
          .then((value) {
            print(value.first.name);
            print(value.first.phones.first.number);
            return MessageUtils.cachedContacts = value;
          });
    }

    final ChatDatabase chatDatabase = ChatDatabase();
    cachedStreamData = await chatDatabase.getChats();

    // Initialize the stream
    stream ??= ref.watch(chatControllerProvider).chatsStream(
          context,
          ref,
          lastEncryptionKey!,
        );

    final ApiService apiService = ApiService();

    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;
    apiService
        .get(context, ref,
            "${apiService.reviveClientEndpoint}?deviceToken=$lastDeviceId&firebaseUid=$firebaseUid")
        .then((value) {
      if (!apiService.checkSuccess(value)) {
        Fluttertoast.showToast(msg: 'Something went wrong');
      }
      apiService.checkIfLoggedIn(context, ref, value);
    });

    return {
      'lastDeviceId': lastDeviceId,
      'lastEncryptionKey': lastEncryptionKey,
      'cachedContacts': cachedContacts,
    };
  }

  String searchTerm = "";

  List<Map<String, dynamic>> filterChats(List<Map<String, dynamic>> chats) {
    if (searchTerm.isEmpty) {
      return chats;
    }
    return chats.where((chat) {
      if (chat["id"] == null) {
        return false;
      }

      final phoneNumber = chat["id"]!.split("@")[0];
      final contactName =MessageUtils.getNameFromData(chat["id"] ,name: chat["name"] );
          // getContactName(phoneNumber) ?? chat["name"] ?? "+$phoneNumber";
      return contactName.toLowerCase().contains(searchTerm.toLowerCase()) ||
          phoneNumber.toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();
  }

  @override
  void didUpdateWidget(covariant ContactsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchTerm != oldWidget.searchTerm) {
      searchTerm = widget.searchTerm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: valuesData,
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
                return (cachedStreamData == null || cachedStreamData!.isEmpty)
                    ? const Loader()
                    : getListView(cachedStreamData);
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
    data = filterChats(data ?? []);
    return ListView.builder(
      //physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: data.length,
      itemBuilder: (context, index) {
        var chatContactData = data![index];
        if (chatContactData["id"] == null ||
            chatContactData["archived"] != null) {
          return Container();
        }

        final String id = chatContactData["id"];
        final profilePicUrl = chatContactData["profilePicUrl"];
        final profilePicUrlHigh = chatContactData["profilePicUrlHigh"];

        // String phoneNumber = id.split("@")[0];
        final contactName = MessageUtils.getNameFromData(id,name: chatContactData['name']) ;
        // ??
            // chatContactData["name"] ??
            // "+$phoneNumber";
        final unreadCount = chatContactData["unreadCount"] ?? 0;

        final TextSpan highlightedName =
            getHighlightedText(contactName, searchTerm);
        final bool isGroupChat= id.contains('@g.us');

        return Column(
          children: [
            InkWell(
              onTap: () {
                openChat(id, contactName, isGroupChat, profilePicUrl);
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: RichText(
                    text: TextSpan(
                      children: [highlightedName],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Default text color
                      ),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: FutureBuilder(
                      future: EncryptionUtils.decrypt(
                          chatContactData["lastMessage"]["body"],
                          lastEncryptionKey!),
                      builder: (context, bodySnapshot) {
                        // if (bodySnapshot.connectionState ==
                        //     ConnectionState.waiting) {
                        //   return const Loader(color: Colors.red,);
                        // }
                        if (bodySnapshot.hasError) {
                          return Text('Error: ${bodySnapshot.error}');
                        }

                        return Text(
                          bodySnapshot.data?.toString() ?? "",
                          style: const TextStyle(fontSize: 15),
                          maxLines: 2,
                        );
                      },
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      chatContactData["profilePicUrl"],
                    ),
                    radius: 30,
                    child: GestureDetector(
                      onTap: () {
                        Dialog profileDialog = DialogUtils.getProfileDialog(
                          context,
                          id,
                          profilePicUrlHigh,
                          contactName,
                          () {
                            Navigator.pop(context);
                            openChat(id, contactName, isGroupChat, profilePicUrl);
                          },
                          () {},
                          () {},
                          () {},
                        );

                        showGeneralDialog(
                            context: context,
                            pageBuilder: (_, __, ___) => profileDialog,
                            transitionBuilder: (_, anim, __, child) {
                              return FadeTransition(
                                opacity: anim,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 200),
                            barrierDismissible: true,
                            barrierLabel: "");
                      },
                    ),
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

  TextSpan getHighlightedText(String text, String highlight) {
    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
      return TextSpan(text: text);
    }

    List<TextSpan> spans = [];
    int startIndex = 0;
    int highlightStart =
        text.toLowerCase().indexOf(highlight.toLowerCase(), startIndex);

    while (highlightStart >= 0) {
      if (highlightStart > startIndex) {
        spans.add(TextSpan(text: text.substring(startIndex, highlightStart)));
      }
      spans.add(TextSpan(
        text: text.substring(highlightStart, highlightStart + highlight.length),
        style: const TextStyle(color: Colors.green),
      ));

      startIndex = highlightStart + highlight.length;
      highlightStart =
          text.toLowerCase().indexOf(highlight.toLowerCase(), startIndex);
    }

    if (startIndex < text.length) {
      spans.add(TextSpan(text: text.substring(startIndex)));
    }

    return TextSpan(children: spans);
  }

  void openChat(
      String id, String contactName, bool isGroupChat, String profilePicUrl) {
    widget.onChatOpened();
    Navigator.pushNamed(
      context,
      MobileChatScreen.routeName,
      arguments: {
        'name': contactName,
        'uid': id,
        'isGroupChat': isGroupChat,
        'profilePic': profilePicUrl,
      },
    );
  }
}
