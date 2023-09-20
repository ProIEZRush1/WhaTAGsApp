// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA571m0rgZsMZXUTaL5Lf9WY3DNwxmQBVw',
    appId: '1:797644769847:web:bcec2e79e8d27184d00db2',
    messagingSenderId: '797644769847',
    projectId: 'tag1-3a41d',
    authDomain: 'tag1-3a41d.firebaseapp.com',
    storageBucket: 'tag1-3a41d.appspot.com',
    measurementId: 'G-HSEES8YXQ3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAu_Xgi5N_-uOED-lHL-PxZbM44h5r3Ieo',
    appId: '1:797644769847:android:a9faca26c19928ecd00db2',
    messagingSenderId: '797644769847',
    projectId: 'tag1-3a41d',
    storageBucket: 'tag1-3a41d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6kaFS6MJZgzrugkL-Gd9orOrAVRj2n1Y',
    appId: '1:797644769847:ios:9208d876f91684ded00db2',
    messagingSenderId: '797644769847',
    projectId: 'tag1-3a41d',
    storageBucket: 'tag1-3a41d.appspot.com',
    iosBundleId: 'com.example.whatsappUi',
  );
}
