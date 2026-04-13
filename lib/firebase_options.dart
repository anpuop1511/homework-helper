// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyA4KoQWIUyoDZYte4pWUu46K-YXzIzLZRA',
    ),
    appId: '1:911283793659:web:202e8c9f1de4db4f270a5e',
    messagingSenderId: '911283793659',
    projectId: 'hwhelp-9390f',
    authDomain: 'hwhelp-9390f.firebaseapp.com',
    storageBucket: 'hwhelp-9390f.firebasestorage.app',
    measurementId: 'G-006YK5TCNQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIzaSyAnmpl7UtVbtvf6jROV_9xL1j4luv36X9o',
    ),
    appId: '1:911283793659:android:aa8131111c319b0a270a5e',
    messagingSenderId: '911283793659',
    projectId: 'hwhelp-9390f',
    storageBucket: 'hwhelp-9390f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.homeworkHelper',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_MACOS_API_KEY',
    appId: 'REPLACE_WITH_MACOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.homeworkHelper',
  );
}