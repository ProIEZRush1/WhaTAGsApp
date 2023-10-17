import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:com.jee.tag.whatagsapp/mobile_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/repositories/common_firebase_storage_repository.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/otp_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/qr_code_screen.dart';
import 'package:com.jee.tag.whatagsapp/models/user_model.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    messaging: FirebaseMessaging.instance,
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseMessaging messaging;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.messaging,
  });

  Future<bool> requestPushNotificationsPermissions(BuildContext context) async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return true;
    } else {
      showPlatformDialog(
          context: context,
          builder: (context) => BasicDialogAlert(
                  title: Text("Notifications"),
                  content:
                      Text("We need your permission to send notifications"),
                  actions: <Widget>[
                    BasicDialogAction(
                        title: Text("Accept"),
                        onPressed: () {
                          AppSettings.openAppSettings(
                              type: AppSettingsType.notification);
                          Navigator.pop(context);
                        }),
                    BasicDialogAction(
                        title: Text("Cancel"),
                        onPressed: () {
                          Navigator.pop(context);
                        })
                  ]));
      return false;
    }
  }

  void listenLoadPushNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("HOLA " + message.data.toString());
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    var userData =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();

    return userData.data();
  }

  void signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print(e.message);
        },
        codeSent: ((String verificationId, int? resendToken) async {
          Navigator.pushNamed(
            context,
            OTPScreen.routeName,
            arguments: verificationId,
          );
        }),
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      showSnackBar(context: context, content: e.message!);
    }
  }

  void verifyOTP({
    required BuildContext context,
    required String verificationId,
    required String userOTP,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: userOTP,
      );
      await auth.signInWithCredential(credential);
      Navigator.pushNamedAndRemoveUntil(
        context,
        QRCodeScreen.routeName,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context: context, content: e.message!);
    }
  }

  void saveUserDataToFirebase({
    required ProviderRef ref,
    required BuildContext context,
  }) async {
    try {
      String uid = auth.currentUser!.uid;

      var user = {
        "uid": uid,
        "phoneNumber": auth.currentUser!.phoneNumber!,
      };

      await firestore.collection('users').doc(uid).set(user);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  Stream<UserModel> userData(String userId) {
    return firestore.collection('users').doc(userId).snapshots().map(
          (event) => UserModel.fromMap(
            event.data()!,
          ),
        );
  }

  void setUserState(bool isOnline) async {
    await firestore.collection('users').doc(auth.currentUser!.uid).update({
      'isOnline': isOnline,
    });
  }
}
