import 'dart:io';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/group/screens/create_group_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/select_contacts/screens/select_contacts_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/contacts_list.dart';
import 'package:com.jee.tag.whatagsapp/features/status/screens/confirm_status_screen.dart';
import 'package:path_provider/path_provider.dart';

class MobileLayoutScreen extends ConsumerStatefulWidget {
  const MobileLayoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileLayoutScreen> createState() => _MobileLayoutScreenState();
}

class _MobileLayoutScreenState extends ConsumerState<MobileLayoutScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late TabController tabBarController;

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authControllerProvider).setUserState(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
        ref.read(authControllerProvider).setUserState(false);
        break;
    }
  }

  String searchTerm = "";
  bool isSearching = false;

  void clearSearch() {
    setState(() {
      searchTerm = "";
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isSearching) {
          setState(() {
            isSearching = false;
            searchTerm = "";
          });
          return false; // Prevent the pop action.
        }
        return true; // Allow the pop action.
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: appBarColor,
            centerTitle: false,
            title: isSearching
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            isSearching = false;
                            searchTerm = "";
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search chats...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(color: Colors.grey, fontSize: 18),
                          onChanged: (value) {
                            setState(() {
                              searchTerm = value;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'ZapChat',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            actions: isSearching
                ? []
                : [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          isSearching = true;
                        });
                      },
                    ),
                    PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.grey,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text(
                            'Create Group',
                          ),
                          onTap: () => Future(
                            () => Navigator.pushNamed(
                                context, CreateGroupScreen.routeName),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Text(
                            'Log out',
                          ),
                          onTap: () async {
                            var resp = await ApiService().logout(ref, context);
                            print('resp == $resp');
                          },
                        ),
                      ],
                    ),
                  ],
            bottom: TabBar(
              controller: tabBarController,
              indicatorColor: tabColor,
              indicatorWeight: 4,
              labelColor: tabColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(
                  text: 'CHATS',
                ),
                /*Tab(
                text: 'STATUS',
              ),*/
                Tab(
                  text: 'CALLS',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: tabBarController,
            children: [
              ContactsList(searchTerm: searchTerm, onChatOpened: clearSearch),
              //StatusContactsScreen(),
              const Center(child: Text('Calls are coming soon')),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              if (tabBarController.index == 0) {
                Navigator.pushNamed(context, SelectContactsScreen.routeName);
              } else {
                File? pickedImage = await pickImageFromGallery(context);
                if (pickedImage != null) {
                  if (context.mounted) {
                    Navigator.pushNamed(
                      context,
                      ConfirmStatusScreen.routeName,
                      arguments: pickedImage,
                    );
                  }
                }
              }
            },
            backgroundColor: tabColor,
            child: const Icon(
              Icons.comment,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
