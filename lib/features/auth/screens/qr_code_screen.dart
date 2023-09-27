import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/requests/ApiService.dart';
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/FIleUtils.dart';

class QRCodeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr-code';
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen> {
  Image qrCodeImage = const Image(image: AssetImage("assets/loading.gif"), width: 300, height: 300,);

  @override
  void initState() {
    super.initState();

    isLoggedIn(false).then((loggedIn) {
      if (loggedIn) {
        storeUserData();
      }
      else {
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

    final data = await apiService.get(context, ref, "${apiService.isLoggedInEndpoint}?deviceToken=$deviceToken");
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
    final ApiService apiService = ApiService();

    final deviceToken = await DeviceUtils.getDeviceId();

    final data = await apiService.get(context, ref, "${apiService.generateQrCodeEndpoint}?deviceToken=$deviceToken");
    if (!apiService.checkSuccess(data)) {
      Fluttertoast.showToast(msg: 'Something went wrong');
      return;
    }
    final qrCodeUrl = data['qrCodeUrl'];

    setState(() {
      qrCodeImage = Image.network(qrCodeUrl);
    });
  }

  void storeUserData() async {
    ref.read(authControllerProvider).saveUserDataToFirebase(
      context,
      "",
      null,
    );
  }

  void refreshQRCode() {
    setState(() {
      qrCodeImage = const Image(image: AssetImage("assets/loading.gif"), width: 300, height: 300,);
    });
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
      storeUserData();
    }
    else {
      // Create dialog
      showPlatformDialog(context: context, builder: (context) => BasicDialogAlert(
        title: Text('Login not detected'),
        content: Text('Your login has not been detected. Please try again'),
        actions: <Widget>[
          BasicDialogAction(
            title: Text('Ok'),
            onPressed: () {
              Navigator.pop(context);
            }
          )
        ]
      ));
    }
    checkingLogin = false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'WhaTAGsApp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The Kosher WhatsApp',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              Expanded(
                child: qrCodeImage, // Replace with your image URL or use an asset
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => refreshQRCode(),
                child: Text('Refresh QR Code'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => checkLogin(true),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Colors.green
                  )
                ),
                child: Text('Check Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
