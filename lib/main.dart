
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/common/widgets/error.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/auth/screens/load_messages_screen.dart';
import 'package:whatsapp_ui/features/auth/screens/login_screen.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/landing/screens/landing_screen.dart';
import 'package:whatsapp_ui/firebase_options.dart';
import 'package:whatsapp_ui/models/chat.dart';
import 'package:whatsapp_ui/models/message.dart';
import 'package:whatsapp_ui/requests/ApiService.dart';
import 'package:whatsapp_ui/router.dart';
import 'package:whatsapp_ui/mobile_layout_screen.dart';
import 'package:whatsapp_ui/utils/DeviceUtils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<bool> hasLoadedAllMessages(BuildContext context, WidgetRef ref) async {
    return await ref.read(chatControllerProvider).getHasLoadedAllMessages(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whatsapp UI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          color: appBarColor,
        ),
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: ref.watch(userDataAuthProvider).when(
        data: (user) {
          if (user == null) {
            return const LandingScreen();
          }
          return FutureBuilder<bool>(
            future: hasLoadedAllMessages(context, ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Show a loading indicator while waiting
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}'); // Handle errors if necessary
              } else if (!snapshot.data!) {
                return const LoadMessagesScreen();
              } else {
                return const MobileLayoutScreen();
              }
            },
          );
        }, error: (Object error, StackTrace stackTrace) {
            throw error;
      }, loading: () {
        return Loader();
      },
        // ... (handle other states if necessary)
      ),
    );
  }
}
