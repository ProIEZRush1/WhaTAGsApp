import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/load_messages_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/landing/screens/landing_screen.dart';
import 'package:com.jee.tag.whatagsapp/firebase_options.dart';
import 'package:com.jee.tag.whatagsapp/router.dart';
import 'package:com.jee.tag.whatagsapp/mobile_layout_screen.dart';

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
                return const CircularProgressIndicator(); // Show a loading indicator while waiting
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
