import 'dart:io';
import 'package:com.jee.tag.whatagsapp/features/chat/repositories/chat_database.dart';
import 'package:com.jee.tag.whatagsapp/mobile_layout_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/FIleUtils.dart';
import 'package:uuid/uuid.dart';

class QRCodeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr-code';

  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen> {
  Image qrCodeImage = const Image(
    image: AssetImage("assets/loading.gif"),
    width: 300,
    height: 300,
  );
  String? qrCodeLocalPath;
  bool qrCodeLoading = true;

  @override
  void initState() {
    super.initState();

    isLoggedIn(false).then((loggedIn) {
      if (loggedIn) {
        storeUserData();
      } else {
        generateQrCode();
      }
    });
  }

  Future<bool> isLoggedIn(dialog) async {
    ProgressDialog? progressDialog;
    if (dialog) {
      progressDialog = ProgressDialog(context: context);
      progressDialog.show(max: 1, msg: 'Communicating with the server');
    }

    final ApiService apiService = ApiService();

    final deviceToken = await DeviceUtils.getDeviceId();
    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    final data = await apiService.get(context, ref,
        "${apiService.isLoggedInEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid");
    if (!apiService.checkSuccess(data)) {
      Fluttertoast.showToast(msg: 'Something went wrong');
      return false;
    }
    final loggedIn = data['loggedIn'];

    if (dialog) {
      progressDialog!.close();
    }

    return loggedIn;
  }

  void generateQrCode() async {
    qrCodeLoading = true;

    final ApiService apiService = ApiService();

    final deviceToken = await DeviceUtils.getDeviceId();
    final firebaseUid =
        ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

    final data = await apiService.get(context, ref,
        "${apiService.generateQrCodeEndpoint}?deviceToken=$deviceToken&firebaseUid=$firebaseUid&uuid=${Uuid().v4()}");
    if (!apiService.checkSuccess(data)) {
      Fluttertoast.showToast(msg: 'Something went wrong');
      return;
    }
    final qrCodeUrl = data['qrCodeUrl'];

    // Download the image from the URL
    final dio = Dio();
    final response = await dio.get(qrCodeUrl,
        options: Options(responseType: ResponseType.bytes));
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/{$deviceToken}${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(filePath);

    // Write the image into a file in the temporary directory
    await file.writeAsBytes(response.data);

    setState(() {
      qrCodeImage = Image.file(File(filePath));
      qrCodeLocalPath = filePath;
      qrCodeLoading = false;
    });
  }

  void shareQRCode() {
    if (qrCodeLoading) {
      showPlatformDialog(
          context: context,
          builder: (context) => BasicDialogAlert(
                  title: const Text('QR Code not generated'),
                  content: const Text('Please generate the QR Code first'),
                  actions: <Widget>[
                    BasicDialogAction(
                        title: const Text('Ok'),
                        onPressed: () {
                          Navigator.pop(context);
                        })
                  ]));
    } else {
      Share.shareXFiles([XFile(qrCodeLocalPath!)]);
    }
  }

  void storeUserData() async {
    ref.read(authControllerProvider).saveUserDataToFirebase(context);
  }

  void refreshQRCode() async {
    setState(() {
      qrCodeImage = const Image(
        image: AssetImage("assets/loading.gif"),
        width: 300,
        height: 300,
      );
      qrCodeLocalPath = null;
      qrCodeLoading = true;
    });

    final loggedIn = await isLoggedIn(false);
    if (loggedIn) {
      // Generate dialog
      showPlatformDialog(
          context: context,
          builder: (context) => BasicDialogAlert(
                  title: const Text('Logged in'),
                  content: const Text(
                      "You are already logged in, click the 'Check Login' button"),
                  actions: <Widget>[
                    BasicDialogAction(
                        title: const Text('Ok'),
                        onPressed: () {
                          Navigator.pop(context);
                        })
                  ]));

      setState(() {
        qrCodeLoading = false;
      });
      return;
    }

    generateQrCode();
  }

  bool checkingLogin = false;

  void checkLogin(dialog) async {
    if (checkingLogin) {
      return;
    }
    checkingLogin = true;

    final loggedIn = await isLoggedIn(dialog);
    if (loggedIn) {
      final ChatDatabase chatDatabase = ChatDatabase();
      chatDatabase.deleteAll();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MobileLayoutScreen(),
        ),
        (route) => false,
      );

      storeUserData();
    } else {
      // Create dialog
      showPlatformDialog(
          context: context,
          builder: (context) => BasicDialogAlert(
                  title: const Text('Login not detected'),
                  content: const Text(
                      'Your login has not been detected. Please try again'),
                  actions: <Widget>[
                    BasicDialogAction(
                        title: const Text('Ok'),
                        onPressed: () {
                          Navigator.pop(context);
                        })
                  ]));
    }
    checkingLogin = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ZapChat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The Kosher WhatsApp',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => shareQRCode(),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share),
                  ],
                ),
              ),
              Expanded(
                child:
                    qrCodeImage, // Replace with your image URL or use an asset
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => refreshQRCode(),
                child: const Text('Refresh QR Code'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => checkLogin(true),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                child: const Text('Check Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
