import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/requests/ApiService.dart';
import 'package:whatsapp_ui/utils/DeviceUtils.dart';
import 'package:whatsapp_ui/utils/FIleUtils.dart';

class QRCodeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/qr-code';
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen> {
  Image qrCodeImage = const Image(image: AssetImage("assets/loading.gif"), fit: BoxFit.cover);

  @override
  void initState() {
    super.initState();
    //storeUserData();
    isLoggedIn();
  }

  void isLoggedIn() async {
    final ApiService isLoggedInService = ApiService();

    final authController = ref.read(authControllerProvider);
    final userData = await authController.getUserData();
    final deviceToken = await DeviceUtils.getDeviceId();

    final data = await isLoggedInService.get("${isLoggedInService.isLoggedInEndpoint}?deviceToken=$deviceToken");
    print("HOLA " + data.toString());
  }

  void storeUserData() async {
    ref.read(authControllerProvider).saveUserDataToFirebase(
      context,
      "",
      null,
    );
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
                onPressed: () {
                  // Logic to refresh the QR code
                },
                child: Text('Refresh QR Code'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Logic to check login
                },
                child: Text('Check Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
