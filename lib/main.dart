import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  // final directory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter('hive_data');
   AudioContext audioContext = const AudioContext(
    iOS: AudioContextIOS(
      // defaultToSpeaker: true,
      category: AVAudioSessionCategory.playback,
      options: [
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.mixWithOthers,
      ],
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: true,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );
  AudioPlayer.global.setAudioContext(audioContext);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

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
          } else {
            return const MobileLayoutScreen();
          }
        },
        error: (Object error, StackTrace stackTrace) {
          throw error;
        },
        loading: () {
          return const Loader();
        },
      ),
    );
  }
}
// #include? "../Pods/Target Support Files/Pods-Target Name/Pods-Target Name.debug.xcconfig"
// #include "Generated.xcconfig"
// #include? "../Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
// #include "Generated.xcconfig"