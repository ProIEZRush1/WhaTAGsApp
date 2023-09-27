import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/mobile_layout_screen.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';

class LoadMessagesScreen extends ConsumerStatefulWidget {
  static const routeName = '/load-messages-screen';
  const LoadMessagesScreen({Key? key}) : super(key: key);

  @override
  _LoadMessagesScreenState createState() => _LoadMessagesScreenState();
}

class _LoadMessagesScreenState extends ConsumerState<LoadMessagesScreen> {

  void loadMessages() async {
    final ApiService apiService = ApiService();
    final deviceToken = await DeviceUtils.getDeviceId();
    final firebaseUid = ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    final ProgressDialog apiProgressDialog = ProgressDialog(context: context);
    apiProgressDialog.show(max: 1, msg: 'Communicating with the server');

    final data = await apiService.get(context, ref, "${apiService.loadMessagesEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid");
    if (!apiService.checkSuccess(data)) {
      Fluttertoast.showToast(msg: 'Something went wrong');
      return;
    }
    if (!await apiService.checkIfLoggedIn(context, ref, data)) {
      return;
    }
    final message = data['message'];

    apiProgressDialog.close();

    // Messages will be loaded in the server in the background
    ProgressDialog progressDialog = ProgressDialog(context: context);
    progressDialog.update(value: 0);

    final controller = ref.read(chatControllerProvider);
    Stream<int?> actualChatLengthStream = controller.actualChatLengthStream(context, ref);
    int realChatLength = await controller.getRealChatLength(context, ref);
    progressDialog.show(max: realChatLength, msg: 'Loading chats');

    // Listen to the stream and update the progressDialog accordingly
    StreamSubscription<int?>? subscription;
    subscription = actualChatLengthStream.listen((actualLength) async {
      if (actualLength != null) {
        progressDialog.update(value: actualLength); // Assuming your progressDialog has an update method

        if (actualLength == realChatLength) {
          progressDialog.close();

          final hasLoadedAllMessages = await controller.getHasLoadedAllMessages(context, ref);
          if (hasLoadedAllMessages) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const MobileLayoutScreen(),
            ));
          }
        }
      }
    }, onError: (error) {
      // Handle any error from the stream if necessary
      print("Error: $error");
    }, onDone: () {
      print("Done");
      progressDialog.close(delay: 2);
      subscription?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'We need to load all your messages',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: loadMessages,
              child: Text('Load messages'),
            ),
          ],
        ),
      ),
    );
  }
}
